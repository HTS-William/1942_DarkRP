--[[---------------------------------------------------------------------------
1942 DarkRP - disguise commands (shared declarations)

Declared shared so they show in the F1 command list with the right condition.
Conditions only run at call time, so it doesn't matter that rp1942_core
loads after this module.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

function RP1942.canDisguise(ply)
    local job = RPExtraTeams[ply:Team()]
    local cfg = RP1942.Config and RP1942.Config.Disguise
    return job ~= nil and cfg ~= nil and cfg.jobs[job.command] == true
end

DarkRP.declareChatCommand{
    command = "joingestapo",
    description = "Report for Gestapo duty without it being announced.",
    delay = 1.5,
}

DarkRP.declareChatCommand{
    command = "disguise",
    description = "Silently change the job title others see (e.g. /disguise Baker).",
    delay = 3,
    condition = function(ply) return RP1942.canDisguise(ply) end,
}

DarkRP.declareChatCommand{
    command = "undisguise",
    description = "Drop your cover and show your real job title.",
    delay = 3,
    condition = function(ply) return RP1942.canDisguise(ply) end,
}
