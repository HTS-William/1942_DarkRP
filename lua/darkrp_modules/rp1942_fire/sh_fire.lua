--[[---------------------------------------------------------------------------
1942 DarkRP - Spreading fire (shared: the settings)

Fire that catches, spreads along the ground, burns people, and dies down on
its own unless it's put out. It's made of "fire nodes"
(lua/entities/rp1942_fire.lua): each one is an engine fire (env_fire) with
the molotov's fire sound, and our own damage and spreading around it. The
"look" setting can swap the flames for the molotov's ground fire particle.

WHAT STARTS A FIRE
    Molotovs and WP grenades   a cluster of fires where the pool would
                               burn (the pool itself is replaced, since it
                               can't be put out: replacePool)
    The flamethrower           where its stream lands on the ground
    Every explosion            grenades, dynamite, rockets, rifle grenades,
                               the flamethrower's tank, printers, rigs,
                               RP1942.explode: anything that deals blast
                               damage above blastMinDamage has a
                               blastChance of leaving fires behind
    Staff                      !fire where you're looking
    Code                       RP1942.startFire(pos, { attacker = ply, spots = 3, radius = 120 })

HOW IT SPREADS
    Every spreadInterval seconds each fire rolls spreadChance to light a new
    one spreadDistMin-spreadDistMax units away on walkable ground (never in water, never on a
    steep slope, never on top of another fire). A fire born from another is
    one "generation" older: its chance to spread is multiplied by
    spreadDecay each generation and stops at maxGeneration, so a fire grows
    into a patch and then burns out rather than eating the map. On top of
    that there's a hard cap on fires in all (maxFires) and per fire patch
    (maxPerCluster).

HOW IT'S PUT OUT
    * On its own: each fire lives lifeMin-lifeMax seconds
    * Fire extinguisher SWEP (Workshop 104607228, or any weapon whose class
      contains "extinguish", or one listed in extinguisherClasses): spraying
      at a fire within extinguishRange puts it out. That works whatever the
      SWEP does inside: while it's fired, we put out the fires it points at.
      Each fire put out pays extinguishReward, unless you lit it yourself
      (with a molotov or the like; fires lit by staff with !fire do pay).
      Fires also answer the env_fire "Extinguish" input addons send.
    * Water: fires never start in water
    * Staff: !extinguish (the patch you're looking at), !extinguishall

SERVER SETTINGS (server.cfg or the console; saved, so they stick)
    rp1942_fire 0/1              the whole system on or off
    rp1942_fire_spreading 0/1    fire spreads (1) or only burns where it
                                 was lit (0)
Everything else is a !firesetting (below), also saved.

STAFF (ULX 42Bros)
    !fire [spots]        start a fire where you're looking
    !extinguish          put out every fire within 400 units of where you look
    !extinguishall       put out every fire on the map
    !firestatus          how many fires are burning, and the settings
    !firesetting <key> <value>   change a setting below (saved to
                         data/rp1942/fire.json); "enabled 0" turns the whole
                         system off. No value: shows the current one.

The defaults are below. Values changed with !firesetting are saved in
data/rp1942/fire.json and win over these.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Fire = RP1942.Fire or {}
local F = RP1942.Fire

F.defaults = {
    enabled          = true,   -- the whole system (no fires at all)
    spreading        = true,   -- off: fires still start and burn, but never spread

    -- Burning
    damagePerSecond  = 12,     -- to players and NPCs standing in a fire
    burnRadius       = 70,     -- units from a fire's centre that burn you (~52 units = 1 m)
    afterburn        = 3,      -- seconds you keep burning after stepping out
    ignitePropsFor   = 8,      -- seconds nearby props are set alight (0 = never)
    lifeMin          = 45,     -- seconds a fire burns before dying on its own
    lifeMax          = 80,

    -- Looks and sound
    look             = "engine",   -- "engine":  the engine's env_fire flames
                                   -- "molotov": the molotov's ground fire particle at each fire (big)
    particle         = "Molotov_GroundFire",   -- the particle for the "molotov" look (the pack's pcf)
    flameSize        = 100,    -- "engine" look only: height of each flame in units
    sound            = "ambient/fire/fire_med_loop1.wav",   -- loops at each fire (the molotov pool's; "" = silent)
    soundLevel       = 75,     -- how far it carries (dB-ish: 60 quiet, 80 loud)

    -- Spreading
    spreadInterval   = 1.6,    -- seconds between each fire's attempts to spread
    spreadChance     = 0.5,    -- chance per attempt for a fresh fire (0-1)
    spreadDecay      = 0.75,   -- multiplied into the chance for each generation
    maxGeneration    = 7,      -- a fire this many steps from the start never spreads
    spreadDistMin    = 35,     -- units: how far a new fire appears from its parent
    spreadDistMax    = 85,     -- (with the "molotov" look use about 90-170: its particle is ~200 across)
    minSpacing       = 22,     -- units: no two fires closer than this
    maxFires         = 90,     -- hard cap on fires on the map at once
    maxPerCluster    = 36,     -- hard cap per patch (one molotov = one patch)

    -- Starting from weapons
    replacePool      = true,   -- the molotov / WP pool (unextinguishable, 12 s) is removed and
                               -- our fires take its place; false keeps it under them
    molotovSpots     = 7,      -- fires lit by a molotov / WP pool (within its radius)
    blastChance      = 0.15,   -- chance an explosion leaves fire behind (0-1)
    blastMinDamage   = 40,     -- explosions weaker than this never start fires
    blastMaxSpots    = 2,      -- most fires one explosion can start
    flamethrowerChance = 0.05, -- chance per flame tick (10 a second) that the ground it lands on catches

    -- Putting out
    extinguishReward = 20,     -- RM paid to a player for each fire they put out (not their own)
    extinguishRange  = 220,    -- units an extinguisher reaches
    extinguishAngle  = 35,     -- degrees either side of the crosshair it covers
    extinguishClasses = "weapon_extinguisher",   -- extra SWEP classes, comma separated
                                                 -- (any class containing "extinguish" already counts)
}

-- The live settings (the server loads fire.json over the defaults)
F.settings = F.settings or table.Copy(F.defaults)

function RP1942.fireSetting(key)
    local v = F.settings[key]
    if v == nil then v = F.defaults[key] end
    return v
end

-- Settings a staff member may change with !firesetting, in the order shown
F.keys = {}
for k in pairs(F.defaults) do F.keys[#F.keys + 1] = k end
table.sort(F.keys)
