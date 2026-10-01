--[[---------------------------------------------------------------------------
1942 DarkRP - small shared helpers (both realms)

In lua/autorun so every module and entity can use them while it loads
(DarkRP modules load in an order we don't control; autorun comes first).

    RP1942.UNITS_PER_M        52.5 game units = 1 metre (a player is ~72 tall)
    RP1942.metres(units)      -> whole metres, for "35 m" on screen

Server only:
    RP1942.setHoldBar(ply, seconds, text)   the "hold" progress bar under the
    RP1942.clearHoldBar(ply)                crosshair (drawn by cl_holdbar.lua)
    RP1942.showMarkers(ply, list, seconds, tag)
                                            labels on ply's screen over places in the
                                            world: list = { { pos =, text = }, ... }
                                            (drawn by rp1942_core/cl_markers.lua; up to
                                            255). A tag ("doorlocks") replaces the labels
                                            last sent with the same tag.
    RP1942.mapStore(name)                   a list saved for this map, in
                                            data/rp1942/<name>_<map>.json:
                                            store.load() -> table, store.save(table)
---------------------------------------------------------------------------]]
AddCSLuaFile()
RP1942 = RP1942 or {}

RP1942.UNITS_PER_M = 52.5

function RP1942.metres(units)
    return math.floor((units or 0) / RP1942.UNITS_PER_M)
end

if SERVER then
    util.AddNetworkString("RP1942_Markers")

    function RP1942.setHoldBar(ply, seconds, text)
        if not IsValid(ply) then return end
        local now = CurTime()
        ply:SetNW2Float("RP1942_HoldStart", now)
        ply:SetNW2Float("RP1942_HoldEnd", now + seconds)
        ply:SetNW2String("RP1942_HoldText", text or "")
    end

    function RP1942.clearHoldBar(ply)
        if not IsValid(ply) then return end
        ply:SetNW2Float("RP1942_HoldEnd", 0)
        ply:SetNW2String("RP1942_HoldText", "")
    end

    function RP1942.showMarkers(ply, list, seconds, tag)
        if not IsValid(ply) then return end
        local n = math.min(#list, 255)
        net.Start("RP1942_Markers")
        net.WriteString(tag or "")
        net.WriteFloat(seconds or 60)
        net.WriteUInt(n, 8)
        for i = 1, n do
            net.WriteVector(list[i].pos)
            net.WriteString(list[i].text or "")
        end
        net.Send(ply)
    end

    function RP1942.mapStore(name)
        local function path() return "rp1942/" .. name .. "_" .. game.GetMap() .. ".json" end
        return {
            load = function() return util.JSONToTable(file.Read(path(), "DATA") or "") or {} end,
            save = function(list)
                file.CreateDir("rp1942")
                file.Write(path(), util.TableToJSON(list, true))
            end,
        }
    end
end
