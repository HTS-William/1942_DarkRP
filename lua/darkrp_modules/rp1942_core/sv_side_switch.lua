--[[---------------------------------------------------------------------------
42Bros - no changing sides in the middle of a fight (server)

Changing jobs during active roleplay to change how a situation ends is job
abuse (rule 5c in the F4 rules), and staff deal with it. Changing jobs never
sends you back to spawn.

The one thing the server does by itself: you can't take a job that can raid
(RAID = YES) on a DIFFERENT side while you're wanted, or within FIGHT_SECONDS
of being hurt by another player (RP1942_LastHurt, set in
rp1942_sit_rules.lua). That stops the obvious case, a losing Resistance
fighter typing /wehrrifleman mid-firefight, without staff having to watch.

The sides (a raiding job's group: the Reich, GROUP_OF below, else its branch):
    civilian       Civilian, Doctor
    resistance     Thief, Pro Thief, Resistance, Resistance Medic,
                   Resistance Operative, Resistance Leader
    reich          every Reich job that can raid: Wehrmacht, Waffen-SS,
                   Leibstandarte and Gestapo are all one side

Never refused: jobs that can't raid (producers, dealers, Hobo, Banker...),
moves within your own side, and jobs you can only take from inside your
side (requires = ... in jobs.lua, e.g. Resistance Medic -> Resistance Leader).
---------------------------------------------------------------------------]]
local FIGHT_SECONDS = 20

local GROUP_OF = {   -- by job command; anything not listed uses its branch
    civilian = "civilian", doctor = "civilian",
}

local function groupOf(job)
    if not (job and job.canRaid) then return nil end
    if job.faction == "reich" then return "reich" end   -- the whole Reich is one side
    return GROUP_OF[job.command] or job.branch or job.faction
end
RP1942.raidGroupOf = groupOf

-- The last raiding job you held, so Resistance -> Baker -> Wehrmacht still counts as changing sides
hook.Add("OnPlayerChangedTeam", "RP1942_SideSwitch", function(ply, _, newTeam)
    if not IsValid(ply) then return end
    local group = groupOf(RPExtraTeams[newTeam])
    if group then ply.RP1942_RaidGroup = group end
end)

hook.Add("playerCanChangeTeam", "RP1942_SideSwitchFight", function(ply, newTeam, force)
    if force or not IsValid(ply) then return end
    local job = RPExtraTeams[newTeam]
    local new = groupOf(job)
    if not new or job.requires then return end
    local last = groupOf(RPExtraTeams[ply:Team()]) or ply.RP1942_RaidGroup
    if not last or last == new then return end
    if ply.getDarkRPVar and ply:getDarkRPVar("wanted") then
        return false, "You can't change sides while you're wanted."
    end
    local since = CurTime() - (ply.RP1942_LastHurt or -1000)
    if since < FIGHT_SECONDS then
        return false, "You can't change sides in the middle of a fight. Wait " .. math.ceil(FIGHT_SECONDS - since) .. " seconds."
    end
end)

-- A new player starts with no raiding job behind them
hook.Add("PlayerInitialSpawn", "RP1942_SideSwitch", function(ply)
    ply.RP1942_RaidGroup = nil
end)
