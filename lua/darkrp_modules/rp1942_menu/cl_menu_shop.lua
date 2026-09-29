--[[---------------------------------------------------------------------------
Generic dealer shop. One class for every dealer; WHAT it sells comes from the
job's catalog in rp1942_shop/sh_shop_catalogs.lua.

jobs.lua:   menu = "RP1942_ShopMenu",
            shop = "example",
Server side of the Buy button: sv_menu_shop.lua -> RP1942.buyShopItem

To specialise a dealer later, subclass this instead of the base:
    vgui.Register("RP1942_BlackMarketMenu", PANEL, "RP1942_ShopMenu")
and override GetSubtitle / BuildRow / etc.
---------------------------------------------------------------------------]]
local PANEL = {}

local ROW_H = 116
local ICON = 88
local COLOR_CANT_AFFORD = Color(200, 90, 80)

function PANEL:GetCatalog()
    return RP1942.getShopCatalog and RP1942.getShopCatalog(self.job and self.job.shop)
end

function PANEL:GetSubtitle()
    local catalog = self:GetCatalog()
    if not catalog then return "Shop" end
    if catalog.economy and RP1942.getShopEconomyFactor then
        local pct = math.Round((RP1942.getShopEconomyFactor() - 1) * 100)
        local econ = RP1942.getEconomy and RP1942.getEconomy() or 50
        return catalog.name .. "  ·  economy " .. econ .. ": " .. (pct == 0 and "base prices" or ((pct > 0 and "+" or "") .. pct .. "%"))
    end
    return catalog.name
end

function PANEL:GetMenuSize()
    return math.Clamp(ScrW() * 0.50, 520, 860), math.Clamp(ScrH() * 0.70, 420, 860)
end

