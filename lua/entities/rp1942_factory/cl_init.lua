include("shared.lua")

--[[---------------------------------------------------------------------------
The factory's control plate, in brass & enamel (like the oven's). Where it
sits on the prop: RP1942.PanelSpots.rp1942_factory in sh_production.lua
(fine-tune it in game with the rp1942_panel_* console commands).

    FABRIK  ·  FACTORY LINE
    [ RUN dial ]   RUN TIME LEFT / DOWNTIME / THIS RUN (stars)
    THE LINE: a conveyor carrying crates (moves while it runs), with the
              three stations above it. A fault's lamp flashes; press the
              matching repair button underneath.
    SCRAP HOPPER (one bin per load)        OUTPUT TRAY (one slot per good)
    what to do now
    [ COLLECT ]                            [ POWER lever ]
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 640, h = 910 }
ENT.PanelScale = 0.045
ENT.PanelLift  = 12
ENT.PanelNoBackground = true

local ENAMEL = Color(40, 44, 58)
local WELL   = Color(24, 26, 34)                  -- the recessed parts (belt bed, bins, tray)
local GREEN, RED, AMBER = Color(70, 170, 80), Color(210, 50, 40), Color(240, 170, 60)
local STEEL, CRATE = Color(120, 124, 130), Color(150, 112, 62)
local FIX_BTN, COLLECT_BTN = Color(196, 96, 36), Color(50, 120, 60)
local DIM = Color(170, 166, 150)
local RARITY_COL = {
    common = Color(200, 196, 180), uncommon = Color(120, 200, 120),
    rare = Color(110, 160, 255), ["very rare"] = Color(230, 150, 255),
}

-- Repaint the panel quickly while the fault lamp flashes
function ENT:PanelFast()
    return self:GetState() == self.STATE_HALTED and not self:GetOff()
end

-- The conveyor: crates ride along while the line runs and stand still otherwise
local SPACING = 90
function ENT:BeltOffset(moving)
    local now = RealTime()
    local last = self._beltT or now
    self._beltT = now
    if moving then self._belt = ((self._belt or 0) + math.min(now - last, 0.5) * 40) % SPACING end
    return self._belt or 0
end

local function section(text, x, y) draw.SimpleText(text, "RP1942_BrassSmall", x, y, RP1942.Brass.LIGHT) end

