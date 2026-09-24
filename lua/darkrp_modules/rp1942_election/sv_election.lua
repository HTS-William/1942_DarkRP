--[[---------------------------------------------------------------------------
1942 DarkRP - Führer election (server)

Every rule lives here. The client only ever asks ("enter", "vote for X");
the server checks everything again before doing it.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_ElectionSync")     -- server -> client: full state
util.AddNetworkString("RP1942_ElectionOpen")     -- server -> client: open the ballot
util.AddNetworkString("RP1942_ElectionChat")     -- server -> client: announcement
util.AddNetworkString("RP1942_ElectionAction")   -- client -> server: enter / vote / sync
util.AddNetworkString("RP1942_ElectionSound")    -- server -> client: "voting" / "anthem" / "fuhrerKilled"
util.AddNetworkString("RP1942_FuhrerKilled")     -- server -> client: show the death alert
util.AddNetworkString("RP1942_FuhrerElected")    -- server -> client: show the election result
util.AddNetworkString("RP1942_FuhrerBroadcast")  -- server -> client: show a /broadcast

-- Addon sound files have to be sent to players, or only the server has them.
-- Stock game sounds (not found as files here) need nothing.
for _, key in ipairs({ "voting", "anthem", "fuhrerKilled", "broadcast" }) do
    local path = RP1942.ElectionSounds[key]
    if path then
        if file.Exists(path, "GAME") then
            resource.AddFile(path)
        elseif string.find(path, "^sounds?/") then
            MsgC(Color(255, 170, 0), "[1942] Election sound '", key, "' not found at '", path,
                "'. Check the path in RP1942.ElectionSounds (sh_election.lua).\n")
        end
    end
end

local C = RP1942.ElectionConfig
local IDLE, REGISTRATION, VOTING = RP1942.ELECTION_IDLE, RP1942.ELECTION_REGISTRATION, RP1942.ELECTION_VOTING

local E = {
    phase = IDLE,
    endsAt = 0,
    candidates = {},    -- ordered list of { ply = Player, votes = 0, paid = fee }
    voted = {},         -- [Player] = the Player they voted for
}

--[[---------------------------------------------------------------------------
Helpers
---------------------------------------------------------------------------]]
local function announce(text, target)
    net.Start("RP1942_ElectionChat")
    net.WriteString(text)
    if target then net.Send(target) else net.Broadcast() end
end

local function findCandidate(ply)
    for i, c in ipairs(E.candidates) do
        if c.ply == ply then return c, i end
    end
end

-- Sends the state to one player (or everyone). Each player also learns who
-- they voted for, so the ballot can show it.
local function sync(target)
    local recipients = target and { target } or player.GetHumans()
    for _, ply in ipairs(recipients) do
        net.Start("RP1942_ElectionSync")
        net.WriteUInt(E.phase, 2)
        net.WriteFloat(E.endsAt)
        net.WriteUInt(#E.candidates, 8)
        for _, c in ipairs(E.candidates) do
            net.WriteEntity(c.ply)
            net.WriteUInt(c.votes, 10)
        end
        net.WriteEntity(E.voted[ply] or NULL)
        net.Send(ply)
    end
end

local function playSound(key)
    if not RP1942.ElectionSounds[key] then return end
    net.Start("RP1942_ElectionSound")
    net.WriteString(key)
    net.Broadcast()
end

local function openBallot(target)
    net.Start("RP1942_ElectionOpen")
    if target then net.Send(target) else net.Broadcast() end
end

local function reset()
    E.phase, E.endsAt = IDLE, 0
    E.candidates, E.voted = {}, {}
    sync()
end

local function refundAll(reason)
    for _, c in ipairs(E.candidates) do
        if IsValid(c.ply) then
            c.ply:addMoney(c.paid)
            DarkRP.notify(c.ply, 0, 5, "Your election fee of " .. DarkRP.formatMoney(c.paid) .. " was refunded.")
        end
    end
    announce(reason)
    reset()
end

--[[---------------------------------------------------------------------------
Phases
---------------------------------------------------------------------------]]
local function finish()
    table.sort(E.candidates, function(a, b) return a.votes > b.votes end)

    -- Everyone tied at the top gets an equal chance
    local top = E.candidates[1].votes
    local tied = {}
    for _, c in ipairs(E.candidates) do
        if c.votes == top then tied[#tied + 1] = c end
    end
    local winner = tied[math.random(#tied)]

    local pot = 0
    for _, c in ipairs(E.candidates) do pot = pot + c.paid end
    if C.feesToTreasury and RP1942.treasuryDeposit then
        RP1942.treasuryDeposit(pot, "election fees")
    end

    local results = {}
    for _, c in ipairs(E.candidates) do
        results[#results + 1] = string.format("%s %d", c.ply:Nick(), c.votes)
    end

    if #E.candidates == 1 then
        announce(winner.ply:Nick() .. " stood unopposed and has been elected Führer!")
    else
        local tieNote = #tied > 1 and " (a tie, decided by lot)" or ""
        announce(winner.ply:Nick() .. " has been elected Führer" .. tieNote .. "!  Results: " .. table.concat(results, ", "))
    end
    -- forced: the election IS the permission. Third argument silences DarkRP's
    -- own "has been made Führer" popup; the announcement above replaces it.
    winner.ply:changeTeam(TEAM_FUHRER, true, true)

    -- Everyone gets the result banner, with the anthem playing under it
    local totalVotes = 0
    for _, c in ipairs(E.candidates) do totalVotes = totalVotes + c.votes end
    net.Start("RP1942_FuhrerElected")
    net.WriteString(winner.ply:Nick())
    net.WriteUInt(winner.votes, 10)
    net.WriteUInt(totalVotes, 10)
    net.WriteUInt(#E.candidates == 1 and 1 or (#tied > 1 and 2 or 0), 2)
    net.Broadcast()
    playSound("anthem")

    reset()
end

local function startVoting()
    E.phase = VOTING
    E.endsAt = CurTime() + C.votingTime
    E.voted = {}
    announce("Registration is closed. Voting for Führer is open - type /election to cast your vote.")
    sync()
    if C.openOnVoting then openBallot() end
    playSound("voting")
end

local function closeRegistration()
    local n = #E.candidates
    if n == 0 then
        reset()
    elseif n == 1 then
        if C.unopposedWins then
            finish()
        else
            refundAll("Only one candidate stood, so the election was cancelled.")
        end
    else
        startVoting()
    end
end

--[[---------------------------------------------------------------------------
Actions
---------------------------------------------------------------------------]]
local function enter(ply)
    local fuhrer = RP1942.getFuhrer()
    if IsValid(fuhrer) then
        return DarkRP.notify(ply, 1, 4, fuhrer:Nick() .. " is already Führer. Wait until the office is vacant.")
    end
    if E.phase == VOTING then
        return DarkRP.notify(ply, 1, 4, "Voting has already started. You can still vote.")
    end
    if findCandidate(ply) then
        return DarkRP.notify(ply, 1, 4, "You are already standing in this election.")
    end
    if #E.candidates >= C.maxCandidates then
        return DarkRP.notify(ply, 1, 4, "The ballot is full.")
    end
    if ply:isArrested() then
        return DarkRP.notify(ply, 1, 4, "You can't stand for election from a cell.")
    end
    if not ply:canAfford(C.fee) then
        return DarkRP.notify(ply, 1, 4, "Standing for election costs " .. DarkRP.formatMoney(C.fee) .. ".")
    end

    ply:addMoney(-C.fee)
    table.insert(E.candidates, { ply = ply, votes = 0, paid = C.fee })

    if E.phase == IDLE then
        E.phase = REGISTRATION
        E.endsAt = CurTime() + C.registrationTime
        announce(ply:Nick() .. " is standing for Führer! The office is vacant - type /election to stand against them. Registration closes in " .. C.registrationTime .. " seconds.")
    else
        announce(ply:Nick() .. " has entered the election for Führer. (" .. #E.candidates .. " candidates)")
    end
    sync()
end

-- Players who can vote: everyone except the candidates
local function eligibleVoters()
    local n = 0
    for _, ply in ipairs(player.GetHumans()) do
        if not findCandidate(ply) then n = n + 1 end
    end
    return n
end

local function vote(ply, target)
    if E.phase ~= VOTING then return end
    if findCandidate(ply) then
        return DarkRP.notify(ply, 1, 3, "Candidates can't vote in their own election.")
    end
    if E.voted[ply] then
        return DarkRP.notify(ply, 1, 3, "You have already voted.")
    end
    local c = findCandidate(target)
    if not c then return end

    c.votes = c.votes + 1
    E.voted[ply] = target
    DarkRP.notify(ply, 0, 4, "You voted for " .. target:Nick() .. ".")
    sync()

    -- Everyone who can vote has: no reason to keep waiting
    if table.Count(E.voted) >= eligibleVoters() then E.endsAt = CurTime() end
end

--[[---------------------------------------------------------------------------
The clock: once a second
---------------------------------------------------------------------------]]
timer.Create("RP1942_Election", 1, 0, function()
    if E.phase == IDLE then return end

    -- A Führer appeared some other way (admin, etc.): nothing left to elect
    if IsValid(RP1942.getFuhrer()) then
        refundAll("A Führer is now in office. The election is cancelled.")
        return
    end

    -- Candidates who left the server drop off the ballot
    local changed = false
    for i = #E.candidates, 1, -1 do
        if not IsValid(E.candidates[i].ply) then
            table.remove(E.candidates, i)
            changed = true
        end
    end
    for voter, choice in pairs(E.voted) do
        if not IsValid(voter) or not IsValid(choice) then E.voted[voter] = nil end
    end

    if #E.candidates == 0 then
        announce("Every candidate has left. The election is cancelled.")
        reset()
        return
    end
    if changed then sync() end

    -- Nobody left who is allowed to vote (everyone online is standing):
    -- waiting can't change anything, so count now
    if E.phase == VOTING and eligibleVoters() == 0 then E.endsAt = CurTime() end

    if CurTime() < E.endsAt then return end
    if E.phase == REGISTRATION then
        closeRegistration()
    elseif E.phase == VOTING then
        finish()
    end
end)

--[[---------------------------------------------------------------------------
Client requests
---------------------------------------------------------------------------]]
net.Receive("RP1942_ElectionAction", function(_, ply)
    if not IsValid(ply) then return end
    local now = CurTime()
    if (ply.RP1942_NextElectionAction or 0) > now then return end
    ply.RP1942_NextElectionAction = now + 0.5

    local action = net.ReadString()
    if action == "enter" then
        enter(ply)
    elseif action == "vote" then
        local target = net.ReadEntity()
        if IsValid(target) and target:IsPlayer() then vote(ply, target) end
    elseif action == "sync" then
        sync(ply)
    end
end)

DarkRP.defineChatCommand("election", function(ply)
    sync(ply)
    openBallot(ply)
    return ""
end)

--[[---------------------------------------------------------------------------
Only the election hands out the Führer job. Clicking it in F4 (or /fuhrer)
opens the ballot instead. Forced changes (the winner, admins) go through.
This is a hook rather than the job's customCheck, because with
hideTeamUnbuyable on, a failing customCheck would hide the job from F4.
---------------------------------------------------------------------------]]
hook.Add("playerCanChangeTeam", "RP1942_ElectionOnly", function(ply, teamNr, force)
    if force or teamNr ~= TEAM_FUHRER then return end
    sync(ply)
    openBallot(ply)
    return false, "The Führer is chosen by election. The ballot is open on your screen."
end)

--[[---------------------------------------------------------------------------
The Führer died: tell everyone. Hooks run before DarkRP's own PlayerDeath,
which is where demoteOnDeath takes the job away, so the victim is still
Führer at this point.
---------------------------------------------------------------------------]]
hook.Add("PlayerDeath", "RP1942_FuhrerKilled", function(victim, _, attacker)
    local cfg = RP1942.FuhrerDeathAlert
    if not cfg.enabled or not IsValid(victim) or victim:Team() ~= TEAM_FUHRER then return end

    local murdered = IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim
    local killerName = (murdered and cfg.revealKiller) and attacker:Nick() or ""

    net.Start("RP1942_FuhrerKilled")
    net.WriteString(victim:Nick())
    net.WriteBool(murdered)
    net.WriteString(killerName)
    net.Broadcast()
    playSound("fuhrerKilled")

    local how = murdered and "has been assassinated" or "is dead"
    local by = killerName ~= "" and (" by " .. killerName) or ""
    announce("Führer " .. victim:Nick() .. " " .. how .. by .. ". The office is vacant - type /election to stand.")
end)

--[[---------------------------------------------------------------------------
/broadcast for the Führer. DarkRP has its own /broadcast (a plain chat line
for mayor jobs). canChatCommand runs before it, so for the Führer we show the
banner and return false, which stops DarkRP's version. Anyone else falls
through to DarkRP, which tells them it's the wrong job.
---------------------------------------------------------------------------]]
local function fuhrerBroadcast(ply, text)
    local cfg = RP1942.FuhrerBroadcast

    -- One line of plain text: no control characters, no surrounding spaces
    text = string.Trim(string.gsub(text or "", "%c", " "))
    local len = utf8.len(text)
    if not len then
        return DarkRP.notify(ply, 1, 4, "That message contains characters that can't be sent.")
    end
    if len == 0 then
        return DarkRP.notify(ply, 1, 4, "Usage: /broadcast <message>")
    end
    if len > cfg.maxLength then
        text = string.sub(text, 1, utf8.offset(text, cfg.maxLength + 1) - 1) .. "..."
    end

    local now = CurTime()
    if (ply.RP1942_NextBroadcast or 0) > now then
        return DarkRP.notify(ply, 1, 4, string.format("You can broadcast again in %d seconds.", math.ceil(ply.RP1942_NextBroadcast - now)))
    end
    ply.RP1942_NextBroadcast = now + cfg.cooldown

    net.Start("RP1942_FuhrerBroadcast")
    net.WriteString(ply:Nick())
    net.WriteString(text)
    net.Broadcast()
    playSound("broadcast")
    ServerLog(string.format("[1942] Führer broadcast by %s (%s): %s\n", ply:Nick(), ply:SteamID(), text))
end

hook.Add("canChatCommand", "RP1942_FuhrerBroadcast", function(ply, cmd, arg)
    if cmd ~= "broadcast" or not RP1942.FuhrerBroadcast.enabled then return end
    if not IsValid(ply) or ply:Team() ~= TEAM_FUHRER then return end
    fuhrerBroadcast(ply, arg)
    return false   -- handled: DarkRP's own /broadcast doesn't run
end)

