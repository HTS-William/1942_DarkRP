--[[---------------------------------------------------------------------------
1942 DarkRP - income tax (shared)

Tax is taken from the AFTER-ECONOMY wage:
    base salary  ->  x economy multiplier  ->  - tax  ->  paid

Rates are whole percentages, set by the Führer:
    by faction   (civilian / resistance / reich)       default for every job in it
    by job       (keyed by job command, e.g. "baker")  overrides its faction

    RP1942.getTaxRate(jobTable)  -> rate, "job" | "faction"
    RP1942.TaxRates              -> { factions = {...}, jobs = {...} } (synced to clients)

Server: RP1942.applyTax, RP1942.setFactionTax, RP1942.setJobTax (sv_taxes.lua)
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.TaxConfig = {
    MAX = 100,                                        -- highest rate the Führer can set
    FACTIONS = { "civilian", "resistance", "reich" },  -- the factions that get a rate
}

RP1942.TaxRates = RP1942.TaxRates or {
    factions = { civilian = 0, resistance = 0, reich = 0 },   -- start: no tax
    jobs = {},
}

function RP1942.getTaxRate(job)
    if not job then return 0, "faction" end

    local rates = RP1942.TaxRates
    local jobRate = rates.jobs[job.command]
    if jobRate then return jobRate, "job" end

    return rates.factions[job.faction or "civilian"] or 0, "faction"
end
