--[[---------------------------------------------------------------------------
1942 DarkRP - production spawner for staff (client)
The window the server opens (sv_prodspawn.lua). Aim first, then open it:
everything spawns at your crosshair.
---------------------------------------------------------------------------]]
local function colors()
    local c = RP1942.F4Config and RP1942.F4Config.colors or {}
    return {
        bg = c.bg or Color(20, 19, 17, 248), bar = c.titleBar or Color(14, 13, 12),
        panel = c.panel or Color(28, 26, 23), card = c.card or Color(38, 35, 31),
        hover = c.cardHover or Color(52, 48, 42), on = c.cardSelected or Color(64, 52, 36),
        head = c.category or Color(84, 18, 18), gold = c.gold or Color(201, 168, 92),
        text = c.text or Color(236, 228, 212), sub = c.sub or Color(160, 152, 136),
        button = c.button or Color(128, 26, 24), buttonHover = c.buttonHover or Color(156, 36, 32),
    }
end

local function fonts()
    local h = ScrH()
    surface.CreateFont("RP1942_PSTitle", { font = "Roboto", size = math.max(20, math.floor(h * 0.026)), weight = 800, extended = true })
    surface.CreateFont("RP1942_PSHead",  { font = "Roboto", size = math.max(15, math.floor(h * 0.018)), weight = 800, extended = true })
    surface.CreateFont("RP1942_PSBody",  { font = "Roboto", size = math.max(13, math.floor(h * 0.015)), weight = 500, extended = true })
end
fonts()
hook.Add("OnScreenSizeChanged", "RP1942_ProdSpawnFonts", fonts)

local function send(kind, id, q, count, pocket)
    net.Start("RP1942_ProdSpawn")
    net.WriteString(kind)
    net.WriteString(id or "")
    net.WriteUInt(q or 2, 2)
    net.WriteUInt(count or 1, 4)
    net.WriteBool(pocket == true)
    net.SendToServer()
    surface.PlaySound("ui/buttonclick.wav")
end

local MACHINES = {
    { class = "rp1942_oven",        name = "Bread Oven",   cfg = "oven" },
    { class = "rp1942_flour",       name = "Sack of Flour", cfg = "flour" },
    { class = "rp1942_wine_barrel", name = "Wine Barrel",  cfg = "wine" },
    { class = "rp1942_factory",     name = "Factory Line", cfg = "factory" },
    { class = "rp1942_oil_rig",     name = "Oil Derrick",  cfg = "oil",    note = "bolted where you aim" },
    { class = "rp1942_market",      name = "Market",       cfg = "market", note = "not saved" },
    { class = "rp1942_printer_bank",    name = "Banking Printer", model = "models/props_c17/consolebox01a.mdl", note = "legal" },
    { class = "rp1942_printer_illegal", name = "Money Printer",   model = "models/props_c17/consolebox01a.mdl", note = "illegal" },
    { class = "rp1942_dumpster",        name = "Dumpster",        model = "models/props_junk/trashdumpster01a.mdl", note = "frozen" },
    { class = "darkrp_laws",            name = "Law Board",       model = "models/props/cs_assault/Billboard.mdl", note = "the laws" },
    { class = "rp1942_bank_vault",      name = "Bank Vault",      model = "models/props_wasteland/controlroom_storagecloset001a.mdl", note = "Reichsbank" },
}

local frame

