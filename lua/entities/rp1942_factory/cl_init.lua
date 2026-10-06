include("shared.lua")

--[[---------------------------------------------------------------------------
The factory line's panel, in the Wine Barrel's style. It sits on the side of
the winch (RP1942.PanelSpots.rp1942_factory in sh_production.lua; fine-tune
it in game with the rp1942_panel_* console commands).

    FACTORY LINE
    Running · 2:10 left                         [progress]
    LINE HALTED: BOILER FAULT   [BELT][BOILER][FUSE]   down 0:12
      (or the output tray, once the run is done)
    THIS RUN (SO FAR)   ★★☆ downtime 0:24 · 2 faults
    SCRAP HOPPER        [loads waiting]
    [ RETHREAD BELT ] [ VENT BOILER ] [ REPLACE FUSE ]
    [ COLLECT                         ] [ OFF ]
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 560, h = 600 }
ENT.PanelScale = 0.045

local ACCENT = Color(86, 128, 170)
local RED_TEXT, GREEN_TEXT = Color(230, 110, 96), Color(140, 220, 140)
local STEEL = Color(120, 124, 130)
local FIX_BTN, COLLECT_BTN, POWER_BTN = Color(196, 96, 36), Color(90, 110, 60), Color(52, 48, 42)
local RARITY_COL = {
    common = Color(200, 196, 180), uncommon = Color(120, 200, 120),
    rare = Color(110, 160, 255), ["very rare"] = Color(230, 150, 255),
}

-- Repaint the panel quickly while the fault lamp flashes
function ENT:PanelFast()
    return self:GetState() == self.STATE_HALTED and not self:GetOff()
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
    local state = self:GetState()
    local running, halted, done, idle = state == self.STATE_RUNNING, state == self.STATE_HALTED, state == self.STATE_DONE, state == self.STATE_IDLE
    local off = self:GetOff()
    local hopper, scrap = c.hopper or 4, self:GetScrap()
    P:Title("FACTORY LINE", ACCENT)

    ------------------------------------------------------------ status and progress
    local left = c.runTime - self:Progress()
    if done then
        P:Text("Run complete!  Collect the goods.", "RP1942_PanelBody", x, y, C.gold)
    elseif idle then
        P:Text("Idle  ·  " .. c.items .. " goods per load, " .. RP1942.clock(c.runTime) .. " a run", "RP1942_PanelBody", x, y, C.dim)
    elseif off then
        P:Text("Switched off  ·  run paused, " .. RP1942.clock(left) .. " left", "RP1942_PanelBody", x, y, C.dim)
    elseif halted then
        P:Text("Halted  ·  " .. RP1942.clock(left) .. " of running left", "RP1942_PanelBody", x, y, C.dim)
    else
        P:Text("Running  ·  " .. RP1942.clock(left) .. " left", "RP1942_PanelBody", x, y, C.dim)
    end
    P:Bar(x, y + 32, iw, 14, done and 1 or (idle and 0 or self:Progress() / c.runTime), ACCENT)
    y = y + 66

    if idle then
        ------------------------------------------------------------ waiting for scrap
        P:Text("SCRAP HOPPER", "RP1942_PanelHead", x, y + 4, C.dim)
        local sw = P:Slots(x, y + 34, scrap, hopper, STEEL)
        P:Text(scrap == 0 and "Empty" or (scrap .. " / " .. hopper .. " loads"), "RP1942_PanelBody", x + sw + 8, y + 40, scrap == 0 and RED_TEXT or C.text)
        y = y + 94
        P:Text("HOW IT WORKS", "RP1942_PanelHead", x, y, C.dim)
        P:Text("Each load of scrap metal makes one run. Now and", "RP1942_PanelBody", x, y + 30, C.dim)
        P:Text("then the line halts with a fault: press the right", "RP1942_PanelBody", x, y + 58, C.dim)
        P:Text("repair fast. Less downtime, better (and rarer) goods.", "RP1942_PanelBody", x, y + 86, C.dim)
        y = y + 150
        if not off then P:Text("PUSH SCRAP METAL INTO THE LINE", "RP1942_PanelHead", x, y, C.gold) end
    else
        if done then
            ------------------------------------------------------------ the output tray
            P:Text("OUTPUT TRAY", "RP1942_PanelHead", x, y, C.dim)
            local goods = self:ReadyGoods()
            local n = math.max(c.items, 1)
            local sw = (iw - (n - 1) * 10) / n
            for i = 1, n do
                local bx = x + (i - 1) * (sw + 10)
                draw.RoundedBox(4, bx, y + 30, sw, 66, C.well)
                local good = goods[i] and RP1942.Goods[goods[i]]
                if good then
                    local name = RP1942.fitText and RP1942.fitText(string.upper(good.name), "RP1942_PanelButtonSmall", sw - 10) or string.upper(good.name)
                    draw.SimpleText(name, "RP1942_PanelButtonSmall", bx + sw / 2, y + 52, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(string.upper(good.rarity or ""), "RP1942_PanelSmall", bx + sw / 2, y + 78, RARITY_COL[good.rarity] or C.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText("-", "RP1942_PanelHead", bx + sw / 2, y + 63, C.faint, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            y = y + 122
        else
            ------------------------------------------------------------ the line's lamps
            local fault
            for _, f in ipairs(RP1942.FactoryFaults) do if f.id == self:GetFault() then fault = f end end
            if off then
                P:Text(halted and "SWITCHED OFF  -  SWITCH ON TO REPAIR" or "SWITCHED OFF  -  RUN PAUSED", "RP1942_PanelHead", x, y, C.dim)
            elseif halted then
                P:Text("LINE HALTED: " .. (fault and fault.lamp or "?") .. " FAULT", "RP1942_PanelHead", x, y, RED_TEXT)
            else
                P:Text("RUNNING  ·  WATCH FOR FAULTS", "RP1942_PanelHead", x, y, GREEN_TEXT)
            end
            local flash = math.floor(RealTime() * 3) % 2 == 0
            local cx = x
            for _, f in ipairs(RP1942.FactoryFaults) do
                local lit = halted and fault == f and (off or flash)
                cx = cx + P:Chip(cx, y + 32, f.lamp, RED_TEXT, lit) + 10
            end
            if halted then
                P:Text("down " .. RP1942.clock(self:Now() - self:GetHaltedAt()), "RP1942_PanelBody", x + iw, y + 36, RED_TEXT, TEXT_ALIGN_RIGHT)
            end
            y = y + 88
        end

        ------------------------------------------------------------ the run's grade
        local down = done and self:GetDownBase() or self:Downtime()
        local stars = done and self:GetReadyQuality() or self:Grade(down)
        local faults = self:GetHalts()
        P:Text(done and "THIS RUN" or "THIS RUN (SO FAR)", "RP1942_PanelHead", x, y, C.dim)
        local sw = P:Stars(x, y + 30, stars, 26)
        P:Text((done and qualityName(stars) or (stars .. (stars == 1 and " star" or " stars"))) .. "  ·  downtime " .. RP1942.clock(down)
            .. "  ·  " .. faults .. (faults == 1 and " fault" or " faults"), "RP1942_PanelBody", x + sw + 8, y + 31, C.text)
        y = y + 78

        ------------------------------------------------------------ the hopper
        P:Text("SCRAP HOPPER", "RP1942_PanelHead", x, y, C.dim)
        local hw = P:Slots(x, y + 30, scrap, hopper, STEEL)
        local note
        if done then note = scrap > 0 and "Next run starts once collected" or "Empty: push in more scrap"
        else note = scrap == 0 and "No more loads waiting" or (scrap .. (scrap == 1 and " more load waiting" or " more loads waiting")) end
        P:Text(note, "RP1942_PanelBody", x + hw + 8, y + 36, (done and scrap == 0) and RED_TEXT or C.text)
    end

    ------------------------------------------------------------ buttons
    local fy = h - 170
    local n = #RP1942.FactoryFaults
    local fw = (iw - (n - 1) * 20) / n
    local names = { collect = "COLLECT THE GOODS", power = off and "SWITCH ON" or "SWITCH OFF (PAUSES THE RUN)" }
    for i, f in ipairs(RP1942.FactoryFaults) do
        P:Button("fix:" .. f.id, x + (i - 1) * (fw + 20), fy, fw, 50, f.button, { enabled = halted and not off, color = FIX_BTN, font = "RP1942_PanelButtonSmall" })
        names["fix:" .. f.id] = f.button
    end
    local pw = 110
    local items = done and #self:ReadyGoods() or 0
    P:Button("collect", x, fy + 66, iw - 20 - pw, 46, items > 0 and ("COLLECT (" .. items .. ")") or "COLLECT", { enabled = done, color = COLLECT_BTN })
    P:Button("power", x + iw - pw, fy + 66, pw, 46, off and "ON" or "OFF", { color = POWER_BTN })

    P:Hint(x, h, names)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
