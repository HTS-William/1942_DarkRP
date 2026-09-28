--[[---------------------------------------------------------------------------
1942 DarkRP - explosions unfreeze props (server)

A frozen prop caught in an explosion (grenades, rockets, the oil derrick
blowing up, RP1942.explode...) is knocked loose: it unfreezes and gets
pushed away from the blast. So barricades and prop walls can be blown open.

Only players' props (owned through prop protection) are affected: props
that came with the map, and our bolted-down things (markets, derricks,
dumpsters), stay put.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.BlastUnfreeze = {
    enabled   = true,
    minDamage = 15,        -- smaller blasts (and the edges of big ones) don't shift anything
    push      = 1.0,       -- how hard it's thrown: 0 = just unfrozen, 1 = normal, 2 = twice as hard
    ownedOnly = true,      -- false = map props too (can break maps that freeze their props)

    -- Classes that are never knocked loose
    exclude = {
        rp1942_market = true, rp1942_oil_rig = true, rp1942_dumpster = true,
    },
    excludePrefix = { "func_", "prop_door", "prop_vehicle", "gmod_sent_vehicle", "npc_" },
}

local CFG = RP1942.BlastUnfreeze

local function eligible(ent)
    if not IsValid(ent) or ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() then return false end
    local class = ent:GetClass()
    if CFG.exclude[class] then return false end
    for _, p in ipairs(CFG.excludePrefix) do
        if string.StartWith(class, p) then return false end
    end
    if CFG.ownedOnly then
        local owner = ent.CPPIGetOwner and ent:CPPIGetOwner()
        if not IsValid(owner) then return false end
    end
    return true
end

hook.Add("EntityTakeDamage", "RP1942_BlastUnfreeze", function(ent, dmg)
    if not CFG.enabled or not dmg:IsExplosionDamage() then return end
    if dmg:GetDamage() < CFG.minDamage or not eligible(ent) then return end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) or phys:IsMotionEnabled() then return end   -- already loose: the blast pushes it anyway

    phys:EnableMotion(true)
    phys:Wake()

    -- Thrown away from the blast, harder the closer it was
    if CFG.push > 0 then
        local from = dmg:GetDamagePosition()
        local center = ent:WorldSpaceCenter()
        local dir = center - from
        if dir:LengthSqr() < 1 then dir = VectorRand() end
        dir:Normalize()
        dir.z = math.max(dir.z, 0.25)   -- a little lift, so it doesn't just grind along the floor
        local speed = math.Clamp(dmg:GetDamage() * 4 * CFG.push, 0, 1200)   -- units per second
        phys:ApplyForceCenter(dir * speed * math.min(phys:GetMass(), 250))   -- very heavy props move less
        phys:AddAngleVelocity(VectorRand() * 90 * CFG.push)
    end
end)
