include("shared.lua")

ENT.PanelSize  = { w = 600, h = 560 }
ENT.PanelScale = 0.05
ENT.PanelLift  = 14

local ACCENT = Color(82, 140, 70)
local UP, DOWN = Color(110, 190, 100), Color(220, 100, 80)

-- A small up/down triangle (fonts may not have the arrow characters)
local function arrow(x, y, up, color)
    draw.NoTexture()
    surface.SetDrawColor(color)
    local pts = up and { { x = x, y = y + 12 }, { x = x + 7, y = y }, { x = x + 14, y = y + 12 } }
        or { { x = x, y = y }, { x = x + 14, y = y }, { x = x + 7, y = y + 12 } }
    surface.DrawPoly(pts)
    surface.DrawPoly({ pts[3], pts[2], pts[1] })   -- either winding shows
end

-- Rows: every kind of good in my pocket (by quality) first, then 2-star
-- reference rows for goods I don't carry, while there's room on the board
-- (the good in demand first among those)
local function rows()
    local list, carried = {}, {}
    for key, n in pairs(RP1942.MyPocketGoods or {}) do
        local id, q = string.match(key, "^(.-)|(%d)$")
        q = tonumber(q)
        if id and RP1942.Goods[id] and n > 0 then
            list[#list + 1] = { id = id, q = q, n = n }
            carried[id] = true
        end
    end
    for id in pairs(RP1942.Goods) do
        if not carried[id] then list[#list + 1] = { id = id, q = 2, n = 0 } end
    end
    local demand = RP1942.goodInDemand()
    table.sort(list, function(a, b)
        if (a.n > 0) ~= (b.n > 0) then return a.n > 0 end
        if a.n == 0 and (a.id == demand) ~= (b.id == demand) then return a.id == demand end
        if a.id ~= b.id then return RP1942.Goods[a.id].name < RP1942.Goods[b.id].name end
        return a.q > b.q
    end)
    return list
end

local VISIBLE = 4        -- rows shown at once; the rest scroll
local ROW_H, ROW_GAP = 64, 8

-- Scrolling (this player's view only): the arrows on the board, or the
-- mouse wheel while looking at it
function ENT:ScrollBy(n)
    self.scroll = math.Clamp((self.scroll or 0) + n, 0, math.max((self.rowCount or 0) - VISIBLE, 0))
end
function ENT:OnPanelScroll(dir) self:ScrollBy(dir) end
function ENT:OnLocalPress(id)
    if id == "up" then self:ScrollBy(-1) elseif id == "down" then self:ScrollBy(1) end
end

function ENT:PaintPanel(P, w, h)
    local C = RP1942.PanelColors
    local x, y, iw = 28, 72, w - 56
    P:Title("MARKET  ·  TODAY'S PRICES", ACCENT)

    local demand = RP1942.goodInDemand()
    if RP1942.Goods[demand] then
        P:Text("In demand today: " .. string.upper(RP1942.Goods[demand].name)
            .. " (+" .. math.floor(RP1942.Production.market.demandBonus * 100) .. "%)", "RP1942_PanelHead", x, y, UP)
    end
    y = y + 36

    -- Totals for the pocket, over every row (not just the ones on screen)
    local list = rows()
    local total, count, perGood = 0, 0, {}
    for _, r in ipairs(list) do
        if r.n > 0 then
            total = total + RP1942.marketPrice(r.id, r.q) * r.n
            count = count + r.n
            perGood[r.id] = (perGood[r.id] or 0) + r.n
        end
    end

    -- The rows that fit, from the scroll position
    self.rowCount = #list
    self:ScrollBy(0)   -- keep it in range if the list got shorter
    local first = (self.scroll or 0) + 1
    local listW = iw - 52                     -- room for the scroll column on the right
    local top = y
    for i = first, math.min(first + VISIBLE - 1, #list) do
        local r = list[i]
        local good = RP1942.Goods[r.id]
        local price = RP1942.marketPrice(r.id, r.q)
        surface.SetDrawColor(r.n > 0 and Color(40, 37, 33) or Color(28, 26, 24))
        surface.DrawRect(x - 8, y, listW + 8, ROW_H)
        P:Text(good.name, "RP1942_PanelBody", x + 4, y + 8, r.n > 0 and C.text or C.dim)
        P:Stars(x + 4, y + 36, r.q, 18)
        P:Text(DarkRP.formatMoney(price), "RP1942_PanelTitle", x + 280, y + 32, C.text, TEXT_ALIGN_RIGHT)

        local trend = RP1942.marketTrend(r.id)
        local pct = math.floor(math.abs(trend) * 100 + 0.5)
        if pct >= 1 then
            arrow(x + 292, y + 22, trend > 0, trend > 0 and UP or DOWN)
            P:Text(pct .. "%", "RP1942_PanelSmall", x + 310, y + 18, trend > 0 and UP or DOWN)
        end

        P:Button("sell:" .. r.id .. ":" .. r.q, x + listW - 140, y + 10, 132, ROW_H - 20,
            r.n > 0 and ("SELL (" .. r.n .. ")") or "SELL", { enabled = r.n > 0, color = Color(60, 100, 52) })
        y = y + ROW_H + ROW_GAP
    end

    -- Scroll column: up, a track with the thumb, down
    local areaH = VISIBLE * (ROW_H + ROW_GAP) - ROW_GAP
    local sx, sw = x + iw - 40, 40
    local canUp, canDown = first > 1, first + VISIBLE - 1 < #list
    P:Button("local:up", sx, top, sw, 44, "", { enabled = canUp, color = Color(52, 48, 42) })
    arrow(sx + 13, top + 16, true, canUp and C.text or C.faint)
    P:Button("local:down", sx, top + areaH - 44, sw, 44, "", { enabled = canDown, color = Color(52, 48, 42) })
    arrow(sx + 13, top + areaH - 28, false, canDown and C.text or C.faint)
    local trackY, trackH = top + 50, areaH - 100
    surface.SetDrawColor(C.well)
    surface.DrawRect(sx + 16, trackY, 8, trackH)
    if #list > VISIBLE then
        local thumbH = math.max(trackH * VISIBLE / #list, 20)
        local thumbY = trackY + (trackH - thumbH) * ((first - 1) / (#list - VISIBLE))
        surface.SetDrawColor(ACCENT)
        surface.DrawRect(sx + 14, thumbY, 12, thumbH)
    else
        surface.SetDrawColor(ACCENT)
        surface.DrawRect(sx + 14, trackY, 12, trackH)
    end
    y = top + areaH + 14

    -- "Your pocket: 3x Loaf of Bread, 3x Bottle of Wine"
    local summary = {}
    for id, n in SortedPairs(perGood) do summary[#summary + 1] = n .. "x " .. RP1942.Goods[id].name end
    local pocketText = count > 0 and ("Your pocket: " .. table.concat(summary, ", ")) or "Your pocket has no goods. Pocket some, or push them into the mailbox."
    surface.SetFont("RP1942_PanelSmall")
    if surface.GetTextSize(pocketText) > iw then pocketText = "Your pocket: " .. count .. " goods, " .. table.Count(perGood) .. " kinds" end
    P:Text(pocketText, "RP1942_PanelSmall", x, y, C.dim)
    y = y + 30

    -- Everything, after tax (the same rate as wages)
    local rate = RP1942.getTaxRate and RP1942.getTaxRate(RPExtraTeams[LocalPlayer():Team()]) or 0
    local net = total - math.floor(total * rate / 100)
    P:Button("sellall", x, y, iw, 56, count > 0 and ("SELL EVERYTHING  (" .. DarkRP.formatMoney(net) .. " after tax)") or "SELL EVERYTHING IN MY POCKET",
        { enabled = count > 0, color = Color(60, 100, 52) })
    y = y + 66

    P:Text("Scroll with the arrows or the mouse wheel. Goods you carry are listed first.", "RP1942_PanelSmall", x, y, C.faint)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
