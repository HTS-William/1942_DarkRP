--[[---------------------------------------------------------------------------
1942 DarkRP - /roll (shared)

    /roll          a number from 1 to 100
    /roll 20       1 to 20
    /roll 5 50     5 to 50        (/roll 5-50 works too)
    /roll 2d6      dice: two six-sided dice, each shown, plus the total

The server does the rolling, so results can't be faked. Shown to players
near you (like /me), in the colour below.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.RollConfig = {
    defaultMax = 100,              -- /roll on its own: 1 to this
    maxValue   = 1000000,          -- biggest number anyone can roll up to
    maxDice    = 10,               -- /roll NdM: at most this many dice at once
    range      = "local",          -- "local" = players near you, "global" = everyone
    distance   = nil,              -- how near, in game units; nil = same as /me
    cooldown   = 2,                -- seconds between rolls
    color      = Color(201, 168, 92),
}

DarkRP.declareChatCommand{
    command = "roll",
    description = "Roll a random number: /roll, /roll 20, /roll 5 50, /roll 2d6",
    delay = RP1942.RollConfig.cooldown,
}