function ENT:PaintPanel(P, w, h)
    local B = RP1942.Brass
    local c = self:Config()
    local state = self:GetState()
    local running, halted, done = state == self.STATE_RUNNING, state == self.STATE_HALTED, state == self.STATE_DONE
    local idle = state == self.STATE_IDLE
    local off = self:GetOff()
    local live = running and not off
    local flash = math.floor(RealTime() * 3) % 2 == 0

    B.Plate(w, h, ENAMEL)
    B.Plaque(w / 2, 24, 480, 46, "FABRIK  ·  FACTORY LINE")

    ------------------------------------------------------------ the run
    local pct = idle and 0 or (done and 100 or 100 * self:Progress() / c.runTime)
    B.Dial(160, 200, 92, pct, { { 0, pct, GREEN } }, "LAUF  ·  RUN", live)

    local rx = 300
    section("RUN TIME LEFT", rx, 96)
    B.Counter(rx, 118, RP1942.clock(c.runTime - self:Progress()), 40)
    section("DOWNTIME", rx, 178)
    B.Counter(rx, 200, RP1942.clock(done and self:GetDownBase() or self:Downtime()), 40)
    section(done and "THIS RUN" or "THIS RUN (SO FAR)", rx, 260)
    B.Stars(rx, 282, done and self:GetReadyQuality() or (idle and 0 or self:Grade(self:Downtime())), 26)
    -- the line's own lamps, beside the stars
    B.Lamp(530, 112, 13, live, GREEN)
    draw.SimpleText("RUNNING", "RP1942_BrassSmall", 530, 136, B.WHITE, TEXT_ALIGN_CENTER)
    B.Lamp(530, 186, 13, halted and flash, RED)
    draw.SimpleText("HALTED", "RP1942_BrassSmall", 530, 210, B.WHITE, TEXT_ALIGN_CENTER)

    ------------------------------------------------------------ the line
    section("THE LINE", 48, 318)
    local stations = { 130, 320, 510 }
    local by = 400                                   -- the belt's top
    draw.RoundedBox(6, 40, by - 8, w - 80, 52, WELL)
    -- crates riding the belt
    local shift = self:BeltOffset(live)
    for x = 40 - SPACING + shift, w - 40, SPACING do
        if x > 34 and x < w - 74 then
            draw.RoundedBox(2, x, by - 2, 34, 22, CRATE)
            surface.SetDrawColor(110, 80, 40)
            surface.DrawRect(x + 16, by - 2, 2, 22)
        end
    end
    -- the belt and its rollers
    surface.SetDrawColor(STEEL)
    surface.DrawRect(48, by + 22, w - 96, 4)
    for x = 60, w - 60, 36 do B.Circle(x, by + 34, 7, Color(60, 62, 68)) B.Circle(x, by + 34, 3, STEEL) end
    -- stations: a housing over the belt, its fault lamp and name
    for i, f in ipairs(RP1942.FactoryFaults) do
        local cx = stations[i]
        if not cx then break end
        local on = halted and self:GetFault() == f.id
        draw.RoundedBox(4, cx - 34, by - 30, 68, 30, B.DARK)
        draw.RoundedBox(4, cx - 32, by - 28, 64, 26, on and Color(90, 30, 26) or Color(52, 56, 70))
        draw.SimpleText(f.lamp, "RP1942_BrassSmall", cx, by - 15, on and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        B.Lamp(cx, by - 52, 10, on and flash, RED)
        B.PushButton(P, "fix:" .. f.id, cx, 494, 30, FIX_BTN, f.button, halted and not off)
    end

    ------------------------------------------------------------ hopper and tray
    local hopper, scrap = c.hopper or 4, self:GetScrap()
    section("SCRAP HOPPER", 48, 588)
    for i = 1, hopper do
        local x = 48 + (i - 1) * 42
        draw.RoundedBox(4, x, 612, 36, 56, WELL)
        if i <= scrap then
            draw.RoundedBox(3, x + 4, 630, 28, 32, STEEL)
            B.Line(x + 7, 640, x + 28, 652, 3, Color(80, 82, 88))
        end
    end
    draw.SimpleText(scrap .. " / " .. hopper .. " LOADS", "RP1942_BrassSmall", 48, 678, scrap > 0 and B.WHITE or Color(255, 130, 110))

    section("OUTPUT TRAY", 236, 588)
    local goods = done and self:ReadyGoods() or {}
    local slotW = math.floor((w - 48 - 236 - (c.items - 1) * 8) / math.max(c.items, 1))
    for i = 1, c.items do
        local x = 236 + (i - 1) * (slotW + 8)
        draw.RoundedBox(4, x, 612, slotW, 56, WELL)
        local good = goods[i] and RP1942.Goods[goods[i]]
        if good then
            local name = RP1942.fitText(string.upper(good.name), "RP1942_BrassSmall", slotW - 10)
            draw.SimpleText(name, "RP1942_BrassSmall", x + slotW / 2, 630, B.WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(string.upper(good.rarity or ""), "RP1942_BrassSmall", x + slotW / 2, 652, RARITY_COL[good.rarity] or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(idle and "-" or "?", "RP1942_BrassLabel", x + slotW / 2, 640, Color(90, 92, 104), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    draw.SimpleText(c.items .. " GOODS PER LOAD", "RP1942_BrassSmall", 236, 678, DIM)

    ------------------------------------------------------------ what to do now
    local msg, col
    if done then msg, col = "RUN COMPLETE  -  COLLECT THE GOODS", B.LIGHT
    elseif idle then msg, col = "IDLE  -  NO SCRAP  ·  PUSH SCRAP METAL INTO THE LINE", Color(255, 130, 110)
    elseif off then msg, col = halted and "SWITCHED OFF  -  SWITCH ON TO REPAIR" or "SWITCHED OFF  -  RUN PAUSED", DIM
    elseif halted then
        local f
        for _, x in ipairs(RP1942.FactoryFaults) do if x.id == self:GetFault() then f = x end end
        msg, col = "HALTED: " .. (f and f.lamp or "?") .. " FAULT  -  " .. (f and f.button or "REPAIR IT"), Color(255, 130, 110)
    else
        local left = math.max((c.halts or 0) - self:GetHalts(), 0)
        msg, col = "RUNNING  ·  " .. (left > 0 and (left .. (left == 1 and " HALT" or " HALTS") .. " TO COME") or "NO MORE HALTS THIS RUN"), Color(140, 220, 140)
    end
    draw.SimpleText(msg, "RP1942_BrassLabel", w / 2, 718, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    B.PushButton(P, "collect", 200, 782, 30, COLLECT_BTN, "COLLECT", done)
    B.Toggle(P, "power", 470, 772, not off, true)

    local names = { collect = "COLLECT THE GOODS", power = off and "SWITCH ON" or "SWITCH OFF  (PAUSES THE RUN)" }
    for _, f in ipairs(RP1942.FactoryFaults) do names["fix:" .. f.id] = f.button end
    draw.SimpleText(P.hover and ((names[P.hover] or P.hover) .. "  ·  PRESS E") or "LOOK AT A BUTTON  ·  PRESS E",
        "RP1942_BrassSmall", w / 2, h - 22, P.hover and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
