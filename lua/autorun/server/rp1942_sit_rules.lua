--[[---------------------------------------------------------------------------
1942 DarkRP - how SitAnywhere fits the gamemode (server)

SitAnywhere itself (lua/sitanywhere, lua/autorun/sitanywhere.lua) is stock.
These are the rules that make it behave in DarkRP:
    - nobody sits while arrested, and an arrest stands you up
    - a seat is no shield: sitting players can be shot, blown up and
      handcuffed like anyone else, and taking a hit from a player stands
      you up (no sitting back down for a few seconds)
    - the gamemode's own entities aren't seats: machines and their panels,
      printers, the vault, markets, crates, goods, dropped weapons, the
      supply train, law boards (Alt + E on them still does nothing)
    - !spawn and !sitstuck (an_sitanywhere_helper_commands.lua) can't be
      used to escape: not while arrested, being handcuffed, wanted, robbing the bank, or
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

local NO_RESIT_SECONDS = 8   -- after being hurt by a player

hook.Add("ShouldAllowSit", "RP1942_SitRules", function(ply)
    if ply.isArrested and ply:isArrested() then return false end
    if RP1942.isBeingCuffed and RP1942.isBeingCuffed(ply) then return false end
    if (ply.RP1942_LastHurt or 0) > CurTime() - NO_RESIT_SECONDS then return false end
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
    if RP1942.isBeingCuffed and RP1942.isBeingCuffed(ply) then return "not while you're being handcuffed" end
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

--[[---------------------------------------------------------------------------
A seat is no shield

SitAnywhere seats are hidden prisoner pods. Two things made the players in
them untouchable:
    - the engine puts anyone in a vehicle in a collision group that bullets
      and traces pass straight through (so no shot, punch or handcuff grab
      ever reached them). SitAnywhere puts them back in a hittable group
      when they sit, but only if its "sitting_can_damage_players_sitting"
      setting is on, and nothing put it right if something reset it.
    - the engine never passes some damage (explosions, fire, crushing) on to
      someone in a vehicle at all.
So: that setting is forced on, sitting players are kept hittable, and a
player who gets hurt by another player is stood up first, so the damage
lands like on anyone standing.
---------------------------------------------------------------------------]]
local function inSitSeat(ply)
    local veh = ply:GetVehicle()
    return IsValid(veh) and veh.playerdynseat == true
end

hook.Add("InitPostEntity", "RP1942_SitNoShield", function()
    RunConsoleCommand("sitting_can_damage_players_sitting", "1")
end)

local function makeHittable(ply)
    if IsValid(ply) and inSitSeat(ply) and ply:GetCollisionGroup() ~= COLLISION_GROUP_WEAPON then
        ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)   -- hit by bullets and traces, doesn't push anything
        ply:CollisionRulesChanged()
    end
end

hook.Add("PlayerEnteredVehicle", "RP1942_SitNoShield", function(ply)
    timer.Simple(0, function() makeHittable(ply) end)   -- after the engine and SitAnywhere are done
end)

timer.Create("RP1942_SitNoShield", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:InVehicle() then makeHittable(ply) end
    end
end)

-- The attacking player behind some damage (the shooter, or the owner of a grenade or rocket)
local function playerAttacker(dmg)
    local a, i = dmg:GetAttacker(), dmg:GetInflictor()
    if IsValid(a) and a:IsPlayer() then return a end
    if IsValid(i) then
        if i:IsPlayer() then return i end
        local o = i.GetOwner and i:GetOwner()
        if IsValid(o) and o:IsPlayer() then return o end
    end
end

-- Hurt while sitting: stand up first (before the engine looks), then take the hit as normal
hook.Add("EntityTakeDamage", "RP1942_SitNoShield", function(ent, dmg)
    local ply = ent
    if IsValid(ent) and not ent:IsPlayer() and ent.playerdynseat then ply = ent:GetDriver() end   -- the seat itself was hit
    if not (IsValid(ply) and ply:IsPlayer() and inSitSeat(ply)) then return end
    local attacker = playerAttacker(dmg)
    if not attacker or attacker == ply then return end

    ply:ExitVehicle()
    ply.RP1942_LastHurt = CurTime()
    if ent ~= ply then
        -- it hit the hidden seat: give the damage to the player instead
        local d = DamageInfo()
        d:SetDamage(dmg:GetDamage())
        d:SetDamageType(dmg:GetDamageType())
        d:SetDamageForce(dmg:GetDamageForce())
        d:SetDamagePosition(dmg:GetDamagePosition())
        d:SetAttacker(attacker)
        d:SetInflictor(IsValid(dmg:GetInflictor()) and dmg:GetInflictor() or attacker)
        ply:TakeDamageInfo(d)
        return true
    end
end)
