--[[---------------------------------------------------------------------------
1942 DarkRP - economy (server)

The only place the economy value is changed. Everything that changes it
(the Führer's menu, later: taxes, supply trains, air raids...) goes through
setEconomy / addEconomy, so the value is always clamped to 1-110 and every
change fires the same hook.

The value is kept across restarts and map changes: data/rp1942/economy.json,
saved a few seconds after it moves (market sales nudge it often, so changes
are gathered into one write) and again when the server shuts down.
---------------------------------------------------------------------------]]
local E = RP1942.Economy
local store = RP1942.dataStore("economy")
local SAVE_DELAY = 5   -- seconds

local function save()
    store.save({ value = RP1942.getEconomy() })
end

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

hook.Add("RP1942_EconomyChanged", "RP1942_EconomySave", function()
    if not timer.Exists("RP1942_EconomySave") then timer.Create("RP1942_EconomySave", SAVE_DELAY, 1, save) end
end)
hook.Add("ShutDown", "RP1942_EconomySave", save)

hook.Add("InitPostEntity", "RP1942_EconomyStart", function()
    local saved = tonumber(store.load().value)
    SetGlobal2Int(E.KEY, saved and math.Clamp(math.Round(saved), E.MIN, E.MAX) or E.START)
end)

--[[---------------------------------------------------------------------------
Wages: every DarkRP payday is scaled by the economy, then taxed.
    base salary -> x economy multiplier -> - income tax (sv_taxes.lua) -> paid

DarkRP stops at the first playerGetSalary hook that returns a value, so this
must not return for players another rule should handle. It leaves AFK players
alone, which is what DarkRP's own AFK hook freezes, in case that module is on.
---------------------------------------------------------------------------]]
hook.Add("playerGetSalary", "RP1942_EconomyWages", function(ply, amount)
    if ply:getDarkRPVar("AFK") then return end
    if not amount or amount <= 0 then return end

    local gross = RP1942.applyEconomy(amount, "salary")
    -- The Führer's soldiers' pay bonus (rp1942_perks/sh_perks.lua)
    if RP1942.salaryBonus then gross = math.floor(gross * RP1942.salaryBonus(ply)) end
    if not RP1942.applyTax then return false, nil, gross end

    local net, tax, rate = RP1942.applyTax(ply, gross, "salary")
    if tax <= 0 then
        return false, nil, net   -- DarkRP's normal payday message
    end

    return false, string.format("Payday! You received %s after %d%% tax (%s withheld).",
        DarkRP.formatMoney(net), rate, DarkRP.formatMoney(tax)), net
end)

--[[---------------------------------------------------------------------------
No Führer: the economy slips (settings: RP1942.Economy.Leaderless, sh_economy.lua)
---------------------------------------------------------------------------]]
local L = E.Leaderless
local nextDrop, leaderlessSince, drops

local function hasFuhrer()
    for _, p in ipairs(player.GetAll()) do
        local job = RPExtraTeams[p:Team()]
        if job and job.mayor then return true end
    end
    return false
end

local function roll(r) return istable(r) and math.random(r[1], r[2] or r[1]) or (tonumber(r) or 0) end

timer.Create("RP1942_EconomyLeaderless", 5, 0, function()
    if not (L and L.enabled) then return end
    local now = CurTime()
    if hasFuhrer() or player.GetCount() < (L.minPlayers or 0) then
        nextDrop, leaderlessSince, drops = nil, nil, 0
        return
    end
    leaderlessSince = leaderlessSince or now
    if now - leaderlessSince < (L.grace or 0) then return end
    nextDrop = nextDrop or (now + roll(L.every))
    if now < nextDrop then return end
    nextDrop = now + roll(L.every)

    local before = RP1942.getEconomy()
    if before <= (L.floor or 1) then return end
    local after = RP1942.setEconomy(math.max(before - roll(L.drop), L.floor or 1), "no Führer in office")
    drops = (drops or 0) + 1
    -- Say so the first time, then every third drop, so it isn't spammy
    if RP1942.alert and after < before and (drops == 1 or drops % 3 == 0) then
        RP1942.alert(string.format("With no Führer in office the economy is slipping (%d, down %d). The Reich needs a leader.", after, before - after), "wanted")
    end
end)
