SWEP.Base = "mcv_throwable"
SWEP.Spawnable = true

AddCSLuaFile()

SWEP.PrintName = "M18 Smoke (Red)"
SWEP.Category = "Military Conflict: Vietnam"
SWEP.Country = "United States of America"
SWEP.SubCategory = "Grenades"
SWEP.Slot = 4

SWEP.ViewModel = "models/weapons/mcv/v_m18.mdl"
SWEP.WorldModel = "models/weapons/mcv/w_m18.mdl"
SWEP.ModelSkin = 0 // Red M18; skin 4 is the AN-M8 white-smoke canister.
SWEP.MovementPoseWalk = 159
SWEP.MovementPoseSprint = 258
SWEP.MovementPoseSighted = 159

SWEP.ThrowEntity = "mcv_grenade_smoke"
SWEP.SmokeColor = Vector(255, 100, 100)
SWEP.FuseModes = {3, 5}
SWEP.HasUnderhand = true
SWEP.ExplosionDamage = 0
SWEP.ExplosionRadius = 500

SWEP.Primary.Ammo = "mcv_grenade"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 2
SWEP.WeaponWeight = 1
