--[[---------------------------------------------------------------------------
1942 DarkRP - Professional Lockpick (the Pro Thief's)

DarkRP's lockpick, only much faster: it IS DarkRP's lockpick underneath
(SWEP.Base), so it opens the same things, fails the same way (look away,
walk off, holster) and works with every addon that knows the lockpick.

    DarkRP's lockpick:   10 - 30 seconds
    This one:            PICK_TIME below
---------------------------------------------------------------------------]]
AddCSLuaFile()

local PICK_TIME = { 3, 8 }   -- seconds: a random time between these, per lock

SWEP.Base         = "lockpick"
SWEP.PrintName    = "Professional Lockpick"
SWEP.Instructions = "Left or right click to pick a lock. Much faster than a common lockpick."
SWEP.Author       = "1942 DarkRP"
SWEP.Spawnable    = true
SWEP.AdminOnly    = true
SWEP.Category     = "1942 DarkRP"

if CLIENT then
    SWEP.Slot    = 5
    SWEP.SlotPos = 2
end

-- DarkRP asks this hook how long a pick takes (on both client and server,
-- with the same seed, so the progress bar matches)
hook.Add("lockpickTime", "RP1942_ProLockpick", function(ply, ent)
    local wep = IsValid(ply) and ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "rp1942_lockpick_pro" then
        return util.SharedRandom("RP1942_ProLockpick" .. wep:EntIndex() .. "_" .. wep:GetTotalLockpicks(), PICK_TIME[1], PICK_TIME[2])
    end
end)
