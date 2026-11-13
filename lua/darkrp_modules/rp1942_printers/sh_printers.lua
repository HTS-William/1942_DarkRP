--[[---------------------------------------------------------------------------
42Bros - money printers (shared config)

Three printers, bought in the F4 Shop (3 Banking Printers, 2 Money Printers
and 1 Counterfeit Press per player at most):

    Banking Printer   Banker only. Legal. Every print is split with the Reich
                      treasury: 15% at a normal economy (50). A weaker economy
                      sends the treasury more, a stronger one less, so the
                      banker keeps more (see treasuryShare below).
    Money Printer     Illegal. Anyone outside the Reich (and not the Banker).
                      No link to the economy. Reich members can SEIZE it for a
                      reward, or shoot it to pieces; either way its owner is
                      fined (seizeFine), paid into the Reich treasury.
                      Cooling never stops it heating.
    Counterfeit Press The expensive illegal one (R.M.25,000), close to what
                      the printers made before the re-balance. The same rules
                      as the Money Printer, with a bigger fine and reward when
                      the Reich seizes it.

What they make (Nov 2026: one player made R.M.1.15m in 5 h, so they were
re-balanced around what a FULLY UPGRADED printer makes in an hour):

                      start            fully upgraded (Output 5, Speed 5)
    Banking Printer   1,250 / 165 s    3,750 / 90 s  = R.M.150,000 an hour
                      (~27,000 an h)   (before the treasury's share)
    Money Printer     1,250 / 165 s    2,500 / 90 s  = R.M.100,000 an hour
                      (~27,000 an h)
    Counterfeit Press 1,000 / 120 s    2,750 / 45 s  = R.M.220,000 an hour
                      (~30,000 an h)   (the old Money Printer's numbers)

The tray holds a quarter of an hour of that (trayHours): R.M.37,500 in a
Banking Printer, R.M.25,000 in a Money Printer, R.M.55,000 in a Counterfeit
Press. When it's full the printer
stops printing until someone collects, so neither can be left running all
night. Change amount / interval / the upgrades and the tray follows.

Both print money into their tray (COLLECT takes it; anyone can, so guard it),
heat up while they run and explode at 100 degrees. Switch one OFF to let it
cool; with Cooling at tier 5 the Banking Printer never heats up (the Money
Printer still does, slowly). Both hum while printing; the Muffler makes that
quieter but never silent.

A setting given as { bank = ..., illegal = ... } differs by printer; a plain
number is the same for both.

Upgrades (5 tiers each, bought by the owner from the panel, they stay with
the printer):
    Output    more money per print per tier: Banking Printer +40% (tier 5 =
              300%), Money Printer +20% (tier 5 = 200%)
    Speed     prints 15 s sooner per tier
    Cooling   heats up slower; tier 5 stays cool (Banking Printer), heats at a
              quarter of the speed (Money Printer)
    Muffler   quieter
The Counterfeit Press's upgrades cost three times as much (upgradeCostMult).

Files: sh/sv_printers.lua here; lua/entities/rp1942_printer (the shared
base), rp1942_printer_bank, rp1942_printer_illegal, rp1942_printer_press;
the F4 Shop entries are
in darkrp_customthings/entities.lua.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.Printers = {
    model     = "models/props_c17/consolebox01a.mdl",
    amount    = { bank = 1250, illegal = 1250, press = 1000 },  -- R.M. per print before upgrades
    interval  = { bank = 165,  illegal = 165,  press = 120 },   -- seconds between prints before upgrades
    -- Most the tray holds, in hours of a fully upgraded printer's output
    -- (0.25 = a quarter of an hour: 37,500 / 25,000). Full, it stops printing
    -- until someone collects. (trayMax = { bank = ..., illegal = ... } sets
    -- it in R.M. instead.)
    trayHours = 0.25,
    health    = 150,          -- damage it takes before it's destroyed
    seizeReward = { illegal = 750, press = 2500 },    -- what a Reich member gets for seizing (or destroying) an illegal printer
    bankFine    = 1250,       -- what a Reich member pays (into the treasury) for destroying a Banking Printer
    seizeFine   = { illegal = 1250, press = 5000 },   -- what its owner pays when the Reich does; it goes to the Reich treasury
                              -- (as much as they have, if they have less)

    -- Heat, 0-100. It rises while the printer runs and falls while it's off.
    heat = {
        rise  = 0.4,          -- degrees per second while running, at Cooling tier 0
        cool  = 2.0,          -- degrees per second while switched off
        warn  = 80,           -- smokes, warns the owner
        blast = { damage = 90, radius = 260 },
    },

    -- Banking Printer: the treasury's share of each print.
    -- share = base * (normal economy / economy), kept between min and max.
    --   economy 25 -> 30%   economy 50 -> 15%   economy 100 -> 7.5%
    treasury = { base = 0.15, normal = 50, min = 0.05, max = 0.30 },

    -- Upgrades: per-tier effect and the price of each tier (1-5)
    upgrades = {
        -- Output: extra money per print per tier, by printer (bank = Banking Printer)
        output  = { name = "Output",  desc = "More money per print, per tier", per = { bank = 0.40, illegal = 0.20, press = 0.35 }, cost = { 800, 1600, 2800, 4500, 7000 } },
        speed   = { name = "Speed",   desc = "Prints 15 s sooner, per tier",     per = 15,   cost = { 800, 1600, 2800, 4500, 7000 } },
        cooling = { name = "Cooling", desc = { bank = "Heats slower; tier 5 stays cool", illegal = "Heats slower (it never stays cool)", press = "Heats slower (it never stays cool)" },
                    per = { bank = 0.2, illegal = 0.15, press = 0.15 }, cost = { 600, 1200, 2200, 3500, 5500 } },
        muffler = { name = "Muffler", desc = "Quieter, but never silent",        per = 0.13, cost = { 300, 600, 1000, 1500, 2200 } },
    },
    -- Upgrade prices times this, by printer: the Counterfeit Press's cost 3x
    -- (all four maxed: R.M.156,000 instead of 52,000)
    upgradeCostMult = { press = 3 },
    order = { "output", "speed", "cooling", "muffler" },
    tiers = 5,

    sound = "ambient/levels/labs/equipment_printer_loop1.wav",
}

-- What a fully upgraded printer of this kind ("bank" / "illegal") prints in
-- an hour (before the Banking Printer's treasury share)
function RP1942.printerMaxPerHour(kind)
    local P = RP1942.Printers
    local function val(v, d) if istable(v) then v = v[kind] end return v == nil and d or v end
    local amount = val(P.amount, 1000) * (1 + val(P.upgrades.output.per, 0.25) * P.tiers)
    local interval = math.max(val(P.interval, 120) - val(P.upgrades.speed.per, 15) * P.tiers, 10)
    return math.floor(amount * 3600 / interval)
end

-- The treasury's share of a Banking Printer's print right now (0-1)
function RP1942.printerTreasuryShare()
    local t = RP1942.Printers.treasury
    local econ = RP1942.getEconomy and RP1942.getEconomy() or t.normal
    return math.Clamp(t.base * t.normal / math.max(econ, 1), t.min, t.max)
end

-- May this player own an illegal printer? (not the Reich, not the Banker)
function RP1942.canOwnIllegalPrinter(ply)
    if not IsValid(ply) then return false end
    if RP1942.isFaction and RP1942.isFaction(ply, "reich") then return false end
    if TEAM_BANKER and ply:Team() == TEAM_BANKER then return false end
    return true
end

-- The panel lies flat on top of the printer, readable from its front
-- (fine-tune in game with the rp1942_panel_* commands, then paste the line here)
RP1942.PanelSpots = RP1942.PanelSpots or {}
RP1942.PanelSpots.rp1942_printer_bank    = { mount = "top", face = "front", width = 0.95 }
RP1942.PanelSpots.rp1942_printer_illegal = { mount = "top", face = "front", width = 0.95 }
RP1942.PanelSpots.rp1942_printer_press   = { mount = "top", face = "front", width = 0.95 }

-- The illegal printers (the Reich seizes them; the Reich and the Banker can't own them)
RP1942.IllegalPrinters = { rp1942_printer_illegal = true, rp1942_printer_press = true }

