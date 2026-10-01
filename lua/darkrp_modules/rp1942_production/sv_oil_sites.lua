--[[---------------------------------------------------------------------------
1942 DarkRP - oil sites (server)

Oil rigs aren't placed by hand. Admins mark OIL SITES on the map, and a
bought rig is built on the free site nearest the buyer, bolted down.
One rig per site; the site frees up when its rig is removed.

    !addoilsite     mark a site where you're looking (the rig faces you)
    !removeoilsite  remove the site nearest where you're looking (and its rig)
    !oilsites       show every site on this map for a minute

Saved per map in data/rp1942/oilsites_<map>.json.
The F4 Shop only offers a rig while a site is free (GetGlobal2Int
"RP1942_OilSitesFree", used by its customCheck in entities.lua).
---------------------------------------------------------------------------]]
local CFG = RP1942.Production.oil

local store = RP1942.mapStore("oilsites")   -- lua/autorun/rp1942_util.lua
local loadSites, saveSites = store.load, store.save

local sites = {}
local function sitePos(s) return Vector(s.x, s.y, s.z) end

-- Site id -> the rig on it
local function taken()
    local used = {}
    for _, rig in ipairs(ents.FindByClass("rp1942_oil_rig")) do
        if rig.siteId then used[rig.siteId] = rig end
    end
    return used
end

function RP1942.updateOilSites()
    local used, free = taken(), 0
    for id in pairs(sites) do if not used[id] then free = free + 1 end end
    SetGlobal2Int("RP1942_OilSitesFree", free)
end

hook.Add("InitPostEntity", "RP1942_OilSites", function()
    sites = loadSites()
    RP1942.updateOilSites()
    if table.Count(sites) == 0 then
        MsgC(Color(255, 180, 60), "[1942] Production: no oil sites on this map yet. Mark some with !addoilsite, or Petroleum Producers can't buy rigs.\n")
    end
end)
hook.Add("PostCleanupMap", "RP1942_OilSites", function() timer.Simple(0, RP1942.updateOilSites) end)

-- Labels on a player's screen (lua/autorun/rp1942_util.lua)
local function sendMarkers(ply, list, seconds, tag) RP1942.showMarkers(ply, list, seconds, tag) end

