include("shared.lua")

surface.CreateFont("RP1942_RadioName", { font = "Roboto", size = 28, weight = 800, extended = true })
surface.CreateFont("RP1942_RadioSub",  { font = "Roboto", size = 20, weight = 600, extended = true })

local GOLD, SUB, RED = Color(201, 168, 92), Color(170, 162, 146), Color(220, 70, 60)

function ENT:Think()
    RP1942.radioThink(self)
    self:SetNextClientThink(CurTime() + 0.1)
    return true
end

function ENT:OnRemove()
    RP1942.radioStop(self)
end

function ENT:Draw()
    self:DrawModel()
    local eye = LocalPlayer():EyePos()
    local top = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 6)
    if eye:DistToSqr(top) > 350 * 350 then return end

    local ang = (eye - top):Angle()
    ang = Angle(0, ang.y + 90, 90)
    local station, line, col = self:GetStation(), "Press E to tune", SUB
    if station == "BROKEN" then
        station, line, col = "Radio", "Broken", RED
    elseif self:GetURL() ~= "" then
        line = RP1942.radioStatus(self)
        if self.radioFailed then col = RED elseif line == "Playing" then line = "Playing  ·  E to tune" end
    else
        station = "Radio"
    end
    cam.Start3D2D(top, ang, 0.08)
        draw.SimpleTextOutlined(station ~= "" and station or "Radio", "RP1942_RadioName", 0, 0, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, 200))
        draw.SimpleTextOutlined(line, "RP1942_RadioSub", 0, 4, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 200))
    cam.End3D2D()
end
