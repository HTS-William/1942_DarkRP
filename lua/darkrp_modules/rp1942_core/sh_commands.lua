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

--[[---------------------------------------------------------------------------
Wardrobe preset tabs for ply's job (RP1942.Config.Disguise.presets).
Returns a list of tabs:
    { id = "reich", name = "Reich", jobs = {
        { command = "wehrrifleman", name = "Wehrmacht Rifleman", models = { ... } }, ... } }
Same on server and client, so the server can check a request against it.
---------------------------------------------------------------------------]]
local TAB_NAMES = { civilian = "Civilian", resistance = "Resistance", reich = "Reich" }

local function jobModels(job)
    local list = {}
    for _, m in ipairs(istable(job.model) and job.model or { job.model }) do
        if isstring(m) and m ~= "" then list[#list + 1] = m end
    end
    return list
end

local function offered(job, cfg)
    if cfg.jobs[job.command] then return false end   -- never another undercover job
    if cfg.allowLeaders then return true end
    return not (job.whitelisted or (cfg.leaderJobs and cfg.leaderJobs[job.command]))
end

function RP1942.disguisePresets(ply)
    local cfg = RP1942.Config and RP1942.Config.Disguise
    local job = IsValid(ply) and RPExtraTeams[ply:Team()]
    if not (cfg and job and cfg.presets) then return {} end

    local tabs = {}
    for _, faction in ipairs(cfg.presets[job.command] or {}) do
        local tab = { id = faction, name = TAB_NAMES[faction] or faction, jobs = {} }
        for _, j in ipairs(RPExtraTeams) do
            if (j.faction or "civilian") == faction and offered(j, cfg) then
                local models = jobModels(j)
                if #models > 0 then
                    tab.jobs[#tab.jobs + 1] = { command = j.command, name = j.name, models = models }
                end
            end
        end
        if #tab.jobs > 0 then tabs[#tabs + 1] = tab end
    end
    return tabs
end

-- One preset by tab id, job command and model number, if ply may use it
function RP1942.findDisguisePreset(ply, tabId, command, index)
    for _, tab in ipairs(RP1942.disguisePresets(ply)) do
        if tab.id == tabId then
            for _, j in ipairs(tab.jobs) do
                if j.command == command and j.models[index] then return j, j.models[index] end
            end
        end
    end
end
