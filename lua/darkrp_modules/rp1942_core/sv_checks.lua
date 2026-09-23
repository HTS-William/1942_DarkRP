--[[---------------------------------------------------------------------------
1942 DarkRP - startup sanity checks (server)

Warns in the server console about job weapons or models that don't exist,
which is what happens while RP1942.Weapons / RP1942.Models still hold
placeholders. Runs at InitPostEntity so addon SWEPs are registered by then.
---------------------------------------------------------------------------]]
hook.Add("InitPostEntity", "RP1942_SanityChecks", function()
    local missingWeapons, missingModels = {}, {}

    for _, job in pairs(RPExtraTeams) do
        for _, class in ipairs(job.weapons or {}) do
            if not weapons.GetStored(class) and not missingWeapons[class] then
                missingWeapons[class] = job.name
            end
        end

        local models = istable(job.model) and job.model or { job.model }
        for _, mdl in ipairs(models) do
            if not util.IsValidModel(mdl) and not missingModels[mdl] then
                missingModels[mdl] = job.name
            end
        end
    end

    for class, jobName in SortedPairs(missingWeapons) do
        MsgC(Color(255, 170, 0), "[1942] Missing weapon class '", class, "' (first used by ", jobName, ")\n")
    end
    for mdl, jobName in SortedPairs(missingModels) do
        MsgC(Color(255, 170, 0), "[1942] Missing model '", mdl, "' (first used by ", jobName, ")\n")
    end
end)
