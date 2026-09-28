--[[---------------------------------------------------------------------------
1942 DarkRP - Reich jobs (server): sends a player their unit's music
(settings: sh_reichjobs.lua)
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_JobMusic")

-- Addon sound files have to be sent to players, or only the server has them
local sent = {}
for _, path in pairs(RP1942.ReichJobs.music) do
    if not sent[path] then
        sent[path] = true
        if file.Exists(path, "GAME") then
            resource.AddFile(path)
        else
            MsgC(Color(255, 170, 0), "[1942] Reich job music not found at '", path, "'. Check RP1942.ReichJobs.music (sh_reichjobs.lua).\n")
        end
    end
end

hook.Add("OnPlayerChangedTeam", "RP1942_JobMusic", function(ply, _, newTeam)
    local job = RPExtraTeams and RPExtraTeams[newTeam]
    local path = job and RP1942.ReichJobs.music[job.command] or ""
    net.Start("RP1942_JobMusic")
    net.WriteString(path)   -- "" = this job has none: stop any playing
    net.Send(ply)           -- only this player hears it
end)
