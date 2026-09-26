--[[---------------------------------------------------------------------------
1942 DarkRP - faction doors (server): the /factiondoor command
Does exactly what DarkRP's own "set door group" does, with friendlier names.
---------------------------------------------------------------------------]]
local function lookedAtDoor(ply)
    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or not (ent:isDoor() or ent:IsVehicle()) then return nil end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 40000 then return nil end   -- same reach as DarkRP's door commands
    return ent
end

local function optionList()
    local ids = {}
    for _, g in ipairs(RP1942.FactionDoors.groups) do
        if RPExtraTeamDoors[g.name] then ids[#ids + 1] = g.id end
    end
    ids[#ids + 1] = "none"
    return table.concat(ids, ", ")
end

local function setFactionDoor(ply, args)
    args = string.Trim(args or "")
    local ent = lookedAtDoor(ply)

    if args == "" then
        DarkRP.notify(ply, 0, 8, "Usage: /factiondoor <" .. optionList() .. ">")
        if ent then
            DarkRP.notify(ply, 0, 8, "This door: " .. (ent:getKeysDoorGroup() or "not a faction door"))
        end
        return ""
    end

    if not ent then
        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("must_be_looking_at", DarkRP.getPhrase("door_or_vehicle")))
        return ""
    end

    local groupName
    if string.lower(args) ~= "none" then
        local g = RP1942.findFactionDoorGroup(args)
        if not g or not RPExtraTeamDoors[g.name] then
            DarkRP.notify(ply, 1, 6, "No faction called '" .. args .. "'. Options: " .. optionList())
            return ""
        end
        groupName = g.name
    end

    -- The same steps as DarkRP's /togglegroupownable
    ent:keysUnOwn()
    ent:removeAllKeysDoorTeams()
    ent:setDoorGroup(groupName)
    DarkRP.storeDoorGroup(ent, groupName)      -- saved for this map
    DarkRP.storeTeamDoorOwnability(ent)

    DarkRP.notify(ply, 0, 5, groupName and ("Door set to: " .. groupName) or "Door is a normal door again.")
    ServerLog(string.format("[1942] %s set door %d to %s\n", ply:Nick(), ent:MapCreationID(), groupName or "none"))
    return ""
end

DarkRP.definePrivilegedChatCommand("factiondoor", "DarkRP_ChangeDoorSettings", setFactionDoor)
