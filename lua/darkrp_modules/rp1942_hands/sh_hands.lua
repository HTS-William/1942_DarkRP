--[[---------------------------------------------------------------------------
1942 DarkRP - Hands (shared: the settings)

Everyone spawns with Hands (slot 1, weapon rp1942_hands) and holds them by
default. Hands down, nothing happens: you can walk around without fists up.

    LEFT CLICK    raises your fists; click again to punch (left, right...)
    RIGHT CLICK   push the player in front of you (fists up or down)
    R             raise or lower your fists
Fists drop by themselves after lowerAfter seconds without a punch.

Punches hurt players (and NPCs) only. Props get a nudge; doors, padlocks and
fires take no damage from a punch. A push only moves players, never someone
sitting, in a vehicle or in noclip.

Files: sh_hands.lua (this), sv_hands.lua (spawn holding them, the push
gesture), cl_hands.lua (the push gesture), lua/weapons/rp1942_hands.lua.
In darkrp_config/settings.lua: in DefaultWeapons and DisallowDrop.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.HandsConfig = {
    punchDamage   = 8,      -- per punch
    punchDelay    = 0.55,   -- seconds between punches
    punchRange    = 48,     -- how far a punch reaches (units; a player is ~72 tall)
    pushForce     = 320,    -- how hard a push shoves someone
    pushUp        = 90,     -- and how much it lifts them, so it carries
    pushRange     = 60,     -- how far you reach to push
    pushDelay     = 1.5,    -- seconds between pushes
    lowerAfter    = 6,      -- fists drop after this many seconds without a punch (0 = never)
    selectOnSpawn = true,   -- spawn holding your hands
}
