--[[---------------------------------------------------------------------------
Door groups
---------------------------------------------------------------------------
The server owner can set certain doors as owned by a group of people, identified by their jobs.


HOW TO MAKE A DOOR GROUP:
AddDoorGroup("NAME OF THE GROUP HERE, you will see this when looking at a door", Team1, Team2, team3, team4, etc.)
---------------------------------------------------------------------------]]


-- Example: AddDoorGroup("Cops and Mayor only", TEAM_CHIEF, TEAM_POLICE, TEAM_MAYOR)
-- Example: AddDoorGroup("Gundealer only", TEAM_GUN)


-- Faction doors: Reich, Resistance, Civilians and the Reich units, built from
-- the jobs' factions. Set doors with /factiondoor (see rp1942_doors/sh_doors.lua).
if RP1942 and RP1942.createFactionDoorGroups then RP1942.createFactionDoorGroups() end
