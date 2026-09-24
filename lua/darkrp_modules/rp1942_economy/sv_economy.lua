--[[---------------------------------------------------------------------------
1942 DarkRP - economy (server)

The only place the economy value is changed. Everything that changes it
(the Führer's menu, later: taxes, supply trains, air raids...) goes through
setEconomy / addEconomy, so the value is always clamped to 1-110 and every
change fires the same hook.
---------------------------------------------------------------------------]]
local E = RP1942.Economy

-- Returns the new value (clamped). Fires RP1942_EconomyChanged if it moved.
function RP1942.setEconomy(value, reason)
    value = math.Clamp(math.Round(tonumber(value) or E.START), E.MIN, E.MAX)

    local old = RP1942.getEconomy()
    if value == old then return old end

    SetGlobal2Int(E.KEY, value)   -- networked to every client automatically

    ServerLog(string.format("[1942] Economy %d -> %d (%s)\n", old, value, reason or "no reason given"))
    hook.Run("RP1942_EconomyChanged", old, value, reason)
    return value
end

function RP1942.addEconomy(delta, reason)
    return RP1942.setEconomy(RP1942.getEconomy() + (tonumber(delta) or 0), reason)
end

hook.Add("InitPostEntity", "RP1942_EconomyStart", function()
    SetGlobal2Int(E.KEY, E.START)
end)
