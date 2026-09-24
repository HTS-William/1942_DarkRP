--[[---------------------------------------------------------------------------
1942 DarkRP - economy (shared)

The economy is one whole number from 1 to 110, owned by the server and
automatically synced to every client.

FOR OTHER SYSTEMS (works on server and client):
    RP1942.getEconomy()             -> current value, e.g. 63
    RP1942.getEconomyTier()         -> { id = "average", min = 50, text = "..." }
    RP1942.getEconomyTier(80)       -> tier for any value

SERVER ONLY (sv_economy.lua):
    RP1942.setEconomy(value, reason)
    RP1942.addEconomy(delta, reason)
    hook "RP1942_EconomyChanged" (old, new, reason)

A boundary value belongs to the HIGHER tier: 25 is "downturn", 50 is
"average", and so on. Each tier runs from its `min` up to the next tier's.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Economy = RP1942.Economy or {}
local E = RP1942.Economy

E.MIN   = 1
E.MAX   = 110
E.START = 50              -- value when the server starts
E.KEY   = "rp1942_economy"

-- Ascending by min
E.Tiers = {
    { id = "poor",        min = 1,   text = "The economy is poor right now" },
    { id = "downturn",    min = 25,  text = "The economy is in downturn" },
    { id = "average",     min = 50,  text = "The economy is average" },
    { id = "good",        min = 75,  text = "The economy is good" },
    { id = "flourishing", min = 100, text = "The economy is flourishing" },
}

function RP1942.getEconomy()
    return GetGlobal2Int(E.KEY, E.START)
end

function RP1942.getEconomyTier(value)
    value = value or RP1942.getEconomy()
    local tier = E.Tiers[1]
    for _, t in ipairs(E.Tiers) do
        if value >= t.min then tier = t end
    end
    return tier
end
