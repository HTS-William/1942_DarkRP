--[[---------------------------------------------------------------------------
1942 DarkRP - an air raid bomb (rp1942_events/sv_event_airraid.lua drops them)

Nothing to see: an invisible point where the bomb will land. It plays the
falling whistle there and, as the whistle ends, explodes. Not spawnable.
---------------------------------------------------------------------------]]
AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Air raid bomb"
ENT.Spawnable = false

if CLIENT then
    language.Add("rp1942_airbomb", "Air raid bomb")   -- the kill feed's name for it
    function ENT:Draw() end
    return
end

-- target: where it lands (the ground), opts: the event's settings
function ENT:SetDrop(target, opts)
    self.target, self.opts = target, opts
end

function ENT:Initialize()
    local c = self.opts or {}
    self:SetModel("models/props_junk/PopCan01a.mdl")   -- (needs a model; never drawn)
    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:DrawShadow(false)

    -- The whistle, and the bang as it ends
    local whistles = c.whistles or {}
    self.whistle = whistles[math.random(math.max(#whistles, 1))]
    local fallTime = c.fallTime or 4
    if c.fallTimeFrom == "sound" and self.whistle then
        local len = SoundDuration(self.whistle)
        if len and len >= 1 then fallTime = len end
    end
    fallTime = math.Clamp(fallTime, 0.5, 15)
    -- (pitch 100 keeps its length, so the bang comes as the whistle ends)
    if self.whistle then self:EmitSound(self.whistle, c.whistleLevel or 110, 100) end
    self.boomAt = CurTime() + fallTime
end

function ENT:Boom()
    if self.done then return end
    self.done = true
    local c = self.opts or {}
    local pos = self.target or self:GetPos()
    if self.whistle then self:StopSound(self.whistle) end
    -- The bang, loud enough to carry over the siren (level 140 ~ most of a map)
    local booms = c.boomSounds
    local boom = istable(booms) and #booms > 0 and booms[math.random(#booms)] or "ambient/explosions/explode_4.wav"
    sound.Play(boom, pos, 140, math.random(90, 110), 1)
    if RP1942.explode then
        RP1942.explode(pos, { damage = c.damage or 160, radius = c.radius or 320, inflictor = self })
    else
        util.BlastDamage(self, self, pos, c.radius or 320, c.damage or 160)
        local ed = EffectData() ed:SetOrigin(pos) util.Effect("Explosion", ed, true, true)
    end
    self:Remove()
end

function ENT:Think()
    if CurTime() >= (self.boomAt or 0) then self:Boom() end
    self:NextThink(CurTime() + 0.05)
    return true
end
