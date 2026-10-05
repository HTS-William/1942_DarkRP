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
VIPEnabled: false = VIP is switched off. Jobs marked vip{...} in jobs.lua are
            open to everyone and show no VIP tag. true = only the groups below.
VIPGroups:  usergroups that count as VIP. Staff are included so they can test
            VIP jobs; remove them if you don't want that.
---------------------------------------------------------------------------]]
C.VIPEnabled = false

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
    wehrmacht = { name = "the Wehrmacht",     entry = "wehrrifleman" },
    waffen_ss = { name = "the Waffen-SS",     entry = "wssrifleman" },
    leibstandarte = { name = "the Leibstandarte", entry = "leibstandarte" },   -- the single "Leibstandarte" job
}

C.FactionNames = {
    staff      = "staff duty",
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
Disguises (rp1942_core/sv_disguise.lua)
jobs:     job COMMANDS whose custom job title (F4 > Commands, or /job) is a
          SILENT cover: nobody is told. Commands, because TEAM_ numbers don't
          exist yet when this file loads. Typing your real job name reveals you.
freeform: false = cover must be the exact name of a civilian job (Baker, Doctor...)
          true  = any title of 3-25 characters
presets:  the tabs in each undercover job's F3 wardrobe (see below)
models:   an optional extra "Wardrobe" tab of plain models (see below)
---------------------------------------------------------------------------]]
C.Disguise = {
    jobs     = { gestapo = true, resoperative = true },
    freeform = true,

    -- Wardrobe tabs, by job command. Each tab lists that faction's jobs from
    -- jobs.lua; clicking one of a job's models puts it on AND silently sets
    -- your title to that job's name, like "Set a custom job title" in F4.
    -- Tabs: "civilian", "resistance", "reich"
    presets  = {
        gestapo      = { "civilian", "resistance" },   -- infiltrate the Resistance
        resoperative = { "civilian", "reich" },        -- pass as a Reich soldier
    },

    -- Leadership jobs are left out of the tabs: every whitelisted job
    -- (Offiziere, the Leibstandarte Kommandant, the Führer) and the jobs listed
    -- here. true = offer them too. The undercover jobs themselves are never offered.
    allowLeaders = false,
    leaderJobs   = { resleader = true },

    -- Optional: a plain list of models per job, shown as an extra "Wardrobe"
    -- tab (model only, the title isn't touched). Leave empty for no extra tab.
    -- For example:
    --   resoperative = { "models/player/group01/male_01.mdl", "models/player/group02/male_04.mdl" },
    models   = {
        gestapo      = {},
        resoperative = {},
    },
}

--[[---------------------------------------------------------------------------
Faction tags (rp1942_core/cl_faction_tags.lua)
A label above undercover jobs' heads that only their own side can see, so
colleagues recognise each other. Everyone else sees nothing.
jobs:      job COMMAND = { text, seenBy = faction that sees it, accent colour }
distance:  game units (~52 units = 1 m); it fades out over the last quarter
---------------------------------------------------------------------------]]
C.FactionTags = {
    enabled  = true,
    jobs     = {
        gestapo      = { text = "GESTAPO",    seenBy = "reich",      accent = Color(112, 22, 22) },
        resoperative = { text = "RESISTANCE", seenBy = "resistance", accent = Color(70, 104, 56) },
    },
    distance = 600,
    color    = Color(210, 200, 170),        -- text
    bg       = Color(14, 13, 12, 200),      -- label background
}

--[[---------------------------------------------------------------------------
Weapon classes
The left side is the name jobs.lua uses (W.k98k ...), the right side the class
from the weapon pack (the same mcv_* classes the dealers sell).
sv_checks.lua prints a warning for any class that doesn't exist.
---------------------------------------------------------------------------]]
RP1942.Weapons = {
    -- Reich small arms
    k98k        = "mcv_kar98",           -- Karabiner-98K
    k98k_scoped = "mcv_kar98_s",         -- Sniper Karabiner-98K
    g43         = "mcv_g43",             -- Gewehr 43
    mg34        = "mcv_mg43b",           -- MG-34 Belt (the Waffen-SS Machinegunner)
    stg44       = "mcv_stg44",           -- StG-44
    mp40        = "mcv_mp40",            -- MP 40 (the Wehrmacht NCO)
    p38         = "mcv_p38",             -- Walther P38, officer sidearm
    ppk         = "mcv_ppk",             -- Suppressed Walther PPK
    luger       = "mcv_luger",           -- Luger P08, Führer sidearm

    -- DarkRP built-ins (these exist already)
    stun        = "stunstick",           -- every Reich job carries stun + handcuffs + unarrest
    arrest      = "rp1942_handcuffs",    -- handcuffs: 8 s holding them still, then arrested (rp1942_handcuffs); "arrest_stick" = the instant baton
    unarrest    = "unarrest_stick",
    checker     = "weaponchecker",
    ram         = "door_ram",
    lockpick    = "lockpick",
    lockpick_pro = "rp1942_lockpick_pro", -- the Pro Thief's fast lockpick (lua/weapons/rp1942_lockpick_pro.lua)
    medkit      = "med_kit",
}

--[[---------------------------------------------------------------------------
Player models
PLACEHOLDERS: stock HL2/GMod models so the server boots and jobs are testable.
Replace with the paths from your content pack.
---------------------------------------------------------------------------]]
-- The civilians (the d42rp content pack)
local civM = {
    "models/d42rp/player/civilians/citizen_male_01.mdl",
    "models/d42rp/player/civilians/citizen_male_02.mdl",
    "models/d42rp/player/civilians/citizen_male_03.mdl",
    "models/d42rp/player/civilians/citizen_male_04.mdl",
    "models/d42rp/player/civilians/citizen_male_05.mdl",
    "models/d42rp/player/civilians/citizen_male_06.mdl",
    "models/d42rp/player/civilians/citizen_male_07.mdl",
    "models/d42rp/player/civilians/citizen_female_01.mdl",
    "models/d42rp/player/civilians/citizen_female_02.mdl",
    "models/d42rp/player/civilians/citizen_female_03.mdl",
    "models/d42rp/player/civilians/citizen_female_04.mdl",
}

-- The d42rp civilians pack: numbered models, e.g. numbered("rebel_male_", 7)
local function numbered(prefix, n)
    local t = {}
    for i = 1, n do t[#t + 1] = string.format("models/d42rp/player/civilians/%s%02d.mdl", prefix, i) end
    return t
end
local function join(...)
    local t = {}
    for _, list in ipairs({ ... }) do for _, m in ipairs(list) do t[#t + 1] = m end end
    return t
end

-- The Resistance: the rebels, men and women
local resModels = join(numbered("rebel_male_", 7), numbered("rebel_female_", 4))

RP1942.Models = {
    civilian     = civM,
    gestapo      = civM,   -- plain clothes: keep this identical to civilian, or the cover is pointless
    hobo         = civM,   -- the d42rp civilians, men and women
    merchant     = { "models/player/monk.mdl" },
    doctor       = { "models/player/kleiner.mdl" },
    banker       = { "models/player/gman_high.mdl" },
    staff        = { "models/player/breen.mdl" },   -- Staff on Duty
    -- The production jobs (Baker, Winemaker, Petroleum Producer, Factory Owner):
    -- the d42rp businessmen (men only, so everyone gets one of these)
    labourer     = numbered("business_male_", 7),
    -- The Resistance jobs (and the Thieves): the rebels (resModels, above)
    resistance   = resModels,
    -- The Resistance Operative's normal model ("Standard issue" in its wardrobe).
    -- Starts as the Resistance models; change it here without touching other jobs.
    resoperative = resModels,
    res_leader   = numbered("rebleader_male_", 7),   -- the rebel leaders
    -- The dealers, one model each
    dealer_blackmarket = { "models/d42rp/player/blackmarket_dealer.mdl" },
    dealer_cherkesov   = { "models/d42rp/player/cherkesov_dealer.mdl" },
    supplier           = { "models/d42rp/player/wehrmacht_supplier.mdl" },   -- the German Supplier
    dealer       = { "models/d42rp/player/blackmarket_dealer.mdl" },   -- (old shared key: the unused Rüstung Dealer)
    -- The Reich (models/d42rp/player): grunt = riflemen and the other ranks,
    -- nco = the NCO, kommandant = the Offizier. The Leibstandarte may pick any of its three.
    wehrmacht         = { "models/d42rp/player/wehrmacht_grunt.mdl" },
    wehrmacht_nco     = { "models/d42rp/player/wehrmacht_nco.mdl" },
    wehrmacht_officer = { "models/d42rp/player/wehrmacht_kommandant.mdl" },
    waffen_ss         = { "models/d42rp/player/waffen_grunt.mdl" },
    waffen_nco        = { "models/d42rp/player/waffen_nco.mdl" },
    waffen_officer    = { "models/d42rp/player/waffen_kommandant.mdl" },
    leibstandarte     = {   -- the Führer's bodyguard: a choice of all three
        "models/d42rp/player/leibstandarte_grunt.mdl",
        "models/d42rp/player/leibstandarte_nco.mdl",
        "models/d42rp/player/leibstandarte_kommandant.mdl",
    },
    officer      = { "models/d42rp/player/wehrmacht_kommandant.mdl" },   -- (old shared key, kept for anything still using it)
    scientist    = { "models/player/magnusson.mdl" },
    fuhrer       = { "models/player/breen.mdl" },
}
