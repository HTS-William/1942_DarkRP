--[[---------------------------------------------------------------------------
42Bros - Radio (server): the menu's messages
    RP1942_RadioOpen   server -> client   open the tuning menu for that radio
    RP1942_RadioTune   client -> server   a station's number in the list (0 = off), volume
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
    local index = net.ReadUInt(8)
    local volume = net.ReadFloat()
    if volume ~= volume then volume = 1 end                              -- NaN
    if not RP1942.isRadio(radio) then return end
    if radio:GetPos():DistToSqr(ply:GetPos()) > 300 * 300 then return end
    if not RP1942.radioCanTune(ply, radio) then return DarkRP.notify(ply, 1, 4, "That isn't your radio.") end
    if radio.Broken then return DarkRP.notify(ply, 1, 4, "That radio is broken.") end

    -- only a station from the list (sh_radio.lua): the client sends its number, never a link
    local station = index > 0 and RP1942.Radio.stations[index] or nil
    if index > 0 and not station then return end
    local url = station and station.url or ""
    if not radio:Tune(url, station and station.name or nil, volume) then return end
    if url == "" then
        DarkRP.notify(ply, 0, 3, "Radio off.")
    else
        DarkRP.notify(ply, 0, 4, "Tuned to " .. radio:GetStation() .. ".")
    end
    ServerLog(string.format("[42Bros] %s tuned a radio to %s\n", ply:Nick(), station and station.name or "off"))
end)

--[[---------------------------------------------------------------------------
The one-radio limit (sh_radio.lua: perPlayer). Every Radio Set a player has
counts: one standing in the world that they bought or last carried, the ones
in their pocket, and the ones in their inventory. (Pocketing one used to
hide it from the count, so you could keep buying more.)
---------------------------------------------------------------------------]]
local function isRadioGood(id)
    local good = RP1942.Goods and RP1942.Goods[id]
    return good ~= nil and good.radio == true
end

function RP1942.radiosHeld(ply)
    local n = 0
    for _, e in ipairs(ents.FindByClass("rp1942_good")) do
        if e:IsRadio() and (e.RP1942_ShopOwner == ply or e.RP1942_Holder == ply) then n = n + 1 end
    end
    for _, entry in pairs(ply.darkRPPocket or {}) do
        if entry.Class == "rp1942_good" and entry.DT and isRadioGood(entry.DT.Good) then n = n + 1 end
    end
    if RP1942.Inventory and RP1942.Inventory.radios then n = n + RP1942.Inventory.radios(ply) end
    return n
end

