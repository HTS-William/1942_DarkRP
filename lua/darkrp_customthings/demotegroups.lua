--[[---------------------------------------------------------------------------
1942 DarkRP - demote groups

Demoted from ANY job in a group = temporarily banned from EVERY job in it,
recruit included, so a demoted soldier can't simply re-enlist.
A job can only belong to one group. The Führer is deliberately left out
(candemote = false in jobs.lua; removal is an admin matter).
---------------------------------------------------------------------------]]
DarkRP.createDemoteGroup("Wehrmacht", {
    TEAM_WEHR_RECRUIT, TEAM_WEHR_RIFLEMAN, TEAM_WEHR_MEDIC, TEAM_WEHR_ELITE,
    TEAM_WEHR_SHARPSHOOTER, TEAM_WEHR_DRIVER, TEAM_WEHR_NCO, TEAM_WEHR_OFFIZIER,
})

DarkRP.createDemoteGroup("Waffen-SS", {
    TEAM_WSS_RECRUIT, TEAM_WSS_RIFLEMAN, TEAM_WSS_MEDIC, TEAM_WSS_MG, TEAM_WSS_NCO,
    TEAM_WSS_OFFIZIER,
})

DarkRP.createDemoteGroup("Leibstandarte", {
    TEAM_LAH_RECRUIT, TEAM_LAH_RIFLEMAN, TEAM_LAH_KOMMANDANT,
})

DarkRP.createDemoteGroup("Gestapo", {
    TEAM_GESTAPO,
})

DarkRP.createDemoteGroup("Resistance", {
    TEAM_THIEF, TEAM_PROTHIEF, TEAM_RESISTANCE, TEAM_RES_MEDIC,
    TEAM_RES_OPERATIVE, TEAM_RES_LEADER,
})

DarkRP.createDemoteGroup("Arms Dealers", {
    TEAM_BLACKMARKET, TEAM_CHERKESOV, TEAM_SUPPLIER,
})
--[[TEAM_RUSTUNG, ]]
