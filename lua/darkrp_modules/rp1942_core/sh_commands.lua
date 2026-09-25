--[[---------------------------------------------------------------------------
1942 DarkRP - disguise commands and helpers (shared)

Declared shared so they show in the F1 command list with the right condition.
Conditions only run at call time, so it doesn't matter that rp1942_core
loads after this module.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

function RP1942.canDisguise(ply)
    local job = RPExtraTeams[ply:Team()]
    local cfg = RP1942.Config and RP1942.Config.Disguise
    return job ~= nil and cfg ~= nil and cfg.jobs[job.command] == true
end

DarkRP.declareChatCommand{
    command = "joingestapo",
    description = "Report for Gestapo duty without it being announced.",
    delay = 1.5,
}

--[[---------------------------------------------------------------------------
Disguise models for the F3 wardrobe of ply's job.
RP1942.Config.Disguise.models[job command], if it has any; otherwise every
model used by a civilian job, so an agent can look like any resident.
(A plain list instead of per-job lists is also accepted, shared by all.)
Same on server and client, so the server can check a request against it.
---------------------------------------------------------------------------]]
local function civilianModels()
    local list, seen = {}, {}
    for _, job in ipairs(RPExtraTeams or {}) do
        if job.faction == "civilian" then
            local models = istable(job.model) and job.model or { job.model }
            for _, m in ipairs(models) do
                if isstring(m) and not seen[string.lower(m)] then
                    seen[string.lower(m)] = true
                    list[#list + 1] = m
                end
            end
        end
    end
    return list
end

function RP1942.disguiseModels(ply)
    local cfg = RP1942.Config and RP1942.Config.Disguise
    local models = cfg and cfg.models
    if istable(models) then
        if isstring(models[1]) then return models end   -- one shared list
        local job = IsValid(ply) and RPExtraTeams[ply:Team()]
        local own = job and models[job.command]
        if istable(own) and #own > 0 then return own end
    end
    return civilianModels()
end
