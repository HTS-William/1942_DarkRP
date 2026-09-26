--[[---------------------------------------------------------------------------
1942 DarkRP - release from jail

When someone is unarrested (by a baton, an admin, or their jail time running
out) they are properly RESPAWNED, not just teleported: they appear at a spawn
point with fresh health and their job's loadout, the same as after dying.

Which spawn point is used follows the normal spawn rules:
    - the job's own spawns, if any were set with /addspawn or /setspawn
    - otherwise the map's own spawn points

DarkRP's built-in "telefromjail" (settings.lua) only moves the player. This
runs just after it and replaces that with a real respawn.
---------------------------------------------------------------------------]]
local RESPAWN_ON_RELEASE = false   -- false = back to DarkRP's plain teleport
local DELAY = 0.1                 -- seconds; must run after DarkRP's own teleport (next tick)

hook.Add("playerUnArrested", "RP1942_ReleaseRespawn", function(ply, actor, teleportOverride)
    if not RESPAWN_ON_RELEASE then return end
    -- Other code asked for "don't move them" (false) or a specific spot
    -- (a vector): respect that instead of respawning.
    if teleportOverride ~= nil then return end

    timer.Simple(DELAY, function()
        if not IsValid(ply) then return end
        -- Dead players respawn on their own; re-arrested ones stay put.
        if not ply:Alive() or ply:isArrested() then return end
        if ply:InVehicle() then ply:ExitVehicle() end
        ply:Spawn()
    end)
    -- no return value, so DarkRP's own release (notification, timers) still runs
end)
