--[[---------------------------------------------------------------------------
1942 DarkRP - the Führer's decisions (server)

    RP1942.decisionForce(caller, number)   (!fuhrerquestion) -> ok, why
    RP1942.decisionPending()               -> { ply, index, endsAt } or nil

Hook for other systems:
    RP1942_FuhrerDecision(ply, question, answer, success, delta)
        after an answer has been rolled and the economy moved
---------------------------------------------------------------------------]]
local D = RP1942.Decisions
local S = D.settings

util.AddNetworkString("RP1942_DecisionOpen")     -- to the Führer: index, endsAt
util.AddNetworkString("RP1942_DecisionAnswer")   -- from the Führer: index, answer
util.AddNetworkString("RP1942_DecisionResult")   -- to the Führer: what happened
util.AddNetworkString("RP1942_DecisionClose")    -- to the Führer: it's gone (reason)
util.AddNetworkString("RP1942_DecisionBanner")   -- to everyone else: 0 poorly / 1 wisely / 2 ignored

local LAST_FILE = "rp1942/decisions_last.txt"

local pending      -- { ply, index, endsAt, test }
local nextAt       -- when the next one is asked (nil = not scheduled)
local lastFuhrer
local deck = {}
local lastId = file.Read(LAST_FILE, "DATA")   -- survives restarts: no repeat across them

function RP1942.decisionPending() return pending end

