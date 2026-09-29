--[[---------------------------------------------------------------------------
1942 DarkRP - world event settings menu (server)

    !eventsettings  (ULX 42Bros)  or  !eventsettings
Opens a menu to change the automatic event timer, the player minimum and
each event's on/off, start or stop an event, and see when the next one is
due. Saved in data/rp1942/events.json. Who may: "ulx eventsettings" in ULX
Groups (superadmins by default; without ULX, superadmins).
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_EventMenu")        -- server -> client: open with the settings
util.AddNetworkString("RP1942_EventMenuSave")    -- client -> server: new settings
util.AddNetworkString("RP1942_EventMenuAction")  -- client -> server: "start:<id>" / "stop"

local function allowed(ply)
    return RP1942.staffCan(ply, "ulx eventsettings", function(p) return p:IsSuperAdmin() end)
end

function RP1942.openEventMenu(ply)
    if not IsValid(ply) then return end
    if not allowed(ply) then
        DarkRP.notify(ply, 1, 4, "You aren't allowed to change the event settings.")
        return
    end
    local t = RP1942.eventSettings()
    t.nextIn = RP1942.nextEventIn and RP1942.nextEventIn() or -1
    local active = RP1942.activeEvent()
    t.running = active and active.id or ""
    t.players = player.GetCount()
    -- Could each event run automatically right now? (and why not)
    for id, e in pairs(t.events) do
        local ev = RP1942.EventList[id]
        local ok, why = RP1942.canStartEvent(ev)
        e.ready, e.why = ok == true, why
    end
    net.Start("RP1942_EventMenu")
    net.WriteString(util.TableToJSON(t))
    net.Send(ply)
end


net.Receive("RP1942_EventMenuSave", function(_, ply)
    if not allowed(ply) then return end
    local t = util.JSONToTable(net.ReadString() or "")
    if not istable(t) then return end
    RP1942.setEventSettings(t, ply)
    DarkRP.notify(ply, 0, 4, "World event settings saved.")
    RP1942.openEventMenu(ply)   -- refresh the menu with what was saved
end)

net.Receive("RP1942_EventMenuAction", function(_, ply)
    if not allowed(ply) then return end
    local action = net.ReadString()
    local id = string.match(action, "^start:([%w_]+)$")
    if id then
        local ok, why = RP1942.startEvent(id, true)
        DarkRP.notify(ply, ok and 0 or 1, 5, ok and ("Started " .. id .. ".") or ("Can't start " .. id .. ": " .. tostring(why)))
    elseif action == "stop" then
        local active = RP1942.activeEvent()
        if active and active.stop then active.stop() DarkRP.notify(ply, 0, 4, "Stopped " .. active.id .. ".") end
    end
    timer.Simple(0.2, function() if IsValid(ply) then RP1942.openEventMenu(ply) end end)
end)
