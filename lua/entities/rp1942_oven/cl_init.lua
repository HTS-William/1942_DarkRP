include("shared.lua")

--[[---------------------------------------------------------------------------
The oven's control plate, in brass & enamel. It sits on the front of the
oven (RP1942.PanelSpots.rp1942_oven in sh_production.lua; fine-tune it in
game with the rp1942_panel_* console commands).
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 560, h = 600 }
ENT.PanelScale = 0.045   -- only used if the panel floats (no spot)
ENT.PanelNoBackground = true

local ENAMEL = Color(26, 50, 42)
local COLD, RIGHT, HOT = Color(70, 90, 150), Color(60, 140, 70), Color(190, 50, 40)
local AMBER = Color(240, 170, 60)
local RED_BTN, GREEN_BTN = Color(178, 44, 36), Color(50, 120, 60)

function ENT:PaintPanel(P, w, h)
    local B = RP1942.Brass
    local c = self:Config()
    local baking, ready, flour = self:IsBaking(), self:GetReady(), self:GetFlour()

    B.Plate(w, h, ENAMEL)
    B.Plaque(w / 2, 24, 480, 46, "BÄCKEREIOFEN  ·  BREAD OVEN")

    -- The fire: the dial's needle is the heat, its coloured bands the zones
    local heat = baking and self:Heat() or 0
    B.Dial(170, 222, 108, heat, { { 0, c.heat.cold, COLD }, { c.heat.cold, c.heat.hot, RIGHT }, { c.heat.hot, 100, HOT } }, "FEUER / HEAT", baking)

    -- What to do now, under the dial
    local zone = baking and self:HeatZone() or nil
    local msg, col
    if ready > 0 then msg, col = "READY  -  COLLECT IT", B.LIGHT
    elseif not baking then msg, col = flour > 0 and "STARTING..." or "PUSH IN A SACK OF FLOUR", Color(170, 166, 150)
    elseif zone == "cold" then msg, col = "THE FIRE IS DYING - STOKE IT", Color(150, 180, 255)
    elseif zone == "hot" then msg, col = "TOO HOT - LET IT COOL", Color(255, 130, 110)
    else msg, col = "KEEP IT IN THE GREEN", Color(140, 220, 140) end
    draw.SimpleText(msg, "RP1942_BrassLabel", 170, 356, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Right column: time, flour, batch
    local rx = 322
    draw.SimpleText("TIME LEFT", "RP1942_BrassSmall", rx, 102, B.LIGHT)
    B.Counter(rx, 124, baking and RP1942.clock(self:GetDoneAt() - CurTime()) or "0:00", 40)

    draw.SimpleText("FLOUR", "RP1942_BrassSmall", rx, 196, B.LIGHT)
    for i = 1, c.queue do B.Lamp(rx + 18 + (i - 1) * 52, 236, 14, i <= flour, AMBER) end

    if ready > 0 then
        draw.SimpleText("IN THE TRAY", "RP1942_BrassSmall", rx, 276, B.LIGHT)
        B.Stars(rx, 298, self:GetReadyQuality(), 26)
        draw.SimpleText(ready .. (ready == 1 and " LOAF" or " LOAVES"), "RP1942_BrassSmall", rx, 334, B.WHITE)
    else
        draw.SimpleText("BATCH", "RP1942_BrassSmall", rx, 276, B.LIGHT)
        local loaves = 0
        if baking then loaves = self:Grade(self:GetGreen() / math.max(CurTime() - self:GetBakeStart(), 1)) end
        B.Stars(rx, 298, loaves, 26)
        draw.SimpleText(baking and (loaves .. (loaves == 1 and " LOAF" or " LOAVES") .. " SO FAR") or "", "RP1942_BrassSmall", rx, 334, B.WHITE)
    end

    -- Push-buttons
    B.PushButton(P, "stoke", 170, 446, 44, RED_BTN, "STOKE FIRE", baking)
    B.PushButton(P, "collect", 400, 446, 44, GREEN_BTN, ready > 0 and ("COLLECT (" .. ready .. ")") or "COLLECT", ready > 0)

    local names = { stoke = "STOKE FIRE", collect = "COLLECT BREAD" }
    draw.SimpleText(P.hover and (names[P.hover] .. "  ·  PRESS E") or "LOOK AT A BUTTON  ·  PRESS E",
        "RP1942_BrassSmall", w / 2, h - 28, P.hover and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
