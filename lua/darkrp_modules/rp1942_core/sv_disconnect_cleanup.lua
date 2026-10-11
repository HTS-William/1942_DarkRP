--[[---------------------------------------------------------------------------
42Bros - a player's stuff goes when they leave (server)

The moment someone disconnects, everything they own in the world is removed:
props, text screens and other tool things, F4 entities (printers, ovens,
barrels...), their oil rig, their padlocks, for-sale food with their name on
it, dropped guns they own.

Why: DarkRP's prop protection keeps a leaver's props for 2 minutes and hands
them back if they rejoin in time, so leaving and rejoining kept everything.

Never removed (KEEP below): anything staff placed or saved for the map
(markets, the vault, saved machines, law boards, staff padlocks), anything
that's part of the map itself, persistent props, and the Reich's APC (it
passes to the next driver).

GRACE: seconds to wait before removing (0 = right away). With a grace time,
someone who crashes and rejoins in time keeps their things.
---------------------------------------------------------------------------]]
local GRACE = 0

local function ownedBy(e, ply, sid)
    if e.FPPOwnerID == sid then return true end                               -- prop protection (props, tools)
    if e.CPPIGetOwner then
        local o = e:CPPIGetOwner()
        if o == ply then return true end
    end
    if e.Getowning_ent and e:Getowning_ent() == ply then return true end      -- F4 entities, machines
    if e.SID and ply.SID and e.SID == ply.SID then return true end            -- DarkRP's bought things
    if e.RP1942_ShopOwner == ply then return true end                         -- F4 shop goods
    if e.GetLockOwner and e:GetLockOwner() == ply then return true end        -- padlocks
    if e:GetClass() == "rp1942_good" and e.GetOwnerID and e:GetOwnerID() == sid then return true end   -- food with their name
    return false
end

local function keep(e)
    if e:IsPlayer() or e:CreatedByMap() then return true end
    if e.GetPersistent and e:GetPersistent() then return true end
    if e.RP1942_SaveId or e.RP1942_ProdSpawnedBy or e.saveId then return true end   -- staff-placed / saved
    if e.GetStaff and e:GetStaff() then return true end                            -- staff padlock
    if e == GetGlobal2Entity("RP1942_APC") then return true end
    if e:IsWeapon() and IsValid(e:GetOwner()) then return true end                 -- in someone's hands
    if e:IsVehicle() then
        local d = e.GetDriver and e:GetDriver()
        if IsValid(d) then return true end                                         -- someone's driving it
    end
    return false
end

local function collect(ply, sid)
    local list = {}
    for _, e in ipairs(ents.GetAll()) do
        if IsValid(e) and not keep(e) and ownedBy(e, ply, sid) then list[#list + 1] = e end
    end
    return list
end

-- "12 props, 1 text screen, 1 printer"
local NICE = {
    prop_physics = "prop", gmod_textscreen = "text screen", sammyservers_textscreen = "text screen",
    rp1942_good = "good", rp1942_padlock = "padlock", spawned_weapon = "dropped weapon",
}
local function summary(list)
    local counts, order = {}, {}
    for _, e in ipairs(list) do
        local c = e:GetClass()
        local name = NICE[c] or (e.PrintName and e.PrintName ~= "" and e.PrintName) or c
        if not counts[name] then order[#order + 1] = name end
        counts[name] = (counts[name] or 0) + 1
    end
    table.sort(order, function(a, b) return counts[a] > counts[b] end)
    local parts = {}
    for _, n in ipairs(order) do parts[#parts + 1] = counts[n] .. " " .. n .. (counts[n] > 1 and "s" or "") end
    return table.concat(parts, ", ")
end

local function removeAll(name, sid, list)
    local n = 0
    for _, e in ipairs(list) do
        if IsValid(e) then e:Remove() n = n + 1 end
    end
    if n > 0 and RP1942.log then
        RP1942.log("LEAVE", "%s (%s) left: removed %d thing(s) (%s)", name, sid, n, summary(list))
    end
end

hook.Add("PlayerDisconnected", "RP1942_RemoveStuff", function(ply)
    if not IsValid(ply) then return end
    local sid, name = ply:SteamID(), ply:Nick()
    local list = collect(ply, sid)
    if #list == 0 then return end
    if GRACE <= 0 then
        removeAll(name, sid, list)
        return
    end
    timer.Create("RP1942_RemoveStuff_" .. sid, GRACE, 1, function()
        if IsValid(player.GetBySteamID(sid)) then return end   -- came back in time: keeps it all
        removeAll(name, sid, list)
    end)
end)
