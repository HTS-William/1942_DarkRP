--[[---------------------------------------------------------------------------
1942 DarkRP - scrap metal (Factory Owner). Push it into a factory line: each
load runs the line once. E picks it up and carries it.
Settings: RP1942.Production.scrap (rp1942_production/sh_production.lua).
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Scrap Metal"
ENT.Author    = "Claude & William"
ENT.Spawnable = false
ENT.LabelHeight = 8

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")   -- set by DarkRP when bought
end
