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

--[[ Reich payout ]]---------------------------------------------------------------------
-- "split:5000|reich,civilian": share 5000 evenly between every player in those
-- factions. "each:500|...": pay 500 to each of them. From the treasury.
-- Factions with nobody online are skipped; the Führer isn't paid. With a
-- split, anything that doesn't divide evenly stays in the treasury.
local PAYOUT_MAX = 10000        -- most per player in one payout
local PAYOUT_COOLDOWN = 30      -- seconds between payouts
local PAYOUT_NAMES = { reich = "the Reich", civilian = "the civilians", resistance = "the Resistance" }

RP1942.addMenuHandler("RP1942_FuhrerMenu", "payout", function(ply, arg)
    if not (RP1942.treasuryWithdraw and RP1942.getTreasury) then return end
    local mode, amount, list = string.match(arg or "", "^(%a+):(%d+)|([%w_,]*)$")
    if not mode then   -- the old form: "500|reich" = 500 each
        mode = "each"
        amount, list = string.match(arg or "", "^(%d+)|([%w_,]*)$")
    end
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return DarkRP.notify(ply, 1, 4, "Enter an amount to pay out.")
    end
    if (ply.RP1942_NextPayout or 0) > CurTime() then
        return DarkRP.notify(ply, 1, 4, "You can make another payout in " .. math.ceil(ply.RP1942_NextPayout - CurTime()) .. " seconds.")
    end

    -- The chosen factions, and who's in each (never the Führer himself)
    local chosen, recipients, paidFactions, emptyFactions = {}, {}, {}, {}
    for f in string.gmatch(list, "[^,]+") do if PAYOUT_NAMES[f] then chosen[f] = true end end
    if next(chosen) == nil then return DarkRP.notify(ply, 1, 4, "Pick at least one faction.") end
    for f in pairs(chosen) do
        local members = {}
        for _, p in ipairs(player.GetAll()) do
            if p ~= ply and RP1942.getFaction(p) == f then members[#members + 1] = p end
        end
        if #members == 0 then
            emptyFactions[#emptyFactions + 1] = PAYOUT_NAMES[f]
        else
            paidFactions[#paidFactions + 1] = PAYOUT_NAMES[f]
            for _, p in ipairs(members) do recipients[#recipients + 1] = p end
        end
    end
    if #emptyFactions > 0 then
        DarkRP.notify(ply, 1, 5, "Skipped (nobody online): " .. table.concat(emptyFactions, ", ") .. ".")
    end
    if #recipients == 0 then return end

    -- Everyone gets the same: a split of the total, or the amount each
    if mode == "split" then
        amount = math.floor(amount / #recipients)
        if amount < 1 then
            return DarkRP.notify(ply, 1, 5, "That's less than R.M. 1 each for " .. #recipients .. " players.")
        end
    end
    if amount > PAYOUT_MAX then
        return DarkRP.notify(ply, 1, 4, "At most " .. DarkRP.formatMoney(PAYOUT_MAX) .. " per player in one payout.")
    end
    local total = amount * #recipients
    if not RP1942.treasuryWithdraw(total, "Reich payout by " .. ply:Nick()) then
        return DarkRP.notify(ply, 1, 6, "The treasury can't afford that: it needs " .. DarkRP.formatMoney(total)
            .. " and holds " .. DarkRP.formatMoney(RP1942.getTreasury()) .. ".")
    end
    ply.RP1942_NextPayout = CurTime() + PAYOUT_COOLDOWN

    for _, p in ipairs(recipients) do
        p:addMoney(amount)
        DarkRP.notify(p, 0, 6, "Reich payout: the Führer has paid you " .. DarkRP.formatMoney(amount) .. ".")
    end
    table.sort(paidFactions)
    DarkRP.notify(ply, 0, 6, "Paid " .. DarkRP.formatMoney(amount) .. " to " .. #recipients .. " players (" .. table.concat(paidFactions, ", ")
        .. "). Total " .. DarkRP.formatMoney(total) .. " from the treasury.")
    if RP1942.alert then
        RP1942.alert("The Führer has paid " .. DarkRP.formatMoney(amount) .. " to " .. table.concat(paidFactions, " and ") .. ".", "clear")
    end
    ServerLog(string.format("[1942] %s paid %d each to %d players (%s), total %d\n", ply:Nick(), amount, #recipients, table.concat(paidFactions, ", "), total))
end)

