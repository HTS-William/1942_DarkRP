--[[---------------------------------------------------------------------------
Server handlers for RP1942_FuhrerMenu.
Only reachable by a player whose CURRENT job has menu = "RP1942_FuhrerMenu".
---------------------------------------------------------------------------]]
local ECONOMY_STEP = 10
local MAX_TAX_STEP = 25   -- largest single change a request may make

--[[ Economy ]]---------------------------------------------------------------------
local function changeEconomy(ply, delta)
    if not RP1942.addEconomy then
        DarkRP.notify(ply, 1, 4, "The economy module is not loaded.")
        return
    end

    local value = RP1942.addEconomy(delta, "Führer debug menu (" .. ply:Nick() .. ")")
    DarkRP.notify(ply, 0, 4, string.format("Economy is now %d: %s", value, RP1942.getEconomyTier(value).text))
end

RP1942.addMenuHandler("RP1942_FuhrerMenu", "economy_up",   function(ply) changeEconomy(ply,  ECONOMY_STEP) end)
RP1942.addMenuHandler("RP1942_FuhrerMenu", "economy_down", function(ply) changeEconomy(ply, -ECONOMY_STEP) end)

--[[ Taxes ]]---------------------------------------------------------------------------
-- Requests arrive as "key:delta", e.g. "reich:5" or "baker:-5"
local function parseChange(arg)
    local key, delta = string.match(arg, "^([%w_]+):(%-?%d+)$")
    delta = tonumber(delta)
    if not key or not delta or math.abs(delta) > MAX_TAX_STEP then return nil end
    return key, delta
end

RP1942.addMenuHandler("RP1942_FuhrerMenu", "tax_faction", function(ply, arg)
    if not RP1942.setFactionTax then return end
    local faction, delta = parseChange(arg)
    if not faction or RP1942.TaxRates.factions[faction] == nil then return end

    local rate = RP1942.setFactionTax(faction, RP1942.TaxRates.factions[faction] + delta)
    ServerLog(string.format("[1942] %s set %s income tax to %d%%\n", ply:Nick(), faction, rate))
end)

RP1942.addMenuHandler("RP1942_FuhrerMenu", "tax_job", function(ply, arg)
    if not RP1942.setJobTax then return end
    local cmd, delta = parseChange(arg)
    local job = cmd and DarkRP.getJobByCommand(cmd)
    if not job then return end

    -- The first change starts from whatever the job pays now (its faction rate)
    local current = RP1942.getTaxRate(job)
    local rate = RP1942.setJobTax(cmd, current + delta)
    ServerLog(string.format("[1942] %s set %s income tax to %d%%\n", ply:Nick(), job.name, rate))
end)

RP1942.addMenuHandler("RP1942_FuhrerMenu", "tax_job_reset", function(ply, cmd)
    if not RP1942.setJobTax then return end
    local job = DarkRP.getJobByCommand(cmd)
    if not job then return end

    RP1942.setJobTax(cmd, nil)
    ServerLog(string.format("[1942] %s reset %s income tax to its faction rate\n", ply:Nick(), job.name))
end)