--[[ The deck: every question once, in a random order, then reshuffled. The
first of a new deck is never the one just asked. ----------------------------]]
local function shuffle()
    deck = {}
    for i = 1, #D.questions do deck[i] = i end
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    if #deck > 1 and D.questions[deck[1]].id == lastId then
        local j = math.random(2, #deck)
        deck[1], deck[j] = deck[j], deck[1]
    end
end

local function remember(index)
    lastId = D.questions[index].id
    file.CreateDir("rp1942")
    file.Write(LAST_FILE, lastId)
end

local function draw()
    if #deck == 0 then shuffle() end
    local index = table.remove(deck, 1)
    remember(index)
    return index
end

local function schedule()
    nextAt = CurTime() + math.random(S.intervalMin, S.intervalMax)
end

--[[ Asking, closing ---------------------------------------------------------]]
local function sendOpen(ply)
    net.Start("RP1942_DecisionOpen")
    net.WriteUInt(pending.index, 8)
    net.WriteFloat(pending.endsAt)
    net.WriteBool(pending.test == true)
    net.Send(ply)
end

local function ask(ply, index, test)
    pending = { ply = ply, index = index, endsAt = CurTime() + S.answerTime, test = test }
    sendOpen(ply)
    ply:EmitSound("buttons/bell1.wav", 60, 90)
    ServerLog(string.format("[1942] Decision '%s' put to %s%s\n", D.questions[index].id, ply:Nick(), test and " (test)" or ""))
end

local function close(reason, ignored)
    if pending and IsValid(pending.ply) then
        net.Start("RP1942_DecisionClose")
        net.WriteString(reason or "")
        net.WriteBool(ignored == true)
        net.Send(pending.ply)
    end
    pending = nil
end

--[[ The clock ---------------------------------------------------------------]]
timer.Create("RP1942_Decisions", 1, 0, function()
    local fuhrer = RP1942.getFuhrer and RP1942.getFuhrer()
    local now = CurTime()

    -- A new Führer gets the full 3-5 minutes before his first decision
    if fuhrer ~= lastFuhrer then
        lastFuhrer = fuhrer
        nextAt = nil
    end

    if pending then
        local p = pending.ply
        if not IsValid(p) or (not pending.test and p ~= fuhrer) then
            close("You are no longer the Führer.")
            return
        end
        if now > pending.endsAt then
            -- Ignored: the economy pays for it
            local q = D.questions[pending.index]
            local old = RP1942.getEconomy()
            local new = RP1942.addEconomy(-(S.ignorePenalty or 0), "Führer ignored decision '" .. (q and q.id or "?") .. "'")
            local moved = math.abs(new - old)
            close(string.format(D.text.ignoredSelf, moved), true)
            if IsValid(p) then DarkRP.notify(p, 1, 8, string.format(D.text.ignoredSelf, moved)) end
            if (S.ignorePenalty or 0) > 0 then
                net.Start("RP1942_DecisionBanner")
                net.WriteUInt(2, 2)
                net.WriteUInt(moved, 8)
                if IsValid(p) then net.SendOmit(p) else net.Broadcast() end
            end
            ServerLog(string.format("[1942] %s ignored decision '%s': economy %d -> %d\n", IsValid(p) and p:Nick() or "?", q and q.id or "?", old, new))
            schedule()
        end
        return
    end

    if not S.enabled or not IsValid(fuhrer) or #D.questions == 0 then return end
    if not nextAt then schedule() return end
    if now >= nextAt then
        nextAt = nil
        ask(fuhrer, draw(), false)
    end
end)

--[[ The answer --------------------------------------------------------------]]
net.Receive("RP1942_DecisionAnswer", function(_, ply)
    local index = net.ReadUInt(8)
    local choice = net.ReadUInt(2)
    if not pending or pending.ply ~= ply or pending.index ~= index then return end
    local q = D.questions[index]
    local answer = q and q.answers[choice]
    if not answer then return end
    local test = pending.test
    pending = nil
    schedule()

    local impact = RP1942.decisionImpact(answer.impact)
    local chance = math.Rand(impact.chance[1], impact.chance[2])
    local success = math.random() < chance
    local points = math.random(impact.points[1], impact.points[2])
    local old = RP1942.getEconomy()
    local new = RP1942.addEconomy(success and points or -points,
        string.format("Führer decision '%s', answer %d (%s): %s", q.id, choice, answer.impact, success and "success" or "failure"))
    local moved = math.abs(new - old)

    -- The Führer reads what happened
    net.Start("RP1942_DecisionResult")
    net.WriteUInt(index, 8)
    net.WriteUInt(choice, 2)
    net.WriteBool(success)
    net.WriteFloat(chance)
    net.WriteUInt(moved, 8)
    net.Send(ply)

    -- Everyone else hears the verdict
    net.Start("RP1942_DecisionBanner")
    net.WriteUInt(success and 1 or 0, 2)
    net.WriteUInt(moved, 8)
    net.SendOmit(ply)

    ServerLog(string.format("[1942] %s answered '%s' with %d (%s, %d%% odds): %s, economy %d -> %d%s\n",
        ply:Nick(), q.id, choice, answer.impact, math.Round(chance * 100), success and "SUCCESS" or "FAILURE", old, new, test and " (test)" or ""))
    hook.Run("RP1942_FuhrerDecision", ply, q, answer, success, new - old)
end)

-- /decision: reopen the window after closing it
DarkRP.defineChatCommand("decision", function(ply)
    if pending and pending.ply == ply then
        sendOpen(ply)
    else
        DarkRP.notify(ply, 1, 4, "No decision is waiting for you.")
    end
    return ""
end)

--[[ !fuhrerquestion ---------------------------------------------------------
To the Führer; with nobody in office, to whoever typed it (to test). number
picks a question (1 = the first in sh_decisions_questions.lua).
---------------------------------------------------------------------------]]
function RP1942.decisionForce(caller, number)
    if #D.questions == 0 then return false, "There are no questions loaded." end
    local fuhrer = RP1942.getFuhrer and RP1942.getFuhrer()
    local target, test = fuhrer, false
    if not IsValid(target) then
        if not IsValid(caller) then return false, "Nobody is in office. Run it in game to test it on yourself." end
        target, test = caller, true
    end

    local index
    number = tonumber(number) or 0
    if number > 0 then
        if number > #D.questions then return false, "There are only " .. #D.questions .. " questions." end
        index = math.floor(number)
        for i = #deck, 1, -1 do if deck[i] == index then table.remove(deck, i) end end
        remember(index)
    else
        index = draw()
    end

    if pending then close("Replaced by another decision.") end
    ask(target, index, test)
    return true, target, test, index
end
