--[[---------------------------------------------------------------------------
1942 DarkRP - F4 Shop tab (client)

Lists, in this order:
    1. items from sh_f4_shop.lua (including the automatic ammo)
    2. DarkRP's own entities (entities.lua), weapons sold singly, and ammo
       types (ammo.lua)
Items your job can't buy are hidden; prices turn red when you can't afford
them. Shipments are NOT here: the dealers sell those from their own menus.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

-- DarkRP's own lists: how to buy one, and what it costs
local DARKRP_KINDS = {
    { kind = "entities", label = "Entities",
      price = function(item, ply) return item.getPrice and item.getPrice(ply, item.price) or item.price end,
      buy = function(item) RP1942.F4UI.command(item.cmd) end },
    { kind = "weapons", label = "Weapons",
      price = function(item, ply) return item.getPrice and item.getPrice(ply, item.pricesep) or item.pricesep end,
      buy = function(item) RP1942.F4UI.command("buy", item.name) end },
    { kind = "ammo", label = "Ammo",
      price = function(item, ply) return item.getPrice and item.getPrice(ply, item.price) or item.price end,
      buy = function(item) RP1942.F4UI.command("buyammo", item.id) end },
}

local function darkrpAllowed(item, ply)
    if istable(item.allowed) and #item.allowed > 0 and not table.HasValue(item.allowed, ply:Team()) then return false end
    if item.customCheck and not item.customCheck(ply) then return false end
    return true
end

-- Every section to show: { title, entries = { {name, model, price, amount, tip, buy} } }
local function collectSections(ply)
    local sections, byTitle = {}, {}
    local function section(title)
        if not byTitle[title] then
            byTitle[title] = { title = title, entries = {} }
            sections[#sections + 1] = byTitle[title]
        end
        return byTitle[title]
    end

    -- 1. our own items, grouped by category in the order they're listed
    for _, item in ipairs(RP1942.getF4ShopItems and RP1942.getF4ShopItems() or {}) do
        if RP1942.canBuyF4Item(ply, item) then
            table.insert(section(item.category).entries, {
                name = item.name, model = item.model, price = item.price,
                amount = item.type == "ammo" and item.amount or nil, tip = item.description,
                buy = function()
                    net.Start("RP1942_F4Buy")
                    net.WriteString(item.id)
                    net.SendToServer()
                end,
            })
        end
    end

    -- 2. DarkRP's lists
    for _, def in ipairs(DARKRP_KINDS) do
        for _, cat in ipairs(DarkRP.getCategories()[def.kind] or {}) do
            local visible = not cat.canSee or cat.canSee(ply)
            for _, item in ipairs(visible and cat.members or {}) do
                local sellable = def.kind ~= "weapons" or item.separate   -- only weapons sold singly
                if sellable and darkrpAllowed(item, ply) then
                    local title = cat.name == "Other" and def.label or (def.label .. "  ·  " .. cat.name)
                    table.insert(section(title).entries, {
                        name = item.name, model = item.model, price = def.price(item, ply) or 0,
                        amount = def.kind == "ammo" and item.amountGiven or nil,
                        buy = function() def.buy(item) end,
                    })
                end
            end
        end
    end
    return sections
end

RP1942.F4Tabs.shop = {
    name = "Shop",
    icon = "icon16/cart.png",
    build = function(page)
        local UI = RP1942.F4UI
        local C = UI.C
        local s = UI.scale()
        local gap = math.floor(8 * s)
        local cols = 4
        local ply = LocalPlayer()

        local list = vgui.Create("DScrollPanel", page)
        list:Dock(FILL)
        UI.styleScroll(list)
        list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        list:GetCanvas():DockPadding(gap, gap, gap, gap)

        local function addCard(grid, e)
            local card = vgui.Create("DButton", grid)
            card:SetText("")
            card.hover = 0
            card:SetTooltip(e.tip and (e.name .. "\n" .. e.tip) or e.name)

            local icon = vgui.Create("SpawnIcon", card)
            icon:SetModel(e.model or "models/Items/item_item_crate.mdl")
            icon:SetMouseInputEnabled(false)

            card.PerformLayout = function(_, w, h)
                local size = math.floor(math.min(w - 16, h * 0.58))
                icon:SetSize(size, size)
                icon:SetPos((w - size) / 2, 8)
            end
            card.DoClick = function()
                if not ply:canAfford(e.price) then surface.PlaySound("buttons/button10.wav") return end
                surface.PlaySound("ui/buttonclick.wav")
                e.buy()
            end
            card.Paint = function(c, w, h)
                c.hover = Lerp(FrameTime() * 12, c.hover, c:IsHovered() and 1 or 0)
                draw.RoundedBox(4, 0, 0, w, h, UI.mix(C.card, C.cardHover, c.hover))
            end
            card.PaintOver = function(_, w, h)
                surface.SetFont("RP1942_F4Head");  local _, nameH = surface.GetTextSize("Ag")
                surface.SetFont("RP1942_F4Body");  local _, priceH = surface.GetTextSize("Ag")
                local barH = nameH + priceH + 10
                draw.RoundedBoxEx(4, 0, h - barH, w, barH, Color(0, 0, 0, 150), false, false, true, true)
                draw.SimpleText(UI.fit(e.name, "RP1942_F4Head", w - 12), "RP1942_F4Head", w / 2, h - barH + 4, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                local priceText = DarkRP.formatMoney(e.price) .. (e.amount and ("   ·   " .. e.amount .. " rounds") or "")
                draw.SimpleText(UI.fit(priceText, "RP1942_F4Body", w - 8), "RP1942_F4Body", w / 2, h - 5,
                    ply:canAfford(e.price) and C.gold or C.unavailable, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end
        end

        local shown = 0
        for _, sec in ipairs(collectSections(ply)) do
            local n = #sec.entries
            if n > 0 then
                shown = shown + 1
                local bar = UI.categoryBar(list, sec.title, n .. (n == 1 and " item" or " items"))
                bar:Dock(TOP)
                bar:DockMargin(0, 0, 0, gap)

                local grid = list:Add("Panel")
                grid:Dock(TOP)
                grid:DockMargin(0, 0, 0, gap * 2)
                for _, e in ipairs(sec.entries) do addCard(grid, e) end
                grid.PerformLayout = function(g, w)
                    local cw = math.floor((w - gap * (cols - 1)) / cols)
                    local ch = math.floor(cw * 0.95)
                    for i, child in ipairs(g:GetChildren()) do
                        child:SetPos(((i - 1) % cols) * (cw + gap), math.floor((i - 1) / cols) * (ch + gap))
                        child:SetSize(cw, ch)
                    end
                    local rows = math.ceil(#g:GetChildren() / cols)
                    local tall = rows * ch + (rows - 1) * gap
                    if g:GetTall() ~= tall then g:SetTall(tall) end
                end
            end
        end

        if shown == 0 then
            local empty = list:Add("DLabel")
            empty:Dock(TOP)
            empty:DockMargin(gap, gap * 2, gap, 0)
            empty:SetFont("RP1942_F4Body")
            empty:SetTextColor(C.sub)
            empty:SetText("Nothing is for sale to your job here. Dealers sell from their own menu (F3).")
            empty:SetWrap(true)
            empty:SetAutoStretchVertical(true)
        end
    end,
}
