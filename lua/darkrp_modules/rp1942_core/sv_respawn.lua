--[[---------------------------------------------------------------------------
1942 DarkRP - the respawn delay (server)

    Dying: you wait DELAY seconds (a countdown on screen), then you're
    respawned by yourself: no clicking. Clicking earlier does nothing.
    Changing sides (sv_side_switch.lua): the same DELAY before you're sent
    back to spawn, held still and unhurt while the screen fades out.

DarkRP's GM.Config.respawntime (darkrp_config/settings.lua) is set to the
same number, so DarkRP doesn't let anyone respawn sooner either.
Client (the countdown): cl_respawn.lua.
---------------------------------------------------------------------------]]
local DELAY = 6
RP1942.RespawnDelay = DELAY

local function setCountdown(ply, at, text)
    ply:SetNW2Float("RP1942_RespawnAt", at)
    ply:SetNW2String("RP1942_RespawnText", text or "")
end

hook.Add("PlayerDeath", "RP1942_RespawnDelay", function(ply)
    ply.RP1942_RespawnAt = CurTime() + DELAY
    setCountdown(ply, ply.RP1942_RespawnAt, "RESPAWNING")
end)

-- No respawning before the delay is up
hook.Add("PlayerDeathThink", "RP1942_RespawnDelay", function(ply)
    if (ply.RP1942_RespawnAt or 0) > CurTime() then return false end
end)

hook.Add("PlayerSpawn", "RP1942_RespawnDelay", function(ply)
    ply.RP1942_RespawnAt = nil
    if not ply.RP1942_Delaying then setCountdown(ply, 0) end
end)

-- Dead and the delay is up: respawn them
timer.Create("RP1942_RespawnDelay", 0.25, 0, function()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() and ply.RP1942_RespawnAt and ply.RP1942_RespawnAt <= now then
            ply.RP1942_RespawnAt = nil
            ply:Spawn()
        end
    end
end)

-- Send a living player back to spawn after the delay (held still and unhurt
-- meanwhile). text: what the countdown says ("REPORTING FOR DUTY")
function RP1942.delayedRespawn(ply, text, after)
    if not IsValid(ply) or ply.RP1942_Delaying then return end
    ply.RP1942_Delaying = true
    ply:Freeze(true)
    ply:GodEnable()
    setCountdown(ply, CurTime() + DELAY, text)
    timer.Simple(DELAY, function()
        if not IsValid(ply) then return end
        ply.RP1942_Delaying = nil
        ply:Freeze(false)
        ply:GodDisable()
        setCountdown(ply, 0)
        if ply:Alive() then ply:Spawn() end
        if after then after(ply) end
    end)
end
