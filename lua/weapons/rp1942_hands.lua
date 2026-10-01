--[[---------------------------------------------------------------------------
1942 DarkRP - Hands (everyone spawns with them)

    LEFT CLICK    raise your fists; click again to punch
    RIGHT CLICK   push the player in front of you
    R             raise or lower your fists
Settings: RP1942.HandsConfig in darkrp_modules/rp1942_hands/sh_hands.lua.
---------------------------------------------------------------------------]]
AddCSLuaFile()

SWEP.PrintName     = "Hands"
SWEP.Author        = "1942 DarkRP"
SWEP.Instructions  = "Left click: raise your fists, then punch. Right click: push. R: raise or lower your fists."
SWEP.Category      = "1942 DarkRP"
SWEP.Spawnable     = true
SWEP.AdminOnly     = false

SWEP.ViewModel     = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel    = ""
SWEP.ViewModelFOV  = 54
SWEP.UseHands      = true
SWEP.HoldType      = "normal"
SWEP.Slot          = 0
SWEP.SlotPos       = 0
SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = true

SWEP.Primary = { ClipSize = -1, DefaultClip = -1, Automatic = true, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = true, Ammo = "none" }

local SWING     = Sound("WeaponFrag.Throw")
local HIT       = Sound("Flesh.ImpactHard")
local HIT_WORLD = Sound("Flesh.ImpactSoft")
local PUSH      = "physics/body/body_medium_impact_soft%d.wav"   -- 1 to 7

local function cfg(key, default)
    local c = RP1942 and RP1942.HandsConfig
    if c and c[key] ~= nil then return c[key] end
    return default
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool",  0, "Raised")
    self:NetworkVar("Int",   0, "Combo")
    self:NetworkVar("Float", 0, "NextMelee")   -- when the punch being thrown lands
    self:NetworkVar("Float", 1, "NextIdle")
    self:NetworkVar("Float", 2, "LastFight")   -- last punch (or raise): fists drop lowerAfter later
    self:NetworkVar("Float", 3, "HideAt")      -- lowering: the arms stay on screen until then
end

-- Two hold types, picked by Raised on every client (a hold type isn't networked)
function SWEP:Initialize()
    self:SetWeaponHoldType("fist")
    self.RaisedActs = self.ActivityTranslate
    self:SetWeaponHoldType("normal")
    self.LoweredActs = self.ActivityTranslate
end

function SWEP:TranslateActivity(act)
    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsNPC() then return -1 end
    local acts = self:GetRaised() and self.RaisedActs or self.LoweredActs
    if acts then self.ActivityTranslate = acts end
    local t = self.ActivityTranslate
    if t and t[act] ~= nil then return t[act] end
    return -1
end

local function playVM(self, seq)
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end
    local vm = owner:GetViewModel()
    if not IsValid(vm) then return end
    local id = vm:LookupSequence(seq)
    if not id or id < 0 then return end
    vm:SendViewModelMatchingSequence(id)
    vm:SetPlaybackRate(1)
    self:SetNextIdle(CurTime() + vm:SequenceDuration())
end

function SWEP:SetFists(up)
    if self:GetRaised() == up then return end
    self:SetRaised(up)
    if up then
        self:SetLastFight(CurTime())
        self:SetHideAt(0)
        playVM(self, "fists_draw")
    else
        self:SetNextMelee(0)
        self:SetNextIdle(0)
        self:SetHideAt(CurTime() + 0.35)
        playVM(self, "fists_holster")
    end
end

function SWEP:Deploy()
    self:SetRaised(false)
    self:SetHideAt(0)
    self:SetNextMelee(0)
    self:SetNextIdle(0)
    return true
end

function SWEP:Holster()
    self:SetNextMelee(0)
    return true
end

--[[ Punch -----------------------------------------------------------------]]
function SWEP:PrimaryAttack()
    if not self:GetRaised() then
        self:SetFists(true)
        self:SetNextPrimaryFire(CurTime() + 0.4)
        return
    end
    local owner = self:GetOwner()
    self:SetLastFight(CurTime())
    owner:SetAnimation(PLAYER_ATTACK1)
    playVM(self, self:GetCombo() % 2 == 0 and "fists_left" or "fists_right")
    self:EmitSound(SWING)
    self:SetCombo(self:GetCombo() + 1)
    self:SetNextMelee(CurTime() + 0.2)
    self:SetNextPrimaryFire(CurTime() + cfg("punchDelay", 0.55))
end

local function trace(owner, range, size)
    local start = owner:GetShootPos()
    local stop = start + owner:GetAimVector() * range
    if SERVER then owner:LagCompensation(true) end
    local tr = util.TraceLine({ start = start, endpos = stop, filter = owner, mask = MASK_SHOT_HULL })
    if not IsValid(tr.Entity) then
        tr = util.TraceHull({ start = start, endpos = stop, filter = owner, mask = MASK_SHOT_HULL,
            mins = Vector(-size, -size, -size), maxs = Vector(size, size, size) })
    end
    if SERVER then owner:LagCompensation(false) end
    return tr
end

local function living(ent)
    return IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot())
