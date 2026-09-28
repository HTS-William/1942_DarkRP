--[[---------------------------------------------------------------------------
1942 DarkRP - the Reich can't be arrested (server)

Nobody can arrest a member of the Reich with the arrest baton. Staff can
still jail anyone with ULX (!jail) or DarkRP's admin arrest.

Undercover agents (the Gestapo) CAN be arrested: refusing to arrest a
"civilian" would give their cover away.
---------------------------------------------------------------------------]]
local UNDERCOVER_ARRESTABLE = true

hook.Add("canArrest", "RP1942_ReichImmunity", function(arrester, target)
    if not (IsValid(target) and target:IsPlayer() and RP1942.isFaction) then return end
    if not RP1942.isFaction(target, "reich") then return end
    if UNDERCOVER_ARRESTABLE then
        local job = RPExtraTeams[target:Team()]
        local dis = RP1942.Config and RP1942.Config.Disguise
        if job and dis and dis.jobs and dis.jobs[job.command] then return end   -- stays in cover
    end
    return false, "Members of the Reich can't be arrested."
end)