--[[---------------------------------------------------------------------------
Building a rig (the F4 Shop's spawn function, entities.lua). Picks the
free site nearest the buyer. Returns the entity.

It must set the owner itself: DarkRP only does that in its own default
spawn. Without an owner, DarkRP can't count the rig off the buyer when it's
removed (a job change, the remover, a blowout), so the buyer stayed "at the
limit" and couldn't buy another until a restart.
---------------------------------------------------------------------------]]
function RP1942.buildOilRig(ply)
    local used, best, bestDist = taken(), nil, math.huge
    for id, s in pairs(sites) do
        if not used[id] then
            local d = sitePos(s):DistToSqr(ply:GetPos())
            if d < bestDist then best, bestDist = id, d end
        end
    end

    local rig = ents.Create("rp1942_oil_rig")
    rig:Setowning_ent(ply)
    rig.SID = ply.SID
    if not best then
        -- No free site (someone got the last one this very moment): build
        -- nothing useful; remove it next tick. customCheck makes this rare.
        rig:SetPos(ply:GetPos())
        rig:Spawn()
        timer.Simple(0, function() if IsValid(rig) then rig:Remove() end end)
        DarkRP.notify(ply, 1, 5, "Every oil site was just taken.")
        return rig
    end

    local s = sites[best]
    rig.siteId = best
    rig:SetPos(sitePos(s))
    rig:SetAngles(Angle(0, s.yaw or 0, 0))
    rig:Spawn()
    rig:Activate()
    -- Stand it on the site: its lowest point on the marked spot
    local pos = sitePos(s) - Vector(0, 0, rig:OBBMins().z)
    rig:Anchor(pos, Angle(0, s.yaw or 0, 0))
    rig:StartPump()

    RP1942.updateOilSites()
    DarkRP.notify(ply, 0, 6, "Your oil rig has been built at the nearest free oil site. It's marked on your screen.")
    sendMarkers(ply, { { pos = pos + Vector(0, 0, rig:OBBMaxs().z + 20), text = "YOUR OIL RIG" } }, 45)
    return rig
end

--[[---------------------------------------------------------------------------
Bolted down: nobody moves, pockets, freezes or tools a rig (only the
remover, which DarkRP lets the owner use on bought things)
---------------------------------------------------------------------------]]
local function isRig(ent) return IsValid(ent) and ent:GetClass() == "rp1942_oil_rig" end
hook.Add("PhysgunPickup", "RP1942_RigBolted", function(_, ent) if isRig(ent) then return false end end)
hook.Add("CanPlayerUnfreeze", "RP1942_RigBolted", function(_, ent) if isRig(ent) then return false end end)
hook.Add("GravGunPickupAllowed", "RP1942_RigBolted", function(_, ent) if isRig(ent) then return false end end)
hook.Add("GravGunPunt", "RP1942_RigBolted", function(_, ent) if isRig(ent) then return false end end)
hook.Add("canPocket", "RP1942_RigBolted", function(_, ent) if isRig(ent) then return false, "It's bolted down." end end)
hook.Add("CanProperty", "RP1942_RigBolted", function(ply, _, ent) if isRig(ent) and not ply:IsSuperAdmin() then return false end end)
hook.Add("CanTool", "RP1942_RigBolted", function(_, tr, tool)
    if isRig(tr.Entity) and tool ~= "remover" then return false end
end)

--[[---------------------------------------------------------------------------
Admin commands
---------------------------------------------------------------------------]]
local function allowed(ply, access)
    if RP1942.staffCan(ply, access, CFG.siteAdmin) then return true end
    DarkRP.notify(ply, 1, 4, "You aren't allowed to manage oil sites.")
    return false
end

local function showAll(ply)
    local list, used = {}, taken()
    for id, s in pairs(sites) do
        list[#list + 1] = { pos = sitePos(s) + Vector(0, 0, 40), text = used[id] and "OIL SITE (TAKEN)" or "OIL SITE (FREE)" }
    end
    sendMarkers(ply, list, 60, "oilsites")
    return #list
end

RP1942.defineStaffCommand("addoilsite", function(ply)
    if not allowed(ply, "ulx addoilsite") then return "" end
    local tr = ply:GetEyeTrace()
    if not tr.Hit or tr.HitPos:Distance(ply:EyePos()) > 1000 then
        DarkRP.notify(ply, 1, 4, "Look at the ground (or platform) where a rig should stand.")
        return ""
    end
    local id = tostring(os.time()) .. "_" .. math.random(1000, 9999)
    local yaw = math.Round(ply:EyeAngles().y + 180)   -- the rig's front faces you
    sites[id] = { x = tr.HitPos.x, y = tr.HitPos.y, z = tr.HitPos.z, yaw = yaw }
    saveSites(sites)
    RP1942.updateOilSites()
    local n = showAll(ply)
    DarkRP.notify(ply, 0, 5, "Oil site marked and saved for this map (" .. n .. " in all).")
    ServerLog(string.format("[1942] %s marked an oil site at %s\n", ply:Nick(), tostring(tr.HitPos)))
    return ""
end)

RP1942.defineStaffCommand("removeoilsite", function(ply)
    if not allowed(ply, "ulx removeoilsite") then return "" end
    local at = ply:GetEyeTrace().HitPos
    local best, bestDist = nil, 200 * 200
    for id, s in pairs(sites) do
        local d = sitePos(s):DistToSqr(at)
        if d < bestDist then best, bestDist = id, d end
    end
    if not best then
        DarkRP.notify(ply, 1, 4, "No oil site near where you're looking. !oilsites shows them.")
        return ""
    end
    local rig = taken()[best]
    if IsValid(rig) then rig:Remove() end
    ServerLog(string.format("[1942] %s removed the oil site at %s\n", ply:Nick(), tostring(sitePos(sites[best]))))
    sites[best] = nil
    saveSites(sites)
    RP1942.updateOilSites()
    DarkRP.notify(ply, 0, 5, "Oil site removed" .. (IsValid(rig) and " (and its rig)." or "."))
    return ""
end)

RP1942.defineStaffCommand("oilsites", function(ply)
    if not allowed(ply, "ulx oilsites") then return "" end
    local n = showAll(ply)
    DarkRP.notify(ply, 0, 5, n == 0 and "No oil sites on this map yet. !addoilsite marks one." or ("Showing " .. n .. " oil sites for a minute."))
    return ""
end)
