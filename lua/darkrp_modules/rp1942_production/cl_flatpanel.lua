--[[---------------------------------------------------------------------------
1942 DarkRP - flat machine panels (client)

The look of the F4 menu and the HUD, for the panels on the producers'
machines: dark cards, a title bar with the red underline, gold headings,
plain bars and the F4's red buttons. No brass, no dials. The colours come
from RP1942.col (rp1942_core/cl_theme.lua), so they follow the F4 palette.

    local F = RP1942.Flat
    F.Frame(P, w, h, title, sub, status, statusCol, alert)   background + title bar
    F.Label(text, x, y, alignX)                              a small heading
    F.Chip(x, y, text, col)  -> width                        a small coloured tag
    F.Zones(x, y, w, h, value, zones, opts)                  a bar split into zones, with a marker
    F.Progress(x, y, w, h, frac, col)                        a plain progress bar
    F.Banner(x, y, w, h, text, col, flash)                   "what to do now"
    F.Button(P, id, x, y, w, h, label, enabled, opts)        an F4 button (look + E)
    F.Hint(P, w, h, names)                                   the bottom line: what E does
    F.Arrow(x, y, size, up, col)                             a small triangle

All positions are canvas pixels. Panels using it set ENT.PanelNoBackground
(F.Frame draws the background) and call F.Frame first.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
local F = {}
RP1942.Flat = F

local function font(name, size, weight)
    surface.CreateFont(name, { font = "Roboto", size = size, weight = weight, extended = true })
end
font("RP1942_FlatTitle",  34, 800)
font("RP1942_FlatSub",    18, 500)
font("RP1942_FlatLabel",  17, 800)
font("RP1942_FlatBody",   24, 700)
font("RP1942_FlatBig",    48, 800)
font("RP1942_FlatValue",  28, 800)
font("RP1942_FlatButton", 22, 800)
font("RP1942_FlatSmall",  18, 600)

local function C(k) return RP1942.col(k) end
F.C = C

F.TITLE_H = 64

local function dim(c, k, a)
    return Color(c.r * k, c.g * k, c.b * k, a or 255)
end
F.dim = dim

function F.Frame(P, w, h, title, sub, status, statusCol, alert)
    surface.SetDrawColor(C("bg"))
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(alert and dim(C("bad"), 0.45) or C("titleBar"))
    surface.DrawRect(0, 0, w, F.TITLE_H)
    surface.SetDrawColor(alert and C("bad") or C("tabActive"))
    surface.DrawRect(0, F.TITLE_H - 4, w, 4)
    draw.SimpleText(title, "RP1942_FlatTitle", 28, sub and 22 or F.TITLE_H / 2 - 2, C("text"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    if sub then draw.SimpleText(sub, "RP1942_FlatSub", 29, 46, C("sub"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
    if status then
        surface.SetFont("RP1942_FlatLabel")
        local tw = surface.GetTextSize(status)
        local pw, ph = tw + 44, 32
        local px, py = w - 24 - pw, (F.TITLE_H - 4 - ph) / 2
        local col = statusCol or C("sub")
        draw.RoundedBox(ph / 2, px, py, pw, ph, dim(col, 0.28, 255))
        draw.RoundedBox(6, px + 13, py + ph / 2 - 6, 12, 12, col)
        draw.SimpleText(status, "RP1942_FlatLabel", px + 32, py + ph / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    -- the thin frame round the edge, like the F4 window
    surface.SetDrawColor(C("card"))
    surface.DrawOutlinedRect(0, 0, w, h, 2)
end

function F.Label(text, x, y, alignX)
    draw.SimpleText(text, "RP1942_FlatLabel", x, y, C("gold"), alignX or TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function F.Chip(x, y, text, col, alignRight)
    surface.SetFont("RP1942_FlatLabel")
    local tw = surface.GetTextSize(text)
    local cw, ch = tw + 20, 26
    if alignRight then x = x - cw end
    draw.RoundedBox(4, x, y, cw, ch, dim(col, 0.3))
    draw.SimpleText(text, "RP1942_FlatLabel", x + cw / 2, y + ch / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return cw
end

function F.Arrow(x, y, size, up, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    local s = size / 2
    local pts = up and { { x = x, y = y - s }, { x = x + s, y = y + s }, { x = x - s, y = y + s } }
                    or { { x = x - s, y = y - s }, { x = x + s, y = y - s }, { x = x, y = y + s } }
    surface.DrawPoly(pts)
end

-- A bar split into coloured zones (each { from, to, color } on 0-100). The
-- zone the value is in is lit, the others dim; a marker shows the value and
-- opts.ghost (optional) where it's heading. opts.live = false greys it out.
function F.Zones(x, y, w, h, value, zones, opts)
    opts = opts or {}
    local live = opts.live ~= false
    local function px(v) return x + math.floor(w * math.Clamp(v, 0, 100) / 100) end
    draw.RoundedBox(4, x - 3, y - 3, w + 6, h + 6, C("titleBar"))
    for _, z in ipairs(zones) do
        local inside = live and value >= z[1] and (value < z[2] or z[2] >= 100)
        surface.SetDrawColor(inside and z[3] or dim(z[3], live and 0.38 or 0.22))
        surface.DrawRect(px(z[1]), y, px(z[2]) - px(z[1]), h)
    end
    -- zone edges
    for i = 2, #zones do
        surface.SetDrawColor(C("titleBar"))
        surface.DrawRect(px(zones[i][1]) - 1, y, 2, h)
    end
    if not live then return end
    if opts.ghost then
        local gx = px(opts.ghost)
        surface.SetDrawColor(255, 255, 255, 70)
        surface.DrawRect(gx - 1, y + 4, 3, h - 8)
    end
    local mx = px(value)
    surface.SetDrawColor(C("text"))
    surface.DrawRect(mx - 2, y - 8, 5, h + 16)
    F.Arrow(mx, y - 16, 16, false, C("text"))
end

function F.Progress(x, y, w, h, frac, col)
    draw.RoundedBox(4, x, y, w, h, C("well"))
    local fw = math.floor(w * math.Clamp(frac or 0, 0, 1))
    if fw > 0 then draw.RoundedBox(4, x, y, math.max(fw, 8), h, col or C("gold")) end
end

function F.Banner(x, y, w, h, text, col, flash)
    draw.RoundedBox(4, x, y, w, h, flash and dim(col, 0.45) or C("card"))
    draw.RoundedBoxEx(4, x, y, 8, h, col, true, false, true, false)
    text = RP1942.fitText and RP1942.fitText(text, "RP1942_FlatBody", w - 44) or text
    draw.SimpleText(text, "RP1942_FlatBody", x + 26, y + h / 2, flash and C("text") or col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

-- An F4 button. opts.color replaces the red; opts.fill (0-1) shows a
-- progress sweep across it (e.g. while a valve turns)
function F.Button(P, id, x, y, w, h, label, enabled, opts)
    opts = opts or {}
    local hot = P:Hot(id, x, y, w, h, enabled)
    local base = opts.color or C("button")
    local col = not enabled and C("disabled") or (hot and C("buttonHover") or base)
    if hot and opts.color then col = Color(math.min(base.r + 30, 255), math.min(base.g + 30, 255), math.min(base.b + 30, 255)) end
    draw.RoundedBox(4, x, y, w, h, col)
    if opts.fill and opts.fill > 0 and opts.fill < 1 then
        draw.RoundedBox(4, x, y + h - 6, math.floor(w * opts.fill), 6, C("gold"))
    end
    if hot then
        surface.SetDrawColor(C("gold"))
        surface.DrawOutlinedRect(x, y, w, h, 3)
    end
    draw.SimpleText(label, "RP1942_FlatButton", x + w / 2, y + h / 2, enabled and C("text") or C("sub"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return hot
end

-- The line along the bottom: names[id] = what pressing E on it does
function F.Hint(P, w, h, names)
    local text = P.hover and ((names[P.hover] or P.hover) .. "  ·  PRESS E") or "LOOK AT A BUTTON  ·  PRESS E"
    draw.SimpleText(text, "RP1942_FlatSmall", w / 2, h - 26, P.hover and C("text") or C("sub"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
