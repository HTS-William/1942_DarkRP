AddCSLuaFile()

ENT.Base                     = "mcv_proj_rpg"
ENT.PrintName                = "Rocket (Panzerschreck)"
ENT.Spawnable                = false

ENT.Model                    = "models/weapons/shells/panzerschreck_rocket.mdl"

ENT.TrailParticle = "rpg_missile_trail"

// Game script: ExplosionDamage 175, ExplosionRadius 250
// what it does unless the weapon that launched it says otherwise
ENT.ExplosionDamage = 175
ENT.ExplosionRadius = 250

ENT.DestroyDoors = 1
ENT.DestroyDoorsRadius = 100

ENT.UnfreezeProps = 1
ENT.UnfreezePropsRadius = 250

function ENT:Detonate()
    local attacker = self.Attacker or self:GetOwner() or self
    local dmg = self.ExplosionDamage

    -- 1942 DarkRP: rockets leave fire at their own (lower) chance (rp1942_fire: rocketBlastChance)
    if RP1942 and RP1942.Fire then RP1942.Fire.nextBlastChance = "rocketBlastChance" end
    util.BlastDamage(self:GetInflictor(), attacker, self:GetPos(), self.ExplosionRadius, dmg)
    self:FireBullets({
        Attacker = attacker,
        Damage = dmg,
        Tracer = 0,
        Src = self:GetPos(),
        Dir = self:GetForward(),
        HullSize = 0,
        Distance = 32,
        IgnoreEntity = self,
        Callback = function(atk, btr, dmginfo)
            dmginfo:SetDamageType(DMG_AIRBOAT + DMG_BLAST)
            dmginfo:SetDamageForce(self:GetForward() * 4000)
        end,
    })

    MCV.ExplosionEffect("rpg", self:GetImpactPos(), self:GetImpactNormal(), self:WaterLevel() > 0)
    -- 1942 DarkRP: and burst into flame like a molotov (its fire burst particle, not its pool)
    if self:WaterLevel() == 0 then ParticleEffect("Molotov_Explosion", self:GetImpactPos(), MCV.SurfaceAngle(self:GetImpactNormal())) end

    self:EmitSound("MCV_BaseGrenade.Explode")

    self:Remove()
end
