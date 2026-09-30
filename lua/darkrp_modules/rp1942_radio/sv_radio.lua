--[[---------------------------------------------------------------------------
1942 DarkRP - Radio (server): the menu's messages
    RP1942_RadioOpen   server -> client   open the tuning menu for that radio
    RP1942_RadioTune   client -> server   station index or link, volume
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_RadioOpen")
util.AddNetworkString("RP1942_RadioTune")

function RP1942.radioOpenMenu(ply, radio)
    if not RP1942.radioCanTune(ply, radio) then
        return DarkRP.notify(ply, 1, 4, "That isn't your radio.")
    end
    net.Start("RP1942_RadioOpen")
    net.WriteEntity(radio)
    net.Send(ply)
end

net.Receive("RP1942_RadioTune", function(_, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if (ply.RP1942_NextRadio or 0) > CurTime() then return end
    ply.RP1942_NextRadio = CurTime() + 0.5

    local radio = net.ReadEntity()
    local url = net.ReadString()
    local name = net.ReadString()
    local volume = net.ReadFloat()
    if not IsValid(radio) or radio:GetClass() ~= "rp1942_radio" then return end
    if radio:GetPos():DistToSqr(ply:GetPos()) > 300 * 300 then return end
    if not RP1942.radioCanTune(ply, radio) then return DarkRP.notify(ply, 1, 4, "That isn't your radio.") end
    if radio.Broken then return DarkRP.notify(ply, 1, 4, "That radio is broken.") end

    -- a listed station is taken from the list (its link can't be changed from the client)
    local station
    for _, st in ipairs(RP1942.Radio.stations) do
        if st.url == url then station = st break end
    end
    if station then name = station.name end
    if url ~= "" and not station and not RP1942.radioValidUrl(url) then
        return DarkRP.notify(ply, 1, 5, "That isn't a stream link. It needs to start with http:// or https:// and point straight at the stream.")
    end
    if not radio:Tune(url, name ~= "" and name or nil, volume) then return end
    if url == "" then
        DarkRP.notify(ply, 0, 3, "Radio off.")
    else
        DarkRP.notify(ply, 0, 4, "Tuned to " .. radio:GetStation() .. ".")
    end
    ServerLog(string.format("[1942] %s tuned a radio to %s\n", ply:Nick(), url == "" and "off" or url))
end)
