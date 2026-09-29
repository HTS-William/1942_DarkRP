include("shared.lua")

surface.CreateFont("RP1942_CrateName",  { font = "Roboto", size = 34, weight = 800, extended = true })
surface.CreateFont("RP1942_CrateCount", { font = "Roboto", size = 26, weight = 600, extended = true })

local TEXT, GOLD = Color(236, 228, 212), Color(201, 168, 92)

function ENT:Draw()
    self:DrawModel()
    local eye = LocalPlayer():EyePos()
    local top = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 10)
    if eye:DistToSqr(top) > 350 * 350 then return end
    local ang = (eye - top):Angle()
    ang = Angle(0, ang.y + 90, 90)
    cam.Start3D2D(top, ang, 0.1)
        draw.SimpleTextOutlined(self:GetWeaponName(), "RP1942_CrateName", 0, 0, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, 200))
        draw.SimpleTextOutlined(self:GetCount() .. " left  ·  press E to take one", "RP1942_CrateCount", 0, 4, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 200))
    cam.End3D2D()
end
