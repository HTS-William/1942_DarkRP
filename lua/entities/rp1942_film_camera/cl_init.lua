include("shared.lua")

surface.CreateFont("RP1942_BcastLabel", { font = "Roboto", size = 26, weight = 700, extended = true })

local glow = Material("sprites/light_glow02_add")

function ENT:Draw()
    self:DrawModel()
    local eye = LocalPlayer():EyePos()
    if self:GetOnAir() then
        -- the red ON AIR light, and a little blink
        local pos = self:GetPos() + self:GetUp() * 7 + self:GetForward() * -2
        if math.floor(RealTime() * 2) % 2 == 0 then
            render.SetMaterial(glow)
            render.DrawSprite(pos, 10, 10, Color(255, 40, 30))
        end
    end
    if eye:DistToSqr(self:GetPos()) > 250 * 250 then return end
    local top = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 8)
    local ang = (eye - top):Angle()
    cam.Start3D2D(top, Angle(0, ang.y + 90, 90), 0.08)
        draw.SimpleTextOutlined(self:GetOnAir() and "ON AIR" or "Film camera  ·  off air", "RP1942_BcastLabel", 0, 0,
            self:GetOnAir() and Color(235, 70, 60) or Color(236, 228, 212), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, 200))
        draw.SimpleTextOutlined("E: on / off air", "RP1942_BcastLabel", 0, 6, Color(170, 160, 142), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 200))
    cam.End3D2D()
end
