--[[---------------------------------------------------------------------------
1942 DarkRP - demote groups

Demoted from ANY job in a group = temporarily banned from EVERY job in it.
A job can only belong to one group. The Führer is deliberately left out
(candemote = false in jobs.lua; removal is an admin matter).
---------------------------------------------------------------------------]]
DarkRP.createDemoteGroup("Wehrmacht", {
    TEAM_WEHR_RIFLEMAN, TEAM_WEHR_MEDIC, TEAM_WEHR_ELITE, TEAM_WEHR_SHARPSHOOTER,
    TEAM_WEHR_DRIVER, TEAM_WEHR_NCO, TEAM_WEHR_OFFIZIER,
})

DarkRP.createDemoteGroup("Waffen-SS", {
    TEAM_WSS_RIFLEMAN, TEAM_WSS_MEDIC, TEAM_WSS_MG, TEAM_WSS_NCO, TEAM_WSS_OFFIZIER,
})

DarkRP.createDemoteGroup("SS", {
    TEAM_SS_OFFIZIER, TEAM_1ST_SS, TEAM_GESTAPO,   -- Gestapo sat under the SS (RSHA)
})

DarkRP.createDemoteGroup("Resistance", {
    TEAM_THIEF, TEAM_PROTHIEF, TEAM_RESISTANCE, TEAM_RES_MEDIC,
    TEAM_RES_OPERATIVE, TEAM_RES_LEADER,
})

DarkRP.createDemoteGroup("Arms Dealers", {
    TEAM_BLACKMARKET, TEAM_RUSTUNG, TEAM_CHERKESOV, TEAM_SUPPLIER,
})
