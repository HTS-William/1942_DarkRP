AddCSLuaFile()
SWEP.Base = "mcv_kar98_s"
SWEP.Spawnable = true
SWEP.Category = "Military Conflict: Vietnam"
SWEP.PrintName = "Karabiner 98K ZF41"
SWEP.SubCategory = "Bolt-Action Rifles"
SWEP.IconOverride = "entities/mcv_kar98_zf41.png"

SWEP.BayonetBodygroup = 1

SWEP.LastShotAnimation = false
SWEP.MagInClip = true
// A scope sits over the receiver, where the stripper clip would have to go, so a sniper feeds
// one round at a time even where the rifle it is built on takes a clip. The single-round set is
// in the model already (reload_start / reload_insert / reload_end); the clip animations are the
// ones that go unused now. Same as the M40 and the Vz.54 sniper.
SWEP.ShotgunReload = true
SWEP.InsertClipPoseTime = 0.3
SWEP.ShotgunAltReload = true
SWEP.ShotgunReloadEmptyStartAnimation = false
SWEP.PlayCycleAnimation = true
SWEP.HasEmptyReload = true
SWEP.ShotgunReload = false

// weapon_kar98k_zf41: the forward-mounted low-power optic, separate from the ZF39 sniper.
SWEP.BodyGroups = "00200"
SWEP.WorldModelBodyGroups = "00200"
SWEP.AdjustableScopes = false
SWEP.ScopeMaterial = Material("models/weapons/mcv/optics/crosshair_zf41")
SWEP.ScopeFOV = 37.5
SWEP.ScopeFOV2 = 37.5
SWEP.RTScopeMaterialIndex = 9
SWEP.ScopeIdleLensMaterial = "models/weapons/mcv/optics/lens_zf39"
SWEP.SightedViewModelFOV = 15
SWEP.IronsightPos = Vector(0, -5, -0.46)
SWEP.IronsightAng = Angle(0, 0, 0)
SWEP.IronsightSpeedScale = 1
SWEP.WeaponWeight = 3.9
SWEP.RangeModifier = 0.975
SWEP.Spread = 6
SWEP.SpreadIronsighted = 0.15

SWEP.HasBayonet = true

SWEP.BashDamage = 50
SWEP.BayonetDamage = 100