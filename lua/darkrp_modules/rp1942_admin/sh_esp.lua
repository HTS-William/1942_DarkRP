--[[---------------------------------------------------------------------------
1942 DarkRP - admin ESP (shared)
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.ESP = {
    maxDistance = 0,       -- units; 0 = the whole map
    boxes       = true,    -- a box around each player you can see on screen
}

DarkRP.declareChatCommand{
    command     = "esp",
    description = "Staff: toggle ESP (see every player's name, job, health and distance through walls)",
    delay       = 1,
}
