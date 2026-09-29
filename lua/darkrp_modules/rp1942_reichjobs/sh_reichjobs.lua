--[[---------------------------------------------------------------------------
1942 DarkRP - Reich jobs: joining by vote, and each unit's own music

VOTE
Joining the Reich from outside it (a Rifleman, the Supplier, the Scientist,
the Gestapo) takes a vote of the whole server (DarkRP's normal job vote, 20 seconds; it
passes by itself if you're alone on the server). Once you're in, moving up
or across inside the Reich (Rifleman -> NCO, Medic, another unit) is
instant. Leave the Reich and you need a vote again to come back.
The vote reads "<name> would like to join the Reich": it never says which
job, so the Gestapo can be voted in without being exposed (their join stays
quiet, as before). The F4 menu shows "Call a vote for ..." when a vote is
needed; in chat it's /vote<command>, e.g. /votewehrrifleman. The Gestapo's
F4 button, /gestapo and /joingestapo start the vote on their own.
The votes themselves: sv_reichjobs.lua.
Wired into every job with faction = "reich" by job{} in jobs.lua.

MUSIC
Plays once, for that player only, when they become a unit's Rifleman from
outside that unit (i.e. when they're voted in, or transfer from another
unit). Moving through the specialisations (Rifleman -> Medic -> NCO...,
and back to Rifleman) plays nothing new and doesn't cut the song off;
leaving the Reich stops it. Players can mute it for themselves with  rp1942_job_music 0  and
stop what's playing with  rp1942_job_music_stop . Volume follows their music
volume slider.
Files are paths from the addon folder, and are sent to players on join.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.ReichJobs = {
    vote = {
        enabled = true,
        -- Jobs (by command) that never need a vote. The Führer is elected.
        exempt = { fuhrer = true },
        -- What the vote says. It never names the job, so voting in a
        -- Gestapo agent doesn't blow their cover. %s = the player's name.
        message     = "%s\nwould like to join the Reich",
        failMessage = "%s was not allowed to join the Reich.",
        time        = 20,   -- seconds
        cooldown    = 80,   -- seconds before the same player can call another
    },

    musicVolume = 0.6,   -- also scaled by the player's music volume slider
    -- Job command -> track. Jobs not listed play nothing.
    music = {
        wehrrifleman = "sound/42wehrmacht.mp3",
        wssrifleman  = "sound/42waffen.mp3",
        leibstandarte = "sound/42leib.mp3",
        -- Only the Riflemen (the way into each unit). sound/42nco.mp3 and
        -- sound/42officer.mp3 are unused for now.
    },
}

-- Does ply need a vote to take this Reich job? (RequiresVote in jobs.lua)
function RP1942.reichJobNeedsVote(ply, command)
    local v = RP1942.ReichJobs.vote
    if not v.enabled or v.exempt[command] then return false end
    -- Only Reich jobs are voted (the Resistance Operative joins quietly too, but isn't Reich)
    local job = RP1942.getJobByCommand and RP1942.getJobByCommand(command)
    if job and job.faction ~= "reich" then return false end
    if not IsValid(ply) or not RP1942.getFaction then return false end
    return RP1942.getFaction(ply) ~= "reich"
end

-- What happens to the music when a player goes from oldTeam to newTeam:
-- a track path to play, "stop", or nil (leave whatever is playing alone)
function RP1942.reichJobMusicFor(oldTeam, newTeam)
    local new = RPExtraTeams and RPExtraTeams[newTeam]
    local old = RPExtraTeams and RPExtraTeams[oldTeam]
    if not new or new.faction ~= "reich" then
        return (old and old.faction == "reich") and "stop" or nil
    end
    local track = RP1942.ReichJobs.music[new.command]
    if not track then return nil end                            -- a specialisation: no change
    if old and old.faction == "reich" and old.branch == new.branch then return nil end   -- back down to Rifleman
    return track
end
