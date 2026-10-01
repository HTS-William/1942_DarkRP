--[[---------------------------------------------------------------------------
1942 DarkRP - income tax (server)

    RP1942.applyTax(ply, gross, source) -> net, tax, rate
    RP1942.setFactionTax(faction, rate)
    RP1942.setJobTax(jobCommand, rate)       rate = nil removes the override

Collected tax goes to the Reich treasury (sv_treasury.lua listens to):
    hook "RP1942_TaxCollected" (ply, tax, rate, source)

The rates are kept across restarts and map changes: data/rp1942/taxes.json,
saved on every change and loaded when the server starts. Job rates for jobs
that no longer exist are dropped on load.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_TaxRates")

local C = RP1942.TaxConfig

local function clampRate(rate)
    return math.Clamp(math.Round(tonumber(rate) or 0), 0, C.MAX)
end

-- Send the whole rate table: to one player, or to everyone if ply is nil
local function syncRates(ply)
    net.Start("RP1942_TaxRates")
    net.WriteTable(RP1942.TaxRates)
    if ply then net.Send(ply) else net.Broadcast() end
end

local store = RP1942.dataStore("taxes")

local function save()
    store.save(RP1942.TaxRates)
end

hook.Add("InitPostEntity", "RP1942_TaxLoad", function()
    local saved = store.load()
    local rates = RP1942.TaxRates
    for f in pairs(rates.factions) do
        if saved.factions and saved.factions[f] ~= nil then rates.factions[f] = clampRate(saved.factions[f]) end
    end
    rates.jobs = {}
    for cmd, rate in pairs(saved.jobs or {}) do
        if DarkRP.getJobByCommand(cmd) then rates.jobs[cmd] = clampRate(rate) end
    end
    syncRates()
end)

hook.Add("PlayerInitialSpawn", "RP1942_TaxSync", function(ply)
    timer.Simple(2, function() if IsValid(ply) then syncRates(ply) end end)
end)

function RP1942.setFactionTax(faction, rate)
    if RP1942.TaxRates.factions[faction] == nil then return false end
    RP1942.TaxRates.factions[faction] = clampRate(rate)
    syncRates()
    save()
    return RP1942.TaxRates.factions[faction]
end

function RP1942.setJobTax(jobCommand, rate)
    if not DarkRP.getJobByCommand(jobCommand) then return false end
    RP1942.TaxRates.jobs[jobCommand] = rate ~= nil and clampRate(rate) or nil
    syncRates()
    save()
    return RP1942.TaxRates.jobs[jobCommand]
end

function RP1942.applyTax(ply, gross, source)
    local rate = RP1942.getTaxRate(ply:getJobTable())
    local tax = math.floor(gross * rate / 100)

    if tax > 0 then
        hook.Run("RP1942_TaxCollected", ply, tax, rate, source)
    end
    return gross - tax, tax, rate
end
