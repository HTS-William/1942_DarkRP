--[[---------------------------------------------------------------------------
1942 DarkRP - shop lookups (shared)

    RP1942.getShopCatalog(key)          -> catalog table or nil
    RP1942.getShopItem(key, itemId)     -> item table or nil
    RP1942.getShopItemModel(item)       -> model path for pictures / pickups
    RP1942.getShopPrice(key, item)      -> what it costs right now
    RP1942.getShopEconomyFactor()       -> the economy's price factor (1 = base)
    RP1942.getShopItemAmmo(item)        -> ammo text for the menu

The server always prices and validates from its own copy of the catalog;
the client's copy is only used to draw the menu.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.ShopCatalogs = RP1942.ShopCatalogs or {}

function RP1942.getShopCatalog(key)
    return key and RP1942.ShopCatalogs[key] or nil
end

function RP1942.getShopItem(key, itemId)
    local catalog = RP1942.getShopCatalog(key)
    if not catalog then return nil end

    -- Build the id index on first use
    if not catalog._byId then
        catalog._byId = {}
        for _, item in ipairs(catalog.items or {}) do
            if item.id then catalog._byId[item.id] = item end
        end
    end
    return catalog._byId[itemId]
end

--[[---------------------------------------------------------------------------
Economy pricing (catalogs with economy = true: the German Supplier).
factor = 1 + (normal - economy) * perPoint, kept between min and max, so a
strong economy makes weapons cheaper and a weak one dearer:
    economy 110 -> x0.60     economy 75 -> x0.75     economy 50 -> x1.00
    economy 25  -> x1.25     economy 1  -> x1.49
Prices are rounded to the nearest `round`.
---------------------------------------------------------------------------]]
RP1942.ShopEconomyPricing = {
    normal   = 50,
    perPoint = 0.01,
    min      = 0.60,
    max      = 1.50,
    round    = 10,
}

function RP1942.getShopEconomyFactor()
    local c = RP1942.ShopEconomyPricing
    local econ = RP1942.getEconomy and RP1942.getEconomy() or c.normal
    return math.Clamp(1 + (c.normal - econ) * c.perPoint, c.min, c.max)
end

function RP1942.getShopPrice(key, item)
    local catalog = RP1942.getShopCatalog(key)
    if not (catalog and catalog.economy) then return item.price end
    local r = RP1942.ShopEconomyPricing.round or 1
    return math.max(r, math.floor(item.price * RP1942.getShopEconomyFactor() / r + 0.5) * r)
end

function RP1942.getShopItemAmmo(item)
    if item.ammo then return item.ammo end
    local wep = weapons.Get(item.class)
    local ammo = wep and wep.Primary and wep.Primary.Ammo
    if not ammo or ammo == "" or ammo == "none" then return nil end
    return (language and language.GetPhrase and language.GetPhrase(ammo .. "_ammo") ~= ammo .. "_ammo") and language.GetPhrase(ammo .. "_ammo") or ammo
end

function RP1942.getShopItemModel(item)
    if item.model then return item.model end

    local wep = weapons.Get(item.class)
    if wep and wep.WorldModel and wep.WorldModel ~= "" then return wep.WorldModel end

    local ent = scripted_ents.Get(item.class)
    if ent and ent.Model then return ent.Model end

    return "models/props_junk/cardboard_box004a.mdl"
end
