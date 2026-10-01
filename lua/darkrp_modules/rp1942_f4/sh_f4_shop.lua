--[[---------------------------------------------------------------------------
1942 DarkRP - F4 SHOP ITEMS  (this is the file you edit)

Two things are sold in the F4 Shop tab from here:

1. AMMO, automatically. Every weapon the dealers sell (and every job's
   weapons) is checked for the ammo it uses, and a box of each period ammo
   type (rp1942_core/sh_ammo.lua) is sold. Half-Life 2 ammo isn't. A box holds `clipsPerBox` of the biggest magazine that uses it, and
   costs a share of that weapon's price (so rockets cost more than pistol
   rounds). Change any ammo type by hand in `overrides`.

2. ITEMS you list below. Each item:
    name         shown on the card                                   required
    type         "entity", "weapon", "ammo" or "good"                required
    good         (good) the good's id from rp1942_production, e.g. "radio";
                 quality 1-3 (default 3), markup x the market price (the
                 price is then never below `price`)
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
        enabled       = true,    -- sell a box of each period ammo type the weapons use
        onlyListed    = true,    -- only the types in `overrides` (no Half-Life 2 ammo)
        category      = "Ammunition",
        clipsPerBox   = 2,       -- for a type without an amount below: this many full magazines
        maxPerBox     = 150,     -- but never more rounds than this
        priceShare    = 0.08,    -- and each magazine costs 8% of the dearest weapon using it
        minPrice      = 20,
        model         = "models/Items/BoxMRounds.mdl",
        extraWeapons  = {},      -- more weapon classes to sell ammo for, e.g. { "mcv_luger" }

        -- By ammo type (the weapon's SWEP.Primary.Ammo; the names come from
        -- RP1942.AmmoTypes in rp1942_core/sh_ammo.lua). amount = rounds per
        -- box, price = per box. { hidden = true } = don't sell it.
        -- A type is only sold if at least one weapon on the server uses it.
        -- Type rp1942_listammo in console to see every ammo type the shop
        -- found and which weapons use it.
        overrides = {
            -- German
            ["792x33mmkurz"]        = { amount = 60, price = 180, model = "models/Items/BoxMRounds.mdl" },
            ["792x57mm"]            = { amount = 30, price = 120, model = "models/Items/BoxMRounds.mdl" },
            ["9mmluger"]            = { amount = 64, price = 120, model = "models/Items/BoxSRounds.mdl" },
            ["380acp"]              = { amount = 36, price = 60,  model = "models/Items/BoxSRounds.mdl" },
            ["763mauser"]           = { amount = 40, price = 90,  model = "models/Items/BoxSRounds.mdl" },
            ["8mmnambu"]            = { amount = 32, price = 70,  model = "models/Items/BoxSRounds.mdl" },
            ["145x114"]             = { amount = 10, price = 400, model = "models/Items/BoxMRounds.mdl" },
            ["panzerschreckrocket"] = { amount = 1,  price = 900, model = "models/weapons/w_missile_closed.mdl" },
            ["flarecartridge"]      = { amount = 4,  price = 100, model = "models/Items/BoxSRounds.mdl" },
            -- American, British, French, Soviet
            ["45acp"]               = { amount = 60, price = 120, model = "models/Items/BoxSRounds.mdl" },
            ["30cal"]               = { amount = 40, price = 140, model = "models/Items/BoxMRounds.mdl" },
            ["30carbine"]           = { amount = 60, price = 120, model = "models/Items/BoxMRounds.mdl" },
            ["25acp"]               = { amount = 24, price = 40,  model = "models/Items/BoxSRounds.mdl" },
            ["32acp"]               = { amount = 32, price = 50,  model = "models/Items/BoxSRounds.mdl" },
            ["38special"]           = { amount = 24, price = 60,  model = "models/Items/357ammo.mdl" },
            ["bazookarocket"]       = { amount = 1,  price = 900, model = "models/weapons/w_missile_closed.mdl" },
            ["303brit"]             = { amount = 60, price = 150, model = "models/Items/BoxMRounds.mdl" },
            ["765french"]           = { amount = 32, price = 60,  model = "models/Items/BoxSRounds.mdl" },
            ["75french"]            = { amount = 50, price = 130, model = "models/Items/BoxMRounds.mdl" },
            ["8mmfrench"]           = { amount = 18, price = 60,  model = "models/Items/357ammo.mdl" },
            ["762tokarev"]          = { amount = 70, price = 120, model = "models/Items/BoxSRounds.mdl" },
            ["762soviet"]           = { amount = 40, price = 140, model = "models/Items/BoxMRounds.mdl" },
            ["762nagantr"]          = { amount = 28, price = 50,  model = "models/Items/357ammo.mdl" },
            ["762x39"]              = { amount = 75, price = 140, model = "models/Items/BoxMRounds.mdl" },
            ["buckshot"]            = { amount = 16, price = 80,  model = "models/Items/BoxBuckshot.mdl" },
            -- Equipment. always = sold even if no weapon on sale uses it.
            -- One mcv_grenade refills ANY grenade (frag, HE, smoke, stick).
            -- Refills cost what the explosive itself costs at the dealers, so
            -- they can't be used to stock up cheaply. (Smoke grenades are
            -- cheaper bought new.)
            ["mcv_grenade"]           = { amount = 1,   price = 2500,  always = true, model = "models/weapons/w_grenade.mdl" },
            ["mcv_molotov"]           = { amount = 1,   price = 2000,  always = true, model = "models/props_junk/GlassBottle01a.mdl" },
            ["mcv_mine"]              = { amount = 1,   price = 4500, always = true, model = "models/Items/BoxMRounds.mdl" },
            ["mcv_explosive_charge"]  = { amount = 1,   price = 4000, always = true, model = "models/Items/BoxMRounds.mdl" },
            ["mcv_flamethrower_fuel"] = { amount = 100, price = 1500, always = true, model = "models/props_junk/gascan001a.mdl" },
            ["mcv_crossbowbolt"]      = { amount = 6,   price = 120,  always = true, model = "models/Items/CrossbowRounds.mdl" },
            ["mcv_flareround"]        = { amount = 4,   price = 100,  always = true, model = "models/Items/BoxSRounds.mdl" },
        },
    },

    items = {
        -- Fire extinguisher (Workshop "Fire Extinguisher" by Rubat, id 104607228,
        -- mounted on the server). Puts out the spreading fire from molotovs
        -- and explosions (rp1942_fire). This is the never-empty version;
        -- weapon_extinguisher is the one with 500 sprays that refills in water.
        { name = "Fire Extinguisher", type = "weapon", class = "weapon_extinguisher_infinite", price = 1500,
          category = "Tools", model = "models/weapons/w_fire_extinguisher.mdl",
          description = "Puts out fires. Spray at the flames. Never runs out. Each fire you put out pays a small reward." },

        -- The factory's Radio Set, as a working radio (E tunes it, Shift+E carries
        -- it, sells at the market like any good). Its price follows the market:
        -- markup x what the market pays for an excellent one right now, never
        -- below `price`. So buying one to sell it always loses money.
        { name = "Radio Set", type = "good", good = "radio", quality = 3, markup = 1.5, price = 600, max = 1,
          category = "Supplies", model = "models/props_lab/citizenradio.mdl",
          description = "A wireless set. Press E on it to tune in a station or any stream link; Shift+E to carry it." },

        -- Padlock (rp1942_padlocks): fit it to a prop you own and the prop becomes
        -- a door. Our answer to keypads: no codes.
        { name = "Padlock", type = "weapon", class = "rp1942_padlock_kit", price = 250,
          category = "Tools", model = "models/props_wasteland/prison_padlock001a.mdl",
          description = "Fit it to a prop you own: the prop becomes a door that opens for you and whoever you let in (Shift+E on the lock)." },

        -- More examples - remove the -- in front of a line to switch it on:

        -- { name = "Health Kit", type = "entity", class = "item_healthkit", price = 150,
        --   category = "Supplies", model = "models/items/healthkit.mdl",
        --   description = "Restores some health.", jobs = { "doctor" } },

        -- { name = "Crowbar", type = "weapon", class = "weapon_crowbar", price = 200,
        --   category = "Tools" },
    },
}
