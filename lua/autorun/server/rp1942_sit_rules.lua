--[[---------------------------------------------------------------------------
1942 DarkRP - how SitAnywhere fits the gamemode (server)

SitAnywhere itself (lua/sitanywhere, lua/autorun/sitanywhere.lua) is stock.
These are the rules that make it behave in DarkRP:
    - nobody sits while arrested, and an arrest stands you up
    - the gamemode's own entities aren't seats: machines and their panels,
      printers, the vault, markets, crates, goods, dropped weapons, the
      supply train, law boards (Alt + E on them still does nothing)
    - !spawn and !sitstuck (an_sitanywhere_helper_commands.lua) can't be
      used to escape: not while arrested, wanted, robbing the bank, or
      within 20 seconds of taking damage from a player
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local NO_SEAT_PREFIX = { "rp1942_", "darkrp_", "spawned_", "mcv_" }

local function isGamemodeEntity(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    for _, p in ipairs(NO_SEAT_PREFIX) do
        if string.StartWith(class, p) then return true end
    end
    return false
end

hook.Add("ShouldAllowSit", "RP1942_SitRules", function(ply)
    if ply.isArrested and ply:isArrested() then return false end
end)

hook.Add("CheckValidSit", "RP1942_SitRules", function(ply, tr)
    if tr and not tr.HitWorld and isGamemodeEntity(tr.Entity) then return false end
end)

-- Being arrested while sat down: stand up first, so the jail teleport works
hook.Add("playerArrested", "RP1942_SitRules", function(ply)
    if IsValid(ply) and ply:InVehicle() then ply:ExitVehicle() end
end)

--[[---------------------------------------------------------------------------
No free escapes through the helper commands
---------------------------------------------------------------------------]]
local COMBAT_SECONDS = 20

hook.Add("EntityTakeDamage", "RP1942_SitRulesCombat", function(ent, dmg)
    if not (IsValid(ent) and ent:IsPlayer()) then return end
    local attacker = dmg:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= ent then
        ent.RP1942_LastHurt = CurTime()
    end
end)

local function cantTeleport(ply)
    if ply.isArrested and ply:isArrested() then return "not while you're arrested" end
    if ply.getDarkRPVar and ply:getDarkRPVar("wanted") then return "not while you're wanted" end
    if RP1942 and RP1942.bankIsCrew and RP1942.bankIsCrew(ply) then return "not during a bank robbery" end
    if (ply.RP1942_LastHurt or 0) > CurTime() - COMBAT_SECONDS then return "not so soon after a fight" end
end

-- Asked by an_sitanywhere_helper_commands.lua before it teleports. (A
-- separate PlayerSay hook couldn't be relied on: hook order isn't fixed, and
-- the helper's hook ends the chain.)
function RP1942.canUseSitTeleport(ply, cmd)
    local why = cantTeleport(ply)
    if why then
        DarkRP.notify(ply, 1, 5, "You can't use " .. cmd .. " right now: " .. why .. ".")
        return false
    end
    return true
end
