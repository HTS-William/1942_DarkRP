--[[---------------------------------------------------------------------------
42Bros - small shared helpers (both realms)

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
    RP1942.dataStore(name)                  a table saved for the whole server, in
                                            data/rp1942/<name>.json:
                                            store.load() -> table, store.save(table)
    RP1942.mapStore(name)                   the same, but one per map:
                                            data/rp1942/<name>_<map>.json
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

    local function store(path)
        return {
            load = function() return util.JSONToTable(file.Read(path(), "DATA") or "") or {} end,
            save = function(tbl)
                file.CreateDir("rp1942")
                file.Write(path(), util.TableToJSON(tbl, true))
            end,
        }
    end

    function RP1942.dataStore(name)
        return store(function() return "rp1942/" .. name .. ".json" end)
    end

    function RP1942.mapStore(name)
        return store(function() return "rp1942/" .. name .. "_" .. game.GetMap() .. ".json" end)
    end

    --[[-----------------------------------------------------------------------
    RP1942.standOnFloor(ent [, reach]) -> true if it found the floor
    Stands an upright entity on the ground under it: its bottom (OBBMins)
    exactly on the floor, whether it starts sunk into the ground or hanging
    in the air. Looks from `reach` units above its bottom (default 48) to 128
    below. The floor is the map (brushes, displacements, its solid props);
    players, loose items and the thing itself don't count. Works however the
    model's origin sits (a dumpster's is in its middle).
    DarkRP's DropToFloor can't do this: it gives up when the thing already
    starts inside the floor, which left saved dumpsters sunk on every restart.
    -------------------------------------------------------------------------]]
    function RP1942.standOnFloor(ent, reach)
        if not IsValid(ent) then return false end
        reach = reach or 48
        local pos = ent:GetPos()
        local bottom = pos.z + ent:OBBMins().z
        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
        -- a thin square from the middle of its footprint: traces aren't turned
        -- with the entity, so this stays inside it at any angle and a wall
        -- right beside it never counts as the floor
        local half = math.max(1, math.min(-mins.x, maxs.x, -mins.y, maxs.y) * 0.6)
        local start = Vector(pos.x, pos.y, bottom + reach)
        local stop = Vector(pos.x, pos.y, bottom - 128)
        local function notFloor(e)
            if e == ent or e:IsPlayer() or e:IsNPC() or e:IsWeapon() then return false end
            local class = e:GetClass()
            return not (class == "rp1942_good" or class == "spawned_weapon" or class == "spawned_money" or class == ent:GetClass())
        end
        local tr = util.TraceHull({
            start = start, endpos = stop, mins = Vector(-half, -half, 0), maxs = Vector(half, half, 1),
            mask = MASK_SOLID, filter = notFloor,
        })
        if tr.StartSolid or not tr.Hit then
            -- doesn't fit there (a tight corner): fall back to its middle
            tr = util.TraceLine({ start = start, endpos = stop, mask = MASK_SOLID, filter = notFloor })
            if tr.StartSolid or not tr.Hit then return false end
        end
        ent:SetPos(Vector(pos.x, pos.y, tr.HitPos.z - mins.z + 0.25))
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:SetPos(ent:GetPos()) end
        return true
    end
end
