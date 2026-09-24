--[[---------------------------------------------------------------------------
1942 DarkRP - shop lookups (shared)

    RP1942.getShopCatalog(key)          -> catalog table or nil
    RP1942.getShopItem(key, itemId)     -> item table or nil
    RP1942.getShopItemModel(item)       -> model path for pictures / pickups

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

function RP1942.getShopItemModel(item)
    if item.model then return item.model end

    local wep = weapons.Get(item.class)
    if wep and wep.WorldModel and wep.WorldModel ~= "" then return wep.WorldModel end

    local ent = scripted_ents.Get(item.class)
    if ent and ent.Model then return ent.Model end

    return "models/props_junk/cardboard_box004a.mdl"
end
