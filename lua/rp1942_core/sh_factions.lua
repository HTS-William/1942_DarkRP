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
