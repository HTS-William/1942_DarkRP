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

local ROW_H = 104
local ICON = 88
local COLOR_CANT_AFFORD = Color(200, 90, 80)

function PANEL:GetCatalog()
    return RP1942.getShopCatalog and RP1942.getShopCatalog(self.job and self.job.shop)
end

function PANEL:GetSubtitle()
    local catalog = self:GetCatalog()
    return catalog and catalog.name or "Shop"
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

    local lastCategory
    for _, item in ipairs(catalog.items or {}) do
        if item.category and item.category ~= lastCategory then
            self:AddSection(item.category)
            lastCategory = item.category
        end
        self:BuildRow(item)
    end
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

    -- Price + Buy (right side)
    local side = row:Add("DPanel")
    side:Dock(RIGHT)
    side:SetWide(120)
    side:DockMargin(8, 8, 8, 8)
    side.Paint = nil

    local price = side:Add("DLabel")
    price:Dock(TOP)
    price:SetFont("RP1942_MenuSection")
    price:SetText(DarkRP.formatMoney(item.price))
    price:SetContentAlignment(6)
    price:SetTall(28)
    price.Think = function(s)
        local money = LocalPlayer():getDarkRPVar("money") or 0
        s:SetTextColor(money >= item.price and theme.text or COLOR_CANT_AFFORD)
    end

    local buy = self:AddButton("Buy", function() self:Request("buy", item.id) end)
    buy:SetParent(side)
    buy:Dock(BOTTOM)
    buy:DockMargin(0, 0, 0, 0)

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
    ammo:SetText("Ammo: " .. (item.ammo or "-"))
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