end

function SWEP:Punch()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local tr = trace(owner, cfg("punchRange", 48), 8)
    if not tr.Hit then return end
    local ent = tr.Entity
    if IsFirstTimePredicted() then self:EmitSound(living(ent) and HIT or HIT_WORLD) end
    if CLIENT then return end

    if living(ent) then
        local d = DamageInfo()
        d:SetAttacker(owner)
        d:SetInflictor(self)
        d:SetDamage(cfg("punchDamage", 8))
        d:SetDamageType(DMG_CLUB)
        d:SetDamagePosition(tr.HitPos)
        d:SetDamageForce(owner:GetAimVector() * 3000)
        ent:TakeDamageInfo(d)
        if ent:IsPlayer() then ent:ViewPunch(Angle(-4, math.Rand(-6, 6), math.Rand(-3, 3))) end
    elseif IsValid(ent) then
        -- props get a nudge; nothing else (doors, padlocks, fires) is hurt by a punch
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) and phys:IsMoveable() then
            phys:ApplyForceOffset(owner:GetAimVector() * math.min(phys:GetMass(), 50) * 60, tr.HitPos)
        end
    end
end

--[[ Push ------------------------------------------------------------------]]
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.3)
    local owner = self:GetOwner()
    local target = trace(owner, cfg("pushRange", 60), 12).Entity
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return end
    if target:InVehicle() or target:GetMoveType() == MOVETYPE_NOCLIP then return end

    self:SetNextSecondaryFire(CurTime() + cfg("pushDelay", 1.5))
    if IsFirstTimePredicted() then self:EmitSound(string.format(PUSH, math.random(1, 7)), 70) end
    if CLIENT then return end

    -- away from you, along the ground
    local dir = owner:GetAimVector()
    dir.z = 0
    if dir:LengthSqr() < 0.01 then dir = target:GetPos() - owner:GetPos() dir.z = 0 end
    dir:Normalize()
    target:SetVelocity(dir * cfg("pushForce", 320) + Vector(0, 0, cfg("pushUp", 90)))
    target:ViewPunch(Angle(-6, 0, math.Rand(-4, 4)))
    if RP1942.handsGesture then RP1942.handsGesture(owner) end
end

--[[ R: raise / lower --------------------------------------------------------]]
function SWEP:Reload()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:KeyPressed(IN_RELOAD) then return end
    self:SetFists(not self:GetRaised())
    if self:GetRaised() then self:SetNextPrimaryFire(CurTime() + 0.4) end
end

function SWEP:Think()
    local now = CurTime()
    local melee = self:GetNextMelee()
    if melee > 0 and now >= melee then
        self:SetNextMelee(0)
        self:Punch()
    end
    if not self:GetRaised() then return end
    local idle = self:GetNextIdle()
    if idle > 0 and now > idle then playVM(self, "fists_idle_0" .. (self:GetCombo() % 2 + 1)) end
    local after = cfg("lowerAfter", 6)
    if after > 0 and self:GetNextMelee() == 0 and now - self:GetLastFight() > after then self:SetFists(false) end
end

if CLIENT then
    -- Hands down: no arms on screen
    function SWEP:ShouldDrawViewModel()
        return self:GetRaised() or CurTime() < self:GetHideAt()
    end
end
