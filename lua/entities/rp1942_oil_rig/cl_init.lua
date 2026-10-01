include("shared.lua")

--[[---------------------------------------------------------------------------
The rig's control plate, in brass & enamel (like the oven's). Where it
sits on the prop: RP1942.PanelSpots.rp1942_oil_rig in sh_production.lua
(fine-tune it in game with the rp1942_panel_* console commands).
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 620, h = 640 }
ENT.PanelScale = 0.045
ENT.PanelLift  = 12
ENT.PanelNoBackground = true

local ENAMEL = Color(34, 34, 36)
local LOW, RIGHT, HIGH = Color(70, 90, 150), Color(60, 140, 70), Color(190, 50, 40)
local OIL = Color(200, 150, 50)
local AMBER_BTN = Color(170, 120, 30)
local DIAL_FACE = Color(150, 140, 118)   -- aged, like the factory's: a white face glows on dark maps
local IRON, IRON_LIGHT = Color(128, 36, 28), Color(176, 64, 48)

-- The valve wheel: an iron hand-wheel with five spokes, turning a full turn
-- (anticlockwise to open, clockwise to close) each time it's used
local function valveWheel(P, ent, cx, cy, r, enabled)
    local B = RP1942.Brass
    local hot = P:Hot("wheel", cx - r - 14, cy - r - 14, (r + 14) * 2, (r + 14) * 2 + 56, enabled and not ent:WheelTurning())
    local t = math.Clamp((CurTime() - ent:GetWheelTurnedAt()) / (ent:Config().wheelTime or 1.2), 0, 1)
    local ease = t < 1 and (1 - (1 - t) ^ 3) or 1                     -- starts fast, settles
    local turn = (ent:GetValveOpen() and -360 or 360) * ease          -- a full turn, so it ends where it started
    local rim, rimLight = IRON, IRON_LIGHT   -- always red, even while it can't be turned

    if hot then B.Arc(cx, cy, r + 2, r + 9, 0, 360, B.WHITE) end
    -- Spokes and their grips
    for i = 0, 4 do
        local a = math.rad(turn + i * 72 - 90)
        local ex, ey = cx + math.cos(a) * (r - 6), cy + math.sin(a) * (r - 6)
        B.Line(cx, cy, ex, ey, 9, rim)
        B.Line(cx, cy, ex, ey, 3, rimLight)
    end
    -- The rim: dark outer ring, lighter inner edge
    B.Arc(cx, cy, r - 12, r, 0, 360, rim)
    B.Arc(cx, cy, r - 12, r - 8, 0, 360, rimLight)
    -- Grip knobs on the rim, between the spokes
    for i = 0, 4 do
        local a = math.rad(turn + i * 72 - 54)
        local kx, ky = cx + math.cos(a) * (r - 6), cy + math.sin(a) * (r - 6)
        B.Circle(kx, ky, 8, rim)
        B.Circle(kx - 2, ky - 2, 3, rimLight)
    end
    -- Hub, red like the rest
    B.Circle(cx, cy, 17, Color(80, 20, 16))
    B.Circle(cx, cy, 14, rim)
    B.Circle(cx - 3, cy - 4, 5, rimLight)

    B.Plaque(cx, cy + r + 16, 200, 38, ent:GetValveOpen() and "CLOSE VALVE" or "OPEN VALVE", "RP1942_BrassLabel")
    return hot
end

-- Repaint the panel quickly while the wheel turns or the alarm flashes
function ENT:PanelFast()
    return self:WheelTurning() or (not self:GetOff() and self:Alarming())
end

