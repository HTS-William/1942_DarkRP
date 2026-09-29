AddCSLuaFile()
SWEP.Base = "mcv_l1a1"
SWEP.Spawnable = false
SWEP.PrintName = "X2F2A2 FAL"
SWEP.Category = "Military Conflict: Vietnam"
SWEP.SubCategory = "Battle Rifles"
SWEP.Country = "United Kingdom"
SWEP.ViewModel = "models/weapons/mcv/v_x2f2a2.mdl"
SWEP.WorldModel = "models/weapons/mcv/w_x2f2a2.mdl"
SWEP.IconOverride = "entities/mcv_x2f2a2.png"
// Estimated prototype configuration; inherits the standard FAL's ballistics.
SWEP.Firemodes = {MCV.FIREMODE_AUTO, MCV.FIREMODE_SEMI}
SWEP.FireRate = 650
SWEP.Primary.ClipSize = 25
SWEP.Primary.Chamber = 1
SWEP.Primary.DefaultClip = 90
// Lightweight handling tradeoff, following the SOG/SASR variants: livelier recoil
// with faster aiming, tighter hip spread and smaller movement penalties.
SWEP.WeaponWeight = 3.6
SWEP.IronsightSpeedScale = 1.2
SWEP.ViewSlideRecoilUp = 2.53
SWEP.ViewSlideRecoilRight = 0.78
SWEP.ViewSlideRecoilIronsightUp = 1.66
SWEP.ViewSlideRecoilIronsightRight = 0.52
SWEP.Spread = 6.75
SWEP.StandMoveSpreadMultiplier = 1.4
SWEP.SneakMoveSpreadMultiplier = 1.3
SWEP.CrouchMoveSpreadMultiplier = 1.2
SWEP.HasBayonet = false // no bayonet mesh/bodygroup in this model
SWEP.HasBipod = false
SWEP.BodyGroups = "00"
SWEP.BeltBodygroups = {1}
SWEP.MovementPoseWalk = 133
SWEP.MovementPoseSprint = 227
SWEP.MovementPoseSighted = 133
SWEP.SafeMovementAnimations = false
