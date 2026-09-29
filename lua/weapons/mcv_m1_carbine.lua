AddCSLuaFile()

SWEP.Base = "mcv_m2c"
SWEP.Spawnable = true
SWEP.PrintName = "M1 Carbine"
SWEP.Category = "Military Conflict: Vietnam"
SWEP.SubCategory = "Carbines"
SWEP.Country = "United States of America"
SWEP.ViewModel = "models/weapons/mcv/v_m1_carbine.mdl"
SWEP.WorldModel = "models/weapons/mcv/w_m1_carbine.mdl"
SWEP.IconOverride = "entities/mcv_m1_carbine.png"

// Fixed M2 stock and handling, with the Para's 15-round magazine.
SWEP.Firemodes = {MCV.FIREMODE_SEMI}
SWEP.Primary.ClipSize = 15
SWEP.Primary.Chamber = 1
SWEP.Primary.DefaultClip = 75 // Matches the 15-round M1A1 Para.
