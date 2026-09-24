--[[---------------------------------------------------------------------------
1942 DarkRP - jobs

Custom fields used by the rp1942 modules (DarkRP ignores unknown fields):
    faction  = "civilian" | "resistance" | "reich"   (faction balance, radio, orders)
    branch   = "wehrmacht" | "waffen_ss" | "ss" | ... (unit within the Reich)
    requires = { branch = ... } / { faction = ... }   (must CURRENTLY hold such a job)
    arrests  = false                                  (Reich job WITHOUT police powers)
    vip / whitelisted                                 (set via the vip{} / whitelisted{} helpers)

Reich enlistment is two hops:
    1. Join a branch through its Recruit job ("Reich" category, visible to all)
    2. Pick a posting from that branch's category, which is only VISIBLE in F4
       while you hold a job in that branch (canSee in categories.lua) and only
       TAKEABLE from inside the branch (requires = { branch = ... } below).
Leave the branch and you have to enlist again.

Weapons and models come from RP1942.Weapons / RP1942.Models in
darkrp_modules/rp1942_core/sh_config.lua. Edit them there, not here.

Caps: max = 0 is unlimited, whole numbers are hard caps. Fractions (0.25 =
25% of the server) are deliberately NOT used: at low population they block
the job entirely.
---------------------------------------------------------------------------]]
if not (RP1942 and RP1942.Weapons and RP1942.Models and RP1942.jobGateFailure) then
    -- Report exactly what the Lua filesystem shows, so the cause is in the error itself
    local _, moduleDirs = file.Find("darkrp_modules/*", "LUA")
    local coreFiles = file.Find("darkrp_modules/rp1942_core/*", "LUA")
    local disabled = GAMEMODE.Config.DisabledCustomModules and GAMEMODE.Config.DisabledCustomModules["rp1942_core"]

    DarkRP.error("The rp1942_core module did not load (or is outdated), so jobs.lua can't run.", 1, {
        "Realm: " .. (SERVER and "SERVER" or "CLIENT"),
        "Folders in darkrp_modules/: " .. (#moduleDirs > 0 and table.concat(moduleDirs, ", ") or "(none)"),
        "Files in darkrp_modules/rp1942_core/: " .. (#coreFiles > 0 and table.concat(coreFiles, ", ") or "(none)"),
        "Disabled in DisabledCustomModules: " .. tostring(disabled == true),
        "RP1942 table exists: " .. tostring(RP1942 ~= nil),
        "RP1942.jobGateFailure exists: " .. tostring(RP1942 ~= nil and RP1942.jobGateFailure ~= nil) .. " (false = old sh_factions.lua)",
        "Module files must be named sh_*.lua / sv_*.lua / cl_*.lua exactly (no .txt, no ' (1)').",
        "Any error printed BEFORE this one mentioning rp1942_core is the real cause.",
    })
end

local W, M = RP1942.Weapons, RP1942.Models
local SAL = GAMEMODE.Config.normalsalary

-- VIP-only job: shows "(VIP)" in F4
local function vip(job)
    job.vip = true
    job.label = (job.label or job.name) .. " (VIP)"
    return job
end

-- Leadership job: requires a whitelist once RP1942.Config.Whitelist.enabled = true
local function whitelisted(job)
    job.whitelisted = true
    return job
end

--[[---------------------------------------------------------------------------
job{} wraps DarkRP.createJob:
  - keeps name inside the table
  - turns vip / whitelisted / requires / a job's own customCheck into ONE
    customCheck, with a CustomCheckFailMsg that says which rule failed
    (see RP1942.jobGateFailure in rp1942_core/sh_factions.lua)
---------------------------------------------------------------------------]]
local function job(tbl)
    local name = tbl.name
    tbl.name = nil

    -- A job's own customCheck becomes the last gate
    if tbl.customCheck then
        tbl.gate, tbl.gateFailMsg = tbl.customCheck, tbl.CustomCheckFailMsg
    end

    if tbl.vip or tbl.whitelisted or tbl.requires or tbl.gate then
        tbl.customCheck = function(ply) return RP1942.jobGateFailure(ply, tbl) == nil end
        tbl.CustomCheckFailMsg = function(ply) return RP1942.jobGateFailure(ply, tbl) or "" end
    end

    -- Jobs with a menu open it on F3 (DarkRP calls job.ShowSpare1 when F3 is pressed)
    if tbl.menu and not tbl.ShowSpare1 then
        tbl.ShowSpare1 = function(ply)
            if CLIENT then RP1942.openJobMenu() end
        end
    end

    return DarkRP.createJob(name, tbl)
end

--[[###########################################################################
                           CIVILIANS & RESISTANCE
###########################################################################]]

--[[===========================================================================
CIVILIANS
===========================================================================]]
TEAM_CIVILIAN = job{
    name = "Civilian",
    color = Color(120, 120, 110),
    model = M.civilian,
    description = [[An ordinary resident of the city. Keep your papers in order and your head down.]],
    weapons = {},
    command = "civilian",
    max = 0,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    candemote = false,
    category = "Civilians",
    sortOrder = 1,
}

-- Set immediately: if a later job errors, players can still join as Civilian
GAMEMODE.DefaultTeam = TEAM_CIVILIAN

TEAM_HOBO = job{
    name = "Hobo",
    color = Color(90, 80, 65),
    model = M.hobo,
    description = [[Has nothing and owes nobody. Scrapes by on scraps and whatever's worth taking from the bins.]],
    weapons = {},
    command = "hobo",
    max = 0,
    salary = SAL * 0.5,
    admin = 0,
    faction = "civilian",
    category = "Civilians",
}

--[=[ depreciated
TEAM_DESIGNER = job{
    name = "Designer",
    color = Color(150, 110, 70),
    model = M.merchant,
    description = [[Sells clothing and body armour of varying quality to civilians and Reich officials alike.]],
    weapons = {},
    command = "designer",
    max = 2,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Civilians",
}
]=]
TEAM_DOCTOR = job{
    name = "Doctor",
    color = Color(170, 170, 170),
    model = M.doctor,
    description = [[Treats the wounded. Can be engaged by anyone, government or civilian.]],
    weapons = { W.medkit },
    command = "doctor",
    max = 3,
    salary = SAL * 1.2,
    admin = 0,
    medic = true,
    faction = "civilian",
    category = "Civilians",
}

TEAM_BANKER = job{
    name = "Banker",
    color = Color(130, 120, 60),
    model = M.banker,
    description = [[Operates the Reichsbank's legal currency printers (max 3). Printers can be stolen.]],
    weapons = {},
    command = "banker",
    max = 2,
    salary = SAL * 1.3,
    admin = 0,
    faction = "civilian",
    category = "Civilians",
}

TEAM_PETROLEUM = job{
    name = "Petroleum Producer",
    color = Color(60, 60, 60),
    model = M.labourer,
    description = [[Places oil rigs on the lake. Each rig produces oil every 6 minutes.]],
    weapons = {},
    command = "petroleum",
    max = 2,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Civilians",
}

TEAM_WINEMAKER = job{
    name = "Winemaker",
    color = Color(110, 30, 50),
    model = M.labourer,
    description = [[Buys barrels of wine and ferments them (4 minutes).]],
    weapons = {},
    command = "winemaker",
    max = 2,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Civilians",
}

TEAM_FACTORY = job{
    name = "Factory Owner",
    color = Color(90, 80, 70),
    model = M.labourer,
    description = [[Buys factories that produce random goods of varying rarity.
Production halts twice per cycle and must be restarted by hand.]],
    weapons = {},
    command = "factoryowner",
    max = 2,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Civilians",
}
--[=[ Depreciated - moved to Doctor
TEAM_PHARMACIST = job{
    name = "Pharmacist",
    color = Color(80, 120, 100),
    model = M.doctor,
    description = [[Produces opium. It makes you faster and lighter on your feet. Too much will kill you.]],
    weapons = {},
    command = "pharmacist",
    max = 1,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Civilians",
}
]=]
TEAM_BAKER = job{
    name = "Baker",
    color = Color(190, 160, 110),
    model = M.labourer,
    description = [[Buys ovens and bakes bread from flour (3 minutes, 1-3 loaves per batch).]],
    weapons = {},
    command = "baker",
    max = 3,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Civilians",
}

--[[===========================================================================
RESISTANCE (incl. black-market dealers)
===========================================================================]]
TEAM_BLACKMARKET = job{
    name = "Black Market Dealer",
    color = Color(70, 50, 40),
    model = M.dealer,
    description = [[Deals pistols, shotguns, scoped rifles and melee weapons.]],
    weapons = {},
    command = "blackmarket",
    max = 2,
    salary = SAL,
    admin = 0,
    faction = "resistance",
    branch = "resistance", requires = { faction = "resistance" },
    category = "Resistance",
}

--[=[TEAM_RUSTUNG = job{
    name = "Rüstung Dealer",
    color = Color(100, 70, 40),
    model = M.dealer,
    description = [[Deals submachine guns, heavy weapons and explosives.]],
    weapons = {},
    command = "rustung",
    max = 1,
    salary = SAL,
    admin = 0,
    faction = "resistance",
    branch = "resistance",
    category = "Resistance",
}]=]

TEAM_CHERKESOV = job{
    name = "Cherkesov Dealer",
    color = Color(120, 40, 30),
    model = M.dealer,
    description = [[Deals almost everything on the server, including explosives otherwise only the German Supplier can get.]],
    weapons = {},
    command = "cherkesov",
    max = 1,
    salary = SAL,
    admin = 0,
    faction = "resistance",
    branch = "resistance", requires = { faction = "resistance" },
    category = "Resistance",
}

TEAM_THIEF = job{
    name = "Thief",
    color = Color(90, 40, 40),
    model = M.resistance,
    description = [[Carries a standard lockpick.]],
    weapons = { W.lockpick },
    command = "thief",
    max = 4,
    salary = SAL * 0.8,
    admin = 0,
    faction = "resistance",
    branch = "resistance",
    category = "Resistance",
}

TEAM_PROTHIEF = job{
    name = "Pro Thief",
    color = Color(110, 45, 45),
    model = M.resistance,
    description = [[Carries an upgraded lockpick that works much faster.]],
    weapons = { W.lockpick_pro },
    command = "prothief",
    max = 2,
    salary = SAL * 0.8,
    admin = 0,
    faction = "resistance",
    branch = "resistance", requires = { faction = "resistance" },
    category = "Resistance",
}

TEAM_RESISTANCE = job{
    name = "Resistance",
    color = Color(130, 50, 40),
    model = M.resistance,
    description = [[A member of the underground. Arm yourself through the black market.]],
    weapons = {},
    command = "resistance",
    max = 0,   -- uncapped per job; faction balance still applies
    salary = SAL * 0.8,
    admin = 0,
    faction = "resistance",
    branch = "resistance",
    category = "Resistance",
}

TEAM_RES_MEDIC = job{
    name = "Resistance Medic",
    color = Color(140, 70, 60),
    model = M.resistance,
    description = [[Patches up the underground. Carries a medkit.]],
    weapons = { W.medkit },
    command = "resmedic",
    max = 2,
    salary = SAL * 0.8,
    admin = 0,
    faction = "resistance",
    branch = "resistance", requires = { faction = "resistance" },
    category = "Resistance",
}

TEAM_RES_OPERATIVE = job{
    name = "Resistance Operative",
    color = Color(100, 30, 30),
    model = M.resistance,
    description = [[Intelligence and infiltration for the underground.
Use /disguise <trade> to pose as a civilian trade, /undisguise to drop it.]],
    weapons = { W.lockpick },
    command = "resoperative",
    max = 2,
    salary = SAL,
    admin = 0,
    faction = "resistance",
    branch = "resistance", requires = { faction = "resistance" },
    category = "Resistance",
}

TEAM_RES_LEADER = job{
    name = "Resistance Leader",
    color = Color(160, 30, 30),
    model = M.res_leader,
    description = [[Leads the underground. Carries a baton that frees jailed comrades.]],
    weapons = { W.unarrest },
    command = "resleader",
    max = 1,
    salary = SAL * 1.2,
    admin = 0,
    faction = "resistance",
    branch = "resistance", requires = { faction = "resistance" },
    category = "Resistance",
}

--[[###########################################################################
                                   REICH
###########################################################################]]

--[[===========================================================================
HOP 1 - ENLISTMENT ("Reich" category, visible to everyone)
Recruits are a staging job: no weapons, no police powers. Pick a posting next.
===========================================================================]]
TEAM_WEHR_RECRUIT = job{
    name = "Wehrmacht Recruit",
    color = Color(110, 118, 98),
    model = M.wehrmacht,
    description = [[Enlist in the Wehrmacht. Your postings will appear in the Wehrmacht section of this menu.]],
    weapons = {},
    command = "wehrrecruit",
    max = 0,   -- faction balance still applies
    salary = SAL * 0.5,
    admin = 0,
    faction = "reich",
    branch = "wehrmacht",
    arrests = false,
    category = "Reich",
    sortOrder = 1,
}

TEAM_WSS_RECRUIT = job{
    name = "Waffen-SS Recruit",
    color = Color(75, 80, 64),
    model = M.waffen_ss,
    description = [[Enlist in the Waffen-SS. Your postings will appear in the Waffen-SS section of this menu.]],
    weapons = {},
    command = "wssrecruit",
    max = 0,
    salary = SAL * 0.5,
    admin = 0,
    faction = "reich",
    branch = "waffen_ss",
    arrests = false,
    category = "Reich",
    sortOrder = 2,
}

TEAM_SS_RECRUIT = job{
    name = "SS Recruit",
    color = Color(55, 55, 55),
    model = M.ss,
    description = [[Enlist in the Schutzstaffel. Your postings will appear in the Schutzstaffel section of this menu.]],
    weapons = {},
    command = "ssrecruit",
    max = 0,
    salary = SAL * 0.5,
    admin = 0,
    faction = "reich",
    branch = "ss",
    arrests = false,
    category = "Reich",
    sortOrder = 3,
}

-- Single-hop Reich jobs (no branch)
TEAM_SUPPLIER = job{
    name = "German Supplier",
    color = Color(80, 90, 70),
    model = M.merchant,
    description = [[Supplies the Reich with weapons and explosives at a steep discount.]],
    weapons = {},
    command = "gersupplier",
    max = 1,
    salary = SAL,
    admin = 0,
    faction = "reich",
    branch = "supply",
    arrests = false,   -- a contractor, not police
    category = "Reich",
    sortOrder = 10,
}

TEAM_SCIENTIST = job{
    name = "Reich Scientist",
    color = Color(150, 150, 140),
    model = M.scientist,
    -- TODO: role undefined in the design doc. No police powers until decided.
    description = [[Conducts research for the Reich.]],
    weapons = {},
    command = "scientist",
    max = 1,
    salary = SAL * 1.5,
    admin = 0,
    faction = "reich",
    branch = "staff",
    arrests = false,
    category = "Reich",
    sortOrder = 11,
}

--[[===========================================================================
HOP 2 - WEHRMACHT ("Wehrmacht" category, visible only inside the Wehrmacht)
===========================================================================]]
TEAM_WEHR_RIFLEMAN = job{
    name = "Wehrmacht Rifleman",
    color = Color(93, 101, 82),
    model = M.wehrmacht,
    description = [[The backbone of the garrison. Carries a Karabiner 98k.]],
    weapons = { W.k98k, W.arrest },
    command = "wehrrifleman",
    max = 8,
    salary = SAL * 1.1,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Wehrmacht",
}

TEAM_WEHR_MEDIC = job{
    name = "Wehrmacht Medic",
    color = Color(100, 108, 90),
    model = M.wehrmacht,
    description = [[Rifleman's kit plus a medkit.]],
    weapons = { W.k98k, W.arrest, W.medkit },
    command = "wehrmedic",
    max = 2,
    salary = SAL * 1.1,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Wehrmacht",
}

TEAM_WEHR_ELITE = job(vip{
    name = "Wehrmacht Elite Rifleman",
    color = Color(85, 95, 75),
    model = M.wehrmacht,
    description = [[Carries a Gewehr 43.]],
    weapons = { W.g43, W.arrest },
    command = "wehrelite",
    max = 3,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Wehrmacht",
})

TEAM_WEHR_SHARPSHOOTER = job(vip{
    name = "Wehrmacht Sharpshooter",
    color = Color(80, 90, 70),
    model = M.wehrmacht,
    description = [[Carries a scoped Karabiner 98k.]],
    weapons = { W.k98k_scoped, W.arrest },
    command = "wehrsharpshooter",
    max = 2,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Wehrmacht",
})

TEAM_WEHR_DRIVER = job{
    name = "Wehrmacht Driver",
    color = Color(75, 85, 70),
    model = M.wehrmacht,
    description = [[Drives the armoured personnel carrier funded by the Führer.]],
    weapons = { W.k98k, W.arrest },
    command = "wehrdriver",
    max = 1,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Wehrmacht",
}

TEAM_WEHR_NCO = job{
    name = "Wehrmacht NCO",
    color = Color(70, 80, 60),
    model = M.wehrmacht,
    description = [[Commands the Wehrmacht enlisted ranks. Can search for weapons and breach doors with a warrant.]],
    weapons = { W.k98k, W.p38, W.arrest, W.unarrest, W.checker, W.ram },
    command = "wehrnco",
    max = 2,
    salary = SAL * 1.4,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Wehrmacht",
}

TEAM_WEHR_OFFIZIER = job(whitelisted{
    name = "Wehrmacht Offizier",
    color = Color(60, 70, 55),
    model = M.officer,
    description = [[Commands all of the Wehrmacht. Sets jail positions and issues orders.]],
    weapons = { W.p38, W.arrest, W.unarrest, W.checker, W.ram },
    command = "wehroffizier",
    max = 1,
    salary = SAL * 1.8,
    admin = 0,
    chief = true,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Wehrmacht",
    sortOrder = 200,
})

--[[===========================================================================
HOP 2 - WAFFEN-SS ("Waffen-SS" category, visible only inside the Waffen-SS)
===========================================================================]]
TEAM_WSS_RIFLEMAN = job{
    name = "Waffen-SS Rifleman",
    color = Color(60, 64, 50),
    model = M.waffen_ss,
    description = [[Carries a Gewehr 43.]],
    weapons = { W.g43, W.arrest },
    command = "wssrifleman",
    max = 4,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Waffen-SS",
}

TEAM_WSS_MEDIC = job{
    name = "Waffen-SS Medic",
    color = Color(66, 70, 56),
    model = M.waffen_ss,
    description = [[Carries a Gewehr 43 and a medkit.]],
    weapons = { W.g43, W.arrest, W.medkit },
    command = "wssmedic",
    max = 1,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Waffen-SS",
}

TEAM_WSS_MG = job{
    name = "Waffen-SS Machinegunner",
    color = Color(55, 60, 45),
    model = M.waffen_ss,
    description = [[Carries an MG 42.]],
    weapons = { W.mg42, W.arrest },
    command = "wssmg",
    max = 2,
    salary = SAL * 1.3,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Waffen-SS",
}

TEAM_WSS_NCO = job(vip{
    name = "Waffen-SS NCO",
    color = Color(50, 55, 40),
    model = M.waffen_ss,
    description = [[Commands the Waffen-SS enlisted ranks. Carries an StG 44.]],
    weapons = { W.stg44, W.p38, W.arrest, W.unarrest, W.checker, W.ram },
    command = "wssnco",
    max = 1,
    salary = SAL * 1.5,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Waffen-SS",
}) --kept as VIP so the proper format is seen here

TEAM_1ST_SS = job(whitelisted{
    name = "1st SS",
    color = Color(20, 20, 20),
    model = M.waffen_ss,
    description = [[The Führer's personal bodyguard. Carries an StG 44.]],
    weapons = { W.stg44, W.arrest },
    command = "firstss",
    max = 3,
    salary = SAL * 1.6,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Waffen-SS",
    sortOrder = 190,
})

TEAM_WSS_OFFIZIER = job(whitelisted{
    name = "Waffen-SS Offizier",
    color = Color(40, 44, 34),
    model = M.officer,
    description = [[Commands all of the Waffen-SS.]],
    weapons = { W.stg44, W.p38, W.arrest, W.unarrest, W.checker, W.ram },
    command = "wssoffizier",
    max = 1,
    salary = SAL * 1.8,
    admin = 0,
    chief = true,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Waffen-SS",
    sortOrder = 200,
})

--[[===========================================================================
HOP 2 - SCHUTZSTAFFEL ("Schutzstaffel" category, visible only inside the SS)
Mirrors the Wehrmacht, minus Driver and Elite Rifleman.
===========================================================================]]
TEAM_SS_RIFLEMAN = job{
    name = "SS Rifleman",
    color = Color(45, 45, 45),
    model = M.ss,
    description = [[Carries a Karabiner 98k.]],
    weapons = { W.k98k, W.arrest },
    command = "ssrifleman",
    max = 4,
    salary = SAL * 1.1,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "ss", requires = { branch = "ss" },
    category = "Schutzstaffel",
}

TEAM_SS_MEDIC = job{
    name = "SS Medic",
    color = Color(55, 55, 50),
    model = M.ss,
    description = [[Rifleman's kit plus a medkit.]],
    weapons = { W.k98k, W.arrest, W.medkit },
    command = "ssmedic",
    max = 1,
    salary = SAL * 1.1,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "ss", requires = { branch = "ss" },
    category = "Schutzstaffel",
}

TEAM_SS_SHARPSHOOTER = job{
    name = "SS Sharpshooter",
    color = Color(40, 40, 38),
    model = M.ss,
    description = [[Carries a scoped Karabiner 98k.]],
    weapons = { W.k98k_scoped, W.arrest },
    command = "sssharpshooter",
    max = 1,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "ss", requires = { branch = "ss" },
    category = "Schutzstaffel",
}

TEAM_SS_NCO = job{
    name = "SS NCO",
    color = Color(35, 35, 35),
    model = M.ss,
    description = [[Commands the SS enlisted ranks. Can search for weapons and breach doors with a warrant.]],
    weapons = { W.k98k, W.p38, W.arrest, W.unarrest, W.checker, W.ram },
    command = "ssnco",
    max = 1,
    salary = SAL * 1.4,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "ss", requires = { branch = "ss" },
    category = "Schutzstaffel",
}

TEAM_SS_OFFIZIER = job(whitelisted{
    name = "SS Offizier",
    color = Color(30, 30, 30),
    model = M.officer,
    description = [[Commands all of the SS.]],
    weapons = { W.p38, W.arrest, W.unarrest, W.checker, W.ram },
    command = "ssoffizier",
    max = 1,
    salary = SAL * 1.8,
    admin = 0,
    chief = true,
    faction = "reich",
    arrests = true,
    branch = "ss", requires = { branch = "ss" },
    category = "Schutzstaffel",
    sortOrder = 200,
})

-- Listed under the SS so civilians never see it (or its player count) in F4.
-- Joined quietly from ANY job with /joingestapo; the button stays locked.
TEAM_GESTAPO = job(whitelisted{
    name = "Gestapo Agent",
    color = Color(120, 120, 110),   -- identical to Civilian ON PURPOSE: DarkRP colours names by team
    model = M.gestapo,
    description = [[Geheime Staatspolizei. Works in plain clothes among the population.
Report for duty with /joingestapo: the job button is locked so your enlistment isn't announced.
Use /disguise <trade> to change your cover, /undisguise to show your real title.]],
    weapons = { W.p38, W.arrest, W.unarrest, W.checker },
    command = "gestapo",
    max = 2,
    salary = SAL * 1.5,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "gestapo",
    category = "Schutzstaffel",
    sortOrder = 210,
    -- Only true for the instant /joingestapo runs changeTeam (flag is set server-side)
    customCheck = function(ply) return ply.RP1942_QuietEnlist == true end,
    CustomCheckFailMsg = "The Gestapo doesn't advertise. Report for duty with /joingestapo.",
})

--[[===========================================================================
REICH COMMAND ("Reich Command" category, visible to anyone serving the Reich)
===========================================================================]]
TEAM_FUHRER = job(whitelisted{
    name = "Führer",
    color = Color(120, 20, 20),
    model = M.fuhrer,
    description = [[Chancellor of the Reich. Sets the laws, calls curfews and funds the war effort.]],
    weapons = { W.ppk },
    command = "fuhrer",
    max = 1,
    salary = SAL * 2.5,
    admin = 0,
    vote = true,
    mayor = true,   -- DarkRP mayor powers: laws, lockdown (curfew), lottery
    candemote = false,
    faction = "reich",
    branch = "command", requires = { faction = "reich" },
    category = "Reich Command",
})
--[[---------------------------------------------------------------------------
Civil Protection = every Reich job unless it sets arrests = false.
Gives warrants, wanted, arrest and the other police powers.
---------------------------------------------------------------------------]]
GAMEMODE.CivilProtection = {}
for teamNr, jobTbl in pairs(RPExtraTeams) do
    if jobTbl.faction == "reich" and jobTbl.arrests ~= false then
        GAMEMODE.CivilProtection[teamNr] = true
    end
end

-- No hitman teams in 1942 (hitmenu is disabled in disabled_defaults.lua)
