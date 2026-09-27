--[[---------------------------------------------------------------------------
1942 DarkRP - a sack of flour (Baker). Push it into an oven to bake bread.
E picks it up and carries it.
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Sack of Flour"
ENT.Author    = "Claude & William"
ENT.Spawnable = false
ENT.LabelHeight = 8

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")   -- set by DarkRP when bought
end
