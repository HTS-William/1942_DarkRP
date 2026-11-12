--[[---------------------------------------------------------------------------
42Bros - a television: a small set that shows a film camera that's on air,
like the cinema screen (rp1942_broadcast), and plays what's heard around the
camera. Anyone can buy one (F4 shop, Supplies). E changes channel: the next
camera on air, then off (its owner, or staff). It's an ordinary prop: move
it with the physgun or Shift+E.

The picture is drawn on the front of the model (+X). If it doesn't sit
right on the glass, nudge ENT.ScreenArea below: fractions of the model's
size (width / height of the picture, how far right / up its centre is from
the middle, and how far in front of the box it's drawn, in units).
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Television"
ENT.Author    = "Claude & William"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Model = "models/props_c17/tv_monitor01.mdl"
ENT.ScreenArea = {
    width  = 0.70,   -- of the model's width
    height = 0.64,   -- of the model's height
    right  = -0.04,  -- centre, to the right (of the width); minus = left
    up     = 0.06,   -- centre, upwards (of the height)
    out    = 0.15,   -- units in front of the front face
}

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Camera")
    self:NetworkVar("String", 0, "OwnerName")
end
