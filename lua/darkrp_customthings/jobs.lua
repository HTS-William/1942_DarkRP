--[[---------------------------------------------------------------------------
1942 DarkRP - jobs

Custom fields used by the rp1942 modules (DarkRP ignores unknown fields):
    faction  = "civilian" | "resistance" | "reich"   (faction balance, radio, orders)
    branch   = "wehrmacht" | "waffen_ss" | "leibstandarte" | ... (unit within the Reich)
    requires = { branch = ... } / { faction = ... }   (must CURRENTLY hold such a job)
    arrests  = false                                  (Reich job WITHOUT police powers)
    vip / whitelisted                                 (set via the vip{} / whitelisted{} helpers)

Reich enlistment:
    1. Take a branch's Rifleman ("Reich" category, visible to all). From
       outside the Reich that takes a vote of the server (rp1942_reichjobs).
    2. Holding the Rifleman shows that branch's specialisations in F4
       (subOf), and they're only TAKEABLE from inside the branch
       (requires = { branch = ... } below).
Leave the branch and you have to enlist (and be voted in) again.

WEAPONS: a job's `weapons = { ... }` list is exactly what it spawns with,
nothing is added behind the scenes. The W.something names are short names
from RP1942.Weapons in darkrp_modules/rp1942_core/sh_config.lua, each one a
real weapon class (W.k98k = "mcv_kar98", W.stun = "stunstick"...).
    - Give ONE job a gun: add W.name to its list, or the class itself in
      quotes, e.g. weapons = { W.k98k, "mcv_mp40", W.stun, W.arrest, W.unarrest }
    - Swap a gun for EVERY job that uses a short name: change the class in
      sh_config.lua (e.g. k98k = "mcv_kar98_prewar").
    - Every Reich job lists W.stun, W.arrest, W.unarrest (the batons).
Models come from RP1942.Models in the same file.

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
    -- VIP switched off (RP1942.Config.VIPEnabled): the job is a normal job
    if not (RP1942.Config and RP1942.Config.VIPEnabled) then return job end
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
  - makes joining the Reich from outside take a vote (rp1942_reichjobs)
  - ends every description with RAID = YES / RAID = NO (RAID_JOBS below)
  - gives every Reich job the weapon checker (noChecker = true skips it) and
    every Reich job that can raid the battering ram (noRam = true skips it)
---------------------------------------------------------------------------]]
-- Who may raid. RAID = YES: every Reich job except NO_RAID_REICH, and the
-- jobs in RAID_JOBS. Everyone else: RAID = NO.
local RAID_JOBS = {
    civilian = true, doctor = true,
    thief = true, prothief = true,
    resistance = true, resmedic = true, resoperative = true, resleader = true,
}
local NO_RAID_REICH = { gersupplier = true, scientist = true, fuhrer = true }   -- (the Reich Banker is a civilian job: NO)


