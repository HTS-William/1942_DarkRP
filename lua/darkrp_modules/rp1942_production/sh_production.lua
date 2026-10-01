--[[---------------------------------------------------------------------------
1942 DarkRP - production (shared config)

Producing jobs make GOODS: small physical items that can be carried, pocketed,
handed over, eaten or drunk, and sold. Every good has a QUALITY of 1-3 stars,
earned by how well it was made, and better goods sell for more.

Ovens, wine barrels and markets have interactive panels: look at a button on
the panel and press E.

    Baker       buys an oven and sacks of flour. Push sacks into the oven (it
                holds 3 in a queue). While it bakes, keep the fire in the green
                with STOKE FIRE: the longer it stays there, the more loaves and
                the better the bread. Finished bread waits inside: COLLECT BREAD.
    Winemaker   buys a wine barrel and presses START. While it ferments, the
                barrel calls for stirring a few times: STIR before the timer
                runs out. Every stir it gets raises the vintage. Then BOTTLE.
    Petroleum   buys an oil derrick. It isn't placed by hand: it's built on a
    Producer    free OIL SITE (placed by admins with !addoilsite) and can't be
                moved. It pumps on its own. With the valve shut the pressure
                climbs; turn the wheel to open it and the pressure falls. Keep
                it in the green: more time there = more canisters of crude and
                more stars. FILL CANISTERS when the tank is full.
    Factory     buys a factory line. It runs on its own, but halts twice a
    Owner       run with a fault (BELT, BOILER or FUSE): press the matching
                repair button. The less downtime, the better the run, and the
                better the odds of rare goods (clocks, radios). COLLECT.

Selling:
    - At a MARKET (placed by admins with !addmarket). Its board shows today's
      prices, with trend arrows and one good "in demand" for a bonus. SELL a
      kind of good from your pocket, SELL EVERYTHING, or push goods into it.
      Prices are scaled by the economy and quality, taxed like wages, and every
      market sale nudges the economy bar up a little.
    - To other players, privately, for whatever they'll pay (/give, trades).
      Private sales don't move the economy.

Eating / drinking: hold Shift and press E on a good. E alone picks it up.

Files:
    sh_production.lua     this config
    sv_production.lua     selling, quality, demand, the economy nudge, markets (!addmarket)
    cl_production.lua     the interactive panels, labels and the drunk effect
    sv_oil_sites.lua      oil sites (!addoilsite) and building derricks on them
    sv/cl_prodspawn.lua   the staff production spawner (!prodspawn)
    lua/entities/rp1942_good, rp1942_flour, rp1942_oven, rp1942_wine_barrel, rp1942_market,
        rp1942_oil_rig, rp1942_factory, rp1942_scrap
    darkrp_customthings/entities.lua   the F4 shop entries (prices, limits, jobs)
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

--[[---------------------------------------------------------------------------
Goods. value = market price of a 2-star good before the economy and tax.
economy = how much one market sale pushes the economy bar (it only moves in
whole points, so 0.1 = one point per ten sales).
eat: heal = health restored, drunk = seconds of blurry vision.
model: one model, or a list for a random one per item.
rarity: factory goods only, shown on their label ("common", "rare"...).
---------------------------------------------------------------------------]]
RP1942.Goods = {
    bread = {
        name    = "Loaf of Bread",
        -- A list = each loaf picks one at random (and keeps it)
        model   = {
            "models/props_misc/bread-1.mdl",
            "models/props_misc/bread-2.mdl",
            "models/props_misc/bread-3.mdl",
            "models/props_misc/bread-4.mdl",
        },
        value   = 75,
        economy = 0.10,
        eat     = { verb = "eat", heal = 15 },
    },
    wine = {
        name    = "Bottle of Wine",
        model   = "models/props_junk/GlassBottle01a.mdl",
        value   = 130,
        economy = 0.15,
        eat     = { verb = "drink", heal = 5, drunk = 25 },
    },

    -- Petroleum Producer
    oil = {
        name    = "Barrel of Crude Oil",
        model   = "models/props_c17/oildrum001.mdl",
        value   = 1000,   -- the derrick needs tending the whole time (not AFK-able)
        economy = 0.15,
    },

    -- Factory Owner (which one comes out is rolled: RP1942.Production.factory.odds)
    rations = {
        name    = "Tinned Rations",
        model   = "models/props_junk/garbage_metalcan001a.mdl",
        value   = 60,
        economy = 0.08,
        rarity  = "common",
        eat     = { verb = "eat", heal = 10 },
    },
    boots = {
        name    = "Pair of Boots",
        model   = "models/props_junk/Shoe001a.mdl",
        value   = 70,
        economy = 0.08,
        rarity  = "common",
    },
    pot = {
        name    = "Cooking Pot",
        model   = "models/props_interiors/pot02a.mdl",
        value   = 120,
        economy = 0.12,
        rarity  = "uncommon",
    },
    kettle = {
        name    = "Kettle",
        model   = "models/props_interiors/pot01a.mdl",
        value   = 130,
        economy = 0.12,
        rarity  = "uncommon",
    },
    clock = {
        name    = "Alarm Clock",
        model   = "models/props_c17/clock01.mdl",
        value   = 250,
        economy = 0.20,
        rarity  = "rare",
    },
    radio = {
        name    = "Radio Set",
        model   = "models/props_lab/citizenradio.mdl",
        value   = 450,
        economy = 0.30,
        rarity  = "very rare",
        radio   = true,     -- a working radio: E tunes it (rp1942_radio module), Shift+E carries it
        noExpire = true,    -- never vanishes when left lying around
    },
}

-- Quality: price multiplier and name for 1, 2 and 3 stars
RP1942.Quality = {
    [1] = { mult = 0.75, name = "poor" },
    [2] = { mult = 1.00, name = "fine" },
    [3] = { mult = 1.30, name = "excellent" },
}

RP1942.Production = {
    oven = {
        model     = "models/props_furniture/kitchen_oven1.mdl",
        bakeTime  = 180,              -- seconds per batch
        queue     = 3,                -- sacks of flour it holds waiting
        good      = "bread",
        -- The fire: 0-100. It cools while baking; STOKE FIRE adds heat.
        -- Below cold = too cold, above hot = burning, between = just right.
        heat      = { start = 60, cool = 0.6, stoke = 22, cold = 35, hot = 80 },
        -- Share of the bake spent in the green -> loaves (and stars)
        grades    = { { share = 0.8, loaves = 3 }, { share = 0.5, loaves = 2 }, { share = 0, loaves = 1 } },
    },
    flour = {
        model     = "models/props_junk/garbage_bag001a.mdl",
    },
    scrap = {   -- the factory line's material (price and limit: darkrp_customthings/entities.lua)
        model     = "models/gibs/metal_gib4.mdl",
    },
    wine = {
        model     = "models/props_c17/woodbarrel001.mdl",
        time      = 240,              -- seconds to ferment
        bottles   = 3,
        good      = "wine",
        stirs     = 3,                -- times it calls for stirring
        stirWindow = 15,              -- seconds you have to stir each time
        -- stirs made -> stars: all of them 3, all but one 2, fewer 1
    },

    -- Petroleum Producer. The derrick is built on a free oil site and can't be moved.
    oil = {
        model     = "models/props_c17/FurnitureBoiler001a.mdl",   -- placeholder until the real prop
        pumpTime  = 360,              -- seconds to fill the tank
        good      = "oil",
        -- Well pressure 0-100. With the valve closed it climbs (rise per
        -- second); turning the wheel opens the valve and it falls (fall per
        -- second). Both speeds wander by up to +-vary every changeEvery seconds.
        pressure  = { start = 40, low = 35, high = 70, rise = 0.8, fall = 1.4, vary = 0.3, changeEvery = { 20, 40 } },
        wheelTime = 1.2,              -- seconds the wheel takes to turn (it can't be spun faster)
        -- Left in the red too long: after warnAfter seconds (in a row) an
        -- alarm sounds; after explodeAfter it blows up (and is gone).
        -- Switching it off pauses the count. damage/radius: the blast.
        blowout   = { warnAfter = 15, explodeAfter = 40, damage = 180, radius = 350 },
        -- Share of the pumping spent in the green -> canisters (and stars)
        grades    = { { share = 0.8, count = 3 }, { share = 0.5, count = 2 }, { share = 0, count = 1 } },
        siteAdmin = function(ply) return ply:IsSuperAdmin() end,   -- who may !addoilsite etc. without ULX (with ULX: its Groups tab)
    },

    -- Factory Owner. The line runs on scrap metal: one load per run.
    factory = {
        model     = "models/props_mining/elevator_winch_empty.mdl",
        hopper    = 4,                -- loads of scrap it holds waiting
        runTime   = 300,              -- seconds of running per run (halts don't count)
        items     = 3,                -- goods per run (one load of scrap)
        halts     = 2,                -- faults per run
        wrongFix  = 10,               -- seconds of downtime added for pressing the wrong repair
        -- Downtime (seconds halted this run) -> stars
        grades    = { { downtime = 15, stars = 3 }, { downtime = 45, stars = 2 }, { downtime = math.huge, stars = 1 } },
        -- Odds of each rarity, by the run's stars (they needn't add up to 100)
        odds      = {
            [1] = { common = 75, uncommon = 20, rare = 5,  ["very rare"] = 0 },
            [2] = { common = 55, uncommon = 30, rare = 12, ["very rare"] = 3 },
            [3] = { common = 40, uncommon = 35, rare = 19, ["very rare"] = 6 },
        },
    },

    goodsLifetime = 900,              -- goods left lying around vanish after this many seconds (0 = never)
    labelDistance = 350,              -- panels are drawn up to this far away
    useDistance   = 120,              -- and can be used (look + E) up to this close

    market = {
        model       = "models/props_furniture/inn_mailbox1.mdl",   -- the market's mailbox
        demandBonus = 0.20,           -- the good in demand sells for 20% more
        demandEvery = 3600,           -- seconds between new "in demand" picks (and trend resets)
        -- Who may place markets with !addmarket and !removemarket when ULX
        -- isn't running (with ULX: per rank, ULX menu > Groups > 42Bros)
        adminCheck  = function(ply) return ply:IsSuperAdmin() end,
    },
}

--[[---------------------------------------------------------------------------
Panels mounted ON props (see cl_production.lua for every option, and the
rp1942_panel_* console commands to fine-tune one in game and print its line).
A class that isn't listed gets a panel floating above the prop instead.
---------------------------------------------------------------------------]]
RP1942.PanelSpots = RP1942.PanelSpots or {}
-- kitchen_oven1: 31 deep x 70 wide x 50 tall, origin at the back. The brass
-- plate sits on the front of the oven (tuned in game with rp1942_panel_*).
RP1942.PanelSpots.rp1942_oven = { mount = "face", face = "front", width = 0.46, top = 0.95, size = 0.86, nudge = { 17.5, 0.0, 0.0 } }
-- The factory line's plate. NOT TUNED YET for the winch model: place it in
-- game with the rp1942_panel_* commands and paste the line they print here.
RP1942.PanelSpots.rp1942_factory = { mount = "backguard", face = "front", width = 0.45, top = 0.95, size = 1.00 }
-- The oil derrick's plate (tuned in game with rp1942_panel_*)
RP1942.PanelSpots.rp1942_oil_rig = { mount = "backguard", face = "front", width = 0.45, top = 0.95, size = 1.33, nudge = { -9.0, -41.0, 29.0 } }
-- The market's board, on its mailbox (tuned in game with rp1942_panel_*)
RP1942.PanelSpots.rp1942_market = { mount = "backguard", face = "front", width = 0.45, top = 0.95, size = 1.00, nudge = { 0.0, -50.0, 12.0 } }

-- The good id of an entity, or nil
function RP1942.goodOf(ent)
    return IsValid(ent) and ent:GetClass() == "rp1942_good" and ent.GetGood and ent:GetGood() or nil
end

-- The good in demand right now ("" = none yet)
function RP1942.goodInDemand()
    return GetGlobal2String("RP1942_Demand", "")
end

--[[---------------------------------------------------------------------------
What one good sells for at the market right now, after the economy, quality
and demand, before tax. Works on server and client.
---------------------------------------------------------------------------]]
function RP1942.marketPrice(goodId, quality)
    local good = RP1942.Goods[goodId]
    if not good then return 0 end
    local q = RP1942.Quality[quality or 2] or RP1942.Quality[2]
    local value = good.value * q.mult
    if RP1942.goodInDemand() == goodId then value = value * (1 + RP1942.Production.market.demandBonus) end
    return RP1942.applyEconomy and RP1942.applyEconomy(value, "goods_sale") or math.floor(value)
end

-- Price change since the last demand pick, as a fraction (+0.06 = up 6%)
function RP1942.marketTrend(goodId)
    local snap = GetGlobal2Int("RP1942_EconSnapshot", 0)
    if snap <= 0 or not RP1942.getEconomy then return 0 end
    local now = RP1942.getEconomy()
    local trend = now / snap - 1
    local demand = RP1942.goodInDemand()
    if demand == goodId then trend = trend + RP1942.Production.market.demandBonus end
    return trend
end

-- "excellent", "fine", "poor" (panels draw the stars themselves)
function RP1942.qualityName(quality)
    local q = RP1942.Quality[math.Clamp(quality or 2, 1, 3)]
    return q and q.name or "fine"
end

-- The factory's faults: id -> what the lamp and the repair button say
RP1942.FactoryFaults = {
    { id = "belt",   lamp = "BELT",   button = "RETHREAD BELT" },
    { id = "boiler", lamp = "BOILER", button = "VENT BOILER" },
    { id = "fuse",   lamp = "FUSE",   button = "REPLACE FUSE" },
}




