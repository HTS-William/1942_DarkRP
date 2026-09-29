SWEP.Base = "mcv_throwable"
SWEP.Spawnable = true

AddCSLuaFile()

SWEP.PrintName = "AN-M8 Smoke"
SWEP.Category = "Military Conflict: Vietnam"
SWEP.Country = "United States of America"
SWEP.SubCategory = "Grenades"
SWEP.Slot = 4

SWEP.ViewModel = "models/weapons/mcv/v_m18.mdl"
SWEP.WorldModel = "models/weapons/mcv/w_m18.mdl"
SWEP.ModelSkin = 4
SWEP.MovementPoseWalk = 159
SWEP.MovementPoseSprint = 258
SWEP.MovementPoseSighted = 159

SWEP.ThrowEntity = "mcv_grenade_smoke"
SWEP.FuseModes = {3, 5}
SWEP.HasUnderhand = true
SWEP.ExplosionDamage = 0
SWEP.ExplosionRadius = 500

SWEP.Primary.Ammo = "mcv_grenade"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 2
SWEP.WeaponWeight = 1
