--[[---------------------------------------------------------------------------
1942 DarkRP - faction doors (shared)

Doors that belong to a whole faction (or a Reich unit): anyone in it can lock
and unlock them with their keys, nobody can buy them, and the group name
shows on the door.

Setting a door (admins with DarkRP's door-settings permission, the same one
/toggleownable uses; superadmins by default). Look at the door, then:
    /factiondoor reich            Reich only
    /factiondoor resistance       Resistance only
    /factiondoor civilian         Civilians only
    /factiondoor wehrmacht        a Reich unit only (also: waffen_ss, leibstandarte)
    /factiondoor none             back to a normal door
    /factiondoor                  shows these options and what the door is now
It's saved per map, like every DarkRP door setting. The groups also appear
in DarkRP's own admin door menu (F2 on a door -> set door group).

The groups are built from jobs.lua automatically: every job whose faction
(or branch) matches is in the group, so new jobs join the right doors
without touching this file.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.FactionDoors = {
    -- id: what you type after /factiondoor
    -- name: shown on the door. Doors are saved by this name, so renaming a
    --       group later means setting its doors again.
    -- faction / branch: which jobs are in it (the fields in jobs.lua)
    groups = {
        { id = "reich",         name = "Reich",         faction = "reich" },
        { id = "resistance",    name = "Resistance",    faction = "resistance" },
        { id = "civilian",      name = "Civilians",     faction = "civilian" },
        { id = "wehrmacht",     name = "Wehrmacht",     branch = "wehrmacht" },
        { id = "waffen_ss",     name = "Waffen-SS",     branch = "waffen_ss" },
        { id = "leibstandarte", name = "Leibstandarte", branch = "leibstandarte" },
    },

    -- Jobs (by command) added to every Reich unit's doors as well,
    -- e.g. the Führer can open the Leibstandarte's doors.
    reichUnitsAlsoAllow = { "fuhrer" },
}

DarkRP.declareChatCommand{
    command     = "factiondoor",
    description = "Admin: make the door you're looking at a faction door (/factiondoor reich, resistance, civilian, wehrmacht, waffen_ss, leibstandarte or none)",
    delay       = 1,
}

-- Called from darkrp_customthings/doorgroups.lua, which runs after jobs.lua
function RP1942.createFactionDoorGroups()
    local cfg = RP1942.FactionDoors
    local extra = {}
    for _, command in ipairs(cfg.reichUnitsAlsoAllow or {}) do extra[command] = true end

    for _, g in ipairs(cfg.groups) do
        local teams = {}
        for teamNr, job in pairs(RPExtraTeams) do
            local inGroup = (g.faction and job.faction == g.faction)
                or (g.branch and (job.branch == g.branch or (job.faction == "reich" and extra[job.command])))
            if inGroup then teams[#teams + 1] = teamNr end
        end
        table.sort(teams)
        if #teams > 0 then
            DarkRP.createEntityGroup(g.name, unpack(teams))
        else
            MsgC(Color(255, 180, 60), "[1942] Faction door group '" .. g.name .. "' has no jobs; skipped.\n")
        end
    end
end

-- "Waffen-SS", "waffen ss", "waffenss" and "waffen_ss" all find the same group
local function squash(text)
    return (string.lower(text or ""):gsub("[%s%-_]", ""))
end

function RP1942.findFactionDoorGroup(text)
    local key = squash(text)
    for _, g in ipairs(RP1942.FactionDoors.groups) do
        if squash(g.id) == key or squash(g.name) == key then return g end
    end
end
