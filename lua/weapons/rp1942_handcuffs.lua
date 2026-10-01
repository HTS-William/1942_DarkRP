--[[---------------------------------------------------------------------------
1942 DarkRP - Handcuffs (instead of DarkRP's arrest baton)

Left click a player: they're held still while a bar fills (8 s), then
arrested. Right click: let go. The rules and settings are in
darkrp_modules/rp1942_handcuffs/sh_handcuffs.lua.
---------------------------------------------------------------------------]]
AddCSLuaFile()

SWEP.PrintName     = "Handcuffs"
SWEP.Author        = "1942 DarkRP"
SWEP.Instructions  = "Left click a player to handcuff them: they're held still, and arrested when the bar fills. Right click to let go."
SWEP.Category      = "1942 DarkRP"
SWEP.Spawnable     = true
SWEP.AdminOnly     = true

SWEP.ViewModel     = "models/weapons/c_arms.mdl"
SWEP.WorldModel    = ""
SWEP.UseHands      = false
SWEP.HoldType      = "normal"
SWEP.Slot          = 1
SWEP.SlotPos       = 3
SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

local function cfg(key, default)
    local c = RP1942 and RP1942.HandcuffsConfig
    if c and c[key] ~= nil then return c[key] end
    return default
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not RP1942.handcuffStart then return end

    local start = owner:GetShootPos()
    local stop = start + owner:GetAimVector() * cfg("range", 90)
    owner:LagCompensation(true)
    local tr = util.TraceLine({ start = start, endpos = stop, filter = owner, mask = MASK_SHOT_HULL })
    if not (IsValid(tr.Entity) and tr.Entity:IsPlayer()) then
        tr = util.TraceHull({ start = start, endpos = stop, filter = owner, mask = MASK_SHOT_HULL,
            mins = Vector(-10, -10, -10), maxs = Vector(10, 10, 10) })
    end
    owner:LagCompensation(false)

    local ent = tr.Entity
    if not IsValid(ent) then return end
    if ent.onArrestStickUsed then ent:onArrestStickUsed(owner) return end   -- what the baton did to entities
    if ent:IsPlayer() then RP1942.handcuffStart(owner, ent) end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)
    if SERVER and RP1942.handcuffStop then RP1942.handcuffStop(self:GetOwner(), "you let go") end
end

if CLIENT then
    function SWEP:ShouldDrawViewModel() return false end

    -- Shown in the HUD's bottom-right panel (rp1942_hud/cl_hud.lua, drawWeaponInfo)
    function SWEP:HudInfo()
        return {
            "LEFT CLICK  a player: handcuff them",
            "stay close " .. cfg("time", 8) .. " s: they're arrested",
            "RIGHT CLICK  let go",
        }
    end
end