function ENT:PaintPanel(P, w, h)
    local B = RP1942.Brass
    local c = self:Config()
    local pumping, ready = self:IsPumping(), self:GetReady()
    local off = self:GetOff()

    B.Plate(w, h, ENAMEL)
    B.Plaque(w / 2, 24, 480, 46, "BOHRANLAGE  ·  OIL RIG")

    -- The well: the needle is the pressure, the bands its zones
    local p = pumping and self:Pressure() or 0
    local pc = c.pressure
    B.Dial(170, 222, 108, p, { { 0, pc.low, LOW }, { pc.low, pc.high, RIGHT }, { pc.high, 100, HIGH } }, "DRUCK / PRESSURE", pumping, DIAL_FACE)

    -- Which way it's heading: a small arrow beside the dial
    if pumping then
        local rate = self:GetPressRate()
        if math.abs(rate) > 0.05 and p > 0.5 and p < 99.5 then
            local ax, ay = 312, 222
            draw.NoTexture()
            surface.SetDrawColor(rate > 0 and HIGH or LOW)
            if rate > 0 then B.Poly({ { x = ax - 11, y = ay + 8 }, { x = ax, y = ay - 10 }, { x = ax + 11, y = ay + 8 } })
            else B.Poly({ { x = ax - 11, y = ay - 8 }, { x = ax + 11, y = ay - 8 }, { x = ax, y = ay + 10 } }) end
        end
    end

    -- What to do now, under the dial
    local zone = pumping and self:PressureZone() or nil
    local msg, col
    local blow = c.blowout
    if not off and self:Alarming() then
        local left = math.max(blow.explodeAfter - self:RedTime(), 0)
        local flashOn = math.floor(RealTime() * 4) % 2 == 0
        msg, col = "DANGER! OPEN THE VALVE  ·  " .. RP1942.clock(left), flashOn and Color(255, 70, 50) or Color(255, 200, 120)
    elseif self:GetStalled() then msg, col = "STALLED  -  SWITCH IT BACK ON", Color(255, 130, 110)
    elseif off then msg, col = "SWITCHED OFF", Color(170, 166, 150)
    elseif ready > 0 then msg, col = "TANK FULL  -  FILL BARRELS", B.LIGHT
    elseif not pumping then msg, col = "STARTING...", Color(170, 166, 150)
    elseif zone == "low" then msg, col = self:GetValveOpen() and "PRESSURE LOW - CLOSE THE VALVE" or "PRESSURE LOW - BUILDING UP", Color(150, 180, 255)
    elseif zone == "high" then msg, col = self:GetValveOpen() and "PRESSURE HIGH - BLEEDING OFF" or "PRESSURE HIGH - OPEN THE VALVE", Color(255, 130, 110)
    else
        msg, col = self:GetPressRate() > 0 and "IN THE GREEN  ·  RISING" or "IN THE GREEN  ·  FALLING", Color(140, 220, 140)
    end
    draw.SimpleText(msg, "RP1942_BrassLabel", 170, 356, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Right column: time, the tank, stars
    local rx = 340
    draw.SimpleText("TANK FULL IN", "RP1942_BrassSmall", rx, 102, B.LIGHT)
    B.Counter(rx, 124, pumping and RP1942.clock(self:GetDoneAt() - self:Now()) or "0:00", 40)

    local cans = ready
    if pumping then cans = self:Grade(self:GetGreen() / math.max(self:Now() - self:GetPumpStart(), 1)) end
    draw.SimpleText(ready > 0 and "IN THE TANK" or "TANK SO FAR", "RP1942_BrassSmall", rx, 196, B.LIGHT)
    for i = 1, 3 do B.Lamp(rx + 18 + (i - 1) * 52, 236, 14, i <= cans, OIL) end

    draw.SimpleText("GRADE", "RP1942_BrassSmall", rx, 276, B.LIGHT)
    B.Stars(rx, 298, ready > 0 and self:GetReadyQuality() or cans, 26)
    draw.SimpleText(cans .. (cans == 1 and " BARREL" or " BARRELS"), "RP1942_BrassSmall", rx, 334, B.WHITE)

    -- The valve wheel, the valve's lamp, and FILL
    local open = self:GetValveOpen()
    valveWheel(P, self, 130, 452, 62, pumping and not off)

    B.Lamp(262, 440, 16, pumping and open and not off, Color(240, 200, 90))
    draw.SimpleText("VALVE", "RP1942_BrassSmall", 262, 472, B.LIGHT, TEXT_ALIGN_CENTER)
    draw.SimpleText(open and "OPEN" or "SHUT", "RP1942_BrassSmall", 262, 492, open and B.WHITE or Color(170, 166, 150), TEXT_ALIGN_CENTER)

    B.PushButton(P, "fill", 400, 446, 40, AMBER_BTN, ready > 0 and ("FILL (" .. ready .. ")") or "FILL BARRELS", ready > 0)
    B.Toggle(P, "power", 548, 440, not off, true)

    local hint = "LOOK AT THE WHEEL OR A BUTTON  ·  PRESS E"
    if P.hover == "wheel" then
        hint = (open and "CLOSE THE VALVE  (PRESSURE RISES)" or "OPEN THE VALVE  (PRESSURE FALLS)") .. "  ·  PRESS E"
    elseif P.hover == "fill" then
        hint = "FILL BARRELS  ·  PRESS E"
    elseif P.hover == "power" then
        hint = (off and "SWITCH ON" or "SWITCH OFF  (PAUSES PUMPING)") .. "  ·  PRESS E"
    end
    draw.SimpleText(hint, "RP1942_BrassSmall", w / 2, h - 28, P.hover and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
