--[[---------------------------------------------------------------------------
1942 DarkRP - disguises (server)

The difference this module relies on:
    changeTeam(t)    changes the REAL job (weapons, powers, faction)
    updateJob(text)  changes only the TITLE other players see

Three parts:
    Quiet joining     jobs with quietJoin = true (the Gestapo) are never announced
    Silent cover      for undercover jobs (RP1942.Config.Disguise.jobs), the custom
                      job title (F4 > Commands, or /job) isn't announced either
    Wardrobe          the F3 wardrobe's model choice (Gestapo, Resistance
                      Operative), kept until a job change
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
Quiet joining (jobs with quietJoin = true in jobs.lua, e.g. the Gestapo)

DarkRP normally announces "X has been made a <job>!" to everyone, which would
blow an undercover agent. So ANY attempt to take a quietJoin job - the F4
button, /gestapo, DarkRP's old F4 - is caught below and redone silently, and
the player starts with a civilian cover title.
---------------------------------------------------------------------------]]
function RP1942.quietJoin(ply, teamNr)
    local job = RPExtraTeams[teamNr]
    if not (IsValid(ply) and job) then return false end

    if ply:Team() == teamNr then
        DarkRP.notify(ply, 1, 4, "You are already on duty.")
        return false
    end

    -- Silent joins also silence DarkRP's reason when it refuses, so check the
    -- common reasons first and say which one it is
    local gate = RP1942.jobGateFailure and RP1942.jobGateFailure(ply, job)
    if gate then
        DarkRP.notify(ply, 1, 5, gate)
        return false
    end
    if job.max and job.max >= 1 and team.NumPlayers(teamNr) >= job.max then
        DarkRP.notify(ply, 1, 5, "Every " .. job.name .. " post is filled.")
        return false
    end

    ply.RP1942_QuietEnlist = true   -- lets the change through the hook below
    local ok = ply:changeTeam(teamNr, false, true) -- suppressNotification = true
    ply.RP1942_QuietEnlist = nil

    if not ok then
        DarkRP.notify(ply, 1, 6, "You can't report for duty right now (demotion ban, job cooldown or faction limit).")
        return false
    end

    -- changeTeam just set the real title; replace it in the same tick
    local civ = RPExtraTeams[GAMEMODE.DefaultTeam]
    local cover = civ and civ.name or "Civilian"
    ply:updateJob(cover)
    DarkRP.notify(ply, 0, 6, "On duty as " .. job.name .. ". Your cover is '" .. cover .. "'. Change it with Set a custom job title (F4 > Commands): nobody is told.")
    return true
end

hook.Add("playerCanChangeTeam", "RP1942_QuietJoin", function(ply, teamNr, force)
    if force or ply.RP1942_QuietEnlist then return end
    local job = RPExtraTeams[teamNr]
    if not (job and job.quietJoin) then return end

    -- Do it the quiet way instead, a tick later (not inside this change)
    timer.Simple(0, function() RP1942.quietJoin(ply, teamNr) end)
    return false   -- no message: the quiet join reports how it went
end)

-- Old command, kept for anyone used to it
DarkRP.defineChatCommand("joingestapo", function(ply)
    if TEAM_GESTAPO then RP1942.quietJoin(ply, TEAM_GESTAPO) end
    return ""
end)

--[[---------------------------------------------------------------------------
Silent cover. DarkRP's /job (the F4 "Set a custom job title" box) tells the
whole server "X's job has become Y", which would expose an agent. For
undercover jobs, it's done here instead and nobody is told. The title must be
a civilian trade (unless freeform is on); typing your real job name reveals you.
canChatCommand runs before DarkRP's /job, and returning false stops it.
---------------------------------------------------------------------------]]
local function setCover(ply, text)
    text = string.Trim(text or "")
    local job = RPExtraTeams[ply:Team()]

    if job and string.lower(text) == string.lower(job.name) then
        ply:updateJob(job.name)
        DarkRP.notify(ply, 0, 4, "You are now openly a " .. job.name .. ".")
        return
    end

    local title
    if RP1942.Config.Disguise.freeform then
        if #text < 3 or #text > 25 then
            DarkRP.notify(ply, 1, 4, "A cover title must be 3-25 characters.")
            return
        end
        title = text
    else
        local civ = civilianJobByName(text)
        if not civ then
            DarkRP.notify(ply, 1, 5, "Your cover must be a real civilian trade, e.g. " .. coverExamples() .. ".")
            return
        end
        title = civ.name
    end

    ply:updateJob(title)
    DarkRP.notify(ply, 0, 4, "Your cover is now '" .. title .. "'. Nobody was told.")
end

hook.Add("canChatCommand", "RP1942_SilentCover", function(ply, cmd, args)
    if cmd ~= "job" or not RP1942.canDisguise(ply) then return end
    setCover(ply, args)
    return false
end)

--[[---------------------------------------------------------------------------
Wardrobe (F3 menu of the undercover jobs): wear any model from RP1942.disguiseModels(ply).
Kept through respawns; cleared when you change job. "" = standard issue.
---------------------------------------------------------------------------]]
local WARDROBE_COOLDOWN = 3

RP1942.addMenuHandler("RP1942_WardrobeMenu", "model", function(ply, model)
    if not RP1942.canDisguise(ply) then return end
    local now = CurTime()
    if (ply.RP1942_NextWardrobe or 0) > now then return end
    ply.RP1942_NextWardrobe = now + WARDROBE_COOLDOWN

    if model == "" then
        ply.RP1942_DisguiseModel = nil
        hook.Call("PlayerSetModel", GAMEMODE, ply)   -- back to the job's own model
        ply:SetupHands()
        DarkRP.notify(ply, 0, 4, "Back in standard issue.")
        return
    end

    if not table.HasValue(RP1942.disguiseModels(ply), model) then return end   -- not on this job's list
    ply.RP1942_DisguiseModel = model
    ply:SetModel(model)
    ply:SetupHands()
    DarkRP.notify(ply, 0, 4, "Disguise changed.")
end)

-- On respawn, keep wearing the disguise (runs before DarkRP picks the job model)
hook.Add("PlayerSetModel", "RP1942_Wardrobe", function(ply)
    local model = ply.RP1942_DisguiseModel
    if model and RP1942.canDisguise(ply) then
        ply:SetModel(model)
        return true
    end
end)

hook.Add("OnPlayerChangedTeam", "RP1942_Wardrobe", function(ply)
    ply.RP1942_DisguiseModel = nil
end)
