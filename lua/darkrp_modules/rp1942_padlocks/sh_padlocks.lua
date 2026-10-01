--[[---------------------------------------------------------------------------
1942 DarkRP - padlocks (shared: the settings and DarkRP's lockpick and ram)

Our answer to keypads. A padlock turns a prop you own into a door:
    E                 open it (5 s), if you're allowed. It closes by itself,
                      and never on someone standing in the doorway.
    E (not allowed)   knock: the owner is told someone's at the door
    Shift + E         the owner (or staff): the lock's menu. Who may open
                      it: players by name, "anyone in my faction", "anyone
                      with my job". Remove the padlock: you get it back
                      (also with the remover tool on it or its door).
No codes, so nothing to crack, share or watch being typed.

RAIDING (DarkRP's own weapons, nothing extra; shooting only with the setting)
    Lockpick          picks the padlock (the Pro Thief's is faster). The
                      owner is told.
    Battering ram     breaks it open, only with a warrant on the owner
                      (DarkRP's rule for doors and fading doors)
    Shooting it       with "shootable" on: every padlock shows a health bar.
                      At 0 it breaks: the door is open for brokenTime, then
                      closes and the padlock is whole again. A damaged one
                      heals after healDelay seconds without a hit.

GETTING ONE
    F4 shop -> Tools -> Padlock. Look at a prop you own, left click.
    Limits: settings below (doors per player, prop size).

STAFF (ULX 42Bros)
    !padlock          a staff padlock (doesn't run out): fits on any prop,
                      with no owner. Shift+E it to choose which faction /
                      Reich unit opens it. For Reich buildings, hideouts...
    !savelock         look at a staff lock: it (and its prop) come back
                      after every restart and cleanup, on this map
    !removelock       look at any lock: removes it (and from the save)
    !doorlocks        every lock on the map, highlighted for a minute
    !locksettings     <setting> <value>: change a setting below (saved in
                      data/rp1942/padlocks.json). No value shows it.
Looking at a lock, staff see its owner; Shift+E shows who has access.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Padlocks = RP1942.Padlocks or {}
local P = RP1942.Padlocks

P.defaults = {
    openTime     = 5,     -- seconds a door stays open (E, lockpick or ram)
    perPlayer    = 2,     -- padlocked doors one player may have at once
    minSize      = 40,    -- the prop's longest side must be at least this (units)...
    maxSize      = 200,   -- ...and at most this, so nobody padlocks a whole wall
    maxAccess    = 12,    -- players one lock can list by name
    allowFaction = true,  -- the owner may tick "anyone in my faction"
    allowJob     = true,  -- the owner may tick "anyone with my job"
    knock        = true,  -- E on a lock you can't open knocks, and tells the owner
    staffPickable  = true, -- staff locks (no owner) can be lockpicked
    staffRammable  = true, -- staff locks can be rammed (there's no owner to warrant)

    -- Shooting padlocks off (off by default)
    shootable    = false, -- padlocks take damage (bullets, explosions, melee) and show a health bar
    lockHealth   = 200,   -- damage a padlock takes before it breaks
    brokenTime   = 60,    -- seconds a door stays open once its padlock is shot off
    healDelay    = 30,    -- seconds without a hit before a damaged padlock is back to full (0 = never)
    hitRadius    = 16,    -- a bullet or melee hit on the door this close to the padlock counts as hitting it
}
P.settings = P.settings or table.Copy(P.defaults)

P.MODEL = "models/props_wasteland/prison_padlock001a.mdl"
P.KIT   = "rp1942_padlock_kit"

function RP1942.padlockSetting(key)
    local v = P.settings[key]
    if v == nil then v = P.defaults[key] end
    return v
end

P.keys = {}
for k in pairs(P.defaults) do P.keys[#P.keys + 1] = k end
table.sort(P.keys)

-- The padlock on a door, from the door prop or the padlock itself (or nil)
function RP1942.padlockOf(ent)
    if not IsValid(ent) then return nil end
    if ent:GetClass() == "rp1942_padlock" then return ent end
    local lock = ent:GetNW2Entity("RP1942_Padlock")
    if IsValid(lock) then return lock end
end

-- Faction-door groups (rp1942_doors) a lock can let in: same names, same members
function RP1942.padlockGroups()
    return RP1942.FactionDoors and RP1942.FactionDoors.groups or {}
end

function RP1942.inPadlockGroup(ply, id)
    for _, g in ipairs(RP1942.padlockGroups()) do
        if g.id == id then
            if g.faction then return RP1942.getFaction(ply) == g.faction end
            if g.branch then
                if RP1942.getBranch(ply) == g.branch then return true end
                local job = RPExtraTeams[ply:Team()]
                local extra = RP1942.FactionDoors.reichUnitsAlsoAllow or {}
                return job ~= nil and job.faction == "reich" and table.HasValue(extra, job.command)
            end
        end
    end
    return false
end

--[[ DarkRP's lockpick and battering ram ------------------------------------
Both run on the client too (prediction), so these hooks are shared. The
server decides; the client only needs to know the target is a padlocked door.
---------------------------------------------------------------------------]]
hook.Add("canLockpick", "RP1942_Padlocks", function(ply, ent, trace)
    local lock = RP1942.padlockOf(ent)
    if not lock then return end
    if trace and trace.HitPos:DistToSqr(ply:GetShootPos()) > 10000 then return false end
    if lock:GetOpen() then return false end
    if lock:GetStaff() and not RP1942.padlockSetting("staffPickable") then return false end
    return true
end)

-- Low priority: the lockpick's own clean-up hooks still run before this one,
-- which takes over what happens on success (our door, our timing)
hook.Add("onLockpickCompleted", "RP1942_Padlocks", function(ply, success, ent)
    local lock = RP1942.padlockOf(ent)
    if not lock then return end
    if SERVER and success and RP1942.padlockPicked then RP1942.padlockPicked(lock, ply) end
    return true
end, HOOK_LOW or 1)

hook.Add("canDoorRam", "RP1942_Padlocks", function(ply, trace, ent)
    local lock = RP1942.padlockOf(ent)
    if not lock then return end
    if trace.HitPos:DistToSqr(ply:EyePos()) > 10000 then return false end
    if CLIENT then return not lock:GetOpen() end
    return RP1942.padlockRammed and RP1942.padlockRammed(lock, ply) or false
end)
