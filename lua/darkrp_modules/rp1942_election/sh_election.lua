--[[---------------------------------------------------------------------------
1942 DarkRP - Führer election (shared)

How an election runs:
    1. The office is vacant. Anyone opens the ballot (/election, or clicks
       Führer in F4) and pays the fee to stand. Everyone sees it in chat.
    2. The first candidate opens registration. Others can join until it closes.
    3. Voting: the ballot pops up for everyone. One vote each.
    4. Most votes wins (a tie is drawn by lot) and becomes Führer.
       Entry fees go to the Reich treasury.

While a Führer is in office nobody can stand. If one is appointed some other
way mid-election, the election is cancelled and every fee is refunded.

Files:
    sh_election.lua   this config + shared helpers
    sv_election.lua   the election itself (all rules are enforced here)
    cl_election.lua   the ballot window and the HUD notice
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.ElectionConfig = {
    fee              = 200,   -- cost to stand
    registrationTime = 60,    -- seconds candidates have to enter after the first one
    votingTime       = 45,    -- seconds of voting (ends early once everyone has voted)
    maxCandidates    = 6,
    unopposedWins    = true,  -- a lone candidate wins when registration closes;
                              -- false = cancelled and refunded (needs 2+ candidates)
    showLiveVotes    = true,  -- show vote counts while voting is still open
    feesToTreasury   = true,  -- winner's election: fees go to the Reich treasury
    openOnVoting     = true,  -- pop the ballot up for everyone when voting starts
    resultSeconds    = 10,    -- how long the "new Führer" banner stays up
}

--[[---------------------------------------------------------------------------
Sounds. Two kinds of path work:
    "sounds/anthem.mp3"            a file in this addon (path from the addon
                                   folder). Sent to players automatically;
                                   volume applies.
    "ambient/alarms/warningbell1.wav"   a stock game sound (under sound/).
                                   Plays at normal game volume.
Set a path to false to turn that sound off. Players can mute all election
sounds for themselves with:  rp1942_election_sounds 0
---------------------------------------------------------------------------]]
RP1942.ElectionSounds = {
    voting       = "ambient/alarms/warningbell1.wav",  -- when the ballot pops up to vote
    votingVolume = 0.8,
    anthem       = "sounds/anthem.mp3",                -- when a Führer is elected
    anthemVolume = 0.6,   -- also scaled by the player's music volume slider
    fuhrerKilled       = "ambient/alarms/klaxon1.wav", -- when the Führer dies
    fuhrerKilledVolume = 0.9,
    broadcast          = "npc/overwatch/radiovoice/on1.wav", -- Führer's /broadcast
    broadcastVolume    = 0.9,
}

--[[---------------------------------------------------------------------------
/broadcast <message> - Führer only. Shows the message to everyone as a banner
across the top of the screen (same style as the election announcements),
plays the sound above, and logs it in chat.
---------------------------------------------------------------------------]]
RP1942.FuhrerBroadcast = {
    enabled   = true,
    cooldown  = 60,    -- seconds between broadcasts
    maxLength = 160,   -- characters
}

--[[---------------------------------------------------------------------------
Alert when the Führer dies: red flash, a headline across the top of the
screen, the sound above, and a chat line. Everyone sees it.
---------------------------------------------------------------------------]]
RP1942.FuhrerDeathAlert = {
    enabled      = true,
    revealKiller = false,   -- true = the headline names who did it
    seconds      = 8,       -- how long the headline stays up
}

-- Phases, shared so the client can read what the server sends
RP1942.ELECTION_IDLE, RP1942.ELECTION_REGISTRATION, RP1942.ELECTION_VOTING = 0, 1, 2

-- The sitting Führer, or nil
function RP1942.getFuhrer()
    if not TEAM_FUHRER then return nil end
    return team.GetPlayers(TEAM_FUHRER)[1]
end

DarkRP.declareChatCommand{
    command = "election",
    description = "Open the Führer election ballot.",
    delay = 1,
}
