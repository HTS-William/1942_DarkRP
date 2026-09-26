--[[---------------------------------------------------------------------------
1942 DarkRP - world events scheduler (server)
---------------------------------------------------------------------------]]
local CFG = RP1942.Events
local TIMER = "RP1942_WorldEvents"

function RP1942.activeEvent()
    for _, ev in pairs(RP1942.EventList) do
        if ev.isActive and ev.isActive() then return ev end
    end
end

-- Can this event run now? Returns false and a reason if not.
function RP1942.canStartEvent(ev, ignorePlayers)
    local c = ev.config or {}
    if c.enabled == false then return false, "disabled in the config" end
    if c.map and c.map ~= game.GetMap() then return false, "only runs on " .. c.map end
    local need = c.minPlayers or CFG.minPlayers or 0
    if not ignorePlayers and player.GetCount() < need then return false, "needs " .. need .. " players" end
    if RP1942.activeEvent() then return false, "another event is running" end
    if ev.canStart then
        local ok, why = ev.canStart()
        if not ok then return false, why or "not possible right now" end
    end
    return true
end

function RP1942.startEvent(id, ignorePlayers)
    local ev = RP1942.EventList[id]
    if not ev then return false, "no event called " .. tostring(id) end
    local ok, why = RP1942.canStartEvent(ev, ignorePlayers)
    if not ok then return false, why end
    if ev.start() == false then return false, "failed to start (see the server console)" end
    ServerLog("[1942] World event started: " .. id .. "\n")
    return true
end

-- Weighted pick among the events that may run now
local function pickEvent()
    local pool, total = {}, 0
    for id, ev in pairs(RP1942.EventList) do
        local w = (ev.config and ev.config.weight) or 1
        if w > 0 and RP1942.canStartEvent(ev) then
            total = total + w
            pool[#pool + 1] = { id = id, w = w }
        end
    end
    if total <= 0 then return end
    local roll = math.random() * total
    for _, p in ipairs(pool) do
        roll = roll - p.w
        if roll <= 0 then return p.id end
    end
    return pool[#pool].id
end

local function scheduleNext(delay)
    timer.Create(TIMER, delay, 1, function()
        if CFG.enabled then
            local id = pickEvent()
            if id then RP1942.startEvent(id) end
        end
        scheduleNext(math.random(CFG.interval.min, CFG.interval.max))
    end)
end

hook.Add("InitPostEntity", "RP1942_WorldEvents", function()
    scheduleNext(CFG.firstDelay)
end)

--[[---------------------------------------------------------------------------
Admin commands (who may use them: RP1942.Events.adminCheck in sh_events.lua)
    Chat:     /train              start the supply train
              /event              list events and what's running
              /event <id>         start an event
              /event stop         end the running event
    Console:  rp1942_event [<id> | stop]   (same as /event; also works from the server console)
---------------------------------------------------------------------------]]
local function runEventCommand(ply, arg, say)
    if IsValid(ply) and not CFG.adminCheck(ply) then return say("You aren't allowed to run events.") end

    arg = string.lower(arg or "")
    if arg == "" then
        local active = RP1942.activeEvent()
        say("Running: " .. (active and active.id or "none"))
        local left = timer.TimeLeft(TIMER)
        if left then say(string.format("Next automatic event in %d:%02d", math.floor(left / 60), math.floor(left % 60))) end
        for id, ev in SortedPairs(RP1942.EventList) do
            local ok, why = RP1942.canStartEvent(ev, true)
            say(string.format("  %s - %s%s", id, ev.name or id, ok and "" or ("  (" .. why .. ")")))
        end
        return say("Usage: /event <id> | stop")
    end

    if arg == "stop" then
        local active = RP1942.activeEvent()
        if not active then return say("No event is running.") end
        if active.stop then active.stop() end
        ServerLog("[1942] " .. (IsValid(ply) and ply:Nick() or "Console") .. " stopped world event " .. active.id .. "\n")
        return say("Stopped " .. active.id .. ".")
    end

    local ok, why = RP1942.startEvent(arg, true)   -- admins ignore the player minimum
    if ok then ServerLog("[1942] " .. (IsValid(ply) and ply:Nick() or "Console") .. " started world event " .. arg .. "\n") end
    say(ok and ("Started " .. arg .. ".") or ("Can't start " .. arg .. ": " .. why))
end

concommand.Add("rp1942_event", function(ply, _, args)
    runEventCommand(ply, args[1], function(msg)
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
    end)
end)

-- Chat replies: the first line as a notification, the full list in the console
local function chatSay(ply)
    local first = true
    return function(msg)
        if first then DarkRP.notify(ply, 0, 5, msg) first = false end
        ply:PrintMessage(HUD_PRINTCONSOLE, msg)
    end
end

DarkRP.defineChatCommand("event", function(ply, args)
    runEventCommand(ply, string.Explode(" ", string.Trim(args or ""))[1], chatSay(ply))
    return ""
end)

DarkRP.defineChatCommand("train", function(ply)
    runEventCommand(ply, "train", chatSay(ply))
    return ""
end)
