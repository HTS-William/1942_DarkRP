include("shared.lua")

--[[---------------------------------------------------------------------------
The derrick's control plate, in brass & enamel (like the oven's). It floats
above the prop until the real prop is in; then mount it with the
rp1942_panel_* console commands and paste the printed line into
RP1942.PanelSpots in sh_production.lua.
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 620, h = 600 }
ENT.PanelScale = 0.045
ENT.PanelLift  = 12
ENT.PanelNoBackground = true

local ENAMEL = Color(34, 34, 36)
local LOW, RIGHT, HIGH = Color(70, 90, 150), Color(60, 140, 70), Color(190, 50, 40)
local OIL = Color(200, 150, 50)
local BLUE_BTN, RED_BTN, AMBER_BTN = Color(52, 82, 150), Color(178, 44, 36), Color(170, 120, 30)

function ENT:PaintPanel(P, w, h)
    local B = RP1942.Brass
    local c = self:Config()
    local pumping, ready = self:IsPumping(), self:GetReady()

    B.Plate(w, h, ENAMEL)
    B.Plaque(w / 2, 24, 480, 46, "BOHRTURM  ·  OIL DERRICK")

    -- The well: the needle is the pressure, the bands its zones
    local p = pumping and self:Pressure() or 0
    local pc = c.pressure
    B.Dial(170, 222, 108, p, { { 0, pc.low, LOW }, { pc.low, pc.high, RIGHT }, { pc.high, 100, HIGH } }, "DRUCK / PRESSURE", pumping)

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
    if ready > 0 then msg, col = "TANK FULL  -  FILL CANISTERS", B.LIGHT
    elseif not pumping then msg, col = "STARTING...", Color(170, 166, 150)
    elseif zone == "low" then msg, col = "PRESSURE LOW - CLOSE THE VALVE", Color(150, 180, 255)
    elseif zone == "high" then msg, col = "PRESSURE HIGH - OPEN THE VALVE", Color(255, 130, 110)
    else
        msg, col = self:GetPressRate() > 0 and "IN THE GREEN  ·  RISING" or "IN THE GREEN  ·  FALLING", Color(140, 220, 140)
    end
    draw.SimpleText(msg, "RP1942_BrassLabel", 170, 356, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Right column: time, the tank, stars
    local rx = 340
    draw.SimpleText("TANK FULL IN", "RP1942_BrassSmall", rx, 102, B.LIGHT)
    B.Counter(rx, 124, pumping and RP1942.clock(self:GetDoneAt() - CurTime()) or "0:00", 40)

    local cans = ready
    if pumping then cans = self:Grade(self:GetGreen() / math.max(CurTime() - self:GetPumpStart(), 1)) end
    draw.SimpleText(ready > 0 and "IN THE TANK" or "TANK SO FAR", "RP1942_BrassSmall", rx, 196, B.LIGHT)
    for i = 1, 3 do B.Lamp(rx + 18 + (i - 1) * 52, 236, 14, i <= cans, OIL) end

    draw.SimpleText("GRADE", "RP1942_BrassSmall", rx, 276, B.LIGHT)
    B.Stars(rx, 298, ready > 0 and self:GetReadyQuality() or cans, 26)
    draw.SimpleText(cans .. (cans == 1 and " CANISTER" or " CANISTERS"), "RP1942_BrassSmall", rx, 334, B.WHITE)

    -- Push-buttons
    B.PushButton(P, "open", 115, 446, 40, BLUE_BTN, "OPEN VALVE", pumping)
    B.PushButton(P, "close", 310, 446, 40, RED_BTN, "CLOSE VALVE", pumping)
    B.PushButton(P, "fill", 505, 446, 40, AMBER_BTN, ready > 0 and ("FILL (" .. ready .. ")") or "FILL CANISTERS", ready > 0)

    local names = { open = "OPEN VALVE  (PRESSURE DOWN)", close = "CLOSE VALVE  (PRESSURE UP)", fill = "FILL CANISTERS" }
    draw.SimpleText(P.hover and (names[P.hover] .. "  ·  PRESS E") or "LOOK AT A BUTTON  ·  PRESS E",
        "RP1942_BrassSmall", w / 2, h - 28, P.hover and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
