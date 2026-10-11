--[[---------------------------------------------------------------------------
42Bros - server console logs (settings)

Every line starts with a tag, so the console and the log files can be
searched by kind:

    [42Bros][KILL]    a player killed by a player: jobs, sides, weapon, distance,
                    and flags staff care about (SAME SIDE, UNARMED, KILLER ON NLR,
                    STAFF ON DUTY, VICTIM ARRESTED)
    [42Bros][DEATH]   other deaths: suicide, falls, fire, bombs, props
    [42Bros][MONEY]   money between players and to/from the game: /give, dropped
                    money and cheques, food bought with E, market sales,
                    shop purchases, printers emptied, dead drops
    [42Bros][BIG]     anything that looks like an exploit: one payment of
                    bigPayment or more (with the file and line that paid it),
                    or someone earning fastEarnings within fastWindow
    [42Bros][STATUS]  every statusEvery seconds: players per side, treasury,
                    economy, money in wallets, the richest players
    [42Bros][SETUP]   once after the map loads: what's placed on this map and
                    what's missing
    [42Bros][LEAVE]   what was removed when a player left (sv_disconnect_cleanup)

Lines also go to a file per day: garrysmod/data/rp1942/logs/YYYY-MM-DD.txt
(download it from your host's file manager). Old files are not deleted.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.Logs = {
    toFile        = true,     -- also write data/rp1942/logs/<date>.txt
    toConsole     = true,

    bigPayment    = 10000,    -- [BIG]: one payment this size or more
    fastEarnings  = 25000,    -- [BIG]: earned this much...
    fastWindow    = 600,      -- ...within this many seconds

    statusEvery   = 600,      -- seconds between [STATUS] lines (0 = off)
    statusRichest = 3,        -- how many of the richest players to name

    startupDelay  = 30,       -- seconds after the map loads before the [SETUP] check

    -- Weapons that don't count as "armed" for the UNARMED flag
    -- (the default weapons from settings.lua are added on top)
    harmless = {
        keys = true, pocket = true, weapon_physgun = true, weapon_physcannon = true,
        gmod_tool = true, gmod_camera = true, rp1942_hands = true,
        arrest_stick = true, unarrest_stick = true, weaponchecker = true, med_kit = true,
        door_ram = true, lockpick = true, rp1942_lockpick_pro = true,
    },
}
