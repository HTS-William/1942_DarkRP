include("shared.lua")

surface.CreateFont("RP1942_VaultTitle", { font = "Roboto", size = 42, weight = 900, extended = true })
surface.CreateFont("RP1942_VaultSub",   { font = "Roboto", size = 26, weight = 600, extended = true })

local GOLD, SUB, RED = RP1942.col("gold"), Color(170, 162, 146), Color(220, 70, 60)

local function fmt(sec)
    sec = math.max(0, math.ceil(sec))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

function ENT:Draw()
    self:DrawModel()
    local eye = LocalPlayer():EyePos()
    local top = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 18)
    if eye:DistToSqr(top) > 600 * 600 then return end

    local ang = (eye - top):Angle()
    ang = Angle(0, ang.y + 90, 90)
    local st = RP1942.bankState and RP1942.bankState() or {}
    local now = CurTime()
    local line, col
    if st.active then
        line, col = "BEING ROBBED  ·  " .. fmt(st.endsAt - now), RED
    elseif (st.cooldown or 0) > now then
        line, col = "On alert  ·  " .. fmt(st.cooldown - now), SUB
    else
        line, col = "Press E to rob", SUB
    end

    cam.Start3D2D(top, ang, 0.1)
        draw.SimpleTextOutlined("REICHSBANK", "RP1942_VaultTitle", 0, 0, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, 200))
        draw.SimpleTextOutlined(line, "RP1942_VaultSub", 0, 6, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 200))
    cam.End3D2D()
end
