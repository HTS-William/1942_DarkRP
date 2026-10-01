include("shared.lua")

--[[---------------------------------------------------------------------------
The factory's control desk, in brass & enamel (like the oven's), laid out
wide rather than tall so it sits on the winch. Where it sits on the prop:
RP1942.PanelSpots.rp1942_factory in sh_production.lua (fine-tune it in game
with the rp1942_panel_* console commands).

    FABRIK  ·  FACTORY LINE
    [ RUN dial ] RUN TIME LEFT / DOWNTIME / THIS RUN    SCRAP HOPPER
                 RUNNING / HALTED lamps                 OUTPUT TRAY
    THE LINE: a conveyor carrying crates (moves while it runs), with its
              three stations; a fault's lamp flashes over its station
    what to do now
    [ the three repairs, under their stations ]  [ COLLECT ]  [ POWER ]
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 960, h = 640 }
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
local STATIONS = { 140, 340, 540 }               -- x of each station, its lamp and its repair button
local DIAL_FACE = Color(150, 140, 118)            -- aged, darker than the oven's: an ivory face glows on dark maps

-- Repaint the panel quickly while the fault lamp flashes
function ENT:PanelFast()
    return self:GetState() == self.STATE_HALTED and not self:GetOff()
end

-- The conveyor: crates ride along while the line runs and stand still otherwise
local SPACING = 96
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
    B.Plaque(w / 2, 22, 520, 46, "FABRIK  ·  FACTORY LINE")

    ------------------------------------------------------------ the run (top left)
    local pct = idle and 0 or (done and 100 or 100 * self:Progress() / c.runTime)
    B.Dial(140, 192, 82, pct, { { 0, pct, GREEN } }, "LAUF  ·  RUN", live, DIAL_FACE)

    local rx = 260
    section("RUN TIME LEFT", rx, 90)
    B.Counter(rx, 110, RP1942.clock(c.runTime - self:Progress()), 40)
    section("DOWNTIME", rx, 168)
    B.Counter(rx, 188, RP1942.clock(done and self:GetDownBase() or self:Downtime()), 40)
    section(done and "THIS RUN" or "THIS RUN (SO FAR)", rx, 244)
    B.Stars(rx, 264, done and self:GetReadyQuality() or (idle and 0 or self:Grade(self:Downtime())), 24)
    B.Lamp(420, 116, 13, live, GREEN)
    draw.SimpleText("RUNNING", "RP1942_BrassSmall", 420, 138, B.WHITE, TEXT_ALIGN_CENTER)
    B.Lamp(420, 192, 13, halted and flash, RED)
    draw.SimpleText("HALTED", "RP1942_BrassSmall", 420, 214, B.WHITE, TEXT_ALIGN_CENTER)

    ------------------------------------------------------------ hopper and tray (top right)
    local hx = 500
    local hopper, scrap = c.hopper or 4, self:GetScrap()
    section("SCRAP HOPPER", hx, 84)
    for i = 1, hopper do
        local x = hx + (i - 1) * 46
        draw.RoundedBox(4, x, 106, 40, 52, WELL)
        if i <= scrap then
            draw.RoundedBox(3, x + 4, 122, 32, 30, STEEL)
            B.Line(x + 8, 131, x + 31, 143, 3, Color(80, 82, 88))
        end
    end
    draw.SimpleText(scrap .. " / " .. hopper .. " LOADS", "RP1942_BrassSmall", hx + hopper * 46 + 8, 132,
        scrap > 0 and B.WHITE or Color(255, 130, 110), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    section("OUTPUT TRAY  ·  " .. c.items .. " GOODS PER LOAD", hx, 182)
    local goods = done and self:ReadyGoods() or {}
    local trayW = w - 40 - hx
    local slotW = math.floor((trayW - (c.items - 1) * 8) / math.max(c.items, 1))
    for i = 1, c.items do
        local x = hx + (i - 1) * (slotW + 8)
        draw.RoundedBox(4, x, 204, slotW, 60, WELL)
        local good = goods[i] and RP1942.Goods[goods[i]]
        if good then
            local name = RP1942.fitText(string.upper(good.name), "RP1942_BrassSmall", slotW - 10)
            draw.SimpleText(name, "RP1942_BrassSmall", x + slotW / 2, 224, B.WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(string.upper(good.rarity or ""), "RP1942_BrassSmall", x + slotW / 2, 246, RARITY_COL[good.rarity] or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(idle and "-" or "?", "RP1942_BrassLabel", x + slotW / 2, 234, Color(90, 92, 104), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    ------------------------------------------------------------ the line (middle)
    section("THE LINE", 40, 296)
    local by = 382                                   -- the belt's top
    draw.RoundedBox(6, 40, by - 8, w - 80, 52, WELL)
    local shift = self:BeltOffset(live)
    for x = 40 - SPACING + shift, w - 40, SPACING do
        if x > 34 and x < w - 74 then
            draw.RoundedBox(2, x, by - 2, 34, 22, CRATE)
            surface.SetDrawColor(110, 80, 40)
            surface.DrawRect(x + 16, by - 2, 2, 22)
        end
    end
    surface.SetDrawColor(STEEL)
    surface.DrawRect(48, by + 22, w - 96, 4)
    for x = 60, w - 60, 36 do B.Circle(x, by + 34, 7, Color(60, 62, 68)) B.Circle(x, by + 34, 3, STEEL) end
    -- the stations, raised a little above the belt so the crates pass under them
    local lift = 14
    for i, f in ipairs(RP1942.FactoryFaults) do
        local cx = STATIONS[i]
        if not cx then break end
        local on = halted and self:GetFault() == f.id
        draw.RoundedBox(4, cx - 34, by - 30 - lift, 68, 30, B.DARK)
        draw.RoundedBox(4, cx - 32, by - 28 - lift, 64, 26, on and Color(90, 30, 26) or Color(52, 56, 70))
        draw.SimpleText(f.lamp, "RP1942_BrassSmall", cx, by - 15 - lift, on and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        B.Lamp(cx, by - 52 - lift, 10, on and flash, RED)
    end
    -- the machine end of the belt, where the goods come out
    draw.RoundedBox(4, w - 230, by - 34 - lift, 170, 34, B.DARK)
    draw.RoundedBox(4, w - 228, by - 32 - lift, 166, 30, Color(52, 56, 70))
    draw.SimpleText("PRESSE  ·  PRESS", "RP1942_BrassSmall", w - 145, by - 17 - lift, B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

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
        msg, col = "RUNNING  ·  WATCH FOR FAULTS", Color(140, 220, 140)
    end
    draw.SimpleText(msg, "RP1942_BrassLabel", w / 2, 452, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    ------------------------------------------------------------ the controls (bottom)
    for i, f in ipairs(RP1942.FactoryFaults) do
        local cx = STATIONS[i]
        if not cx then break end
        B.PushButton(P, "fix:" .. f.id, cx, 512, 26, FIX_BTN, f.button, halted and not off)
    end
    B.PushButton(P, "collect", 730, 512, 26, COLLECT_BTN, "COLLECT", done)
    B.Toggle(P, "power", 880, 506, not off, true)

    local names = { collect = "COLLECT THE GOODS", power = off and "SWITCH ON" or "SWITCH OFF  (PAUSES THE RUN)" }
    for _, f in ipairs(RP1942.FactoryFaults) do names["fix:" .. f.id] = f.button end
    draw.SimpleText(P.hover and ((names[P.hover] or P.hover) .. "  ·  PRESS E") or "LOOK AT A BUTTON  ·  PRESS E",
        "RP1942_BrassSmall", w / 2, h - 22, P.hover and B.WHITE or B.LIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
