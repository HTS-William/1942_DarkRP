--[[---------------------------------------------------------------------------
1942 DarkRP - prop ghosting (server). Settings: sh_propghost.lua
---------------------------------------------------------------------------]]
local CFG = RP1942.PropGhost

local function ghostable(ent)
    if not IsValid(ent) or ent:IsPlayer() or ent:IsVehicle() or ent:IsNPC() then return false end
    local class = ent:GetClass()
    if CFG.exclude[class] then return false end
    for _, p in ipairs(CFG.excludePrefix) do
        if string.StartWith(class, p) then return false end
    end
    return true
end

local function ghost(ent)
    if ent.RP1942_Ghost then return end   -- already (still waiting to turn solid)
    ent.RP1942_Ghost = {
        group = ent:GetCollisionGroup(),
        color = ent:GetColor(),
        mode  = ent:GetRenderMode(),
    }
    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)   -- only hits the world
    ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
    local c = ent.RP1942_Ghost.color
    ent:SetColor(Color(c.r, c.g, c.b, math.min(c.a, CFG.alpha)))
end

local function unghost(ent)
    local saved = ent.RP1942_Ghost
    if not saved then return end
    ent.RP1942_Ghost = nil
    timer.Remove("RP1942_PropGhost_" .. ent:EntIndex())
    ent:SetCollisionGroup(saved.group)
    ent:SetRenderMode(saved.mode)
    ent:SetColor(saved.color)
end

-- Is any living player standing inside (or touching) it?
local function someoneInside(ent)
    local mins, maxs = ent:WorldSpaceAABB()
    local pad = Vector(2, 2, 2)
    mins, maxs = mins - pad, maxs + pad
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local pmins, pmaxs = ply:WorldSpaceAABB()
            if pmins.x <= maxs.x and pmaxs.x >= mins.x and pmins.y <= maxs.y and pmaxs.y >= mins.y
                and pmins.z <= maxs.z and pmaxs.z >= mins.z then
                return true
            end
        end
    end
    return false
end

-- After letting go: solid again once nobody is inside it
local function settle(ent)
    if not IsValid(ent) or not ent.RP1942_Ghost then return end
    if not someoneInside(ent) then
        unghost(ent)
        return
    end
    timer.Create("RP1942_PropGhost_" .. ent:EntIndex(), CFG.recheck, 0, function()
        if not IsValid(ent) or not ent.RP1942_Ghost then return end
        if ent.RP1942_Held then return end            -- picked up again meanwhile
        if not someoneInside(ent) then unghost(ent) end
    end)
end

-- After a pickup is allowed (FPP and everything else have had their say)
hook.Add("OnPhysgunPickup", "RP1942_PropGhost", function(ply, ent)
    if not CFG.enabled or not ghostable(ent) then return end
    ent.RP1942_Held = ply
    timer.Remove("RP1942_PropGhost_" .. ent:EntIndex())
    ghost(ent)
end)

hook.Add("PhysgunDrop", "RP1942_PropGhost", function(ply, ent)
    if not IsValid(ent) or not ent.RP1942_Held then return end
    ent.RP1942_Held = nil
    settle(ent)
end)

-- A player who dies or leaves while holding something (in case the physgun
-- didn't report the drop)
local function releaseAll()
    timer.Simple(0, function()
        for _, ent in ipairs(ents.GetAll()) do
            local holder = ent.RP1942_Held
            if holder and (not IsValid(holder) or not holder:Alive()) then
                ent.RP1942_Held = nil
                settle(ent)
            end
        end
    end)
end
hook.Add("PlayerDeath", "RP1942_PropGhost", releaseAll)
hook.Add("PlayerDisconnected", "RP1942_PropGhost", releaseAll)

hook.Add("EntityRemoved", "RP1942_PropGhost", function(ent)
    if ent.RP1942_Ghost then timer.Remove("RP1942_PropGhost_" .. ent:EntIndex()) end
end)
