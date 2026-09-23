--[[---------------------------------------------------------------------------
1942 DarkRP - faction helpers (shared)

Every job in jobs.lua carries a custom `faction` field:
    "civilian" | "resistance" | "reich"
Dealers are "civilian": they're a trade, not a side.

Only functions here. Do not read RP1942.Config at file load time
(sh_config.lua loads AFTER this file, see the note there).
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

function RP1942.getJobFaction(teamNr)
    local job = RPExtraTeams and RPExtraTeams[teamNr]
    return job and job.faction or "civilian"
end

function RP1942.getFaction(ply)
    return RP1942.getJobFaction(ply:Team())
end

function RP1942.getBranch(ply)
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    return job and job.branch
end

-- Used by F4 category canSee: true if the player's CURRENT job is in one of the branches
function RP1942.inBranch(ply, ...)
    local branch = RP1942.getBranch(ply)
    if not branch then return false end
    for _, b in ipairs({...}) do
        if b == branch then return true end
    end
    return false
end

function RP1942.isFaction(ply, faction)
    return RP1942.getFaction(ply) == faction
end

-- Count players in a faction, optionally ignoring one player (the one switching)
function RP1942.countFaction(faction, ignore)
    local n = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= ignore and RP1942.getFaction(ply) == faction then
            n = n + 1
        end
    end
    return n
end

-- GetUserGroup is networked, so this works in customCheck on both realms
function RP1942.isVIP(ply)
    local groups = RP1942.Config and RP1942.Config.VIPGroups or {}
    return groups[ply:GetUserGroup()] == true
end

function RP1942.hasWhitelist(ply, jobCommand)
    local wl = RP1942.Config and RP1942.Config.Whitelist or {}
    if not wl.enabled then return true end
    if wl.staffBypass and ply:IsAdmin() then return true end

    -- The ranks module answers this. Must be an explicit true.
    return hook.Run("RP1942_HasWhitelist", ply, jobCommand) == true
end

function RP1942.getJobByCommand(command)
    for teamNr, job in pairs(RPExtraTeams) do
        if job.command == command then return job, teamNr end
    end
end

--[[---------------------------------------------------------------------------
Job gates
Returns nil when the player may take the job, otherwise the reason (string).
Order: VIP -> whitelist -> requirements -> job-specific gate.
jobs.lua turns this into DarkRP's customCheck + CustomCheckFailMsg, so the same
rules decide both the F4 button (client) and the actual job change (server).

Job fields read here:
    vip         = true
    whitelisted = true
    requires    = { faction = "reich" }                  must currently be in the faction
    requires    = { branch = "wehrmacht" }               must currently be in the branch
    requires    = { branch = { "wehrmacht", "waffen_ss" } }
    gate        = function(ply) ... end                  extra job-specific check
    gateFailMsg = "..."
---------------------------------------------------------------------------]]
local function asSet(v)
    if istable(v) then
        local set = {}
        for _, x in ipairs(v) do set[x] = true end
        return set, v
    end
    return { [v] = true }, { v }
end

function RP1942.jobGateFailure(ply, job)
    local C = RP1942.Config

    if job.vip and not RP1942.isVIP(ply) then
        return "This job is for VIP members."
    end

    if job.whitelisted and not RP1942.hasWhitelist(ply, job.command) then
        return "You are not whitelisted for this rank."
    end

    local req = job.requires
    if req then
        local current = RPExtraTeams[ply:Team()]

        if req.faction and (not current or current.faction ~= req.faction) then
            return "You must be serving " .. (C.FactionNames[req.faction] or req.faction) .. " first."
        end

        if req.branch then
            local set, list = asSet(req.branch)
            if not current or not set[current.branch] then
                local options = {}
                for _, b in ipairs(list) do
                    local info = C.Branches[b]
                    local entry = info and RP1942.getJobByCommand(info.entry)
                    if info and entry then
                        table.insert(options, info.name .. " (join as " .. entry.name .. ")")
                    else
                        table.insert(options, b)
                    end
                end
                return "Enlist in " .. table.concat(options, " or ") .. " first, then specialise."
            end
        end
    end

    if job.gate and not job.gate(ply) then
        return job.gateFailMsg or "You can't take this job right now."
    end
end
