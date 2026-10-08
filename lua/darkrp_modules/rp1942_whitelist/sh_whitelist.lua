--[[---------------------------------------------------------------------------
1942 DarkRP - job whitelists (shared: settings)

Jobs listed in RP1942.Whitelist.jobs can only be taken by players staff have
whitelisted for them. With hidden = true the job doesn't even show (F4 Jobs
tab, the Führer's tax list) to anyone who isn't whitelisted for it.
Staff (admins and up) always see and can take them.

Staff commands (ULX, 42Bros category):
    !whitelist <player> <job>         whitelist someone who's online
    !unwhitelist <player> <job>       take it away (they're moved off the job)
    !whitelistid <SteamID> <job>      the same for someone offline
    !unwhitelistid <SteamID> <job>
    !whitelists [player]              who's whitelisted (for everything, or one player)
<job> is the job's command, e.g. eliteguard.

Saved in data/rp1942/whitelist.json (sv_whitelist.lua).
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.Whitelist = {
    -- job command = { hidden = true/false }
    jobs = {
        eliteguard = { hidden = true },   -- Elite Guard
    },
    -- Players whitelisted the first time the server starts with this file.
    -- Added once: removing them in game later sticks.
    seed = {
        eliteguard = { "STEAM_0:0:433634123" },
    },
    staffBypass = true,   -- admins and up can see and take every whitelisted job
}

-- Is ply whitelisted for this job? (works on server and client)
function RP1942.isWhitelistedFor(ply, command)
    if not IsValid(ply) then return false end
    if RP1942.Whitelist.staffBypass and ply:IsAdmin() then return true end
    local list = ply:GetNW2String("RP1942_Whitelist", "")
    return string.find("," .. list .. ",", "," .. command .. ",", 1, true) ~= nil
end

-- Should ply see this job at all?
function RP1942.canSeeJob(ply, job)
    local wl = job and RP1942.Whitelist.jobs[job.command]
    if not (wl and wl.hidden) then return true end
    return RP1942.isWhitelistedFor(ply, job.command)
end
