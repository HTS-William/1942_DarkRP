--[[---------------------------------------------------------------------------
42Bros - a cinema screen: shows a film camera that's on air, in black and
white, and plays what's heard around the camera (rp1942_broadcast).
E changes channel: the next camera on air, then off (its owner, or staff).
It's put down standing up, facing whoever bought it.
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Cinema Screen"
ENT.Author    = "Claude & William"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Camera")
    self:NetworkVar("String", 0, "OwnerName")
end
