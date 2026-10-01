--[[---------------------------------------------------------------------------
1942 DarkRP - Reich treasury (server)

The balance is kept across restarts and map changes: data/rp1942/treasury.json.
It's saved a few seconds after it changes (taxes come in often, so changes are
gathered into one write) and again when the server shuts down.
---------------------------------------------------------------------------]]
local T = RP1942.Treasury
local store = RP1942.dataStore("treasury")
local SAVE_DELAY = 5   -- seconds

local function save()
    store.save({ balance = RP1942.getTreasury() })
end

local function setBalance(value, reason)
    local old = RP1942.getTreasury()
    SetGlobal2Int(T.KEY, value)   -- networked to clients automatically
    hook.Run("RP1942_TreasuryChanged", old, value, reason)
    return value
end

function RP1942.treasuryDeposit(amount, source)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return RP1942.getTreasury() end
    return setBalance(RP1942.getTreasury() + amount, source)
end

-- Never goes below zero: returns false and changes nothing if funds are short
function RP1942.treasuryWithdraw(amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local balance = RP1942.getTreasury()
    if amount > balance then return false end

    setBalance(balance - amount, reason)
    ServerLog(string.format("[1942] Treasury paid %d (%s). Balance: %d\n", amount, reason or "no reason given", balance - amount))
    return true
end

-- Every income tax goes into the pot
hook.Add("RP1942_TaxCollected", "RP1942_TreasuryTaxIntake", function(ply, tax, rate, source)
    RP1942.treasuryDeposit(tax, "tax:" .. (source or "unknown"))
end)

hook.Add("RP1942_TreasuryChanged", "RP1942_TreasurySave", function()
    if not timer.Exists("RP1942_TreasurySave") then timer.Create("RP1942_TreasurySave", SAVE_DELAY, 1, save) end
end)
hook.Add("ShutDown", "RP1942_TreasurySave", save)

hook.Add("InitPostEntity", "RP1942_TreasuryStart", function()
    local saved = tonumber(store.load().balance)
    SetGlobal2Int(T.KEY, saved and math.max(math.floor(saved), 0) or T.START)
end)
