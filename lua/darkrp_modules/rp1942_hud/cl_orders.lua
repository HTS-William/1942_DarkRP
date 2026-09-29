--[[---------------------------------------------------------------------------
1942 DarkRP - Orders (DarkRP agendas: "Reich Orders", "Resistance Plans")

Replaces DarkRP's big agenda box with a compact panel in the top-left
corner, in the HUD's style. It keeps clear of everything else on screen:
    top-left     the Reich alerts (wanted, events) stack BELOW this panel
    top-centre   banners (broadcast, martial law, bank robbery) and the
                 election notice
    right side   DarkRP's notifications and the WANTED tag
    left-centre  chat (the panel is kept short: maxLines)
    bottom       player panel, economy bar, ammo

Long orders wrap and are cut at maxLines. Players can hide it with
    rp1942_orders_hud 0
The rectangle it uses each frame is left in RP1942.OrdersRect.
---------------------------------------------------------------------------]]
local CFG = {
    width    = 420,   -- at 1080p (scales with the screen)
    maxLines = 6,
    top      = 0.018, -- share of the screen height from the top
}

local show = CreateClientConVar("rp1942_orders_hud", "1", true, false, "Show your faction's orders (agenda) in the top-left corner", 0, 1)

local function fonts()
    local h = ScrH()
    surface.CreateFont("RP1942_OrdersTitle", { font = "Roboto", size = math.max(15, math.floor(h * 0.018)), weight = 900, extended = true })
    surface.CreateFont("RP1942_OrdersText",  { font = "Roboto", size = math.max(15, math.floor(h * 0.019)), weight = 500, extended = true })
    surface.CreateFont("RP1942_OrdersSmall", { font = "Roboto", size = math.max(12, math.floor(h * 0.014)),  weight = 500, extended = true })
end
fonts()
hook.Add("OnScreenSizeChanged", "RP1942_OrdersFonts", fonts)

-- DarkRP's own agenda box is replaced
hook.Add("HUDShouldDraw", "RP1942_Orders", function(name)
    if name == "DarkRP_Agenda" then return false end
end)

local STYLE = {
    reich      = { strip = Color(93, 101, 82),  title = Color(214, 206, 170) },
    resistance = { strip = Color(150, 44, 36),  title = Color(236, 170, 150) },
    other      = { strip = Color(201, 168, 92), title = Color(201, 168, 92) },
}
local TEXT, SUB, BG = Color(236, 228, 212), Color(160, 152, 136), Color(20, 19, 17, 215)

-- Word-wrap into lines no wider than maxW (long words are cut)
local function wrap(text, font, maxW)
    surface.SetFont(font)
    local lines = {}
    for para in string.gmatch(text .. "\n", "(.-)\n") do
        local line = ""
        for word in string.gmatch(para, "%S+") do
            local try = line == "" and word or (line .. " " .. word)
            if surface.GetTextSize(try) <= maxW then
                line = try
            else
                if line ~= "" then lines[#lines + 1] = line end
                while surface.GetTextSize(word) > maxW and #word > 1 do
                    local cut = #word
                    while cut > 1 and surface.GetTextSize(string.sub(word, 1, cut)) > maxW do cut = cut - 1 end
                    lines[#lines + 1] = string.sub(word, 1, cut)
                    word = string.sub(word, cut + 1)
                end
                line = word
            end
        end
        lines[#lines + 1] = line
    end
    while #lines > 0 and lines[#lines] == "" do table.remove(lines) end
    return lines
end

local cache = { text = nil, w = 0, lines = {} }

hook.Add("HUDPaint", "RP1942_Orders", function()
    RP1942.OrdersRect = nil
    if not show:GetBool() then return end
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp.getAgendaTable then return end
    local agenda = lp:getAgendaTable()
    if not agenda then return end

    local s = ScrH() / 1080
    local w = math.floor(CFG.width * s)
    local pad = math.floor(13 * s)
    local x, y = math.floor(16 * s), math.floor(ScrH() * CFG.top)

    local raw = (lp:getDarkRPVar("agenda") or ""):gsub("//", "\n"):gsub("\\n", "\n")
    raw = string.Trim(raw)
    if cache.text ~= raw or cache.w ~= w then
        cache.text, cache.w = raw, w
        cache.lines = raw ~= "" and wrap(raw, "RP1942_OrdersText", w - pad * 2 - 4) or {}
        if #cache.lines > CFG.maxLines then
            local l = {}
            for i = 1, CFG.maxLines do l[i] = cache.lines[i] end
            l[CFG.maxLines] = l[CFG.maxLines] .. " ..."
            cache.lines = l
        end
    end

    local faction = RP1942.getFaction and RP1942.getFaction(lp) or "other"
    local st = STYLE[faction] or STYLE.other
    local titleH = draw.GetFontHeight("RP1942_OrdersTitle")
    local lineH = draw.GetFontHeight("RP1942_OrdersText") + 1
    local lines = #cache.lines
    local bodyH = lines > 0 and lines * lineH or draw.GetFontHeight("RP1942_OrdersSmall")
    local h = pad + titleH + math.floor(6 * s) + bodyH + pad

    draw.RoundedBox(6, x, y, w, h, BG)
    surface.SetDrawColor(st.strip)
    surface.DrawRect(x, y, math.max(3, math.floor(4 * s)), h)

    local tx = x + pad + 4
    draw.SimpleText(string.upper(agenda.Title or "Orders"), "RP1942_OrdersTitle", tx, y + pad, st.title)
    local cy = y + pad + titleH + math.floor(6 * s)
    if lines == 0 then
        draw.SimpleText("No orders yet.", "RP1942_OrdersSmall", tx, cy, SUB)
    else
        for i = 1, lines do
            draw.SimpleText(cache.lines[i], "RP1942_OrdersText", tx, cy, TEXT)
            cy = cy + lineH
        end
    end

    RP1942.OrdersRect = { x = x, y = y, w = w, h = h }
end)
