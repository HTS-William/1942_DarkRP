--[[---------------------------------------------------------------------------
1942 DarkRP - production spawner for staff (client)
Two ways in, the same spawner:
    !prodspawn      its own window (the server opens it, sv_prodspawn.lua)
    F4 > Spawner    a tab in the F4 menu, only for staff allowed !prodspawn
Aim first, then open it: everything spawns at your crosshair. The server
checks the permission again on every click.
---------------------------------------------------------------------------]]
local function colors()   -- the shared palette (rp1942_core/cl_theme.lua)
    local C = RP1942.col
    return {
        bg = C("bg"), bar = C("titleBar"), panel = C("panel"), card = C("card"),
        hover = C("cardHover"), on = C("cardSelected"), head = C("category"), gold = C("gold"),
        text = C("text"), sub = C("sub"), button = C("button"), buttonHover = C("buttonHover"),
    }
end

-- fonts sized from the screen: lua/autorun/client/rp1942_screenfonts.lua
RP1942.screenFont("RP1942_PSTitle", 0.026, 800, { min = 20 })
RP1942.screenFont("RP1942_PSHead", 0.018, 800, { min = 15 })
RP1942.screenFont("RP1942_PSBody", 0.015, 500, { min = 13 })

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
    { class = "rp1942_scrap",       name = "Scrap Metal",  cfg = "scrap" },
    { class = "rp1942_oil_rig",     name = "Oil Derrick",  cfg = "oil",    note = "bolted where you aim" },
    { class = "rp1942_market",      name = "Market",       cfg = "market", note = "not saved" },
    { class = "rp1942_printer_bank",    name = "Banking Printer", model = "models/props_c17/consolebox01a.mdl", note = "legal" },
    { class = "rp1942_printer_illegal", name = "Money Printer",   model = "models/props_c17/consolebox01a.mdl", note = "illegal" },
    { class = "rp1942_dumpster",        name = "Dumpster",        model = "models/props_junk/trashdumpster01a.mdl", note = "frozen" },
    { class = "darkrp_laws",            name = "Law Board",       model = "models/props/cs_assault/Billboard.mdl", note = "the laws" },
    { class = "rp1942_bank_vault",      name = "Bank Vault",      model = "models/props_wasteland/controlroom_storagecloset001a.mdl", note = "Reichsbank" },
    { class = "rp1942_radio",           name = "Radio",           model = "models/props_lab/citizenradio.mdl", note = "E to tune" },
}

-- The spawner's contents, in any panel: its own window (!prodspawn) or the
-- F4 menu's Spawner tab. w = the width it has, for sizing the cards.
local function build(parent, w)
    local C = colors()
    -- Settings for goods
    local quality, amount, pocket = 3, 1, true

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)
    if RP1942.F4UI then RP1942.F4UI.styleScroll(scroll) end

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

local frame

-- Its own window (!prodspawn)
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

    build(frame, w)
end

net.Receive("RP1942_ProdSpawnOpen", open)

-- The F4 menu's Spawner tab (rp1942_f4/cl_f4.lua shows it only when canSee says so)
RP1942.F4Tabs = RP1942.F4Tabs or {}
RP1942.F4Tabs.spawner = {
    name = "Spawner",
    icon = "icon16/brick_add.png",
    canSee = function(ply)
        return RP1942.staffCan(ply, "ulx prodspawn", function(p) return p:IsSuperAdmin() end)
    end,
    build = function(page)
        local C = colors()
        local intro = vgui.Create("DLabel", page)
        intro:Dock(TOP)
        intro:DockMargin(2, 0, 0, 6)
        intro:SetFont("RP1942_PSBody")
        intro:SetTextColor(C.sub)
        intro:SetText("Staff  ·  aim before opening F4: things spawn at your crosshair, owned by you  ·  Z undoes  ·  also !prodspawn")
        intro:SizeToContentsY(4)
        build(page, math.max(page:GetWide(), ScrW() * 0.6))
    end,
}

-- !prodsaves: highlight every saved machine for a minute
-- (!prodsaves markers: rp1942_core/cl_markers.lua)
