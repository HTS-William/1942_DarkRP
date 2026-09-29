--============================================================
-- Advanced SitAnywhere Physics / Gravity Gun Protection
-- Improved version for DarkRP 
--============================================================

if not SERVER then return end

local function IsSitSeat(ent)
    if not IsValid(ent) then return false end

    local class = ent:GetClass()

    return class == "prop_vehicle_prisoner_pod"
        or ent:GetNWBool("SitAnywhereSeat", false)
end

local function ForcePlayerOutOfSeat(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if ply:InVehicle() then
        ply:ExitVehicle()
    end

    ply:SetMoveType(MOVETYPE_WALK)

    timer.Simple(0, function()
        if not IsValid(ply) then return end

        ply:SetVelocity(-ply:GetVelocity())
    end)
end

local function IsPlayerUsingSeat(ent)
    if not IsValid(ent) then return false end

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end

        local veh = ply:GetVehicle()

        if IsValid(veh) and veh == ent then
            return true, ply
        end

        local nwEnt = ply:GetNWEntity("sitanywhereentity")

        if IsValid(nwEnt) and nwEnt == ent then
            return true, ply
        end
    end

    return false, nil
end

--============================================================
-- Physgun Protection
--============================================================

hook.Add("OnPhysgunPickup", "AN_SitAnywhere_PhysgunProtection", function(admin, ent)
    local usingSeat, ply = IsPlayerUsingSeat(ent)

    if usingSeat and IsValid(ply) then
        ForcePlayerOutOfSeat(ply)
    end
end)

--============================================================
-- Gravity Gun Protection
--============================================================

hook.Add("GravGunOnPickedUp", "AN_SitAnywhere_GravityGunProtection", function(admin, ent)
    local usingSeat, ply = IsPlayerUsingSeat(ent)

    if usingSeat and IsValid(ply) then
        ForcePlayerOutOfSeat(ply)
    end
end)

--============================================================
-- Toolgun Protection
--============================================================

hook.Add("CanTool", "AN_SitAnywhere_BlockToolgunOnSeat", function(ply, tr)
    if not tr or not IsValid(tr.Entity) then return end

    local usingSeat = IsPlayerUsingSeat(tr.Entity)

    if usingSeat then
        return ply:IsAdmin()
    end
end)

--============================================================
-- Cleanup Broken References
--============================================================

hook.Add("PlayerLeaveVehicle", "AN_SitAnywhere_CleanupVehicle", function(ply)
    if not IsValid(ply) then return end

    ply:SetNWEntity("sitanywhereentity", NULL)
end)

hook.Add("PlayerDisconnected", "AN_SitAnywhere_CleanupDisconnect", function(ply)
    if not IsValid(ply) then return end

    local veh = ply:GetVehicle()

    if IsValid(veh) then
        veh:Remove()
    end
end)

--============================================================
-- SitAnywhere Tracking
--============================================================

hook.Add("OnPlayerSit", "AN_SitAnywhere_TrackSeat", function(ply, pos, ang, parent, parentbone, vehicle)
    if not IsValid(ply) or not IsValid(vehicle) then return end

    vehicle:SetNWBool("SitAnywhereSeat", true)

    ply:SetNWEntity("sitanywhereentity", vehicle)
end)

--============================================================
-- Prevent seat dragging exploits
--============================================================

hook.Add("PhysgunPickup", "AN_SitAnywhere_BlockSeatPickup", function(ply, ent)
    local usingSeat = IsPlayerUsingSeat(ent)

    if usingSeat and not ply:IsAdmin() then
        return false
    end
end)
