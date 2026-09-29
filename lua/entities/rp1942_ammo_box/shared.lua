--[[---------------------------------------------------------------------------
1942 DarkRP - a box of period ammo (rp1942_core/sh_ammo.lua), e.g. found in
a dumpster. Press E to take the rounds. Can be pocketed.
    RP1942.makeAmmoBox(ammoType, amount, pos)   (server)
---------------------------------------------------------------------------]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ammo Box"
ENT.Author = "1942 DarkRP"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "AmmoType")
    self:NetworkVar("Int", 0, "Amount")
end
