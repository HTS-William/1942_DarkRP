--[[---------------------------------------------------------------------------
1942 DarkRP - Q menu: only the Military Conflict: Vietnam weapons the dealers
sell (client)

Only the MCV weapons (mcv_...) are touched. Of those, the Weapons tab of the
Q menu lists just the ones a dealer job sells: the catalogs named in
CATALOGS below (rp1942_shop/sh_shop_catalogs.lua):
    blackmarket = Black Market Dealer
    cherkesov   = Cherkesov Dealer
    supplier    = German Supplier
Every other MCV weapon is left out of the menu. Everything else (Half-Life 2,
DarkRP, other addons) shows as normal.

The hidden ones still exist, so staff can hand one out with ulx give, and
jobs still spawn with their loadouts. Only the menu changes; nothing on the
server does. A change shows after a map change or restart (the Q menu is
built once, when you join).
---------------------------------------------------------------------------]]
local CATALOGS = { blackmarket = true, cherkesov = true, supplier = true }

local KEEP = {
    -- Weapon classes to show even though no dealer sells them, e.g.
    -- ["mcv_binoculars_us"] = true,
}

local inUse

local function buildInUse()
    inUse = {}
    for key, cat in pairs(RP1942.ShopCatalogs or {}) do
        if CATALOGS[key] then
            for _, item in ipairs(cat.items or {}) do
                if item.type == "weapon" and item.class then inUse[item.class] = true end
            end
        end
    end
end

local function hidden(class)
    if not class:find("^mcv_") or KEEP[class] then return false end
    if not inUse then buildInUse() end
    return not inUse[class]
end

-- As each weapon is loaded, before it's added to the Q menu's list
hook.Add("PreRegisterSWEP", "RP1942_SpawnMenuWeapons", function(swep, class)
    if isstring(class) and swep.Spawnable and hidden(class) then swep.Spawnable = false end
end)
