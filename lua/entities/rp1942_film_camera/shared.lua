--[[---------------------------------------------------------------------------
42Bros - a placed film camera: films live for cinema screens (rp1942_broadcast),
like the hand-held Newsreel Camera but left standing somewhere (a stage, the
town square, a courtroom). E puts it on air or takes it off (its owner, or
staff). It films where its lens points: aim it with the physgun.
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

-- What the broadcast films: out of the lens (the same as the hand-held one's)
function ENT:BroadcastView()
    return self:GetPos() + self:GetForward() * 10, self:GetAngles(), nil
end

function ENT:Broadcasting() return self:GetOnAir() end

-- Whose camera, for the screen's "Showing ...'s camera"
function ENT:BroadcastName() return self:GetOwnerName() ~= "" and self:GetOwnerName() or "a" end
