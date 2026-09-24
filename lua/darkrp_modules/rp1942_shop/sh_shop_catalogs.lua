--[[---------------------------------------------------------------------------
1942 DarkRP - SHOP CATALOGS  (this is the file you edit)

Each catalog is a list of things a dealer can buy. A job uses one with:
    menu = "RP1942_ShopMenu",
    shop = "example",          -- the catalog key below

ITEM FIELDS
    id           unique within the catalog (letters, digits, _)          required
    name         shown in the menu                                        required
    class        weapon or entity class to spawn                          required
    type         "weapon" (spawns as a pickup) or "entity"               required
    price        whole number                                             required
    ammo         text shown in the Ammo section, e.g. "9x19mm"           optional
    description  text under the name                                      optional
    model        model for the picture (and the weapon pickup);           optional
                 needed for stock HL2 weapons, which have no Lua table
    category     groups items under a heading, in the order written      optional

Only plain data here, no function calls: this file loads before the shop
functions exist (module files load in reverse alphabetical order).

Items whose class doesn't exist yet (placeholders) are safe: the purchase is
refused and no money is taken.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.ShopCatalogs = RP1942.ShopCatalogs or {}

RP1942.ShopCatalogs.example = {
    name = "Example Dealer",
    items = {
        -- Period items: placeholder classes from rp1942_core/sh_config.lua.
        -- They show in the menu but can't be bought until the weapon pack is installed.
        {
            id = "p38", category = "Sidearms",
            name = "Walther P38", class = "weapon_rp1942_p38", type = "weapon",
            price = 450, ammo = "9x19mm Parabellum",
            model = "models/weapons/w_pistol.mdl",
            description = "Standard Wehrmacht sidearm. Reliable, eight rounds.",
        },
        {
            id = "k98k", category = "Rifles",
            name = "Karabiner 98k", class = "weapon_rp1942_k98k", type = "weapon",
            price = 1200, ammo = "7.92x57mm Mauser",
            model = "models/weapons/w_irifle.mdl",
            description = "Bolt-action service rifle. Five-round stripper clips.",
        },

        -- Stock Garry's Mod items: these exist on every server, so the
        -- purchase flow can be tested right now. Delete once real items exist.
        {
            id = "test_pistol", category = "Test items",
            name = "HL2 Pistol", class = "weapon_pistol", type = "weapon",
            price = 100, ammo = "9mm (HL2)",
            model = "models/weapons/w_pistol.mdl",
            description = "Stock weapon for testing purchases.",
        },
        {
            id = "test_medkit", category = "Test items",
            name = "Medical Kit", class = "item_healthkit", type = "entity",
            price = 50,
            model = "models/items/healthkit.mdl",
            description = "Stock entity for testing purchases.",
        },
    },
}
