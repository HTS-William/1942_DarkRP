include("shared.lua")

surface.CreateFont("RP1942_AmmoBox", { font = "Roboto", size = 26, weight = 700, extended = true })

function ENT:Draw()
    self:DrawModel()
    local eye = LocalPlayer():EyePos()
    local top = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 6)
    if eye:DistToSqr(top) > 200 * 200 then return end
    local ang = (eye - top):Angle()
    ang = Angle(0, ang.y + 90, 90)
    local name = RP1942.ammoName and RP1942.ammoName(self:GetAmmoType()) or self:GetAmmoType()
    cam.Start3D2D(top, ang, 0.08)
        draw.SimpleTextOutlined(self:GetAmount() .. " × " .. name, "RP1942_AmmoBox", 0, 0, Color(236, 228, 212), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, 200))
    cam.End3D2D()
end
