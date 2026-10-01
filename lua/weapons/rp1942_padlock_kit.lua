--[[---------------------------------------------------------------------------
1942 DarkRP - the Padlock (what you buy, and fit to a prop)

Left click a prop you own: the padlock goes on it and the prop becomes a
door (darkrp_modules/rp1942_padlocks). The padlock is used up.
Staff get one that doesn't run out with !padlock: it fits on any prop and
makes a staff lock (no owner, opened by faction / Reich unit).
---------------------------------------------------------------------------]]
AddCSLuaFile()

SWEP.PrintName    = "Padlock"
SWEP.Author       = "1942 DarkRP"
SWEP.Instructions = "Left click a prop you own to fit the padlock. The prop becomes a door."
SWEP.Category     = "1942 DarkRP"
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = "models/props_wasteland/prison_padlock001a.mdl"
SWEP.UseHands     = false
SWEP.HoldType     = "slam"
SWEP.Slot         = 5
SWEP.SlotPos      = 4
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"
SWEP.Secondary = SWEP.Primary

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "StaffKit")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.8)
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or not RP1942.padlockFit then return end
    if RP1942.padlockFit(ply, ply:GetEyeTrace(), self:GetStaffKit()) and not self:GetStaffKit() then
        ply:StripWeapon(self:GetClass())   -- used up
    end
end

function SWEP:SecondaryAttack() end

if CLIENT then
    function SWEP:ShouldDrawViewModel() return false end   -- nothing to hold up in first person

    -- Shown in the HUD's bottom-right panel, where the ammo would be
    -- (rp1942_hud/cl_hud.lua, drawWeaponInfo)
    function SWEP:HudInfo()
        if self:GetStaffKit() then
            return {
                "LEFT CLICK  any prop: a staff door",
                "Shift+E the lock  who opens it",
                "!savelock  keep it on this map",
            }
        end
        return {
            "LEFT CLICK  a prop you own",
            "it becomes a door you lock",
            "Shift+E the lock  who else opens it",
        }
    end
end
