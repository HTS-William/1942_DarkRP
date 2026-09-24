--[[---------------------------------------------------------------------------
1942 DarkRP - income tax (server)

    RP1942.applyTax(ply, gross, source) -> net, tax, rate
    RP1942.setFactionTax(faction, rate)
    RP1942.setJobTax(jobCommand, rate)       rate = nil removes the override

Collected tax currently leaves the economy (like DarkRP's own taxes).
Socket for a future Reich treasury:
    hook "RP1942_TaxCollected" (ply, tax, rate, source)
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

hook.Add("PlayerInitialSpawn", "RP1942_TaxSync", function(ply)
    timer.Simple(2, function() if IsValid(ply) then syncRates(ply) end end)
end)

function RP1942.setFactionTax(faction, rate)
    if RP1942.TaxRates.factions[faction] == nil then return false end
    RP1942.TaxRates.factions[faction] = clampRate(rate)
    syncRates()
    return RP1942.TaxRates.factions[faction]
end

function RP1942.setJobTax(jobCommand, rate)
    if not DarkRP.getJobByCommand(jobCommand) then return false end
    RP1942.TaxRates.jobs[jobCommand] = rate ~= nil and clampRate(rate) or nil
    syncRates()
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
