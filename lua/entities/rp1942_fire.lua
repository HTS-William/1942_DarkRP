--[[---------------------------------------------------------------------------
1942 DarkRP - one fire (a "node" of the spreading fire system)

Made by rp1942_fire/sv_fire.lua (RP1942.startFire) or by another fire
spreading. Don't spawn it by hand; use !fire.

Each node shows the molotov's ground fire particle (the "look" setting;
"engine" uses an env_fire instead), loops the molotov's fire sound, and
does its own work around it: burning whoever stands in it
(with the arsonist getting the kill), setting nearby props alight, and
spreading. When the env_fire is gone (burnt out, or an addon sent it the
Extinguish input) the node goes with it.

Putting it out, any of these work:
    node:Extinguish()                 (also what an extinguisher SWEP may call)
    node:Fire("Extinguish")           (input, same as env_fire's)
    node:IsOnFire() is true, so "put out everything on fire" addons find it
---------------------------------------------------------------------------]]
AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Fire"
ENT.Author    = "1942 DarkRP"
ENT.Spawnable = false

-- set by whoever spawns it (see RP1942.startFire)
ENT.Generation = 0        -- 0 = lit directly, 1 = spread from that, ...
ENT.Cluster    = 0        -- patch id, for the per-patch cap
ENT.Life       = nil      -- seconds; nil = random between lifeMin and lifeMax
ENT.Arsonist   = nil      -- player who gets the kills
ENT.Inflictor  = nil

-- env_fire spawnflags
local SF_START_ON  = 4
local SF_START_FULL = 8
local SF_DONT_DROP = 16        -- we've already found the ground
local SF_DIE_PERMANENT = 128   -- "delete when out": it's gone once extinguished

local function S(k) return RP1942.fireSetting(k) end

if CLIENT then
    function ENT:Draw() end
    return
end

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate.mdl")
    self:SetNoDraw(true)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(false)
    self:SetNotSolid(true)

    local life = self.Life or math.Rand(S("lifeMin"), S("lifeMax"))
    if self.Generation > 0 then life = life * math.Rand(0.7, 1) end
    self.DieAt = CurTime() + life
    self.NextTick = CurTime() + 0.1
    self.NextSpread = CurTime() + S("spreadInterval") * math.Rand(0.8, 1.6)

    if S("look") == "engine" then
        -- the engine's own fire (env_fire): flames, light, smoke, answers the
        -- Extinguish input
        local base = S("flameSize") or 100
        local size = math.random(math.floor(base * 0.8), math.floor(base * 1.2))
        local fire = ents.Create("env_fire")
        if IsValid(fire) then
            fire:SetPos(self:GetPos())
            fire:SetKeyValue("health", tostring(math.ceil(life)))
            fire:SetKeyValue("firesize", tostring(size))
            fire:SetKeyValue("fireattack", "1")
            fire:SetKeyValue("damagescale", "0")       -- we do the damage ourselves
            fire:SetKeyValue("ignitionpoint", "32")
            fire:SetKeyValue("firetype", "0")
            fire:SetKeyValue("spawnflags", tostring(SF_START_ON + SF_DONT_DROP + SF_DIE_PERMANENT + (self.Generation > 0 and 0 or SF_START_FULL)))
            fire:SetParent(self)
            fire:Spawn()
            fire:Activate()
            fire:Fire("StartFire", "", 0)
            self.EnvFire = fire
        end
    else
        -- the molotov's ground fire particle (mcv_firepool uses the same one)
        local particle = S("particle")
        if particle and particle ~= "" then
            self.Particle = particle
            ParticleEffect(particle, self:GetPos(), Angle(0, math.random(0, 359), 0), self)
        end
    end

    local snd = S("sound")
    if snd and snd ~= "" then
        self.LoopSound = snd
        self:EmitSound(snd, S("soundLevel") or 70, math.random(90, 110), 0.8, CHAN_STATIC)
    end

    if RP1942.Fire and RP1942.Fire.register then RP1942.Fire.register(self) end
    self:NextThink(CurTime())
end

function ENT:Think()
    if CurTime() > self.DieAt or (self.EnvFire ~= nil and not IsValid(self.EnvFire)) then
        self:Remove()
        return
    end

    local now = CurTime()
    if now >= self.NextTick then
        self.NextTick = now + 0.25
        self:Burn(0.25)
    end
    if now >= self.NextSpread then
        self.NextSpread = now + S("spreadInterval") * math.Rand(0.8, 1.2)
        self:TrySpread()
    end

    self:NextThink(now + 0.05)
    return true
