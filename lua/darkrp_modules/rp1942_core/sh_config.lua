--[[---------------------------------------------------------------------------
1942 DarkRP - core configuration (shared)

Everything that jobs.lua, shipments.lua etc. need to look up lives here, so
swapping a weapon pack or model pack means editing ONE file.

NOTE: darkrp_modules load in reverse alphabetical order, so sh_factions.lua
runs BEFORE this file. Nothing in sh_factions reads RP1942.Config at load time,
only inside functions, so that's fine. Keep it that way.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Config = RP1942.Config or {}
local C = RP1942.Config

--[[---------------------------------------------------------------------------
VIP
Usergroups that count as VIP. Staff are included so they can test VIP jobs;
remove them if you don't want that.
---------------------------------------------------------------------------]]
C.VIPGroups = {
    ["vip"]        = true,
    ["admin"]      = true,
    ["superadmin"] = true,
}

--[[---------------------------------------------------------------------------
Whitelist (leadership jobs)
Disabled until the ranks module exists. When enabled, a job marked as
whitelisted asks the "RP1942_HasWhitelist" hook, and anything other than an
explicit `true` answer denies the job.
---------------------------------------------------------------------------]]
C.Whitelist = {
    enabled     = false,
    staffBypass = true,
}

--[[---------------------------------------------------------------------------
Branches and enlistment
Jobs with `requires = { branch = "..." }` can only be taken by someone who is
CURRENTLY serving in that branch. `entry` is the job command you enlist
through; it is only used to tell players where to start.
---------------------------------------------------------------------------]]
C.Branches = {
    wehrmacht = { name = "the Wehrmacht",     entry = "wehrrecruit" },
    waffen_ss = { name = "the Waffen-SS",     entry = "wssrecruit" },
    ss        = { name = "the Schutzstaffel", entry = "ssrecruit" },
}

C.FactionNames = {
    reich      = "the Reich",
    resistance = "the Resistance",
    civilian   = "civilian life",
}

--[[---------------------------------------------------------------------------
Faction balance
A faction may hold at most: floor + perOpponent * (players in opponent faction).
Example with the values below and 3 resistance online: Reich cap = 6 + 2*3 = 12.
Only applies when a player JOINS the faction (moving between Reich jobs is free),
and admins forcing a job bypass it.
---------------------------------------------------------------------------]]
C.Balance = {
    reich      = { floor = 6, perOpponent = 2, opponent = "resistance" },
    resistance = { floor = 4, perOpponent = 1, opponent = "reich" },
}

--[[---------------------------------------------------------------------------
Disguises (rp1942_disguise module)
jobs:     job COMMANDS allowed to use /disguise (commands, because TEAM_ numbers
          don't exist yet when this file loads)
freeform: false = cover must be the exact name of a civilian job (Baker, Doctor...)
          true  = any title of 3-25 characters
---------------------------------------------------------------------------]]
C.Disguise = {
    jobs     = { gestapo = true, resoperative = true },
    freeform = false,
}

--[[---------------------------------------------------------------------------
Weapon classes
PLACEHOLDERS: replace the right-hand side with the class names from your
weapon pack. sv_checks.lua prints a warning for any class that doesn't exist.
---------------------------------------------------------------------------]]
RP1942.Weapons = {
    -- Reich small arms
    k98k        = "weapon_rp1942_k98k",
    k98k_scoped = "weapon_rp1942_k98k_scoped",
    g43         = "weapon_rp1942_g43",
    mg42        = "weapon_rp1942_mg42",   -- swap for mg34 if preferred
    stg44       = "weapon_rp1942_stg44",
    p38         = "weapon_rp1942_p38",    -- officer sidearm
    ppk         = "weapon_rp1942_ppk",    -- Führer sidearm

    -- DarkRP built-ins (these exist already)
    arrest      = "arrest_stick",
    unarrest    = "unarrest_stick",
    checker     = "weaponchecker",
    ram         = "door_ram",
    lockpick    = "lockpick",
    lockpick_pro = "lockpick",            -- TODO: replace with the upgraded lockpick SWEP
    medkit      = "med_kit",
}

--[[---------------------------------------------------------------------------
Player models
PLACEHOLDERS: stock HL2/GMod models so the server boots and jobs are testable.
Replace with the paths from your content pack.
---------------------------------------------------------------------------]]
local civM = {
    "models/player/group01/male_02.mdl",
    "models/player/group01/male_04.mdl",
    "models/player/group01/male_07.mdl",
    "models/player/group01/female_01.mdl",
    "models/player/group01/female_04.mdl",
}

RP1942.Models = {
    civilian     = civM,
    gestapo      = civM,   -- plain clothes: keep this identical to civilian, or the cover is pointless
    hobo         = { "models/player/group01/male_01.mdl" },
    merchant     = { "models/player/monk.mdl" },
    doctor       = { "models/player/kleiner.mdl" },
    banker       = { "models/player/gman_high.mdl" },
    labourer     = { "models/player/group02/male_02.mdl", "models/player/group02/male_06.mdl" },
    resistance   = { "models/player/group03/male_01.mdl", "models/player/group03/male_05.mdl", "models/player/group03/female_02.mdl" },
    res_leader   = { "models/player/odessa.mdl" },
    dealer       = { "models/player/eli.mdl" },
    wehrmacht    = { "models/player/combine_soldier.mdl" },
    waffen_ss    = { "models/player/combine_soldier_prisonguard.mdl" },
    ss           = { "models/player/police.mdl" },
    officer      = { "models/player/combine_super_soldier.mdl" },
    scientist    = { "models/player/magnusson.mdl" },
    fuhrer       = { "models/player/breen.mdl" },
}
