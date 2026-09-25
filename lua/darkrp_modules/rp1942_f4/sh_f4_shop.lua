--[[---------------------------------------------------------------------------
1942 DarkRP - F4 SHOP ITEMS  (this is the file you edit)

Two things are sold in the F4 Shop tab from here:

1. AMMO, automatically. Every weapon the dealers sell (and every job's
   weapons) is checked for the ammo it uses, and a box of each ammo type is
   sold. A box holds `clipsPerBox` of the biggest magazine that uses it, and
   costs a share of that weapon's price (so rockets cost more than pistol
   rounds). Change any ammo type by hand in `overrides`.

2. ITEMS you list below. Each item:
    name         shown on the card                                   required
    type         "entity", "weapon" or "ammo"                        required
    class        the entity / weapon class        (entity, weapon)   required
    ammo         the ammo type, e.g. "pistol"     (ammo)             required
    amount       rounds given                     (ammo)             required
    price        in dollars                                          required
    category     heading it's listed under (default "Supplies")      optional
    model        picture on the card                                 optional
    description  tooltip text                                        optional
    jobs         only these jobs can buy it, by job command,         optional
                 e.g. jobs = { "doctor", "resmedic" }
    max          (entity) how many one player can own at once        optional

DarkRP's own entities.lua and ammo.lua items still show up in the Shop too.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.F4Shop = {
    ammo = {
        enabled       = false,   -- off for now: the HL2 ammo below is sold instead.
                                 -- true = sell ammo for the weapon pack automatically
        category      = "Ammunition",
        clipsPerBox   = 2,       -- a box = this many full magazines
        maxPerBox     = 150,     -- but never more rounds than this
        priceShare    = 0.08,    -- each magazine in the box costs 8% of the weapon's price
        minPrice      = 20,
        model         = "models/Items/BoxMRounds.mdl",
        extraWeapons  = {},      -- more weapon classes to sell ammo for, e.g. { "weapon_pistol" }

        -- By ammo type (the weapon's SWEP.Primary.Ammo). Examples:
        --   ["some_ammo_type"] = { name = "7.92mm Mauser", amount = 30, price = 90 },
        --   ["some_ammo_type"] = { hidden = true },   -- don't sell this one
        -- Type rp1942_listammo in console (server or client) to see every
        -- ammo type the shop found and which weapons use it.
        overrides = {
        },
    },

    items = {
        -- Vanilla Half-Life 2 ammo (the same boxes as the spawn menu's Ammo and Items)
        { name = "Pistol Ammo Box",         type = "ammo", ammo = "Pistol",       amount = 20,  price = 40,  category = "Ammunition", model = "models/items/boxsrounds.mdl" },
        { name = "Pistol Ammo Box (Large)", type = "ammo", ammo = "Pistol",       amount = 100, price = 180, category = "Ammunition", model = "models/items/boxsrounds.mdl" },
        { name = ".357 Ammo Box",           type = "ammo", ammo = "357",          amount = 6,   price = 60,  category = "Ammunition", model = "models/items/357ammo.mdl" },
        { name = ".357 Ammo Box (Large)",   type = "ammo", ammo = "357",          amount = 20,  price = 180, category = "Ammunition", model = "models/items/357ammo.mdl" },
        { name = "SMG Ammo Box",            type = "ammo", ammo = "SMG1",         amount = 45,  price = 60,  category = "Ammunition", model = "models/items/boxmrounds.mdl" },
        { name = "SMG Ammo Box (Large)",    type = "ammo", ammo = "SMG1",         amount = 225, price = 270, category = "Ammunition", model = "models/items/boxmrounds.mdl" },
        { name = "AR2 Magazine",            type = "ammo", ammo = "AR2",          amount = 20,  price = 80,  category = "Ammunition", model = "models/items/combine_rifle_cartridge01.mdl" },
        { name = "AR2 Magazine (Large)",    type = "ammo", ammo = "AR2",          amount = 100, price = 360, category = "Ammunition", model = "models/items/combine_rifle_cartridge01.mdl" },
        { name = "Shotgun Ammo Box",        type = "ammo", ammo = "Buckshot",     amount = 20,  price = 80,  category = "Ammunition", model = "models/items/boxbuckshot.mdl" },
        { name = "Crossbow Bolt Bundle",    type = "ammo", ammo = "XBowBolt",     amount = 6,   price = 120, category = "Ammunition", model = "models/items/crossbowrounds.mdl" },
        { name = "SMG Grenade",             type = "ammo", ammo = "SMG1_Grenade", amount = 1,   price = 150, category = "Ammunition", model = "models/items/ar2_grenade.mdl" },
        { name = "AR2 Energy Orb Ammo",     type = "ammo", ammo = "AR2AltFire",   amount = 1,   price = 200, category = "Ammunition", model = "models/items/combine_rifle_ammo01.mdl" },
        { name = "RPG Rocket",              type = "ammo", ammo = "RPG_Round",    amount = 1,   price = 400, category = "Ammunition", model = "models/weapons/w_missile_closed.mdl" },

        -- More examples - remove the -- in front of a line to switch it on:

        -- { name = "Health Kit", type = "entity", class = "item_healthkit", price = 150,
        --   category = "Supplies", model = "models/items/healthkit.mdl",
        --   description = "Restores some health.", jobs = { "doctor" } },

        -- { name = "Crowbar", type = "weapon", class = "weapon_crowbar", price = 200,
        --   category = "Tools" },
    },
}
