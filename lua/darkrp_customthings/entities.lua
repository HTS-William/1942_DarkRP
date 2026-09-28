--[[---------------------------------------------------------------------------
DarkRP custom entities
---------------------------------------------------------------------------

This file contains your custom entities.
This file should also contain entities from DarkRP that you edited.

Note: If you want to edit a default DarkRP entity, first disable it in darkrp_config/disabled_defaults.lua
    Once you've done that, copy and paste the entity to this file and edit it.

The default entities can be found here:
https://github.com/FPtje/DarkRP/blob/master/gamemode/config/addentities.lua

For examples and explanation please visit this wiki page:
https://darkrp.miraheze.org/wiki/DarkRP:CustomEntityFields

Add entities under the following line:
---------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
Production (rp1942_production). Shown in the F4 Shop tab to these jobs only.
max = how many one player can own at once.
---------------------------------------------------------------------------]]
DarkRP.createEntity("Bread Oven", {
    ent = "rp1942_oven",
    model = "models/props_furniture/kitchen_oven1.mdl",
    price = 800,
    max = 2,
    cmd = "buyoven",
    allowed = { TEAM_BAKER },
    category = "Production",
})

DarkRP.createEntity("Sack of Flour", {
    ent = "rp1942_flour",
    model = "models/props_junk/garbage_bag001a.mdl",
    price = 60,
    max = 4,
    cmd = "buyflour",
    allowed = { TEAM_BAKER },
    category = "Production",
})

DarkRP.createEntity("Wine Barrel", {
    ent = "rp1942_wine_barrel",
    model = "models/props_c17/woodbarrel001.mdl",
    price = 250,
    max = 3,
    cmd = "buywinebarrel",
    allowed = { TEAM_WINEMAKER },
    category = "Production",
})

-- Not placed where you look: built on the nearest free oil site (admins mark
-- them with /addoilsite) and bolted down. Only offered while a site is free.
DarkRP.createEntity("Oil Derrick", {
    ent = "rp1942_oil_rig",
    model = "models/props_c17/FurnitureBoiler001a.mdl",
    price = 1500,
    max = 1,
    cmd = "buyoilderrick",
    allowed = { TEAM_PETROLEUM },
    category = "Production",
    customCheck = function(ply) return GetGlobal2Int("RP1942_OilSitesFree", 0) > 0 end,
    CustomCheckFailMsg = "Every oil site is taken, or none has been marked on this map yet.",
    spawn = function(ply, tr, tbl) return RP1942.buildOilRig(ply) end,
})

DarkRP.createEntity("Factory Line", {
    ent = "rp1942_factory",
    model = "models/props_wasteland/laundry_washer001a.mdl",
    price = 1200,
    max = 1,
    cmd = "buyfactory",
    allowed = { TEAM_FACTORY },
    category = "Production",
})

--[[---------------------------------------------------------------------------
Money printers (rp1942_printers). 3 of each per player at most.
Settings (print amount, heat, upgrades, treasury share): sh_printers.lua
---------------------------------------------------------------------------]]
DarkRP.createEntity("Banking Printer", {
    ent = "rp1942_printer_bank",
    model = "models/props_c17/consolebox01a.mdl",
    price = 2500,
    max = 3,
    cmd = "buybankprinter",
    allowed = { TEAM_BANKER },
    category = "Printers",
})

DarkRP.createEntity("Money Printer", {
    ent = "rp1942_printer_illegal",
    model = "models/props_c17/consolebox01a.mdl",
    price = 2000,
    max = 3,
    cmd = "buymoneyprinter",
    category = "Printers",
    -- Anyone outside the Reich, and not the Banker (who only has the legal one)
    customCheck = function(ply) return RP1942.canOwnIllegalPrinter(ply) end,
    CustomCheckFailMsg = "The Reich and the Banker can't own illegal printers.",
})

