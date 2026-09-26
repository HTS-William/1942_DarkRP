--[[---------------------------------------------------------------------------
1942 DarkRP - world events (shared config)

Random events that happen on their own every so often. The scheduler picks
one at random (by weight) from the events that are allowed to run right now.

Admins can also run one by hand (who counts as an admin: adminCheck below):
    /train                    start the supply train now
    /event                    list events and whether one is running
    /event train              same as /train
    /event stop               end the running event
    rp1942_event [id | stop]  the same from the console (also the server console)

Files:
    sh_events.lua        this config
    sv_events.lua        the scheduler and the console command
    sv_event_train.lua   the supply train event
    cl_events.lua        the "hold E" progress bar
    lua/entities/rp1942_supply_train/   the train itself
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.Events = {
    enabled     = true,
    firstDelay  = 1200,                       -- seconds after the map loads before the first event
    interval    = { min = 1200, max = 1200 }, -- seconds between events: every 20 minutes.
                                              -- Make min and max different for a random gap.
                                              -- Admin-started events don't change this timer.
    minPlayers  = 4,                          -- no automatic events below this many players online

    -- Who may use /train, /event and rp1942_event. IsAdmin() is true for
    -- admins and superadmins; use ply:IsSuperAdmin() to tighten it.
    adminCheck  = function(ply) return ply:IsAdmin() end,
}

DarkRP.declareChatCommand{
    command     = "event",
    description = "Admin: list world events, start one (/event train) or end it (/event stop)",
    delay       = 1.5,
    condition   = function(ply) return RP1942.Events.adminCheck(ply) end,
}

DarkRP.declareChatCommand{
    command     = "train",
    description = "Admin: start the supply train event now",
    delay       = 1.5,
    condition   = function(ply) return RP1942.Events.adminCheck(ply) end,
}

--[[---------------------------------------------------------------------------
Supply train
A Reich supply train rolls in from behind the start point, stops at the
station, blows its horn and carries on down the line. It vanishes when it
reaches the end. Anyone outside the Reich can hold E on it to rob a crate
(money and a weapon, straight into their pockets), which makes them wanted.
Whatever wasn't stolen by the end goes to the Reich treasury.

    [spawn] ---> start ---> stop (station) ======> finish (vanishes)
     hidden behind          waits stopTime
---------------------------------------------------------------------------]]
RP1942.Events.train = {
    enabled    = true,
    weight     = 1,          -- chance relative to other events (only one event exists so far)
    minPlayers = 4,          -- overrides the global minimum for this event
    map        = nil,        -- e.g. "rp_yourmap": only run on that map. nil = any map
                             -- (set this if you ever run a map where the coordinates below make no sense)

    -- The line. Every point shares the same X and Z so the path is perfectly
    -- straight along the Y axis. (Measured X: start -1710.44, stop -1712.24,
    -- end -1713.50; all set to -1712.)
    start  = Vector(-1712, 1031.97, -887.97),   -- where it comes in from
    stop   = Vector(-1712, 617.12, -887.97),    -- the station: it stops here
    finish = Vector(-1712, -3935.97, -887.97),  -- the end of the ride: it vanishes here
    spawnBehind = "auto",    -- how far behind the start it spawns (units). "auto" = one
                             -- train length, so its nose starts at the start point
    groundTrace = true,      -- drop the train onto whatever is below the line (the rails)
    zOffset     = 0,         -- raise (+) or lower (-) the train if it floats or sinks
    yawOffset   = 0,         -- if the train drives backwards set 180; sideways: 90 or -90

    model      = "models/props_trainstation/diesel.mdl",
    hornSound  = "ambient/alarms/train_horn2.wav",
    wheelSound = "ambient/machines/razor_train_wheels_loop1.wav",
    hornLevel  = 140,        -- how far the horn carries (decibels; 140 is most of a map)
    wheelLevel = 90,

    stopTime     = 20,       -- seconds it waits at the station
    hornOnDepart = true,     -- blow the horn again when it leaves the station
    speed        = 200,      -- units per second at full speed (a running player is ~240)
    accelTime    = 4,        -- seconds to get up to speed / to brake to a stop
    fadeTime     = 0.5,      -- seconds it takes to vanish at the end
    shoveForce   = 450,      -- how hard it knocks players off the line
    hitDamage    = 20,       -- damage per hit (at most once a second); 0 = none

    -- Cargo
    crates       = 6,        -- how many times it can be robbed
    holdTime     = 4,        -- seconds of holding E to rob one crate
                             -- The money goes straight into the robber's wallet and the
                             -- weapon into their pocket (full pocket: dropped at their feet).
    useRange     = 140,      -- how close you have to be (units)
    money        = { min = 400, max = 900 },   -- per crate
    weaponChance = 70,       -- % of crates that also contain a weapon
    -- weapon class = weight (higher = more common). German weapons from the
    -- German Supplier's list. Classes that aren't installed are skipped.
    weapons = {
        mcv_kar98               = 30,
        mcv_mp40                = 20,
        mcv_p38                 = 20,
        mcv_luger               = 15,
        mcv_g43                 = 10,
        mcv_stg44               = 8,
        mcv_stielhand_explosive = 8,
        mcv_mg43                = 3,
        mcv_panzerschreck       = 1,
    },

    -- Who may rob it: factions that CANNOT (the Reich guards its own train)
    blockedFactions = { reich = true },
    wantedOnRob     = true,  -- robbing makes you wanted ("train_robbery" below)
    leftoverToTreasury = true, -- unrobbed crates' money goes to the Reich treasury

    -- Messages (Reich Alert! boxes). %d is filled with a number.
    msgStart    = "A Reich supply train is pulling into the station.",
    msgRobbed   = "The supply train is being robbed!",     -- to the Reich, once per train
    msgDone     = "The supply train has arrived. %d Reichsmark reached the treasury.",
    msgEmpty    = "The supply train was stripped bare before it arrived.",
}

-- Reason text for robbing the train, added to the wanted system's reasons
if RP1942.Wanted and RP1942.Wanted.reasons then
    RP1942.Wanted.reasons.train_robbery = { text = "For robbing a Reich supply train", time = 300 }
end

--[[---------------------------------------------------------------------------
Event registry (server). Each event file calls:
    RP1942.registerEvent("id", {
        name     = "Shown in rp1942_event",
        config   = RP1942.Events.<id>,          -- uses enabled / weight / minPlayers / map
        canStart = function() return true end,  -- optional extra condition
        start    = function() ... end,          -- return false if it couldn't start
        isActive = function() return bool end,
        stop     = function() ... end,          -- end it early
    })
---------------------------------------------------------------------------]]
RP1942.EventList = RP1942.EventList or {}

function RP1942.registerEvent(id, def)
    def.id = id
    RP1942.EventList[id] = def
end
