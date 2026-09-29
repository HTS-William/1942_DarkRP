--[[---------------------------------------------------------------------------
1942 DarkRP - Reich jobs (server): sends a player their unit's music when they join it
(settings: sh_reichjobs.lua)
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_JobMusic")

-- Addon sound files have to be sent to players, or only the server has them
local sent = {}
for _, path in pairs(RP1942.ReichJobs.music) do
    if not sent[path] then
        sent[path] = true
        if file.Exists(path, "GAME") then
            resource.AddFile(path)
        else
            MsgC(Color(255, 170, 0), "[1942] Reich job music not found at '", path, "'. Check RP1942.ReichJobs.music (sh_reichjobs.lua).\n")
        end
    end
end

-- Backup for the client's own job watcher (cl_reichjobs.lua)
hook.Add("OnPlayerChangedTeam", "RP1942_JobMusic", function(ply, oldTeam, newTeam)
    local what = RP1942.reichJobMusicFor(oldTeam, newTeam)
    if not what then return end
    net.Start("RP1942_JobMusic")
    net.WriteString(what == "stop" and "" or what)   -- "" = stop
    net.Send(ply)   -- only this player hears it
end)

--[[---------------------------------------------------------------------------
The vote to join the Reich. Replaces DarkRP's own job vote for Reich jobs,
so the question reads "<name> would like to join the Reich" and never names
the job (settings: RP1942.ReichJobs.vote in sh_reichjobs.lua).
---------------------------------------------------------------------------]]
local function fail(ply, msg) DarkRP.notify(ply, 1, 5, msg) return false end

function RP1942.startReichVote(ply, teamNr)
    local job = RPExtraTeams[teamNr]
    local cfg = RP1942.ReichJobs.vote
    if not (IsValid(ply) and job) then return false end
    if not RP1942.reichJobNeedsVote(ply, job.command) then return false end   -- no vote needed: the caller carries on
    if ply:Team() == teamNr then return fail(ply, "You already have that job.") end
    if ply.isArrested and ply:isArrested() then return fail(ply, "You can't do that while arrested.") end

    local gate = RP1942.jobGateFailure and RP1942.jobGateFailure(ply, job)
    if gate then return fail(ply, gate) end
    if job.max and job.max >= 1 and team.NumPlayers(teamNr) >= job.max then
        return fail(ply, "Every " .. job.name .. " post is filled.")
    end
    local allowed, wait = ply:changeAllowed(teamNr)
    if not allowed then
        return fail(ply, wait and ("You have to wait " .. math.ceil(wait) .. " seconds (demoted or banned from that job).") or "You're banned from that job.")
    end
    if ply.LastJob and 10 - (CurTime() - ply.LastJob) >= 0 then
        return fail(ply, "You have to wait " .. math.ceil(10 - (CurTime() - ply.LastJob)) .. " seconds before changing job again.")
    end
    local since = CurTime() - (ply.RP1942_LastReichVote or -1e9)
    if since < (cfg.cooldown or 80) then
        return fail(ply, "You have to wait " .. math.ceil((cfg.cooldown or 80) - since) .. " seconds before asking to join again.")
    end
    ply.RP1942_LastReichVote = CurTime()

    DarkRP.createVote(string.format(cfg.message, ply:Nick()), "job", ply, cfg.time or 20, function(vote, choice)
        local target = vote.target
        if not IsValid(target) then return end
        if choice < 0 then
            DarkRP.notifyAll(1, 4, string.format(cfg.failMessage, target:Nick()))
            return
        end
        if job.quietJoin and RP1942.quietJoin then
            target.RP1942_ReichVotePassed = true
            RP1942.quietJoin(target, teamNr)   -- silent, with a civilian cover
            target.RP1942_ReichVotePassed = nil
        else
            target:changeTeam(teamNr)
        end
    end, nil, nil, {})   -- no targetTeam: nothing tells the clients which job
    return true
end

-- DarkRP's /vote<command> for every Reich job that can need a vote
local function takeOverVoteCommands()
    for teamNr, job in pairs(RPExtraTeams or {}) do
        if job.faction == "reich" and job.RequiresVote and DarkRP.getChatCommand and DarkRP.getChatCommand("vote" .. job.command) then
            DarkRP.defineChatCommand("vote" .. job.command, function(ply)
                if not RP1942.reichJobNeedsVote(ply, job.command) then
                    DarkRP.notify(ply, 1, 4, "You don't need a vote for that job: take it from F4.")
                    return ""
                end
                RP1942.startReichVote(ply, teamNr)
                return ""
            end)
        end
    end
end
hook.Add("postLoadCustomDarkRPItems", "RP1942_ReichVote", function()
    takeOverVoteCommands()
    timer.Simple(0, takeOverVoteCommands)   -- in case DarkRP defines its own a tick later
end)
