--[[---------------------------------------------------------------------------
1942 DarkRP - Reich jobs (server): sends a player their unit's music when they join it
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

-- Backup for the client's own job watcher (cl_reichjobs.lua)
hook.Add("OnPlayerChangedTeam", "RP1942_JobMusic", function(ply, oldTeam, newTeam)
    local what = RP1942.reichJobMusicFor(oldTeam, newTeam)
    if not what then return end
    net.Start("RP1942_JobMusic")
    net.WriteString(what == "stop" and "" or what)   -- "" = stop
    net.Send(ply)   -- only this player hears it
end)
