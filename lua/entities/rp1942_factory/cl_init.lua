include("shared.lua")

--[[---------------------------------------------------------------------------
The factory's control plate, in brass & enamel (like the oven's). Where it
sits on the prop: RP1942.PanelSpots.rp1942_factory in sh_production.lua
(fine-tune it in game with the rp1942_panel_* console commands).
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 640, h = 770 }
ENT.PanelScale = 0.045
ENT.PanelLift  = 12
ENT.PanelNoBackground = true

local ENAMEL = Color(40, 44, 58)
local GREEN, RED, AMBER = Color(70, 170, 80), Color(210, 50, 40), Color(240, 170, 60)
local FIX_BTN, COLLECT_BTN = Color(196, 96, 36), Color(50, 120, 60)
local RARITY_COL = {
    common = Color(200, 196, 180), uncommon = Color(120, 200, 120),
    rare = Color(110, 160, 255), ["very rare"] = Color(230, 150, 255),
}

function ENT:PaintPanel(P, w, h)
    local B = RP1942.Brass
    local c = self:Config()
    local state = self:GetState()
    local running, halted, done = state == self.STATE_RUNNING, state == self.STATE_HALTED, state == self.STATE_DONE
    local off = self:GetOff()
    local flash = math.floor(RealTime() * 3) % 2 == 0

    B.Plate(w, h, ENAMEL)
    B.Plaque(w / 2, 24, 480, 46, "FABRIK  ·  FACTORY LINE")

    -- Left column: run time left, downtime
    local lx = 48
    draw.SimpleText("RUN TIME LEFT", "RP1942_BrassSmall", lx, 96, B.LIGHT)
    B.Counter(lx, 118, RP1942.clock(c.runTime - self:Progress()), 40)
    draw.SimpleText("DOWNTIME", "RP1942_BrassSmall", lx, 184, B.LIGHT)
    B.Counter(lx, 206, RP1942.clock(done and self:GetDownBase() or self:Downtime()), 40)

    -- Right column: line lamps, this run's stars
    local rx = 360
    draw.SimpleText("LINE", "RP1942_BrassSmall", rx, 96, B.LIGHT)
    B.Lamp(rx + 22, 140, 16, running and not off, GREEN)
    draw.SimpleText("RUNNING", "RP1942_BrassSmall", rx + 22, 172, B.WHITE, TEXT_ALIGN_CENTER)
    B.Lamp(rx + 132, 140, 16, halted and flash, RED)
    draw.SimpleText("HALTED", "RP1942_BrassSmall", rx + 132, 172, B.WHITE, TEXT_ALIGN_CENTER)

    local stars = done and self:GetReadyQuality() or self:Grade(self:Downtime())
    draw.SimpleText(done and "THIS RUN" or "THIS RUN (SO FAR)", "RP1942_BrassSmall", rx, 200, B.LIGHT)
    B.Stars(rx, 222, stars, 26)

    -- What to do now
    local msg, col
    if done then msg, col = "RUN COMPLETE  -  COLLECT THE GOODS", B.LIGHT
    elseif off then msg, col = halted and "SWITCHED OFF  -  SWITCH ON TO REPAIR" or "SWITCHED OFF  -  RUN PAUSED", Color(170, 166, 150)
    elseif halted then
        local f
        for _, x in ipairs(RP1942.FactoryFaults) do if x.id == self:GetFault() then f = x end end
        msg, col = "HALTED: " .. (f and f.lamp or "?") .. " FAULT  -  " .. (f and f.button or "REPAIR IT"), Color(255, 130, 110)
    else
        local left = math.max((c.halts or 0) - self:GetHalts(), 0)
        msg, col = "RUNNING  ·  " .. (left > 0 and (left .. (left == 1 and " HALT" or " HALTS") .. " TO COME") or "NO MORE HALTS THIS RUN"), Color(140, 220, 140)
    end
    draw.SimpleText(msg, "RP1942_BrassLabel", w / 2, 290, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Faults: a lamp and a repair button each
    local xs = { 130, 320, 510 }
    for i, f in ipairs(RP1942.FactoryFaults) do
        local cx = xs[i]
        if not cx then break end
        local on = halted and self:GetFault() == f.id
        B.Lamp(cx, 328, 11, on and flash, RED)
        draw.SimpleText(f.lamp, "RP1942_BrassSmall", cx, 350, on and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER)
        B.PushButton(P, "fix:" .. f.id, cx, 418, 34, FIX_BTN, f.button, halted and not off)
    end

    -- Output and COLLECT
    if done then
        -- One line per good: its name, then its rarity in the rarity's colour
        local goods = self:ReadyGoods()
        for i, id in ipairs(goods) do
            if i > 3 then break end
            local good = RP1942.Goods[id]
            local name, rarity = string.upper(good.name) .. "  ", string.upper(good.rarity or "")
            surface.SetFont("RP1942_BrassLabel")
            local nw = surface.GetTextSize(name)
            surface.SetFont("RP1942_BrassSmall")
            local rw = surface.GetTextSize(rarity)
            local x, y = w / 2 - (nw + rw) / 2, 534 + (i - 1) * 26
            draw.SimpleText(name, "RP1942_BrassLabel", x, y, B.WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(rarity, "RP1942_BrassSmall", x + nw, y, RARITY_COL[good.rarity] or B.LIGHT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    else
        draw.SimpleText("OUTPUT:  " .. c.items .. " GOODS AT THE END OF THE RUN", "RP1942_BrassLabel", w / 2, 544, Color(170, 166, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    B.PushButton(P, "collect", w / 2, 630, 30, COLLECT_BTN, "COLLECT", done)
    B.Toggle(P, "power", 540, 622, not off, true)

    local names = { collect = "COLLECT THE GOODS", power = off and "SWITCH ON" or "SWITCH OFF  (PAUSES THE RUN)" }
    for _, f in ipairs(RP1942.FactoryFaults) do names["fix:" .. f.id] = f.button end
    draw.SimpleText(P.hover and ((names[P.hover] or P.hover) .. "  ·  PRESS E") or "LOOK AT A BUTTON  ·  PRESS E",
        "RP1942_BrassSmall", w / 2, h - 24, P.hover and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
