--[[---------------------------------------------------------------------------
42Bros - a film camera: films live for cinema screens (rp1942_broadcast).
E puts it on air or takes it off (its owner, or staff). It films where its
lens points: aim it with the physgun.
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Film Camera"
ENT.Author    = "Claude & William"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "OnAir")
    self:NetworkVar("String", 0, "OwnerName")
end
