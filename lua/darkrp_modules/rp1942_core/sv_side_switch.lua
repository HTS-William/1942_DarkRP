--[[---------------------------------------------------------------------------
1942 DarkRP - changing sides sends you back to spawn (server)

Stops job abuse like fighting as the Resistance, switching to the Waffen-SS
on the spot and carrying on from the same place. When you take a job that
can raid (RAID = YES) and the last raiding job you held was in a different
GROUP, you're sent back to spawn with the new job's gear (not killed: no
death, no NLR, nothing dropped).

The groups (a raiding job's group: the Reich, GROUP_OF below, else its branch):
    civilian       Civilian, Doctor
    resistance     Thief, Pro Thief, Resistance, Resistance Medic,
                   Resistance Operative, Resistance Leader
    reich          every Reich job that can raid: Wehrmacht, Waffen-SS,
                   Leibstandarte and Gestapo are all one side

    Resistance -> Waffen-SS Rifleman             back to spawn (new group)
    Waffen-SS Rifleman -> Waffen-SS Machinegunner  no (same group)
    Baker -> Resistance                          no (a Baker can't raid)
    Resistance -> Baker -> Waffen-SS Rifleman    back to spawn: the Baker in
        between doesn't count, it's the last RAIDING job that's compared
    Wehrmacht Rifleman -> Waffen-SS Rifleman     no (both the Reich)
    Resistance Medic -> Resistance Leader        no: a job you can only take
        from inside your side (requires = ... in jobs.lua) is never a way in

So only the ways IN send you to spawn: the starting jobs (Wehrmacht and
Waffen-SS Rifleman, Gestapo, Resistance, Thief, Civilian, Doctor).

Jobs that can't raid (producers, dealers, Hobo, Banker, Scientist, Supplier,
the Führer, Staff on Duty) never send anyone to spawn.
---------------------------------------------------------------------------]]
local GROUP_OF = {   -- by job command; anything not listed uses its branch
    civilian = "civilian", doctor = "civilian",
}

local function groupOf(job)
    if not (job and job.canRaid) then return nil end
    if job.faction == "reich" then return "reich" end   -- the whole Reich is one side
    return GROUP_OF[job.command] or job.branch or job.faction
end
RP1942.raidGroupOf = groupOf

local GROUP_NAMES = { civilian = "the civilians", resistance = "the Resistance", reich = "the Reich" }

hook.Add("OnPlayerChangedTeam", "RP1942_SideSwitch", function(ply, oldTeam, newTeam)
    if not IsValid(ply) then return end
    local job = RPExtraTeams[newTeam]
    local new = groupOf(job)
    if not new then return end   -- the new job can't raid: nothing to do

    -- The last raiding job's group (this job change's old job, or an earlier one)
    local last = groupOf(RPExtraTeams[oldTeam]) or ply.RP1942_RaidGroup
    ply.RP1942_RaidGroup = new
    if not last or last == new then return end
    -- A job you can only take from inside (requires = ...: Leibstandarte, the
    -- Resistance Medic...) is a move within your side, never a way in
    if job.requires then return end

    -- Different side: back to spawn once DarkRP has finished the job change
    timer.Simple(0, function()
        if not IsValid(ply) or ply:Team() ~= newTeam then return end
        if not ply:Alive() then return end   -- dead: they respawn anyway
        if ply.isArrested and ply:isArrested() then return end
        ply:Spawn()
        DarkRP.notify(ply, 0, 6, "You've joined " .. (GROUP_NAMES[new] or new) .. ": you've been sent back to spawn.")
    end)
end)

-- A new player starts with no raiding job behind them
hook.Add("PlayerInitialSpawn", "RP1942_SideSwitch", function(ply)
    ply.RP1942_RaidGroup = nil
end)
