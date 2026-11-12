--[[---------------------------------------------------------------------------
42Bros - F4 Shop tab (client)

    +----------------------+  [ Search...                ] [ Crate size - 5 + ]
    | YOUR JOB · DEALER    |  +---------------------------------------------+
    |   Handguns        8  |  | Submachine guns          12 items · crates of 5
    | > Submachine guns 12 |  | [MP-40   ] [Thompson] [M3A1    ] [PPSh-41 ] |
    |   Rifles          7  |  | [9mm     ] [.45 ACP ] [.45 ACP ] [7.62 Tok] |
    | EVERYONE             |  | [R.M.2400] [R.M.2800] [R.M.1900] [R.M.2800] |
    |   Tools           2  |  |  ...                                        |
    |   Ammunition     22  |  +---------------------------------------------+
    | Your money R.M.14250 |
    +----------------------+

Left: the categories. What only your job can buy comes first: a dealer's
whole stock (its `shop` catalog, which used to be its F3 menu), then F4 Shop
items and DarkRP entities limited to your job (ovens, flour...). Then
everything else. Click one to show it on the right (remembered while the
game's open).

Right: that category's cards: name, the ammo it takes (guns), price. Click a
card to buy it. The search looks through every category at once (name,
category, ammo, description) and shows each match under its category's bar.
A dealer buying a weapon sets the crate size (up to
RP1942.ShopShipments.maxAmount) beside the search: more than 1 comes as a
crate, and the card shows the crate's price. Items your job can't buy are
hidden; prices turn red when you can't afford them.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local lastSection   -- the category shown last time (kept while the game's open)

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

-- The ammo a gun takes, for its card ("7.92×57mm Mauser"). Nothing for
-- grenades, mines and the like (they're their own ammo) or tools.
local function gunAmmo(class)
    if not class then return nil end
    for base in pairs(RP1942.WeaponStartAmmo and RP1942.WeaponStartAmmo.bases or {}) do
        if class == base or weapons.IsBasedOn(class, base) then return nil end
    end
    return RP1942.getShopItemAmmo and RP1942.getShopItemAmmo({ class = class }) or nil
end

-- Every category to show, your job's first:
-- { title, short, job, entries = { { name, model, price(), amount, ammo, desc, crate, buy(qty), search } } }
local function collectSections(ply)
    local jobSecs, otherSecs, byTitle = {}, {}, {}
    local function section(title, job)
        local full = job and ("Your job  ·  " .. title) or title
        if not byTitle[full] then
            byTitle[full] = { title = full, short = title, job = job, entries = {} }
            table.insert(job and jobSecs or otherSecs, byTitle[full])
        end
        return byTitle[full]
    end
    local function add(sec, e)
        e.search = string.lower(table.concat({ e.name or "", sec.short, e.ammo or "", e.desc or "" }, " "))
        table.insert(sec.entries, e)
    end

    -- 1. the dealer's stock (the job's shop catalog)
    local job = RPExtraTeams[ply:Team()]
    local key = job and job.shop
    local catalog = key and RP1942.getShopCatalog and RP1942.getShopCatalog(key)
    if catalog then
        for _, item in ipairs(catalog.items or {}) do
            add(section(item.category or catalog.name, true), {
                name = item.name, model = RP1942.getShopItemModel and RP1942.getShopItemModel(item),
                price = function() return RP1942.getShopPrice and RP1942.getShopPrice(key, item) or item.price end,
                crate = item.type == "weapon",
                ammo = item.ammo or (item.type == "weapon" and gunAmmo(item.class)) or nil,
                desc = item.description,
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
                amount = item.type == "ammo" and item.amount or nil,
                ammo = item.type == "weapon" and gunAmmo(item.class) or nil,
                desc = item.description,
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
                        ammo = def.kind == "weapons" and gunAmmo(item.entity) or nil,
                        buy = function() def.buy(item) end,
                    })
                end
            end
        end
    end

    local all = {}
    for _, s in ipairs(jobSecs) do if #s.entries > 0 then all[#all + 1] = s end end
    for _, s in ipairs(otherSecs) do if #s.entries > 0 then all[#all + 1] = s end end
    return all, catalog
end

RP1942.F4Tabs.shop = {
    name = "Shop",
    icon = "icon16/cart.png",
    build = function(page)
        local UI = RP1942.F4UI
        local C = UI.C
        local s = UI.scale()
        local gap = math.floor(8 * s)
        local cardW = math.floor(175 * s)   -- target card width
        local ply = LocalPlayer()
        local sections, catalog = collectSections(ply)

        local current       -- the category shown when not searching
        local searching = false
        local qty = 1       -- how many of a weapon a dealer buys at once (more than 1 = a crate)
        local maxQty = (RP1942.ShopShipments and RP1942.ShopShipments.maxAmount) or 1

        local function count(e) return e.crate and qty or 1 end
        local function totalOf(e) return (e.price() or 0) * count(e) end

        ------------------------------------------------------------ the categories (left)
        local rail = vgui.Create("DPanel", page)
        rail:Dock(LEFT)
        rail:DockMargin(0, 0, gap, 0)
        rail:SetWide(math.floor(250 * s))
        rail:DockPadding(gap, gap, gap, gap)
        rail.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end

        local money = vgui.Create("DPanel", rail)
        money:Dock(BOTTOM)
        money:DockMargin(0, gap, 0, 0)
        money:SetTall(math.floor(58 * s))
        money.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, C.card)
            draw.SimpleText("Your money", "RP1942_F4Small", 12, math.floor(8 * s), C.sub)
            draw.SimpleText(DarkRP.formatMoney(ply:getDarkRPVar("money") or 0), "RP1942_F4Head", 12, h - math.floor(8 * s), C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        end

        local cats = vgui.Create("DScrollPanel", rail)
        cats:Dock(FILL)
        UI.styleScroll(cats)

        ------------------------------------------------------------ the cards (right)
        local right = vgui.Create("Panel", page)
        right:Dock(FILL)

        local top = vgui.Create("DPanel", right)
        top:Dock(TOP)
        top:SetTall(math.floor(34 * s))
        top:DockMargin(0, 0, 0, gap)
        top:SetPaintBackground(false)

        if catalog and maxQty > 1 then
            local box = vgui.Create("DPanel", top)
            box:Dock(RIGHT)
            box:DockMargin(gap, 0, 0, 0)
            box:SetWide(math.floor(250 * s))
            box:DockPadding(2, 2, 2, 2)
            box:SetTooltip("How many of a weapon to buy at once: more than 1 comes as a crate. Shift steps by 5.")
            box.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, C.entry)
                draw.SimpleText("Crate size", "RP1942_F4Body", 10, h / 2, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(qty), "RP1942_F4Head", w - 2 - math.floor(30 * s) - math.floor(32 * s), h / 2, qty > 1 and C.gold or C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            local function step(label, d)
                local b = UI.button(box, label, function()
                    qty = math.Clamp(qty + d * (input.IsKeyDown(KEY_LSHIFT) and 5 or 1), 1, maxQty)
                end)
                b:Dock(RIGHT)
                b:SetWide(math.floor(30 * s))
            end
            step("+", 1)
            local spacer = vgui.Create("Panel", box)
            spacer:Dock(RIGHT)
            spacer:SetWide(math.floor(64 * s))
            step("-", -1)
        end

        local search = UI.textEntry(top, "", function() end)
        search:Dock(FILL)
        search:SetUpdateOnType(true)
        search.PaintOver = function(self, w, h)
            surface.SetDrawColor(self:HasFocus() and C.gold or C.tabHover)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if self:GetValue() == "" and not self:HasFocus() then
                draw.SimpleText("Search everything: name, kind or ammo...", "RP1942_F4Body", 10, h / 2, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        local list = vgui.Create("DScrollPanel", right)
        list:Dock(FILL)
        UI.styleScroll(list)
        list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        list:GetCanvas():DockPadding(gap, gap, gap, gap)

        local function relayout()
            list:GetCanvas():InvalidateLayout(true)
            list:InvalidateLayout(true)
        end

        local function addCard(grid, e)
            local card = vgui.Create("DButton", grid)
            card:SetText("")
            card.hover = 0
            card.entry = e
            card:SetTooltip(e.desc and e.desc ~= "" and (e.name .. "\n" .. e.desc) or e.name)

            local icon = vgui.Create("SpawnIcon", card)
            icon:SetModel(e.model or "models/Items/item_item_crate.mdl")
            icon:SetMouseInputEnabled(false)

            local function barHeight()
                surface.SetFont("RP1942_F4Head");  local _, nameH = surface.GetTextSize("Ag")
                surface.SetFont("RP1942_F4Body");  local _, priceH = surface.GetTextSize("Ag")
                surface.SetFont("RP1942_F4Small"); local _, ammoH = surface.GetTextSize("Ag")
                return nameH, priceH, ammoH, nameH + priceH + (e.ammo and ammoH or 0) + 10
            end
            card.PerformLayout = function(_, w, h)
                local _, _, _, barH = barHeight()
                local size = math.max(24, math.floor(math.min(w - 24, h - barH - 12)))
                icon:SetSize(size, size)
                icon:SetPos((w - size) / 2, 6)
            end
            card.DoClick = function()
                if not ply:canAfford(totalOf(e)) then surface.PlaySound("buttons/button10.wav") return end
                surface.PlaySound("ui/buttonclick.wav")
                e.buy(qty)
            end
            card.Paint = function(c, w, h)
                c.hover = Lerp(FrameTime() * 12, c.hover, c:IsHovered() and 1 or 0)
                draw.RoundedBox(4, 0, 0, w, h, UI.mix(C.card, C.cardHover, c.hover))
            end
            card.PaintOver = function(_, w, h)
                local nameH, _, _, barH = barHeight()
                local y = h - barH
                draw.RoundedBoxEx(4, 0, y, w, barH, Color(0, 0, 0, 150), false, false, true, true)
                draw.SimpleText(UI.fit(e.name, "RP1942_F4Head", w - 12), "RP1942_F4Head", w / 2, y + 4, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                if e.ammo then
                    draw.SimpleText(UI.fit(e.ammo, "RP1942_F4Small", w - 12), "RP1942_F4Small", w / 2, y + 4 + nameH, C.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
                local total = totalOf(e)
                local extra = e.amount and ("  ·  " .. e.amount .. " rounds") or ((e.crate and qty > 1) and ("  ·  ×" .. qty) or "")
                draw.SimpleText(UI.fit(DarkRP.formatMoney(total) .. extra, "RP1942_F4Body", w - 8), "RP1942_F4Body", w / 2, h - 5,
                    ply:canAfford(total) and C.gold or C.unavailable, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end
            return card
        end

        -- Each category: its bar and its grid of cards (only the one picked on
        -- the left shows, or every one with a match while searching)
        local built = {}
        for _, sec in ipairs(sections) do
            local bar = UI.categoryBar(list, sec.title, "", sec.job and C.categoryAlt or nil)
            bar:Dock(TOP)
            bar:DockMargin(0, 0, 0, gap)
            local grid = list:Add("Panel")
            grid:Dock(TOP)
            grid:DockMargin(0, 0, 0, gap * 2)
            local entry = { sec = sec, bar = bar, grid = grid, cards = {}, shown = #sec.entries }
            local hasCrates = false
            for _, e in ipairs(sec.entries) do
                entry.cards[#entry.cards + 1] = addCard(grid, e)
                hasCrates = hasCrates or e.crate == true
            end

            local basePaint = bar.Paint
            bar.Paint = function(b, w, h)
                basePaint(b, w, h)
                local n = entry.shown
                local text = n .. (n == 1 and " item" or " items")
                if hasCrates and qty > 1 then text = text .. "  ·  crates of " .. qty end
                draw.SimpleText(text, "RP1942_F4Small", w - 10, h / 2, C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            grid.PerformLayout = function(g, w)
                local cols = math.max(3, math.floor((w + gap) / (cardW + gap)))
                local cw = math.floor((w - gap * (cols - 1)) / cols)
                local ch = cw
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

        local empty = list:Add("DLabel")
        empty:Dock(TOP)
        empty:DockMargin(gap, gap * 2, gap, 0)
        empty:SetFont("RP1942_F4Body")
        empty:SetTextColor(C.sub)
        empty:SetWrap(true)
        empty:SetAutoStretchVertical(true)
        empty:SetText(#built == 0 and "Nothing is for sale to your job here." or "Nothing matches your search.")
        empty:SetVisible(#built == 0)

        -- show one category (not searching)
        local function showSection(entry)
            current = entry
            lastSection = entry and entry.sec.title
            for _, b in ipairs(built) do
                local on = b == entry
                b.bar:SetVisible(on)
                b.grid:SetVisible(on)
                b.shown = #b.sec.entries
                for _, card in ipairs(b.cards) do card:SetVisible(true) end
                if on then b.grid:InvalidateLayout(true) end
            end
            empty:SetVisible(#built == 0)
            relayout()
            list:GetVBar():SetScroll(0)
        end

        ------------------------------------------------------------ the category buttons
        local function railHeading(text, color)
            local l = cats:Add("DLabel")
            l:Dock(TOP)
            l:DockMargin(math.floor(10 * s), math.floor(6 * s), 0, math.floor(4 * s))
            l:SetFont("RP1942_F4Small")
            l:SetTextColor(color)
            l:SetText(string.upper(text))
            l:SizeToContentsY()
        end
        local function railButton(entry)
            local b = cats:Add("DButton")
            b:SetText("")
            b:Dock(TOP)
            b:DockMargin(0, 0, 0, 2)
            b:SetTall(math.floor(38 * s))
            b.hover = 0
            b.DoClick = function()
                surface.PlaySound("ui/buttonclick.wav")
                if searching then searching = false search:SetValue("") end
                showSection(entry)
            end
            b.Paint = function(btn, w, h)
                local on = not searching and current == entry
                btn.hover = Lerp(FrameTime() * 12, btn.hover, btn:IsHovered() and 1 or 0)
                if on then
                    draw.RoundedBox(4, 0, 0, w, h, C.cardSelected)
                    surface.SetDrawColor(C.gold)
                    surface.DrawRect(0, 0, 3, h)
                elseif btn.hover > 0.01 then
                    draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(C.cardHover, 255 * btn.hover))
                end
                local n = searching and entry.shown or #entry.sec.entries
                local dim = searching and n == 0
                draw.SimpleText(UI.fit(entry.sec.short, "RP1942_F4Body", w - math.floor(56 * s)), "RP1942_F4Body", math.floor(12 * s), h / 2, dim and C.sub or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(n), "RP1942_F4Small", w - math.floor(10 * s), h / 2, C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end

        local job = RPExtraTeams[ply:Team()]
        local headedJob, headedAll = false, false
        for _, entry in ipairs(built) do
            if entry.sec.job and not headedJob then
                railHeading("Your job  ·  " .. (job and job.name or ""), C.available)
                headedJob = true
            elseif not entry.sec.job and not headedAll then
                if headedJob then
                    local line = cats:Add("DPanel")
                    line:Dock(TOP)
                    line:DockMargin(4, gap, 4, gap)
                    line:SetTall(1)
                    line.Paint = function(_, w, h) surface.SetDrawColor(C.tabHover) surface.DrawRect(0, 0, w, h) end
                end
                railHeading("Everyone", C.sub)
                headedAll = true
            end
            railButton(entry)
        end

        -- The search: every word typed has to be in the item's name, category, ammo or description
        search.OnValueChange = function(_, text)
            local words = {}
            for word in string.gmatch(string.lower(text or ""), "%S+") do words[#words + 1] = word end
            if #words == 0 then
                searching = false
                showSection(current)
                return
            end
            searching = true
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
                entry.grid:SetVisible(n > 0)
                entry.grid:InvalidateLayout(true)
                any = any or n > 0
            end
            empty:SetVisible(not any)
            relayout()
            list:GetVBar():SetScroll(0)
        end

        -- start on the category from last time, else the first (your job's)
        local start = built[1]
        for _, entry in ipairs(built) do if entry.sec.title == lastSection then start = entry end end
        showSection(start)
    end,
}
