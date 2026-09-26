--[[---------------------------------------------------------------------------
1942 DarkRP - agendas ("Orders")

Managers can set the text, listeners see it on their HUD.
A job can only be part of ONE agenda.
---------------------------------------------------------------------------]]
DarkRP.createAgenda("Reich Orders",
    { TEAM_FUHRER, TEAM_WEHR_OFFIZIER, TEAM_WSS_OFFIZIER, TEAM_LAH_KOMMANDANT },
    {
        TEAM_WEHR_RECRUIT, TEAM_WEHR_RIFLEMAN, TEAM_WEHR_MEDIC, TEAM_WEHR_ELITE,
        TEAM_WEHR_SHARPSHOOTER, TEAM_WEHR_DRIVER, TEAM_WEHR_NCO,
        TEAM_WSS_RECRUIT, TEAM_WSS_RIFLEMAN, TEAM_WSS_MEDIC, TEAM_WSS_MG, TEAM_WSS_NCO,
        TEAM_LAH_RECRUIT, TEAM_LAH_RIFLEMAN, TEAM_GESTAPO,
        TEAM_SCIENTIST, TEAM_SUPPLIER,
    }
)

DarkRP.createAgenda("Resistance Plans",
    TEAM_RES_LEADER,
    { TEAM_THIEF, TEAM_PROTHIEF, TEAM_RESISTANCE, TEAM_RES_MEDIC, TEAM_RES_OPERATIVE }
)
