--[[---------------------------------------------------------------------------
1942 DarkRP - Reich jobs: joining by vote, and each unit's own music

VOTE
Joining the Reich from outside it (a Rifleman, the Supplier, the Scientist)
takes a vote of the whole server (DarkRP's normal job vote, 20 seconds; it
passes by itself if you're alone on the server). Once you're in, moving up
or across inside the Reich (Rifleman -> NCO, Medic, another unit) is
instant. Leave the Reich and you need a vote again to come back.
The F4 menu shows "Call a vote for ..." when a vote is needed; in chat it's
/vote<command>, e.g. /votewehrrifleman.
Wired into every job with faction = "reich" by job{} in jobs.lua.

MUSIC
Plays for the player who took the job, and nobody else. Moving between two
jobs with the same track doesn't restart it; leaving for a job without one
stops it. Players can mute it for themselves with  rp1942_job_music 0  and
stop what's playing with  rp1942_job_music_stop . Volume follows their music
volume slider.
Files are paths from the addon folder, and are sent to players on join.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.ReichJobs = {
    vote = {
        enabled = true,
        -- Jobs (by command) that never need a vote. The Führer is elected;
        -- the Gestapo joins quietly (a vote would announce the agent).
        exempt = { fuhrer = true, gestapo = true },
    },

    musicVolume = 0.6,   -- also scaled by the player's music volume slider
    -- Job command -> track. Jobs not listed play nothing.
    music = {
        -- Wehrmacht
        wehrrifleman     = "sounds/42wehrmacht.mp3",
        wehrmedic        = "sounds/42wehrmacht.mp3",
        wehrelite        = "sounds/42wehrmacht.mp3",
        wehrsharpshooter = "sounds/42wehrmacht.mp3",
        wehrdriver       = "sounds/42wehrmacht.mp3",
        wehrnco          = "sounds/42nco.mp3",
        wehroffizier     = "sounds/42officer.mp3",
        -- Waffen-SS
        wssrifleman      = "sounds/42waffen.mp3",
        wssmedic         = "sounds/42waffen.mp3",
        wssmg            = "sounds/42waffen.mp3",
        wssnco           = "sounds/42nco.mp3",
        wssoffizier      = "sounds/42officer.mp3",
        -- Leibstandarte
        lahrifleman      = "sounds/42leib.mp3",
        lahkommandant    = "sounds/42officer.mp3",
        -- Not set: gersupplier, scientist, gestapo, fuhrer (the Führer has the anthem)
    },
}

-- Does ply need a vote to take this Reich job? (RequiresVote in jobs.lua)
function RP1942.reichJobNeedsVote(ply, command)
    local v = RP1942.ReichJobs.vote
    if not v.enabled or v.exempt[command] then return false end
    if not IsValid(ply) or not RP1942.getFaction then return false end
    return RP1942.getFaction(ply) ~= "reich"
end
