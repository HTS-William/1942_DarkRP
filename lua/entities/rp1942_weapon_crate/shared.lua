--[[---------------------------------------------------------------------------
1942 DarkRP - a crate of weapons: a gun dealer's shipment, bought from their
F3 shop in any amount (RP1942.ShopShipments in rp1942_shop/sh_shop.lua).
Press E on it to take one weapon out. Empty = it's gone.
---------------------------------------------------------------------------]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Weapon Crate"
ENT.Author = "1942 DarkRP"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "WeaponClass")
    self:NetworkVar("String", 1, "WeaponName")
    self:NetworkVar("Int", 0, "Count")
end
