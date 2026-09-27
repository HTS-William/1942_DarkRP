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

    -- One row per good (and quality): name, stars, price, trend, SELL
    local total, count, perGood = 0, 0, {}
    local list = rows()
    for i, r in ipairs(list) do
        if i > 5 then break end
        local good = RP1942.Goods[r.id]
        local price = RP1942.marketPrice(r.id, r.q)
        local rh = 64
        surface.SetDrawColor(r.n > 0 and Color(40, 37, 33) or Color(28, 26, 24))
        surface.DrawRect(x - 8, y, iw + 16, rh)
        P:Text(good.name, "RP1942_PanelBody", x + 4, y + 8, r.n > 0 and C.text or C.dim)
        P:Stars(x + 4, y + 36, r.q, 18)
        P:Text(DarkRP.formatMoney(price), "RP1942_PanelTitle", x + 300, y + 32, C.text, TEXT_ALIGN_RIGHT)

        local trend = RP1942.marketTrend(r.id)
        local pct = math.floor(math.abs(trend) * 100 + 0.5)
        if pct >= 1 then
            arrow(x + 316, y + 22, trend > 0, trend > 0 and UP or DOWN)
            P:Text(pct .. "%", "RP1942_PanelSmall", x + 336, y + 18, trend > 0 and UP or DOWN)
        end

        P:Button("sell:" .. r.id .. ":" .. r.q, x + iw - 150, y + 10, 150, rh - 20,
            r.n > 0 and ("SELL (" .. r.n .. ")") or "SELL", { enabled = r.n > 0, color = Color(60, 100, 52) })

        if r.n > 0 then
            total = total + price * r.n
            count = count + r.n
            perGood[r.id] = (perGood[r.id] or 0) + r.n
        end
        y = y + rh + 8
    end

    -- "Your pocket: 3x Loaf of Bread, 3x Bottle of Wine"
    local summary = {}
    for id, n in SortedPairs(perGood) do summary[#summary + 1] = n .. "x " .. RP1942.Goods[id].name end
    y = y + 6
    P:Text(count > 0 and ("Your pocket: " .. table.concat(summary, ", ")) or "Your pocket has no goods. Pocket some, or push them into the crate.",
        "RP1942_PanelBody", x, y, C.dim)
    y = y + 40

    -- Everything, after tax (the same rate as wages)
    local rate = RP1942.getTaxRate and RP1942.getTaxRate(RPExtraTeams[LocalPlayer():Team()]) or 0
    local net = total - math.floor(total * rate / 100)
    P:Button("sellall", x, y, iw, 60, count > 0 and ("SELL EVERYTHING IN MY POCKET  (" .. DarkRP.formatMoney(net) .. " after tax)") or "SELL EVERYTHING IN MY POCKET",
        { enabled = count > 0, color = Color(60, 100, 52) })
    y = y + 76

    P:Text("Prices follow the economy and quality; demand changes every hour. Goods you carry are listed first.", "RP1942_PanelSmall", x, y, C.faint)
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
