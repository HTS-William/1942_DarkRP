--[[---------------------------------------------------------------------------
42Bros - F4 Shop tab (client)

    [ Search...                                   ]  [ Crates: - 1 + ]
    YOUR JOB · ...      (green bars) what only your job can buy, first:
                        a dealer's whole stock (its `shop` catalog, which used
                        to be its F3 menu), then F4 Shop items and DarkRP
                        entities limited to your job (ovens, flour...)
    Tools / Supplies /  (red bars) everything else you can buy
    Ammo / ...

Click a bar to fold that section away (remembered while the game's open).
The search matches names, sections, ammo and descriptions. Items your job
can't buy are hidden; prices turn red when you can't afford them.
Crates: a dealer buying a weapon can buy up to RP1942.ShopShipments.maxAmount
at once (they come in a crate); the amount box sits beside the search.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local folded = {}   -- [section title] = true while folded (kept while the game's open)

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

-- Only some jobs may buy it (so it belongs under "Your job")
local function jobOnly(allowedList)
    return istable(allowedList) and #allowedList > 0 and #allowedList < table.Count(RPExtraTeams)
end

-- Every section to show, your job's first:
-- { title, job, entries = { { name, model, price(), amount, crate, tip, buy(qty), search } } }
local function collectSections(ply)
    local jobSecs, otherSecs, byTitle = {}, {}, {}
    local function section(title, job)
        local full = job and ("Your job  ·  " .. title) or title
        if not byTitle[full] then
            byTitle[full] = { title = full, job = job, entries = {} }
            table.insert(job and jobSecs or otherSecs, byTitle[full])
        end
        return byTitle[full]
    end
    local function add(sec, e)
        e.search = string.lower(table.concat({ e.name or "", sec.title, e.tip or "" }, " "))
        table.insert(sec.entries, e)
    end

    -- 1. the dealer's stock (the job's shop catalog)
    local job = RPExtraTeams[ply:Team()]
    local key = job and job.shop
    local catalog = key and RP1942.getShopCatalog and RP1942.getShopCatalog(key)
    if catalog then
        for _, item in ipairs(catalog.items or {}) do
            local ammo = RP1942.getShopItemAmmo and RP1942.getShopItemAmmo(item)
            add(section(item.category or catalog.name, true), {
                name = item.name, model = RP1942.getShopItemModel and RP1942.getShopItemModel(item),
                price = function() return RP1942.getShopPrice and RP1942.getShopPrice(key, item) or item.price end,
                crate = item.type == "weapon",
                tip = (ammo and ("Ammo: " .. ammo .. (item.description and "\n" or "")) or "") .. (item.description or ""),
                buy = function(qty)
                    net.Start("RP1942_DealerBuy")
                    net.WriteString(item.id)
                    net.WriteUInt(item.type == "weapon" and qty or 1, 8)
                    net.SendToServer()
                end,
            })
        end
    end

    -- 2. our own items (sh_f4_shop.lua), by category in the order they're listed
    for _, item in ipairs(RP1942.getF4ShopItems and RP1942.getF4ShopItems() or {}) do
        if RP1942.canBuyF4Item(ply, item) then
            local price = RP1942.f4ItemPrice(item)
            add(section(item.category, jobOnly(item.jobs)), {
                name = item.name, model = item.model, price = function() return price end,
                amount = item.type == "ammo" and item.amount or nil, tip = item.description,
                buy = function()
                    net.Start("RP1942_F4Buy")
                    net.WriteString(item.id)
                    net.SendToServer()
                end,
            })
        end
    end

    -- 3. DarkRP's lists (entities.lua, single weapons, ammo types)
    for _, def in ipairs(DARKRP_KINDS) do
        for _, cat in ipairs(DarkRP.getCategories()[def.kind] or {}) do
            local visible = not cat.canSee or cat.canSee(ply)
            for _, item in ipairs(visible and cat.members or {}) do
                local sellable = def.kind ~= "weapons" or item.separate   -- only weapons sold singly
                if sellable and darkrpAllowed(item, ply) then
                    local price = def.price(item, ply) or 0
                    add(section(cat.name == "Other" and def.label or cat.name, jobOnly(item.allowed)), {
                        name = item.name, model = item.model, price = function() return price end,
                        amount = def.kind == "ammo" and item.amountGiven or nil,
                        buy = function() def.buy(item) end,
                    })
                end
            end
        end
    end

    local all = {}
    for _, s in ipairs(jobSecs) do all[#all + 1] = s end
    for _, s in ipairs(otherSecs) do all[#all + 1] = s end
    return all, catalog ~= nil
end

RP1942.F4Tabs.shop = {
    name = "Shop",
    icon = "icon16/cart.png",
    build = function(page)
        local UI = RP1942.F4UI
        local C = UI.C
        local s = UI.scale()
        local gap = math.floor(8 * s)
        local cardW = math.floor(175 * s)   -- target card width: fewer, bigger cards per row
        local ply = LocalPlayer()
        local sections, dealer = collectSections(ply)

        -- how many of a weapon a dealer buys at once (more than 1 = a crate)
        local qty = 1
        local maxQty = (RP1942.ShopShipments and RP1942.ShopShipments.maxAmount) or 1

        ------------------------------------------------------------ the top row
        local top = vgui.Create("DPanel", page)
        top:Dock(TOP)
        top:SetTall(math.floor(34 * s))
        top:DockMargin(0, 0, 0, gap)
        top:SetPaintBackground(false)

        if dealer and maxQty > 1 then
            local box = vgui.Create("DPanel", top)
            box:Dock(RIGHT)
            box:DockMargin(gap, 0, 0, 0)
            box:SetWide(math.floor(250 * s))
            box.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, C.entry)
                draw.SimpleText("Crate size", "RP1942_F4Body", 10, h / 2, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(qty), "RP1942_F4Head", w - math.floor(62 * s), h / 2, qty > 1 and C.gold or C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            box:SetTooltip("How many of a weapon to buy at once: more than 1 comes as a crate. Shift steps by 5.")
            local function step(label, d, dock)
                local b = UI.button(box, label, function()
                    qty = math.Clamp(qty + d * (input.IsKeyDown(KEY_LSHIFT) and 5 or 1), 1, maxQty)
                end)
                b:Dock(dock)
                b:SetWide(math.floor(30 * s))
                b:DockMargin(dock == RIGHT and 2 or 0, 2, dock == RIGHT and 2 or 0, 2)
            end
            step("+", 1, RIGHT)
            local spacer = vgui.Create("Panel", box)
            spacer:Dock(RIGHT)
            spacer:SetWide(math.floor(64 * s))
            step("-", -1, RIGHT)
        end

        local search = UI.textEntry(top, "", function() end)
        search:Dock(FILL)
        search:SetUpdateOnType(true)
        search.PaintOver = function(self, w, h)
            surface.SetDrawColor(self:HasFocus() and C.gold or C.tabHover)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if self:GetValue() == "" and not self:HasFocus() then
                draw.SimpleText("Search: name, kind or ammo...", "RP1942_F4Body", 10, h / 2, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        ------------------------------------------------------------ the list
        local list = vgui.Create("DScrollPanel", page)
        list:Dock(FILL)
        UI.styleScroll(list)
        list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        list:GetCanvas():DockPadding(gap, gap, gap, gap)

        -- Lay the list out again straight away (a section folded, or the search
        -- hid cards): the canvas first, so the sections below move up this
        -- frame, then the scroll panel, so the scrollbar fits the new height
        local function relayout()
            list:GetCanvas():InvalidateLayout(true)
            list:InvalidateLayout(true)
        end

        local function priceOf(e)
            local p = e.price() or 0
            return (e.crate and qty > 1) and p * qty or p
        end

        local function addCard(grid, e)
            local card = vgui.Create("DButton", grid)
            card:SetText("")
            card.hover = 0
            card.entry = e
            card:SetTooltip(e.tip and e.tip ~= "" and (e.name .. "\n" .. e.tip) or e.name)

            local icon = vgui.Create("SpawnIcon", card)
            icon:SetModel(e.model or "models/Items/item_item_crate.mdl")
            icon:SetMouseInputEnabled(false)

            card.PerformLayout = function(_, w, h)
                surface.SetFont("RP1942_F4Head");  local _, nameH = surface.GetTextSize("Ag")
                surface.SetFont("RP1942_F4Body");  local _, priceH = surface.GetTextSize("Ag")
                local size = math.max(24, math.floor(math.min(w - 24, h - (nameH + priceH + 10) - 12)))
                icon:SetSize(size, size)
                icon:SetPos((w - size) / 2, 6)
            end
            card.DoClick = function()
                if not ply:canAfford(priceOf(e)) then surface.PlaySound("buttons/button10.wav") return end
                surface.PlaySound("ui/buttonclick.wav")
                e.buy(qty)
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
                local price = priceOf(e)
                local extra = e.amount and ("  ·  " .. e.amount .. " rounds") or ((e.crate and qty > 1) and ("  ·  crate of " .. qty) or "")
                draw.SimpleText(UI.fit(DarkRP.formatMoney(price) .. extra, "RP1942_F4Body", w - 8), "RP1942_F4Body", w / 2, h - 5,
                    ply:canAfford(price) and C.gold or C.unavailable, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end
            return card
        end

        -- A section: its bar (click to fold) and its grid of cards
        local built = {}
        for _, sec in ipairs(sections) do
            if #sec.entries > 0 then
                local bar = UI.categoryBar(list, sec.title, "", sec.job and C.categoryAlt or nil)
                bar:Dock(TOP)
                bar:DockMargin(0, 0, 0, gap)
                bar:SetCursor("hand")
                local grid = list:Add("Panel")
                grid:Dock(TOP)
                grid:DockMargin(0, 0, 0, gap * 2)
                local entry = { sec = sec, bar = bar, grid = grid, cards = {}, shown = #sec.entries }
                for _, e in ipairs(sec.entries) do entry.cards[#entry.cards + 1] = addCard(grid, e) end

                -- the bar's right side: how many, and that a click folds it
                local basePaint = bar.Paint
                bar.Paint = function(b, w, h)
                    basePaint(b, w, h)
                    local n = entry.shown
                    local right = n .. (n == 1 and " item" or " items") .. "   ·   " .. (folded[sec.title] and "show" or "hide")
                    draw.SimpleText(right, "RP1942_F4Small", w - 10, h / 2, C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                bar.OnMousePressed = function()
                    folded[sec.title] = not folded[sec.title] or nil
                    surface.PlaySound("ui/buttonclick.wav")
                    grid:SetVisible(not folded[sec.title])
                    if not folded[sec.title] then grid:InvalidateLayout(true) end
                    relayout()
                end
                grid:SetVisible(not folded[sec.title])

                grid.PerformLayout = function(g, w)
                    local cols = math.max(3, math.floor((w + gap) / (cardW + gap)))
                    local cw = math.floor((w - gap * (cols - 1)) / cols)
                    local ch = math.floor(cw * 1.0)
                    local i = 0
                    for _, card in ipairs(entry.cards) do
                        if card:IsVisible() then
                            card:SetPos((i % cols) * (cw + gap), math.floor(i / cols) * (ch + gap))
                            card:SetSize(cw, ch)
                            i = i + 1
                        end
                    end
                    local rows = math.ceil(i / cols)
                    local tall = math.max(0, rows * ch + (rows - 1) * gap)
                    if g:GetTall() ~= tall then g:SetTall(tall) end
                end
                built[#built + 1] = entry
            end
        end

        local empty = list:Add("DLabel")
        empty:Dock(TOP)
        empty:DockMargin(gap, gap * 2, gap, 0)
        empty:SetFont("RP1942_F4Body")
        empty:SetTextColor(C.sub)
        empty:SetWrap(true)
        empty:SetAutoStretchVertical(true)
        empty:SetText(#built == 0 and "Nothing is for sale to your job here." or "Nothing matches your search.")
        empty:SetVisible(#built == 0)

        -- The search: every word typed has to be in the item's name, section or description
        search.OnValueChange = function(_, text)
            local words = {}
            for word in string.gmatch(string.lower(text or ""), "%S+") do words[#words + 1] = word end
            local any = false
            for _, entry in ipairs(built) do
                local n = 0
                for _, card in ipairs(entry.cards) do
                    local show = true
                    for _, word in ipairs(words) do
                        if not string.find(card.entry.search, word, 1, true) then show = false break end
                    end
                    card:SetVisible(show)
                    if show then n = n + 1 end
                end
                entry.shown = n
                entry.bar:SetVisible(n > 0)
                -- searching opens folded sections that have a match
                entry.grid:SetVisible(n > 0 and (#words > 0 or not folded[entry.sec.title]))
                entry.grid:InvalidateLayout(true)
                any = any or n > 0
            end
            empty:SetVisible(not any)
            relayout()
            list:GetVBar():SetScroll(0)
        end
    end,
}
