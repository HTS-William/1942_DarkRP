--[[---------------------------------------------------------------------------
1942 DarkRP - admin ESP (server)

    !esp  (ULX 42Bros, or !esp)   toggles it for yourself
Who may: "ulx esp" in ULX Groups (admins by default; without ULX, admins).

Players far away aren't sent to your game normally, so while ESP is on the
server sends everyone's position twice a second, and the ESP shows them
wherever they are on the map. The drawing is cl_esp.lua.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_ESP")        -- server -> client: on/off
util.AddNetworkString("RP1942_ESPData")    -- server -> client: positions

local function allowed(ply)
    return RP1942.staffCan(ply, "ulx esp", function(p) return p:IsAdmin() end)
end

function RP1942.toggleESP(ply, on)
    if not IsValid(ply) then return end
    if on == nil then on = not ply.RP1942_ESP end
    if on and not allowed(ply) then
        DarkRP.notify(ply, 1, 4, "You aren't allowed to use ESP.")
        return
    end
    ply.RP1942_ESP = on or nil
    net.Start("RP1942_ESP")
    net.WriteBool(on)
    net.Send(ply)
    DarkRP.notify(ply, 0, 3, on and "ESP on." or "ESP off.")
    ServerLog(string.format("[1942] %s turned ESP %s\n", ply:Nick(), on and "on" or "off"))
end


timer.Create("RP1942_ESPData", 0.5, 0, function()
    local viewers = {}
    for _, p in ipairs(player.GetHumans()) do
        if p.RP1942_ESP then
            if allowed(p) then viewers[#viewers + 1] = p else RP1942.toggleESP(p, false) end
        end
    end
    if #viewers == 0 then return end
    local list = player.GetAll()
    net.Start("RP1942_ESPData")
    net.WriteUInt(#list, 8)
    for _, p in ipairs(list) do
        net.WriteUInt(p:UserID(), 16)
        net.WriteVector(p:GetPos())
        net.WriteUInt(math.Clamp(p:Health(), 0, 255), 8)
        net.WriteBool(p:Alive())
    end
    net.Send(viewers)
end)
