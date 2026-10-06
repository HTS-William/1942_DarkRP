include("shared.lua")

--[[---------------------------------------------------------------------------
The rig's panel, in the Wine Barrel's style. It sits on the front of the tank
(RP1942.PanelSpots.rp1942_oil_rig in sh_production.lua; fine-tune it in game
with the rp1942_panel_* console commands).

    OIL RIG
    Pumping · tank full in 3:12                  [progress]
    PRESSURE · RISING                  VALVE SHUT
    [low | just right | too high]  with a marker and which way it's heading
    (DANGER: a strip counting down to the blowout)
    TANK (SO FAR)   ★★☆ 2 barrels · in the green 71% of the time
    [ OPEN VALVE ] [ FILL BARRELS ] [ OFF ]
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 560, h = 600 }
ENT.PanelScale = 0.045
ENT.PanelLift  = 12

local ACCENT = Color(200, 150, 50)
local LOW, RIGHT, HIGH = Color(70, 90, 150), Color(60, 140, 70), Color(190, 50, 40)
local BLUE_TEXT, RED_TEXT, GREEN_TEXT = Color(120, 160, 240), Color(230, 110, 96), Color(140, 220, 140)
local VALVE_BTN, FILL_BTN, POWER_BTN = Color(150, 40, 30), Color(90, 110, 60), Color(52, 48, 42)
local DANGER = Color(255, 70, 50)

-- A line from the foreman's log, picked once per rig by the tank's stars
local NOTES = {
    [1] = { "Thick and gritty. It'll burn, eventually.", "More sludge than oil. Strain it twice.", "The motor pool will complain. Loudly." },
    [2] = { "Decent crude: it'll keep the trucks rolling.", "Fair yield, a little water in it. Nothing a filter can't fix.", "Steady work. Nobody's getting a medal for it." },
    [3] = { "Clean and steady: the motor pool will be pleased.", "Light sweet crude. Berlin will hear about this one.", "Not a drop wasted. The foreman almost smiled." },
}

-- Repaint the panel quickly while the valve turns or the alarm flashes
function ENT:PanelFast()
    return self:WheelTurning() or (not self:GetOff() and self:Alarming())
end

-- "Excellent", "Fine", "Poor"
local function qualityName(q)
    local n = RP1942.qualityName(q)
    return string.upper(string.sub(n, 1, 1)) .. string.sub(n, 2)
end

function ENT:PaintPanel(P, w, h)
    local C = RP1942.PanelColors
    local c = self:Config()
    local x, y, iw = 28, 76, w - 56
    local pumping, ready, off = self:IsPumping(), self:GetReady(), self:GetOff()
    local open = self:GetValveOpen()
    local alarm = pumping and not off and self:Alarming()
    P:Title("OIL RIG", ACCENT)

    ------------------------------------------------------------ status and progress
    if ready > 0 then
        P:Text("Tank full!  Fill the barrels.", "RP1942_PanelBody", x, y, C.gold)
        P:Bar(x, y + 32, iw, 14, 1, ACCENT)
    elseif pumping then
        local left = math.max(self:GetDoneAt() - self:Now(), 0)
        local line
        if self:GetStalled() then line = "Stalled  ·  switch it back on"
        elseif off then line = "Switched off  ·  pumping paused, " .. RP1942.clock(left) .. " left"
        else line = "Pumping  ·  tank full in " .. RP1942.clock(left) end
        P:Text(line, "RP1942_PanelBody", x, y, self:GetStalled() and RED_TEXT or C.dim)
        P:Bar(x, y + 32, iw, 14, 1 - left / c.pumpTime, ACCENT)
    else
        P:Text(off and "Switched off" or "Starting...", "RP1942_PanelBody", x, y, C.dim)
        P:Bar(x, y + 32, iw, 14, 0, ACCENT)
    end
    y = y + 70

    ------------------------------------------------------------ the pressure
    local p = pumping and self:Pressure() or 50
    local pc = c.pressure
    local zone = pumping and self:PressureZone() or nil
    local rate = self:GetPressRate()
    if alarm then
        local flashOn = math.floor(RealTime() * 4) % 2 == 0
        P:Text("DANGER!  OPEN THE VALVE", "RP1942_PanelHead", x, y, flashOn and DANGER or Color(255, 200, 120))
    elseif self:GetStalled() then
        P:Text("STALLED  -  SWITCH IT BACK ON", "RP1942_PanelHead", x, y, RED_TEXT)
    elseif ready > 0 or not pumping or off then
        P:Text("PRESSURE", "RP1942_PanelHead", x, y, C.dim)
    elseif zone == "low" then
        P:Text(open and "LOW  -  CLOSE THE VALVE" or "LOW  ·  BUILDING UP", "RP1942_PanelHead", x, y, BLUE_TEXT)
    elseif zone == "high" then
        P:Text(open and "HIGH  ·  BLEEDING OFF" or "HIGH  -  OPEN THE VALVE", "RP1942_PanelHead", x, y, RED_TEXT)
    else
        P:Text(rate > 0 and "PRESSURE  ·  RISING" or "PRESSURE  ·  FALLING", "RP1942_PanelHead", x, y, GREEN_TEXT)
    end
    local right
    if ready > 0 then right = "RESTING" elseif self:GetStalled() then right = nil elseif off then right = "SWITCHED OFF" elseif pumping then right = open and "VALVE OPEN" or "VALVE SHUT" end
    if right then P:Text(right, "RP1942_PanelHead", x + iw, y, (ready > 0 or off) and C.faint or C.dim, TEXT_ALIGN_RIGHT) end
    local live = pumping and not off and ready == 0
    P:Zones(x, y + 52, iw, 22, p, { { 0, pc.low, LOW, "LOW" }, { pc.low, pc.high, RIGHT, "JUST RIGHT" }, { pc.high, 100, HIGH, "TOO HIGH" } },
        { live = live, arrow = live and (math.abs(rate) > 0.05 and (rate > 0 and 1 or -1)) or nil })
    y = y + 118

    if alarm then
        local blowIn = math.max(c.blowout.explodeAfter - self:RedTime(), 0)
        P:Strip(x, y, iw, 44, "Explodes in " .. RP1942.clock(blowIn) .. " unless the pressure drops", DANGER)
        y = y + 66
    else
        y = y + 8
    end

    ------------------------------------------------------------ the tank
    if ready > 0 then
        local q = self:GetReadyQuality()
        P:Text("IN THE TANK", "RP1942_PanelHead", x, y, C.dim)
        local sw = P:Stars(x, y + 30, q, 26)
        P:Text(qualityName(q) .. "  ·  " .. ready .. (ready == 1 and " barrel" or " barrels"), "RP1942_PanelBody", x + sw + 8, y + 31, C.text)
        y = y + 80
        local notes = NOTES[q] or NOTES[2]
        P:Text("FROM THE FOREMAN'S LOG", "RP1942_PanelHead", x, y, C.dim)
        P:Text("\"" .. notes[(self:EntIndex() % #notes) + 1] .. "\"", "RP1942_PanelSmall", x, y + 30, C.dim)
    elseif pumping then
        local share = self:GetGreen() / math.max(self:Now() - self:GetPumpStart(), 1)
        local cans = self:Grade(share)
        P:Text("TANK (SO FAR)", "RP1942_PanelHead", x, y, C.dim)
        local sw = P:Stars(x, y + 30, cans, 26)
        P:Text(cans .. (cans == 1 and " barrel" or " barrels") .. "  ·  in the green " .. math.Round(math.Clamp(share, 0, 1) * 100) .. "% of the time",
            "RP1942_PanelBody", x + sw + 8, y + 31, C.text)
        y = y + 80
        if not alarm then
            P:Text("Turn the valve before it reaches the red:", "RP1942_PanelBody", x, y, C.dim)
            P:Text("open, it falls; shut, it climbs.", "RP1942_PanelBody", x, y + 28, C.dim)
        end
    end

    ------------------------------------------------------------ buttons
    local by, pw = h - 140, 110
    local bw = (iw - 40 - pw) / 2
    local turning = self:WheelTurning()
    P:Button("wheel", x, by, bw, 58, turning and "TURNING..." or (open and "CLOSE VALVE" or "OPEN VALVE"),
        { enabled = pumping and not off and not turning, color = VALVE_BTN })
    P:Button("fill", x + bw + 20, by, bw, 58, ready > 0 and ("FILL (" .. ready .. ")") or "FILL BARRELS", { enabled = ready > 0, color = FILL_BTN })
    P:Button("power", x + 2 * bw + 40, by, pw, 58, off and "ON" or "OFF", { color = POWER_BTN })

    P:Hint(x, h, {
        wheel = open and "CLOSE VALVE (PRESSURE RISES)" or "OPEN VALVE (PRESSURE FALLS)",
        fill = "FILL BARRELS",
        power = off and "SWITCH ON" or "SWITCH OFF (PAUSES PUMPING)",
    })
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