function PANEL:Populate()
    local catalog = self:GetCatalog()
    if not catalog then
        self:AddText("This job has no shop catalog. Set shop = \"...\" on the job in jobs.lua.")
        return
    end

    self:AddSearch()
    self.rows, self.sections = {}, {}
    local lastCategory, section
    for _, item in ipairs(catalog.items or {}) do
        if item.category and item.category ~= lastCategory then
            section = { label = self:AddSection(item.category), rows = {} }
            self.sections[#self.sections + 1] = section
            lastCategory = item.category
        end
        local row = self:BuildRow(item)
        -- What the search matches: name, category, ammo, class and description
        row.searchText = string.lower(table.concat({ item.name or "", item.category or "", item.class or "",
            (RP1942.getShopItemAmmo and RP1942.getShopItemAmmo(item)) or "", item.description or "" }, " "))
        self.rows[#self.rows + 1] = row
        if section then section.rows[#section.rows + 1] = row end
    end

    self.noMatch = self:AddText("Nothing matches your search.")
    self.noMatch:SetVisible(false)
end

--[[---------------------------------------------------------------------------
Search bar: fixed above the list. Every word typed must appear in the item's
name, category, ammo, class or description ("mp40", "smg 9mm", "sniper").
---------------------------------------------------------------------------]]
local SEARCH_H = 32

function PANEL:AddSearch()
    local theme = self.theme
    local box = vgui.Create("DTextEntry", self)
    box:SetFont("RP1942_MenuBody")
    box:SetUpdateOnType(true)
    box:SetPaintBackground(false)
    box.Paint = function(e, w, h)
        surface.SetDrawColor(theme.accent.r, theme.accent.g, theme.accent.b, 160)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(e:HasFocus() and theme.text or theme.accentHover)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        e:DrawTextEntryText(theme.text, theme.accentHover, theme.text)
        if e:GetValue() == "" and not e:HasFocus() then
            draw.SimpleText("Search: name, type or ammo...", "RP1942_MenuBody", 8, h / 2, theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    box.OnValueChange = function(_, v) self:ApplySearch(v) end
    self.search = box
    self.content:DockMargin(0, SEARCH_H + 8, 0, 0)   -- room for the bar above the list
end

function PANEL:PerformLayout(w, h)
    local frame = baseclass.Get("DFrame")   -- the menu base is a DFrame
    if frame and frame.PerformLayout then frame.PerformLayout(self, w, h) end
    if IsValid(self.search) then
        local l, t, r = self:GetDockPadding()
        self.search:SetPos(l, t)
        self.search:SetSize(w - l - r, SEARCH_H)
    end
end

function PANEL:ApplySearch(text)
    local words = {}
    for word in string.gmatch(string.lower(text or ""), "%S+") do words[#words + 1] = word end
    local any = false
    for _, row in ipairs(self.rows or {}) do
        local show = true
        for _, word in ipairs(words) do
            if not string.find(row.searchText, word, 1, true) then show = false break end
        end
        row:SetVisible(show)
        any = any or show
    end
    for _, sec in ipairs(self.sections or {}) do
        local visible = false
        for _, row in ipairs(sec.rows) do if row:IsVisible() then visible = true break end end
        if IsValid(sec.label) then sec.label:SetVisible(visible) end
    end
    if IsValid(self.noMatch) then self.noMatch:SetVisible(not any) end
    self.content:GetCanvas():InvalidateLayout(true)
    self.content:InvalidateLayout(true)
    self.content:GetVBar():SetScroll(0)
end

-- One row: [picture] [name / ammo / description] [price / Buy]
function PANEL:BuildRow(item)
    local theme = self.theme

    local row = self.content:Add("DPanel")
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 6)
    row:SetTall(ROW_H)
    row.Paint = function(s, w, h)
        surface.SetDrawColor(theme.accent.r, theme.accent.g, theme.accent.b, 120)
        surface.DrawRect(0, 0, w, h)
    end

    -- Picture
    local icon = row:Add("SpawnIcon")
    icon:Dock(LEFT)
    icon:DockMargin(8, (ROW_H - ICON) / 2, 8, (ROW_H - ICON) / 2)
    icon:SetWide(ICON)
    icon:SetModel(RP1942.getShopItemModel(item))
    icon:SetTooltip(item.name)

    -- Price + amount + Buy (right side)
    local side = row:Add("DPanel")
    side:Dock(RIGHT)
    side:SetWide(170)
    side:DockMargin(8, 8, 8, 8)
    side.Paint = nil

    local price = side:Add("DLabel")
    price:Dock(TOP)
    price:SetFont("RP1942_MenuSection")
    local key = self.job and self.job.shop
    local function cost() return RP1942.getShopPrice and RP1942.getShopPrice(key, item) or item.price end
    price:SetText(DarkRP.formatMoney(cost()))
    price:SetContentAlignment(6)
    price:SetTall(28)
    price.Think = function(s)
        local now = cost()   -- the Supplier's moves with the economy while the menu is open
        if s.shown ~= now then s.shown = now s:SetText(DarkRP.formatMoney(now)) end
        local money = LocalPlayer():getDarkRPVar("money") or 0
        s:SetTextColor(money >= now and theme.text or COLOR_CANT_AFFORD)
    end

    -- How many: 1 = a single weapon, more = a crate (RP1942.ShopShipments)
    local maxAmount = (RP1942.ShopShipments and RP1942.ShopShipments.maxAmount) or 1
    local amount = 1
    local buy = self:AddButton("Buy", function() self:Request("buy", item.id .. ":" .. amount) end)
    buy:SetParent(side)
    buy:Dock(BOTTOM)
    buy:DockMargin(0, 0, 0, 0)
    buy.Think = function(s)
        local want = amount > 1 and ("Buy crate  ·  " .. DarkRP.formatMoney(cost() * amount)) or "Buy"
        if s:GetText() ~= want then s:SetText(want) end
    end

    if item.type == "weapon" and maxAmount > 1 then
        local qty = side:Add("DPanel")
        qty:Dock(BOTTOM)
        qty:DockMargin(0, 0, 0, 4)
        qty:SetTall(24)
        qty.Paint = nil
        local function step(label, d)
            local b = qty:Add("DButton")
            b:Dock(d < 0 and LEFT or RIGHT)
            b:SetWide(28)
            b:SetText(label)
            b:SetFont("RP1942_MenuBody")
            b:SetTextColor(theme.text)
            b.Paint = function(s, w, h)
                surface.SetDrawColor(s:IsHovered() and theme.accentHover or theme.accent)
                surface.DrawRect(0, 0, w, h)
            end
            b.DoClick = function()
                amount = math.Clamp(amount + d * ((input.IsKeyDown(KEY_LSHIFT) and 5) or 1), 1, maxAmount)
                surface.PlaySound("ui/buttonclick.wav")
            end
        end
        step("-", -1)
        step("+", 1)
        local box = qty:Add("DTextEntry")
        box:Dock(FILL)
        box:DockMargin(4, 0, 4, 0)
        box:SetNumeric(true)
        box:SetFont("RP1942_MenuBody")
        box:SetText("1")
        box:SetUpdateOnType(true)
        box.OnValueChange = function(s, v)
            local n = tonumber(v)
            if n then amount = math.Clamp(math.floor(n), 1, maxAmount) end
        end
        box.Think = function(s)
            if not s:HasFocus() and s:GetValue() ~= tostring(amount) then s:SetText(tostring(amount)) end
        end
        box:SetTooltip("How many (1-" .. maxAmount .. "). More than 1 comes as a crate. Shift + / - steps by 5.")
    end

    -- Text (middle)
    local info = row:Add("DPanel")
    info:Dock(FILL)
    info:DockMargin(0, 8, 0, 8)
    info.Paint = nil

    local name = info:Add("DLabel")
    name:Dock(TOP)
    name:SetFont("RP1942_MenuSection")
    name:SetTextColor(theme.text)
    name:SetText(item.name)
    name:SizeToContentsY()

    local ammo = info:Add("DLabel")
    ammo:Dock(TOP)
    ammo:SetFont("RP1942_MenuBody")
    ammo:SetTextColor(theme.sub)
    ammo:SetText("Ammo: " .. ((RP1942.getShopItemAmmo and RP1942.getShopItemAmmo(item)) or "-"))
    ammo:SizeToContentsY()

    local desc = info:Add("DLabel")
    desc:Dock(FILL)
    desc:DockMargin(0, 4, 0, 0)
    desc:SetFont("RP1942_MenuBody")
    desc:SetTextColor(theme.sub)
    desc:SetWrap(true)
    desc:SetContentAlignment(7)
    desc:SetText(item.description or "")

    return row
end

vgui.Register("RP1942_ShopMenu", PANEL, "RP1942_MenuBase")
