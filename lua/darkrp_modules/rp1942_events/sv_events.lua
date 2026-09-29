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
    timer.Create(TIMER, math.max(delay, 5), 1, function()
        local started = false
        if CFG.enabled then
            local id = pickEvent()
            if id then started = RP1942.startEvent(id) end
        end
        -- Nothing could run (e.g. too few players): try again soon instead
        -- of waiting a whole interval
        if CFG.enabled and not started and (CFG.retryDelay or 0) > 0 then
            scheduleNext(CFG.retryDelay)
        else
            scheduleNext(math.random(CFG.interval.min, math.max(CFG.interval.min, CFG.interval.max)))
        end
    end)
end

-- Seconds until the next automatic event (nil if none is scheduled)
function RP1942.nextEventIn() return timer.TimeLeft(TIMER) end

--[[---------------------------------------------------------------------------
Settings changed in game (!eventsettings), saved in data/rp1942/events.json.
They override sh_events.lua until they're reset.
---------------------------------------------------------------------------]]
local SAVE = "rp1942/events.json"

local function applySettings(t)
    if not istable(t) then return end
    if t.enabled ~= nil then CFG.enabled = t.enabled == true end
    if tonumber(t.intervalMin) then CFG.interval.min = math.Clamp(math.floor(t.intervalMin), 60, 86400) end
    if tonumber(t.intervalMax) then CFG.interval.max = math.Clamp(math.floor(t.intervalMax), CFG.interval.min, 86400) end
    if tonumber(t.firstDelay) then CFG.firstDelay = math.Clamp(math.floor(t.firstDelay), 30, 86400) end
    if tonumber(t.minPlayers) then CFG.minPlayers = math.Clamp(math.floor(t.minPlayers), 0, 128) end
    if tonumber(t.retryDelay) then CFG.retryDelay = math.Clamp(math.floor(t.retryDelay), 0, 3600) end
    for id, e in pairs(istable(t.events) and t.events or {}) do
        local ev = RP1942.EventList[id]
        if ev and ev.config and istable(e) then
            if e.enabled ~= nil then ev.config.enabled = e.enabled == true end
            if tonumber(e.minPlayers) then ev.config.minPlayers = math.Clamp(math.floor(e.minPlayers), 0, 128) end
        end
    end
end

-- The current settings, as saved / sent to the menu
function RP1942.eventSettings()
    local t = {
        enabled = CFG.enabled ~= false, intervalMin = CFG.interval.min, intervalMax = CFG.interval.max,
        firstDelay = CFG.firstDelay, minPlayers = CFG.minPlayers or 0, retryDelay = CFG.retryDelay or 0, events = {},
    }
    for id, ev in SortedPairs(RP1942.EventList) do
        local c = ev.config or {}
        t.events[id] = { name = ev.name or id, enabled = c.enabled ~= false, minPlayers = c.minPlayers or CFG.minPlayers or 0 }
    end
    return t
end

function RP1942.setEventSettings(t, who)
    applySettings(t)
    local saved = RP1942.eventSettings()
    for _, e in pairs(saved.events) do e.name = nil end
    file.CreateDir("rp1942")
    file.Write(SAVE, util.TableToJSON(saved, true))
    -- A shorter gap takes effect now, not after the old timer runs out
    local left = timer.TimeLeft(TIMER)
    if not left or left > CFG.interval.max then scheduleNext(math.random(CFG.interval.min, CFG.interval.max)) end
    ServerLog(string.format("[1942] %s changed the world event settings\n", IsValid(who) and who:Nick() or "Console"))
end

hook.Add("InitPostEntity", "RP1942_WorldEvents", function()
    local raw = file.Read(SAVE, "DATA")
    if raw then applySettings(util.JSONToTable(raw)) end
    scheduleNext(CFG.firstDelay)
end)

--[[---------------------------------------------------------------------------
Staff commands: !train, !event <id>, !stopevent, !eventsettings (ULX 42Bros,
lua/ulx/modules/sh/42bros.lua; in the server console: ulx event train).
---------------------------------------------------------------------------]]


