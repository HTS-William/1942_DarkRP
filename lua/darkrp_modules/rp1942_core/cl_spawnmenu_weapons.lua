--[[---------------------------------------------------------------------------
1942 DarkRP - Q menu: only the dealers' weapons (client)

The Weapons tab of the Q menu only lists the weapons a dealer job sells:
the catalogs named in CATALOGS below (rp1942_shop/sh_shop_catalogs.lua):
    blackmarket = Black Market Dealer
    cherkesov   = Cherkesov Dealer
    supplier    = German Supplier
Every other weapon is left out of the menu: the unused MCV guns, Half-Life
2's weapons, DarkRP's tools and other addons' weapons. They still exist, so
staff can hand one out with ulx give, and jobs still spawn with their
loadouts.

Only the menu changes; nothing on the server does. A change shows after a map
change or restart (the Q menu is built once, when you join).
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
    if KEEP[class] then return false end
    if not inUse then buildInUse() end
    return not inUse[class]
end

-- Scripted weapons (MCV, DarkRP, addons): as each is loaded, before it's
-- added to the Q menu's list
hook.Add("PreRegisterSWEP", "RP1942_SpawnMenuWeapons", function(swep, class)
    if isstring(class) and swep.Spawnable and hidden(class) then swep.Spawnable = false end
end)

-- Half-Life 2's weapons (listed by Sandbox) and anything else already in the
-- list. Run now, and once more after joining in case something was added
-- late; if that second pass hides anything, the Q menu is rebuilt.
local function sweep()
    local changed = false
    for class, w in pairs(list.GetForEdit("Weapon")) do
        if w.Spawnable and hidden(class) then w.Spawnable = false changed = true end
    end
    return changed
end
sweep()
hook.Add("InitPostEntity", "RP1942_SpawnMenuWeapons", function()
    if sweep() and IsValid(g_SpawnMenu) then RunConsoleCommand("spawnmenu_reload") end
end)
