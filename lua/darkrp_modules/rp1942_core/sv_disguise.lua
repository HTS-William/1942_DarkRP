--[[---------------------------------------------------------------------------
1942 DarkRP - disguises (server)

The difference this module relies on:
    changeTeam(t)    changes the REAL job (weapons, powers, faction)
    updateJob(text)  changes only the TITLE other players see
DarkRP's /job calls updateJob but announces it to the whole server.
These commands call it silently.
---------------------------------------------------------------------------]]

-- Case-insensitive lookup of a civilian job by display name
local function civilianJobByName(name)
    name = string.lower(name)
    for _, job in pairs(RPExtraTeams) do
        if job.faction == "civilian" and string.lower(job.name) == name then
            return job
        end
    end
end

local function coverExamples()
    local names = {}
    for _, job in pairs(RPExtraTeams) do
        if job.faction == "civilian" and #names < 4 then table.insert(names, job.name) end
    end
    return table.concat(names, ", ")
end

--[[---------------------------------------------------------------------------
/joingestapo: join without the server-wide "has been made" announcement
---------------------------------------------------------------------------]]
DarkRP.defineChatCommand("joingestapo", function(ply)
    if not TEAM_GESTAPO then return "" end

    if ply:Team() == TEAM_GESTAPO then
        DarkRP.notify(ply, 1, 4, "You are already on duty.")
        return ""
    end

    -- The job's customCheck only passes while this flag is set, so the
    -- normal /gestapo command and the F4 button stay locked.
    ply.RP1942_QuietEnlist = true
    local ok = ply:changeTeam(TEAM_GESTAPO, false, true) -- suppressNotification = true
    ply.RP1942_QuietEnlist = nil

    if not ok then
        -- suppressNotification also hides the failure reason, so give a general one
        DarkRP.notify(ply, 1, 6, "You can't report for duty right now (ranks full, not whitelisted, demotion ban, job cooldown or faction limit).")
        return ""
    end

    -- changeTeam just set the title to "Gestapo Agent"; replace it in the same tick
    local civ = RPExtraTeams[GAMEMODE.DefaultTeam]
    ply:updateJob(civ and civ.name or "Civilian")
    DarkRP.notify(ply, 0, 6, "On duty. Your cover is '" .. (civ and civ.name or "Civilian") .. "'. Change it with /disguise <trade>.")

    return ""
end)

--[[---------------------------------------------------------------------------
/disguise <title>
---------------------------------------------------------------------------]]
DarkRP.defineChatCommand("disguise", function(ply, args)
    if not RP1942.canDisguise(ply) then
        DarkRP.notify(ply, 1, 4, "Your job can't use disguises.")
        return ""
    end

    local text = string.Trim(args or "")
    local title

    if RP1942.Config.Disguise.freeform then
        if #text < 3 or #text > 25 then
            DarkRP.notify(ply, 1, 4, "A cover title must be 3-25 characters.")
            return ""
        end
        title = text
    else
        local job = civilianJobByName(text)
        if not job then
            DarkRP.notify(ply, 1, 5, "Pick a real civilian trade, e.g. " .. coverExamples() .. ".")
            return ""
        end
        title = job.name
    end

    ply:updateJob(title)
    DarkRP.notify(ply, 0, 4, "Your cover is now '" .. title .. "'.")
    return ""
end)

--[[---------------------------------------------------------------------------
/undisguise: show the real job title (a deliberate reveal)
---------------------------------------------------------------------------]]
DarkRP.defineChatCommand("undisguise", function(ply)
    if not RP1942.canDisguise(ply) then return "" end

    local job = RPExtraTeams[ply:Team()]
    ply:updateJob(job.name)
    DarkRP.notify(ply, 0, 4, "You are now openly a " .. job.name .. ".")
    return ""
end)
