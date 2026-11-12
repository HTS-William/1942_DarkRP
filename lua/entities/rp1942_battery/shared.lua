--[[---------------------------------------------------------------------------
42Bros - a car battery (Factory Owner, Petroleum Producer): power for the
factory line and the oil rig. Push it into one to charge it; E picks it up
and carries it. Settings: RP1942.Battery (rp1942_production/sh_machine_upgrades.lua).
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Car Battery"
ENT.Author    = "Claude & William"
ENT.Spawnable = false
ENT.LabelHeight = 10

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")   -- set by DarkRP when bought
end