local function open()
    if IsValid(frame) then frame:Remove() end
    local C = colors()
    local w, h = math.Clamp(ScrW() * 0.5, 640, 900), math.Clamp(ScrH() * 0.72, 480, 760)
    local pad = 12

    frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:DockPadding(pad, 64, pad, pad)
    frame.Paint = function(_, fw, fh)
        draw.RoundedBox(6, 0, 0, fw, fh, C.bg)
        draw.RoundedBoxEx(6, 0, 0, fw, 54, C.bar, true, true, false, false)
        draw.SimpleText("PRODUCTION SPAWNER", "RP1942_PSTitle", pad + 2, 8, C.gold)
        draw.SimpleText("Staff debug  ·  aim first: things spawn at your crosshair, owned by you  ·  Z undoes", "RP1942_PSBody", pad + 2, 34, C.sub)
    end

    -- Settings for goods
    local quality, amount, pocket = 3, 1, true

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)

    local function header(text)
        local bar = scroll:Add("DPanel")
        bar:Dock(TOP)
        bar:DockMargin(0, 6, 0, 6)
        bar:SetTall(28)
        bar.Paint = function(_, bw, bh)
            draw.RoundedBox(4, 0, 0, bw, bh, C.head)
            draw.SimpleText(text, "RP1942_PSHead", 10, bh / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return bar
    end

    -- A row of small toggle buttons; returns nothing, calls set(value)
    local function segmented(parent, label, options, get, set)
        local row = parent:Add("DPanel")
        row:Dock(LEFT)
        row:DockMargin(0, 0, 18, 0)
        row.Paint = nil
        local lbl = row:Add("DLabel")
        lbl:Dock(LEFT)
        lbl:SetFont("RP1942_PSBody")
        lbl:SetTextColor(C.sub)
        lbl:SetText(label)
        lbl:SizeToContentsX(8)
        local total = lbl:GetWide()
        for _, o in ipairs(options) do
            local b = row:Add("DButton")
            b:Dock(LEFT)
            b:DockMargin(2, 0, 0, 0)
            b:SetFont("RP1942_PSBody")
            b:SetText(o.label)
            b:SetTextColor(C.text)
            b:SizeToContentsX(20)
            total = total + b:GetWide() + 2
            b.Paint = function(s, bw, bh)
                local on = get() == o.value
                draw.RoundedBox(4, 0, 0, bw, bh, on and C.button or (s:IsHovered() and C.hover or C.card))
            end
            b.DoClick = function() set(o.value) surface.PlaySound("ui/buttonclick.wav") end
        end
        row:SetWide(total)
    end

    -- A card: model picture and a name; click spawns
    local function card(grid, model, title, subtitle, onClick)
        local size = math.floor(math.Clamp(w * 0.13, 92, 120))
        local b = grid:Add("DButton")
        b:SetSize(size, size + 36)
        b:SetText("")
        b.Paint = function(s, bw, bh)
            draw.RoundedBox(4, 0, 0, bw, bh, s:IsHovered() and C.hover or C.card)
            draw.SimpleText(title, "RP1942_PSBody", bw / 2, size + 2, C.text, TEXT_ALIGN_CENTER)
            if subtitle then draw.SimpleText(subtitle, "RP1942_PSBody", bw / 2, size + 17, C.sub, TEXT_ALIGN_CENTER) end
        end
        b.DoClick = onClick
        local icon = b:Add("SpawnIcon")
        icon:SetPos(4, 4)
        icon:SetSize(size - 8, size - 8)
        icon:SetModel(model or "models/props_junk/cardboard_box004a.mdl")
        icon:SetMouseInputEnabled(false)
        icon:SetTooltip(false)
        return b
    end

    local function grid()
        local g = scroll:Add("DIconLayout")
        g:Dock(TOP)
        g:SetSpaceX(6)
        g:SetSpaceY(6)
        return g
    end

    ---------------------------------------------------------------- machines
    header("MACHINES & SUPPLIES")
    local mg = grid()
    local P = RP1942.Production
    for _, m in ipairs(MACHINES) do
        local cfg = m.cfg and P[m.cfg]
        card(mg, m.model or (cfg and cfg.model), m.name, m.note, function() send("machine", m.class) end)
    end

    ---------------------------------------------------------------- goods
    header("GOODS")
    local opts = scroll:Add("DPanel")
    opts:Dock(TOP)
    opts:DockMargin(0, 0, 0, 6)
    opts:SetTall(28)
    opts.Paint = nil
    segmented(opts, "Quality", { { label = "1 star", value = 1 }, { label = "2 stars", value = 2 }, { label = "3 stars", value = 3 } },
        function() return quality end, function(v) quality = v end)
    segmented(opts, "Amount", { { label = "1", value = 1 }, { label = "3", value = 3 }, { label = "5", value = 5 }, { label = "10", value = 10 } },
        function() return amount end, function(v) amount = v end)
    segmented(opts, "Put", { { label = "In my pocket", value = true }, { label = "At crosshair", value = false } },
        function() return pocket end, function(v) pocket = v end)

    local gg = grid()
    local ids = table.GetKeys(RP1942.Goods)
    table.sort(ids, function(a, b)
        local ga, gb = RP1942.Goods[a], RP1942.Goods[b]
        if (ga.rarity ~= nil) ~= (gb.rarity ~= nil) then return ga.rarity == nil end
        return ga.name < gb.name
    end)
    for _, id in ipairs(ids) do
        local good = RP1942.Goods[id]
        local model = istable(good.model) and good.model[1] or good.model
        card(gg, model, good.name, good.rarity or DarkRP.formatMoney(good.value), function()
            send("good", id, quality, amount, pocket)
        end)
    end

    ---------------------------------------------------------------- tools
    header("TOOLS  ·  ON WHAT YOU'RE LOOKING AT")
    local tools = scroll:Add("DIconLayout")   -- wraps onto a second row on narrow screens
    tools:Dock(TOP)
    tools:SetSpaceX(8)
    tools:SetSpaceY(8)
    local function tool(label, kind)
        local b = tools:Add("DButton")
        b:SetTall(40)
        b:SetFont("RP1942_PSBody")
        b:SetText(label)
        b:SetTextColor(C.text)
        b:SizeToContentsX(40)
        b.Paint = function(s, bw, bh) draw.RoundedBox(4, 0, 0, bw, bh, s:IsHovered() and C.buttonHover or C.button) end
        b.DoClick = function() send(kind) end
    end
    tool("Finish its timer now", "finish")
    tool("Remove it", "remove")
    tool("Save it (permanent)", "save")
    tool("Unsave it", "unsave")
    tool("Save all I placed", "saveall")

    local note = scroll:Add("DLabel")
    note:Dock(TOP)
    note:DockMargin(0, 10, 0, 0)
    note:SetFont("RP1942_PSBody")
    note:SetTextColor(C.sub)
    note:SetWrap(true)
    note:SetAutoStretchVertical(true)
    note:SetText("Finish ends the bake / ferment / tank / run right away, with the grade it had earned so far (and switches it on if it was off). "
        .. "Save makes a machine permanent for this map: it comes back frozen in place and owned by nobody after every restart (anyone can use it; "
        .. "nobody can upgrade a saved printer). Unsave removes it for good. !prodsaves shows them all. Derricks spawned here don't use an oil site.")
end

net.Receive("RP1942_ProdSpawnOpen", open)

-- !prodsaves: highlight every saved machine for a minute
local savedSpots, savedUntil = {}, 0
net.Receive("RP1942_ProdSaves", function()
    savedSpots = {}
    for i = 1, net.ReadUInt(8) do savedSpots[i] = net.ReadVector() end
    savedUntil = CurTime() + 60
end)
hook.Add("HUDPaint", "RP1942_ProdSaves", function()
    if CurTime() > savedUntil then return end
    local C = colors()
    for _, pos in ipairs(savedSpots) do
        local sp = (pos + Vector(0, 0, 40)):ToScreen()
        if sp.visible then
            draw.RoundedBox(4, sp.x - 5, sp.y - 5, 10, 10, C.gold)
            draw.SimpleText("SAVED  " .. math.floor(LocalPlayer():GetPos():Distance(pos) / 52.5) .. " m", "RP1942_PSBody", sp.x, sp.y - 8, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end
end)