end

-- Hurt whoever's in the flames; set props alight
function ENT:Burn(dt)
    local pos = self:GetPos()
    local radius = S("burnRadius")
    local attacker = IsValid(self.Arsonist) and self.Arsonist or game.GetWorld()
    local inflictor = IsValid(self.Inflictor) and self.Inflictor or self
    local dps = S("damagePerSecond")
    local igniteFor = S("ignitePropsFor")

    for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
        if ent == self or ent == self.EnvFire then continue end
        local living = ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()
        if living then
            if ent:IsPlayer() and not ent:Alive() then continue end
            if math.abs(ent:GetPos().z - pos.z) > 80 then continue end
            local dmg = DamageInfo()
            dmg:SetDamage(dps * dt)
            dmg:SetDamageType(DMG_BURN)
            dmg:SetAttacker(attacker)
            dmg:SetInflictor(inflictor)
            dmg:SetDamagePosition(ent:GetPos())
            ent:TakeDamageInfo(dmg)
            local after = S("afterburn")
            if after > 0 then
                if MCV and MCV.Burn then
                    MCV.Burn(ent, after, attacker, inflictor, math.max(4, dps * 0.5))
                elseif not ent:IsOnFire() then
                    ent:Ignite(after)
                end
            end
        elseif igniteFor > 0 and ent:GetClass() == "prop_physics" and not ent:IsOnFire() then
            if math.abs(ent:GetPos().z - pos.z) < 120 then ent:Ignite(igniteFor) end
        end
    end
end

-- Try to light a new fire a short way off (the ground check and the caps
-- are in sv_fire.lua)
function ENT:TrySpread()
    if not S("spreading") then return end
    if self.Generation >= S("maxGeneration") then return end
    local F = RP1942.Fire
    if not F or not F.canSpawn or not F.canSpawn(self.Cluster) then return end

    local chance = S("spreadChance") * (S("spreadDecay") ^ self.Generation)
    -- the last quarter of its life, a fire is dying: it spreads less
    local left = self.DieAt - CurTime()
    if left < 6 then chance = chance * 0.4 end
    if math.random() > chance then return end

    local ang = math.Rand(0, 360)
    local dist = math.Rand(S("spreadDistMin"), S("spreadDistMax"))
    local target = self:GetPos() + Vector(math.cos(math.rad(ang)) * dist, math.sin(math.rad(ang)) * dist, 0)
    local ground = F.findGround(target, self)
    if not ground then return end

    F.spawnNode(ground, {
        generation = self.Generation + 1,
        cluster    = self.Cluster,
        attacker   = self.Arsonist,
        inflictor  = self.Inflictor,
    })
end

-- Putting it out. `by` is the player with the extinguisher (rewarded), or
-- nothing when it's staff / code.
function ENT:Extinguish(by)
    if self.PutOut then return end
    self.PutOut = true
    local pos = self:GetPos()
    if IsValid(by) and by:IsPlayer() and RP1942.Fire.reward then RP1942.Fire.reward(by, self) end
    if IsValid(self.EnvFire) then self.EnvFire:Fire("Extinguish", "", 0) end
    -- a puff of steam and a hiss
    local ed = EffectData()
    ed:SetOrigin(pos + Vector(0, 0, 16))
    ed:SetScale(1)
    util.Effect("WaterSplash", ed, true, true)
    sound.Play("ambient/water/water_spray" .. math.random(1, 3) .. ".wav", pos, 70, math.random(90, 110), 0.7)
    self:Remove()
end

-- "put everything out" addons look for entities on fire
function ENT:IsOnFire() return not self.PutOut end

function ENT:AcceptInput(name, activator, caller, data)
    name = string.lower(name)
    if name == "extinguish" or name == "extinguishtemporary" or name == "kill" then
        self:Extinguish()
        return true
    end
end

function ENT:OnRemove()
    if self.Particle then self:StopParticles() end
    if self.LoopSound then self:StopSound(self.LoopSound) end
    if IsValid(self.EnvFire) then self.EnvFire:Remove() end
    if RP1942.Fire and RP1942.Fire.unregister then RP1942.Fire.unregister(self) end
end
