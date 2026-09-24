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

--[[---------------------------------------------------------------------------
Wages: every DarkRP payday is scaled by the economy multiplier.

DarkRP stops at the first playerGetSalary hook that returns a value, so this
must not return for players another rule should handle. It leaves AFK players
alone, which is what DarkRP's own AFK hook freezes, in case that module is on.
---------------------------------------------------------------------------]]
hook.Add("playerGetSalary", "RP1942_EconomyWages", function(ply, amount)
    if ply:getDarkRPVar("AFK") then return end
    if not amount or amount <= 0 then return end

    -- suppress = false and no custom message: DarkRP's normal payday
    -- notification shows the adjusted amount
    return false, nil, RP1942.applyEconomy(amount, "salary")
end)
