--[[---------------------------------------------------------------------------
1942 DarkRP - wanted by the Reich (server)
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_Alert")

local CFG = RP1942.Wanted

--[[---------------------------------------------------------------------------
RP1942.alert(text, kind, recipients)
Shows a "Reich Alert!" box. kind: "wanted" (red line) or "clear" (green line).
recipients: a player, a table of players, or nil for everyone.
Usable from any other module too.
---------------------------------------------------------------------------]]
function RP1942.alert(text, kind, recipients)
    net.Start("RP1942_Alert")
    net.WriteString(text)
    net.WriteString(kind or "wanted")
    if recipients then net.Send(recipients) else net.Broadcast() end
end

--[[---------------------------------------------------------------------------
RP1942.makeWanted(ply, reason, actor, ...)
    reason   a key from RP1942.Wanted.reasons (sh_wanted.lua), or plain text
    actor    the player who made them wanted, or nil for "the Reich"
    ...      values for any %s in the reason's text
Someone already wanted gets the new reason and a fresh timer, but no second
alert.
---------------------------------------------------------------------------]]
function RP1942.makeWanted(ply, reason, actor, ...)
    if not IsValid(ply) then return end
    local def = CFG.reasons[reason]   -- nil: reason is the text itself
    local text = def and def.text or tostring(reason)
    if select("#", ...) > 0 then text = string.format(text, ...) end

    if ply:getDarkRPVar("wanted") then ply.RP1942_QuietWanted = true end
    ply:wanted(actor, text, def and def.time)   -- nil time: DarkRP's wantedtime
    ply.RP1942_QuietWanted = nil
end

--[[---------------------------------------------------------------------------
Every wanted change goes through DarkRP (ours, and police using /wanted and
/unwanted), so these hooks are where the alerts come from. Returning true
stops DarkRP's own centre-screen "wanted by the police" messages.
---------------------------------------------------------------------------]]
hook.Add("playerWanted", "RP1942_WantedAlert", function(ply, actor, reason)
    if ply.RP1942_QuietWanted then return true end   -- a refresh, not news

    RP1942.alert(string.format(CFG.wantedText, ply:Nick()), "wanted")
    local by = IsValid(actor) and actor:Nick() or "the Reich"
    ServerLog(string.format("[1942] %s (%s) is wanted, by %s: %s\n", ply:Nick(), ply:SteamID(), by, tostring(reason)))
    return true
end)

-- Why they stopped being wanted, set just before DarkRP clears it:
-- "arrested", "killed", or nil (cleared by police or the timer ran out)
hook.Add("playerUnWanted", "RP1942_WantedAlert", function(ply, actor)
    if not IsValid(ply) then return end
    local why = ply.RP1942_ClearReason
    ply.RP1942_ClearReason = nil
    if not ply:getDarkRPVar("wanted") then return true end   -- nothing to announce

    local text = why == "arrested" and CFG.arrestedText
        or why == "killed" and CFG.killedText
        or CFG.unwantedText
    RP1942.alert(string.format(text, ply:Nick()), "clear")
    return true
end)

-- Arrested: DarkRP's own playerArrested clears wanted right after this hook
-- (as long as nothing returns a value here), so just note why
hook.Add("playerArrested", "RP1942_WantedArrested", function(ply)
    if ply:getDarkRPVar("wanted") then ply.RP1942_ClearReason = "arrested" end
end)

--[[---------------------------------------------------------------------------
Deaths. Hooks run before DarkRP's own PlayerDeath, so jobs are still the
ones people died in (demoteOnDeath changes them later).
---------------------------------------------------------------------------]]
hook.Add("PlayerDeath", "RP1942_Wanted", function(victim, _, attacker)
    -- 1. A wanted player died: clear it properly.
    --    DarkRP clears the wanted flag on death itself, but skips the alert and
    --    leaves the wanted timer running, which later announces "no longer
    --    wanted" out of nowhere. Same conditions as DarkRP: not a suicide
    --    (so suiciding doesn't escape it), not in jail, wantedrespawn off.
    if victim:getDarkRPVar("wanted") and not GAMEMODE.Config.wantedrespawn
       and (attacker ~= victim or victim.Slayed) and not victim:isArrested() then
        victim.RP1942_ClearReason = "killed"
        victim:unWanted()
    end

    -- 2. Killing a member of the Reich makes you wanted
    if not CFG.killMakesWanted then return end
    if not (IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim) then return end
    if not RP1942.isFaction(victim, "reich") then return end

    local killerFaction = RP1942.getFaction(attacker)
    if killerFaction and CFG.exemptFactions[killerFaction] then return end

    local job = RPExtraTeams[victim:Team()]
    RP1942.makeWanted(attacker, "reich_kill", nil, victim:Nick(), job and job.name or "Reich")
end)