local function job(tbl)
    local name = tbl.name
    tbl.name = nil

    -- RAID = YES / NO at the end of the description (and job.canRaid for other code)
    tbl.canRaid = RAID_JOBS[tbl.command] == true or (tbl.faction == "reich" and not NO_RAID_REICH[tbl.command])
    tbl.description = string.TrimRight(tbl.description or "") .. "\n\nRAID = " .. (tbl.canRaid and "YES" or "NO")

    -- Every Reich job carries the weapon checker; those that can raid also the
    -- battering ram (door_ram). (The Reich Banker is a civilian job: neither.)
    if tbl.faction == "reich" then
        tbl.weapons = tbl.weapons or {}
        if not tbl.noChecker and not table.HasValue(tbl.weapons, W.checker) then table.insert(tbl.weapons, W.checker) end
        if tbl.canRaid and not tbl.noRam and not table.HasValue(tbl.weapons, W.ram) then table.insert(tbl.weapons, W.ram) end
    end

    -- A job's own customCheck becomes the last gate
    if tbl.customCheck then
        tbl.gate, tbl.gateFailMsg = tbl.customCheck, tbl.CustomCheckFailMsg
    end

    if tbl.vip or tbl.whitelisted or tbl.requires or tbl.subOf or tbl.gate then
        tbl.customCheck = function(ply) return RP1942.jobGateFailure(ply, tbl) == nil end
        tbl.CustomCheckFailMsg = function(ply) return RP1942.jobGateFailure(ply, tbl) or "" end
    end

    -- Reich jobs: joining the Reich from outside takes a vote; moves inside it don't
    -- (RP1942.reichJobNeedsVote and its exemptions: rp1942_reichjobs/sh_reichjobs.lua)
    -- (quietJoin jobs, the Gestapo, are voted from RP1942.quietJoin instead, so
    -- /gestapo still reaches it and the join stays silent)
    if tbl.faction == "reich" and not tbl.quietJoin and not tbl.vote and not tbl.RequiresVote and RP1942.reichJobNeedsVote then
        local command = tbl.command
        tbl.RequiresVote = function(ply) return RP1942.reichJobNeedsVote(ply, command) end
    end

    -- Jobs with a menu open it on F3 (DarkRP calls job.ShowSpare1 when F3 is pressed).
    -- On the client, the ShowSpare1 hook in rp1942_menu/cl_menu_base.lua handles F3
    -- first, so the cursor toggle keeps working alongside job menus.
    if tbl.menu and not tbl.ShowSpare1 then
        tbl.ShowSpare1 = function(ply)
            if CLIENT then RP1942.openJobMenu() end
        end
    end

    -- Jobs with demoteOnDeath = true become Hobos when they die
    if tbl.demoteOnDeath and not tbl.PlayerDeath then
        tbl.PlayerDeath = function(ply)
            local lost = RPExtraTeams[ply:Team()]
            ply:changeTeam(TEAM_HOBO or GAMEMODE.DefaultTeam, true, true)
            DarkRP.notify(ply, 1, 6, "You died and lost your position" .. (lost and (" as " .. lost.name) or "") .. ".")
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
    name = "Reich Banker",
    color = Color(130, 120, 60),
    model = M.banker,
    description = [[Runs the Reichsbank's legal Banking Printers (F4 Shop, up to 3). Every print is split with the Reich treasury: 15% at a normal economy, more when it's weak, less when it's strong. Upgrade them, switch them off to cool before they overheat, and guard them: anyone can empty the tray.]],
    weapons = {},
    command = "banker",
    max = 1,
    salary = SAL * 1.3,
    admin = 0,
    faction = "civilian",
    category = "Reich",
    sortOrder = 12,
    -- Listed with the Reich, but still a civilian job (faction): no vote, no
    -- arrest immunity, and NOT in the Reich Orders agenda (agendas.lua)
}

TEAM_PETROLEUM = job{
    name = "Petroleum Producer",
    color = Color(60, 60, 60),
    model = M.labourer,
    description = [[Buys an oil rig (F4 Shop). It's built on a free oil site and bolted down. It pumps on its own, and the pressure climbs while the valve is shut: turn the valve wheel to open and close it and keep the pressure in the green. The better you tend it, the more barrels of crude and the finer the grade. Sell oil at a market or to other players.]],
    weapons = {},
    command = "petroleum",
    max = 1,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Production",
}

TEAM_WINEMAKER = job{
    name = "Winemaker",
    color = Color(110, 30, 50),
    model = M.labourer,
    description = [[Buys wine barrels (F4 Shop). Start one fermenting and stir it whenever it calls: every call you miss lowers the vintage. 3 bottles per barrel. Sell wine at a market or to other players.]],
    weapons = {},
    command = "winemaker",
    max = 3,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Production",
}

TEAM_FACTORY = job{
    name = "Factory Owner",
    color = Color(90, 80, 70),
    model = M.labourer,
    description = [[Buys a factory line and scrap metal (F4 Shop): each load of scrap runs the line once, turning out random goods of varying rarity. Now and then it halts with a fault: press the matching repair. The less downtime, the better the run and the rarer the goods. Sell them at a market or to other players.]],
    weapons = {},
    command = "factoryowner",
    max = 2,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Production",
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
    description = [[Buys ovens and sacks of flour (F4 Shop). Push sacks into an oven and keep its fire in the green while it bakes: the better you tend it, the more loaves and the finer the bread. Sell bread at a market or to other players.]],
    weapons = {},
    command = "baker",
    max = 4,
    salary = SAL,
    admin = 0,
    faction = "civilian",
    category = "Production",
    menu = "RP1942_BakerMenu",
}

--[[===========================================================================
RESISTANCE (incl. black-market dealers)
===========================================================================]]
TEAM_BLACKMARKET = job{
    name = "Black Market Dealer",
    color = Color(70, 50, 40),
    model = M.dealer,
    description = [[Buys weapons and explosives off the black market (F3) at fixed prices, whatever the economy, and sells them on. Anti-tank launchers, explosives, silenced guns and plenty more.]],
    weapons = {},
    command = "blackmarket",
    max = 3,
    salary = SAL,
    admin = 0,
    faction = "civilian",       -- a civilian trade: anyone can take it, no side required
    category = "Resistance",
    menu = "RP1942_ShopMenu",
    shop = "blackmarket",   -- rp1942_shop/sh_shop_catalogs.lua
}
--[=[
TEAM_RUSTUNG = job{
    name = "Rüstung Dealer",
    color = Color(100, 70, 40),
    model = M.dealer,
    description = [[Deals submachine guns, heavy weapons and explosives.]],
    weapons = {},
    command = "rustung",
    max = 1,
    salary = SAL,
    admin = 0,
    faction = "civilian",       -- a civilian trade: anyone can take it, no side required
    category = "Civilians",
}
]=]
TEAM_CHERKESOV = job{
    name = "Cherkesov Dealer",
    color = Color(120, 40, 30),
    model = M.dealer,
    description = [[Buys Soviet and Allied weapons (F3) at fixed prices, whatever the economy, and sells them on: machine guns, anti-tank rifles, submachine guns and more.]],
    weapons = {},
    command = "cherkesov",
    max = 3,
    salary = SAL,
    admin = 0,
    faction = "civilian",       -- a civilian trade: anyone can take it, no side required
    category = "Resistance",
    menu = "RP1942_ShopMenu",
    shop = "cherkesov",   -- rp1942_shop/sh_shop_catalogs.lua
}

TEAM_THIEF = job{
    name = "Thief",
    color = Color(90, 40, 40),
    model = M.resistance,
    description = [[Carries a standard lockpick.]],
    weapons = { W.lockpick },
    command = "thief",
    max = 3,
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
    description = [[Carries a professional lockpick that opens doors in a fraction of the time.]],
    weapons = { W.lockpick_pro },
    command = "prothief",
    max = 1,
    salary = SAL * 0.8,
    admin = 0,
    faction = "resistance",
    branch = "resistance", requires = { faction = "resistance" },
    category = "Resistance",
    subOf = "thief",   -- F4: shown once you are a Thief; server-enforced
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
    subOf = "resistance",   -- F4: folded under the Resistance card
}

TEAM_RES_OPERATIVE = job{
    name = "Resistance Operative",
    color = Color(120, 120, 110),   -- identical to Civilian ON PURPOSE: DarkRP colours names by team
    model = M.resoperative,         -- RP1942.Models.resoperative in rp1942_core/sh_config.lua
    description = [[Intelligence and infiltration for the underground.
Joining is never announced, and you start under a civilian cover.
Press F3 for your wardrobe of disguises. Change your cover title with "Set a custom
job title" in the F4 Commands tab: for you, nobody is told.]],
    weapons = { W.lockpick },
    command = "resoperative",
    max = 2,
    salary = SAL,
    admin = 0,
    faction = "resistance",
    branch = "resistance", requires = { faction = "resistance" },
    category = "Resistance",
    subOf = "resistance",   -- F4: folded under the Resistance card
    quietJoin = true,               -- never announced (rp1942_core/sv_disguise.lua)
    menu = "RP1942_WardrobeMenu",   -- F3: the wardrobe (rp1942_menu/cl_menu_wardrobe.lua)
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
    subOf = "resistance",   -- F4: folded under the Resistance card
    demoteOnDeath = true,
}

--[[###########################################################################
                                   REICH
###########################################################################]]

--[[===========================================================================
THE REICH - every German job is in the "Reich" category, folded like the
Resistance: a civilian sees the three Riflemen (plus Supplier, Scientist,
Gestapo). Becoming a Rifleman shows its specialisations (subOf in each job,
enforced server-side). Joining from outside the Reich is voted.
===========================================================================]]
-- Single-hop Reich jobs (no branch)
TEAM_SUPPLIER = job{
    name = "German Supplier",
    color = Color(80, 90, 70),
    model = M.merchant,
    description = [[Buys German service weapons from the Reich armoury (F3) and supplies them to the Reich. Prices follow the economy: cheaper when it's strong, dearer when it's weak.]],
    weapons = { W.stun, W.arrest, W.unarrest },
    command = "gersupplier",
    max = 1,
    salary = SAL,
    admin = 0,
    faction = "reich",
    branch = "supply",
    arrests = true,    -- every Reich job carries the batons, so every one can arrest
    category = "Reich",
    menu = "RP1942_ShopMenu",
    shop = "supplier",   -- rp1942_shop/sh_shop_catalogs.lua
    sortOrder = 10,
}

TEAM_SCIENTIST = job{
    name = "Reich Scientist",
    color = Color(150, 150, 140),
    model = M.scientist,
    -- TODO: role undefined in the design doc. No police powers until decided.
    description = [[Conducts research for the Reich.]],
    weapons = { W.stun, W.arrest, W.unarrest },
    command = "scientist",
    max = 1,
    salary = SAL * 1.5,
    admin = 0,
    faction = "reich",
    branch = "staff",
    arrests = true,
    category = "Reich",
    sortOrder = 11,
    demoteOnDeath = true,
}

--[[===========================================================================
WEHRMACHT (in "Reich": Rifleman -> specialisations)
===========================================================================]]
TEAM_WEHR_RIFLEMAN = job{
    name = "Wehrmacht Rifleman",
    color = Color(93, 101, 82),
    model = M.wehrmacht,
    description = [[The backbone of the garrison. Carries a Karabiner 98k.]],
    weapons = { W.k98k, W.arrest, W.stun, W.unarrest },
    command = "wehrrifleman",
    max = 8,
    salary = SAL * 1.1,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht",   -- the way in: open to all (voted from outside the Reich)
    category = "Reich",
    sortOrder = 1,
}

TEAM_WEHR_MEDIC = job{
    name = "Wehrmacht Medic",
    color = Color(100, 108, 90),
    model = M.wehrmacht,
    description = [[Rifleman's kit plus a medkit.]],
    weapons = { W.k98k, W.arrest, W.medkit, W.stun, W.unarrest },
    command = "wehrmedic",
    max = 2,
    salary = SAL * 1.1,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Reich",
    subOf = "wehrrifleman",   -- F4: shown once you are the base job; server-enforced
}

TEAM_WEHR_ELITE = job(vip{
    name = "Wehrmacht Elite Rifleman",
    color = Color(85, 95, 75),
    model = M.wehrmacht,
    description = [[Carries a Gewehr 43.]],
    weapons = { W.g43, W.arrest, W.stun, W.unarrest },
    command = "wehrelite",
    max = 3,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Reich",
    subOf = "wehrrifleman",   -- F4: shown once you are the base job; server-enforced
})

TEAM_WEHR_SHARPSHOOTER = job(vip{
    name = "Wehrmacht Sharpshooter",
    color = Color(80, 90, 70),
    model = M.wehrmacht,
    description = [[Carries a scoped Karabiner 98k.]],
    weapons = { W.k98k_scoped, W.arrest, W.stun, W.unarrest },
    command = "wehrsharpshooter",
    max = 2,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Reich",
    subOf = "wehrrifleman",   -- F4: shown once you are the base job; server-enforced
})

TEAM_WEHR_DRIVER = job{
    name = "Wehrmacht Driver",
    color = Color(75, 85, 70),
    model = M.wehrmacht,
    description = [[Drives the armoured personnel carrier funded by the Führer.]],
    weapons = { W.k98k, W.arrest, W.stun, W.unarrest },
    command = "wehrdriver",
    max = 1,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Reich",
    subOf = "wehrrifleman",   -- F4: shown once you are the base job; server-enforced
}

TEAM_WEHR_NCO = job{
    name = "Wehrmacht NCO",
    color = Color(70, 80, 60),
    model = M.wehrmacht_nco,
    description = [[Commands the Wehrmacht enlisted ranks. Can search for weapons and breach doors with a warrant.]],
    weapons = { W.mp40, W.p38, W.arrest, W.unarrest, W.checker, W.ram, W.stun },
    command = "wehrnco",
    max = 2,
    salary = SAL * 1.4,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Reich",
    subOf = "wehrrifleman",   -- F4: shown once you are the base job; server-enforced
}

TEAM_WEHR_OFFIZIER = job(whitelisted{
    name = "Wehrmacht Offizier",
    color = Color(60, 70, 55),
    model = M.wehrmacht_officer,
    description = [[Commands all of the Wehrmacht. Sets jail positions and issues orders.]],
    weapons = { W.p38, W.arrest, W.unarrest, W.checker, W.ram, W.stun },
    command = "wehroffizier",
    max = 1,
    salary = SAL * 1.8,
    admin = 0,
    chief = true,
    faction = "reich",
    arrests = true,
    branch = "wehrmacht", requires = { branch = "wehrmacht" },
    category = "Reich",
    subOf = "wehrrifleman",   -- F4: shown once you are the base job; server-enforced
    sortOrder = 200,
})

--[[===========================================================================
WAFFEN-SS (in "Reich": Rifleman -> specialisations)
===========================================================================]]
TEAM_WSS_RIFLEMAN = job{
    name = "Waffen-SS Rifleman",
    color = Color(60, 64, 50),
    model = M.waffen_ss,
    description = [[Carries a Gewehr 43.]],
    weapons = { W.g43, W.arrest, W.stun, W.unarrest },
    command = "wssrifleman",
    max = 8,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss",   -- the way in: open to all (voted from outside the Reich)
    category = "Reich",
    sortOrder = 2,
}

TEAM_WSS_MEDIC = job{
    name = "Waffen-SS Medic",
    color = Color(66, 70, 56),
    model = M.waffen_ss,
    description = [[Carries a Gewehr 43 and a medkit.]],
    weapons = { W.g43, W.arrest, W.medkit, W.stun, W.unarrest },
    command = "wssmedic",
    max = 1,
    salary = SAL * 1.2,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Reich",
    subOf = "wssrifleman",   -- F4: shown once you are the base job; server-enforced
}

TEAM_WSS_MG = job{
    name = "Waffen-SS Machinegunner",
    color = Color(55, 60, 45),
    model = M.waffen_ss,
    description = [[Carries an MG-34 on a belt.]],
    weapons = { W.mg34, W.arrest, W.stun, W.unarrest },
    command = "wssmg",
    max = 2,
    salary = SAL * 1.3,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Reich",
    subOf = "wssrifleman",   -- F4: shown once you are the base job; server-enforced
}

TEAM_WSS_NCO = job(vip{
    name = "Waffen-SS NCO",
    color = Color(50, 55, 40),
    model = M.waffen_nco,
    description = [[Commands the Waffen-SS enlisted ranks. Carries an StG 44.]],
    weapons = { W.stg44, W.p38, W.arrest, W.unarrest, W.checker, W.ram, W.stun },
    command = "wssnco",
    max = 1,
    salary = SAL * 1.5,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Reich",
    subOf = "wssrifleman",   -- F4: shown once you are the base job; server-enforced
}) --kept as VIP so the proper format is seen here

TEAM_WSS_OFFIZIER = job(whitelisted{
    name = "Waffen-SS Offizier",
    color = Color(40, 44, 34),
    model = M.waffen_officer,
    description = [[Commands all of the Waffen-SS.]],
    weapons = { W.stg44, W.p38, W.arrest, W.unarrest, W.checker, W.ram, W.stun },
    command = "wssoffizier",
    max = 1,
    salary = SAL * 1.8,
    admin = 0,
    chief = true,
    faction = "reich",
    arrests = true,
    branch = "waffen_ss", requires = { branch = "waffen_ss" },
    category = "Reich",
    subOf = "wssrifleman",   -- F4: shown once you are the base job; server-enforced
    sortOrder = 200,
})

--[[===========================================================================
LEIBSTANDARTE (in "Reich": one job, taken from any Reich job)
The Führer's bodyguard. Wehrmacht = police, Waffen-SS = special
unit, Leibstandarte = the Führer's protection detail.
===========================================================================]]
TEAM_LAH_RIFLEMAN = job{
    name = "Leibstandarte",
    color = Color(45, 45, 45),
    model = M.leibstandarte,
    description = [[The Führer's personal bodyguard. Stay close to the Führer and keep him alive. Carries an StG 44 and a Walther P38.
Only for those already serving the Reich: take it from any Reich job.]],
    weapons = { W.stg44, W.p38, W.stun, W.arrest, W.unarrest },
    command = "leibstandarte",   -- /leibstandarte
    max = 8,
    salary = SAL * 1.3,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "leibstandarte", requires = { faction = "reich" },   -- must CURRENTLY hold a Reich job (so no vote)
    category = "Reich",
    sortOrder = 3,
}

--[=[ Commented out: the Leibstandarte is a single job now
TEAM_LAH_KOMMANDANT = job(whitelisted{
    name = "Leibstandarte Kommandant",
    color = Color(30, 30, 30),
    model = M.officer,
    description = [[Commands the Leibstandarte and is responsible for the Führer's safety.]],
    weapons = { W.p38, W.arrest, W.unarrest, W.checker, W.ram, W.stun },
    command = "lahkommandant",
    max = 1,
    salary = SAL * 1.8,
    admin = 0,
    chief = true,
    faction = "reich",
    arrests = true,
    branch = "leibstandarte", requires = { branch = "leibstandarte" },
    category = "Reich",
    subOf = "leibstandarte",   -- F4: shown once you are the base job; server-enforced
    sortOrder = 200,
})
]=]

-- In "Reich", visible to everyone so anyone can join from F4 (quietly: see
-- quietJoin). F4 hides its player count from anyone outside the Reich, so
-- seeing the card doesn't reveal whether agents are around.
TEAM_GESTAPO = job{
    name = "Gestapo Agent",
    color = Color(120, 120, 110),   -- identical to Civilian ON PURPOSE: DarkRP colours names by team
    model = M.gestapo,
    description = [[Geheime Staatspolizei. Works in plain clothes among the population.
Joining is never announced, and you start under a civilian cover.
Press F3 for your wardrobe of disguises. Change your cover title with "Set a custom
job title" in the F4 Commands tab: for you, nobody is told.]],
    weapons = { W.p38, W.arrest, W.unarrest, W.checker, W.stun },
    command = "gestapo",
    max = 2,
    salary = SAL * 1.5,
    admin = 0,
    faction = "reich",
    arrests = true,
    branch = "gestapo",
    category = "Reich",
    sortOrder = 210,
    -- Joining by any route (F4, /gestapo, /joingestapo) is done silently with a
    -- civilian cover title: see rp1942_core/sv_disguise.lua
    quietJoin = true,
    menu = "RP1942_WardrobeMenu",   -- F3: the wardrobe (rp1942_menu/cl_menu_wardrobe.lua)
}

--[[===========================================================================
REICH COMMAND ("Reich Command" category, visible to everyone)
===========================================================================]]
TEAM_FUHRER = job(whitelisted{
    name = "Führer",
    color = Color(120, 20, 20),
    model = M.fuhrer,
    description = [[Chancellor of the Reich. Sets the laws, calls curfews and funds the war effort.]],
    weapons = { W.luger, W.stun, W.arrest, W.unarrest },
    command = "fuhrer",
    max = 1,
    salary = SAL * 2.5,
    admin = 0,
    vote = false,   -- chosen by the RP1942 election instead (darkrp_modules/rp1942_election);
                    -- taking the job directly is blocked there, only the winner gets it
    mayor = true,   -- DarkRP mayor powers: laws, lockdown (curfew), lottery
    candemote = false,
    faction = "reich",
    -- Anyone can run for Führer, from any job or faction (no `requires`),
    -- and the Reich's faction cap doesn't apply (see sv_faction_balance.lua)
    branch = "command",
    ignoreBalance = true,
    category = "Reich Command",
    menu = "RP1942_FuhrerMenu",
    demoteOnDeath = true,
})
--[[###########################################################################
                                   STAFF
###########################################################################]]
-- Staff on duty: the only job that gets the admin tools (GM.Config.AdminWeapons
-- and the admin cop weapons are switched off in settings.lua, so staff in any
-- other job spawn like everyone else). Only staff see it or can take it:
-- RP1942.isF4Staff (operator, moderator, admin, superadmin, or ULX 42Bros access).
TEAM_STAFF = job{
    name = "Staff on Duty",
    color = Color(40, 110, 160),
    model = M.staff or M.civilian,
    description = [[On duty as staff. Carries the admin tools. Handle reports, sits and events; don't roleplay in this job.]],
    weapons = { "weapon_keypadchecker", "door_ram", "arrest_stick", "unarrest_stick", "stunstick", "weaponchecker" },
    command = "staffduty",
    max = 0,
    salary = 0,
    admin = 0,
    faction = "staff",
    candemote = false,
    ignoreBalance = true,
    category = "Staff",
    sortOrder = 1,
    customCheck = function(ply) return RP1942.isF4Staff and RP1942.isF4Staff(ply) end,
    CustomCheckFailMsg = "Only staff can go on duty.",
}

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
