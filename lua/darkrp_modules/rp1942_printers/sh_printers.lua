--[[---------------------------------------------------------------------------
1942 DarkRP - money printers (shared config)

Two printers, bought in the F4 Shop (3 of each per player at most):

    Banking Printer   Banker only. Legal. Every print is split with the Reich
                      treasury: 15% at a normal economy (50). A weaker economy
                      sends the treasury more, a stronger one less, so the
                      banker keeps more (see treasuryShare below).
    Money Printer     Illegal. Anyone outside the Reich (and not the Banker).
                      No link to the economy. Reich members can SEIZE it for a
                      reward, or shoot it to pieces; either way its owner is
                      fined (seizeFine), paid into the Reich treasury.

Both print money into their tray (COLLECT takes it; anyone can, so guard it),
heat up while they run and explode at 100 degrees. Switch one OFF to let it
cool; with Cooling at tier 5 it never heats up. Both hum while printing;
the Muffler makes that quieter but never silent.

Upgrades (5 tiers each, bought by the owner from the panel, they stay with
the printer):
    Output    more money per print per tier: Banking Printer +40% (tier 5 =
              300%), Money Printer +35% (tier 5 = 275%)
    Speed     prints sooner
    Cooling   heats up slower; tier 5 stays cool
    Muffler   quieter

Files: sh/sv_printers.lua here; lua/entities/rp1942_printer (the shared
base), rp1942_printer_bank, rp1942_printer_illegal; the F4 Shop entries are
in darkrp_customthings/entities.lua.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.Printers = {
    model     = "models/props_c17/consolebox01a.mdl",
    amount    = 1000,         -- R.M. per print before upgrades
    interval  = 120,          -- seconds between prints before upgrades
    health    = 150,          -- damage it takes before it's destroyed
    seizeReward = 750,        -- what a Reich member gets for seizing (or destroying) an illegal printer
    bankFine    = 1250,       -- what a Reich member pays (into the treasury) for destroying a Banking Printer
    seizeFine   = 1250,       -- what its owner pays when the Reich does; it goes to the Reich treasury
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
        output  = { name = "Output",  desc = "More money per print, per tier", per = { bank = 0.40, illegal = 0.35 }, cost = { 800, 1600, 2800, 4500, 7000 } },
        speed   = { name = "Speed",   desc = "Prints 15 s sooner, per tier",     per = 15,   cost = { 800, 1600, 2800, 4500, 7000 } },
        cooling = { name = "Cooling", desc = "Heats slower; tier 5 stays cool",  per = 0.2,  cost = { 600, 1200, 2200, 3500, 5500 } },
        muffler = { name = "Muffler", desc = "Quieter, but never silent",        per = 0.13, cost = { 300, 600, 1000, 1500, 2200 } },
    },
    order = { "output", "speed", "cooling", "muffler" },
    tiers = 5,

    sound = "ambient/levels/labs/equipment_printer_loop1.wav",
}

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

