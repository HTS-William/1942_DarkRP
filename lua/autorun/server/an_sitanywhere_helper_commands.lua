--============================================================
-- AN SitAnywhere Helper Commands
-- Adds:
--   !sitstuck / /sitstuck = finds a nearby safe unstuck position
--   !spawn    / /spawn    = sends player to one of the spawn positions
-- Server-side only.
--============================================================

if not SERVER then return end

local SPAWN_POINTS = {
    {
        pos = Vector(-5799.850586, 9068.602539, 216.031250),
        ang = Angle(18.413670, 177.596710, 0.000000)
    },
    {
        pos = Vector(-5681.502930, 9255.660156, 216.031250),
        ang = Angle(21.866322, -170.215530, 0.000000)
    },
    {
        pos = Vector(-6714.911133, 9078.112305, 215.405838),
        ang = Angle(17.637774, 177.997391, 0.000000)
    },
    {
        pos = Vector(-6588.626953, 8143.532715, 216.035614),
        ang = Angle(9.978848, -178.325714, 0.000000)
    },
}

local UNSTUCK_SEARCH_RADII = {
    48, 72, 96, 128, 160, 192, 256, 320, 384
}

local UNSTUCK_HEIGHTS = {
    0, 16, 32, 48, 64
}

local function ResetPlayerMovement(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if ply:InVehicle() then
        ply:ExitVehicle()
    end

    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetVelocity(-ply:GetVelocity())

    local phys = ply:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(Vector(0, 0, 0))
    end
end

local function IsSafePlayerPosition(ply, pos)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    local mins = ply:OBBMins()
    local maxs = ply:OBBMaxs()

    -- Check if the player's hull can fit here.
    local hullTrace = util.TraceHull({
        start = pos,
        endpos = pos,
        mins = mins,
        maxs = maxs,
        filter = ply,
        mask = MASK_PLAYERSOLID
    })

    if hullTrace.StartSolid or hullTrace.Hit then
        return false
    end

    -- Check there is ground below the player.
    local groundTrace = util.TraceLine({
        start = pos + Vector(0, 0, 8),
        endpos = pos - Vector(0, 0, 96),
        filter = ply,
        mask = MASK_PLAYERSOLID
    })

    if not groundTrace.Hit then
        return false
    end

    -- Final position should be just above the ground.
    local groundPos = groundTrace.HitPos + Vector(0, 0, 4)

    local finalHullTrace = util.TraceHull({
        start = groundPos,
        endpos = groundPos,
        mins = mins,
        maxs = maxs,
        filter = ply,
        mask = MASK_PLAYERSOLID
    })

    if finalHullTrace.StartSolid or finalHullTrace.Hit then
        return false
    end

    return true, groundPos
end

local function FindNearbySafePosition(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end

    local origin = ply:GetPos()

    -- First try the player's current position in case only the sit state is stuck.
    local currentSafe, currentPos = IsSafePlayerPosition(ply, origin)
    if currentSafe then
        return currentPos
    end

    -- Search in circles around the player.
    for _, radius in ipairs(UNSTUCK_SEARCH_RADII) do
        for angle = 0, 345, 15 do
            local rad = math.rad(angle)
            local offset = Vector(math.cos(rad) * radius, math.sin(rad) * radius, 0)

            for _, height in ipairs(UNSTUCK_HEIGHTS) do
                local testPos = origin + offset + Vector(0, 0, height)
                local safe, safePos = IsSafePlayerPosition(ply, testPos)

                if safe then
                    return safePos
                end
            end
        end
    end

    return nil
end

local function SafeTeleport(ply, pos, ang)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    ResetPlayerMovement(ply)

    timer.Simple(0, function()
        if not IsValid(ply) then return end

        ply:SetPos(pos)

        if ang then
            ply:SetEyeAngles(ang)
        end

        ResetPlayerMovement(ply)
    end)
end

local function SendToSitStuck(ply)
    local safePos = FindNearbySafePosition(ply)

    if safePos then
        SafeTeleport(ply, safePos, ply:EyeAngles())
        ply:ChatPrint("[SitAnywhere] Safe nearby unstuck position found.")
    else
        ply:Spawn()
        ply:ChatPrint("[SitAnywhere] No nearby safe place was found, so you were respawned.")
    end
end

local function SendToSpawn(ply)
    local chosen = table.Random(SPAWN_POINTS)
    SafeTeleport(ply, chosen.pos, chosen.ang)
    ply:ChatPrint("[Spawn] You have been sent to spawn.")
end

hook.Add("PlayerSay", "AN_SitAnywhere_Helper_Commands", function(ply, text)
    local msg = string.lower(string.Trim(text or ""))

    if msg == "!sitstuck" or msg == "/sitstuck" then
        SendToSitStuck(ply)
        return ""
    end

    if msg == "!spawn" or msg == "/spawn" then
        SendToSpawn(ply)
        return ""
    end
end)
