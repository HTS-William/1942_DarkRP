--[[---------------------------------------------------------------------------
1942 DarkRP - padlocks (server). How it plays: sh_padlocks.lua.

    RP1942.padlockFit(ply, trace, staffKit)   fit one (the Padlock SWEP)
    RP1942.padlockCanOpen(ply, lock)
    RP1942.padlockOpen(lock, seconds)

A lock's access, kept on the padlock entity (server only):
    lock.access.players   SteamID -> name     named players
    lock.access.groups    id -> true          faction-door groups: reich,
                                              resistance, civilian, wehrmacht,
                                              waffen_ss, leibstandarte
    lock.access.jobs      job command -> true
The owner can always open their own lock. Staff locks have no owner.
---------------------------------------------------------------------------]]
local P = RP1942.Padlocks
local S = RP1942.padlockSetting

util.AddNetworkString("RP1942_PadlockMenu")     -- to a player: open the lock's menu
util.AddNetworkString("RP1942_PadlockEdit")     -- from a player: change it
util.AddNetworkString("RP1942_PadlockMarkers")  -- to staff: every lock, for !doorlocks

local DATA_DIR = "rp1942"
local SETTINGS_FILE = DATA_DIR .. "/padlocks.json"
local function savesFile() return DATA_DIR .. "/padlocks_" .. game.GetMap() .. ".json" end

local locks = {}   -- every padlock: ent -> true

local function isStaff(ply)
    return RP1942.staffCan(ply, "ulx removelock", function(p) return p:IsSuperAdmin() end)
end

-- Who gets a lock's menu: a player's lock is its owner's alone (staff take
-- one off with !removelock); a staff lock is for staff.
local function canEdit(ply, lock)
    if lock:GetStaff() then return isStaff(ply) end
    return IsValid(lock:GetLockOwner()) and lock:GetLockOwner() == ply
end

--[[ Settings: padlocks.json over the defaults ------------------------------]]
local function loadSettings()
    local saved = util.JSONToTable(file.Read(SETTINGS_FILE, "DATA") or "") or {}
    P.settings = table.Copy(P.defaults)
    for k, v in pairs(saved) do
        if P.defaults[k] ~= nil and type(v) == type(P.defaults[k]) then P.settings[k] = v end
    end
end
loadSettings()

-- What the clients need for the health bar
local function publish()
    SetGlobal2Bool("RP1942_PadlockShootable", S("shootable") == true)
    SetGlobal2Int("RP1942_PadlockHealth", math.floor(S("lockHealth")))
end
publish()

function RP1942.setPadlockSetting(key, value)
    local def = P.defaults[key]
    if def == nil then return false, "No such setting. They are: " .. table.concat(P.keys, ", ") end
    local v
    if isbool(def) then
        value = string.lower(tostring(value))
        if value == "1" or value == "true" or value == "on" or value == "yes" then v = true
        elseif value == "0" or value == "false" or value == "off" or value == "no" then v = false
        else return false, key .. " is on or off (1 / 0)." end
    else
        v = tonumber(value)
        if not v or v < 0 then return false, key .. " needs a number, 0 or more." end
    end
    P.settings[key] = v
    file.CreateDir(DATA_DIR)
    local diff = {}
    for k, val in pairs(P.settings) do if val ~= P.defaults[k] then diff[k] = val end end
    file.Write(SETTINGS_FILE, util.TableToJSON(diff, true))
    publish()
    return true, key .. " = " .. tostring(v)
end

--[[ Who may open it --------------------------------------------------------]]
function RP1942.padlockCanOpen(ply, lock)
    if not IsValid(ply) or not IsValid(lock) then return false end
    if lock:GetLockOwner() == ply then return true end
    local a = lock.access
    if not a then return false end
    if a.players[ply:SteamID()] then return true end
    for id in pairs(a.groups) do
        if RP1942.inPadlockGroup(ply, id) then return true end
    end
    local job = RPExtraTeams[ply:Team()]
    return job ~= nil and a.jobs[job.command] == true
end

--[[ Open and close ---------------------------------------------------------
Open: see-through and not solid. Closing waits while anyone is in the
doorway, so nobody is ever shut inside a prop.
---------------------------------------------------------------------------]]
local function blocked(door)
    local mins, maxs = door:WorldSpaceAABB()
    for _, e in ipairs(ents.FindInBox(mins, maxs)) do
        if (e:IsPlayer() and e:Alive()) or e:IsNPC() or e:IsNextBot() then return true end
    end
    return false
end

local function shut(lock)
    local door = lock:GetDoor()
    lock:SetOpen(false)
    if not IsValid(door) then return end
    local saved = door.RP1942_Look
    if saved then
        door:SetRenderMode(saved.mode)
        door:SetColor(saved.color)
        door.RP1942_Look = nil
    end
    door:DrawShadow(true)
    door:SetNotSolid(false)
    door:EmitSound("doors/door_latch1.wav", 65, 100)
    -- a padlock that was shot off is whole again once its door has shut
    if lock:GetBroken() then
        lock:SetBroken(false)
        lock:SetLockHealth(math.floor(S("lockHealth")))
    end
end

function RP1942.padlockOpen(lock, seconds)
    local door = IsValid(lock) and lock:GetDoor()
    if not IsValid(door) then return false end
    lock.closeAt = CurTime() + (seconds or S("openTime"))
    if lock:GetOpen() then return true end

    lock:SetOpen(true)
    door.RP1942_Look = { mode = door:GetRenderMode(), color = door:GetColor() }
    local c = door.RP1942_Look.color
    door:SetRenderMode(RENDERMODE_TRANSALPHA)
    door:SetColor(Color(c.r, c.g, c.b, math.min(c.a, 60)))
    door:DrawShadow(false)
    door:SetNotSolid(true)
    local phys = door:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    door:EmitSound("doors/door_latch3.wav", 65, 100)

    local name = "RP1942_Padlock_" .. lock:EntIndex()
    timer.Create(name, 0.5, 0, function()
        if not IsValid(lock) then timer.Remove(name) return end
        if CurTime() < (lock.closeAt or 0) then return end
        local d = lock:GetDoor()
        if IsValid(d) and blocked(d) then return end   -- someone in the doorway: wait
        timer.Remove(name)
        shut(lock)
    end)
    return true
end

--[[ Fitting one ------------------------------------------------------------]]
local function ownedBy(ply)
    local n = 0
    for lock in pairs(locks) do
        if IsValid(lock) and lock:GetLockOwner() == ply then n = n + 1 end
    end
    return n
end

local function newLock(door, pos, ang, owner, staff)
    local lock = ents.Create("rp1942_padlock")
    if not IsValid(lock) then return nil end
    lock:SetPos(pos)
    lock:SetAngles(ang)
    lock:Spawn()
    lock:SetParent(door)
    lock:SetDoor(door)
    lock:SetStaff(staff == true)
    lock.access = { players = {}, groups = {}, jobs = {} }
    lock:SetLockHealth(math.floor(S("lockHealth")))
    if IsValid(owner) then
        lock:SetLockOwner(owner)
        lock:SetOwnerName(owner:Nick())
        if lock.CPPISetOwner then lock:CPPISetOwner(owner) end
    end
    door:SetNW2Entity("RP1942_Padlock", lock)
    local phys = door:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) phys:Sleep() end
    door:CallOnRemove("RP1942_Padlock", function() if IsValid(lock) then lock:Remove() end end)
    locks[lock] = true
    return lock
end

function RP1942.padlockFit(ply, tr, staffKit)
    local door = tr and tr.Entity
    local function no(msg) DarkRP.notify(ply, 1, 5, msg) return false end
    if staffKit and not isStaff(ply) then staffKit = false end

    if not IsValid(door) or door:GetClass() ~= "prop_physics" then return no("Look at a prop to turn into a door.") end
    if tr.HitPos:DistToSqr(ply:EyePos()) > 120 * 120 then return no("Get closer to it.") end
    if RP1942.padlockOf(door) then return no("That door already has a padlock.") end

    if not staffKit then
        local owner = door.CPPIGetOwner and door:CPPIGetOwner()
        if owner ~= ply then return no("You can only fit a padlock on a prop you own.") end
        local size = door:OBBMaxs() - door:OBBMins()
        local longest = math.max(size.x, size.y, size.z)
        if longest < S("minSize") then return no("That's too small to be a door.") end
        if longest > S("maxSize") then return no("That's too big to be a door (" .. math.floor(longest) .. " units; the most is " .. S("maxSize") .. ").") end
        if ownedBy(ply) >= S("perPlayer") then return no("You already have " .. S("perPlayer") .. " padlocked doors, the most you can have.") end
    end

    local lock = newLock(door, tr.HitPos + tr.HitNormal * 1.5, tr.HitNormal:Angle(), not staffKit and ply or nil, staffKit)
    if not IsValid(lock) then return no("The padlock couldn't be fitted.") end
    door:EmitSound("doors/handle_pushbar_locked1.wav", 70, 100)
    DarkRP.notify(ply, 0, 7, staffKit
        and "Staff padlock fitted. Shift+E on it to choose who can open it, then !savelock to keep it on this map."
        or "Padlock fitted: the prop is now a door. Shift+E on the padlock to choose who else can open it.")
    ServerLog(string.format("[1942] %s fitted a %spadlock on %s at %s\n", ply:Nick(), staffKit and "staff " or "", door:GetModel(), tostring(door:GetPos())))
    return true
end

-- Hand a Padlock back: into their hands, or at their feet if they already carry one
local function giveKit(ply)
    if not IsValid(ply) then return end
    if not ply:HasWeapon(P.KIT) then
        ply:Give(P.KIT)
    else
        local item = ents.Create("spawned_weapon")
        if IsValid(item) then
            item:SetModel(P.MODEL)
            item:SetWeaponClass(P.KIT)
            item:SetPos(ply:GetPos() + ply:GetForward() * 30 + Vector(0, 0, 20))
            item:Spawn()
            item.nodupe = true
        end
    end
    DarkRP.notify(ply, 0, 5, "You took the padlock off. It's back with you, ready to fit again.")
end

function RP1942.padlockRemoved(lock)
    locks[lock] = nil
    -- the owner took it off themselves (menu or remover tool): they get it back
    local refund = lock.refundTo
    lock.refundTo = nil
    if IsValid(refund) and refund == lock:GetLockOwner() and not lock:GetStaff() then giveKit(refund) end
    timer.Remove("RP1942_Padlock_" .. lock:EntIndex())
    local door = lock:GetDoor()
    if IsValid(door) then
        if lock:GetOpen() then shut(lock) end
        door:SetNW2Entity("RP1942_Padlock", NULL)
        door:RemoveCallOnRemove("RP1942_Padlock")
    end
end

--[[ Raiding: called from the shared lockpick / ram hooks --------------------]]
-- Alerts to the owner (knocking, picked, rammed, shot off): normal notices,
-- like the rest of the server's, not the red "error" kind used for refusals
local function tellOwner(lock, msg)
    local owner = lock:GetLockOwner()
    if IsValid(owner) then DarkRP.notify(owner, 0, 6, msg) end
end

function RP1942.padlockPicked(lock, ply)
    RP1942.padlockOpen(lock)
    tellOwner(lock, "Someone picked the padlock on your door!")
    ServerLog(string.format("[1942] %s picked a padlock (owner %s)\n", ply:Nick(), lock:GetOwnerName()))
end

-- Shooting it (only with the "shootable" setting)
local SHOOTABLE = bit.bor(DMG_BULLET, DMG_BUCKSHOT, DMG_BLAST, DMG_CLUB, DMG_SLASH, DMG_SNIPER, DMG_AIRBOAT)
function RP1942.padlockDamaged(lock, dmg)
    if not S("shootable") or lock:GetBroken() then return end
    if bit.band(dmg:GetDamageType(), SHOOTABLE) == 0 and dmg:GetDamageType() ~= DMG_GENERIC then return end
    local amount = dmg:GetDamage()
    if amount <= 0 then return end
    lock.lastHit = CurTime()
    local hp = math.max(0, math.min(lock:GetLockHealth(), S("lockHealth")) - amount)
    lock:SetLockHealth(math.floor(hp))
    if hp > 0 then
        lock:EmitSound("physics/metal/metal_solid_impact_bullet" .. math.random(1, 4) .. ".wav", 70, math.random(110, 125))
        return
    end

    -- Shot off: the door is open for brokenTime, then whole again (shut())
    lock:SetBroken(true)
    local ed = EffectData()
    ed:SetOrigin(lock:GetPos())
    ed:SetNormal(lock:GetForward())
    util.Effect("ManhackSparks", ed, true, true)
    lock:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 75, 100)
    RP1942.padlockOpen(lock, S("brokenTime"))
    tellOwner(lock, "Your padlock has been shot off! The door is open.")
    local attacker = dmg:GetAttacker()
    ServerLog(string.format("[1942] %s shot off a padlock (owner %s)\n",
        IsValid(attacker) and attacker:IsPlayer() and attacker:Nick() or "something", lock:GetOwnerName()))
end

-- The padlock is small and sits on the door, so a bullet or a blow that hits
-- the door right next to it counts as hitting the padlock. (Explosions reach
-- the padlock itself, so they aren't passed on from the door as well.)
hook.Add("EntityTakeDamage", "RP1942_PadlockDoorHits", function(target, dmg)
    if not S("shootable") or not IsValid(target) or target:GetClass() == "rp1942_padlock" then return end
    local lock = RP1942.padlockOf(target)
    if not lock or lock:GetDoor() ~= target then return end
    if bit.band(dmg:GetDamageType(), DMG_BLAST) ~= 0 then return end
    local r = S("hitRadius")
    if dmg:GetDamagePosition():DistToSqr(lock:WorldSpaceCenter()) > r * r then return end
    RP1942.padlockDamaged(lock, dmg)
end)

-- A damaged padlock heals to full after healDelay seconds without a hit
timer.Create("RP1942_PadlockHeal", 2, 0, function()
    local delay = S("healDelay")
    if delay <= 0 then return end
    local max = math.floor(S("lockHealth"))
    for lock in pairs(locks) do
        if IsValid(lock) and not lock:GetBroken() and lock:GetLockHealth() < max
            and CurTime() - (lock.lastHit or 0) >= delay then
            lock:SetLockHealth(max)
        end
    end
end)

function RP1942.padlockRammed(lock, ply)
    if lock:GetOpen() then return false end
    local allowed
    if lock:GetStaff() then
        allowed = S("staffRammable")
    else
        local owner = lock:GetLockOwner()
        allowed = IsValid(owner) and (owner.warranted == true or owner:isWanted() or owner:isArrested())
    end
    if not allowed then
        DarkRP.notify(ply, 1, 5, DarkRP.getPhrase("warrant_required"))
        return false
    end
    RP1942.padlockOpen(lock)
    tellOwner(lock, "Your door has been broken open!")
    ServerLog(string.format("[1942] %s rammed a padlocked door (owner %s)\n", ply:Nick(), lock:GetOwnerName()))
    return true
end

--[[ The menu ---------------------------------------------------------------]]
local function sendMenu(ply, lock)
    local a = lock.access
    local owner = lock:GetLockOwner()
    local isOwner = owner == ply
    local job = IsValid(owner) and RPExtraTeams[owner:Team()]
    net.Start("RP1942_PadlockMenu")
    net.WriteEntity(lock)
    net.WriteBool(isOwner)
    net.WriteBool(lock:GetStaff())   -- a staff lock's menu: every group and job
    net.WriteBool(S("allowFaction"))
    net.WriteBool(S("allowJob"))
    net.WriteUInt(S("maxAccess"), 8)
    net.WriteString(IsValid(owner) and RP1942.getFaction(owner) or "")
    net.WriteString(job and job.command or "")
    net.WriteString(job and job.name or "")
    net.WriteBool(lock.saveId ~= nil)
    local n = table.Count(a.players)
    net.WriteUInt(n, 8)
    for sid, name in pairs(a.players) do net.WriteString(sid) net.WriteString(name) end
    net.WriteUInt(table.Count(a.groups), 8)
    for id in pairs(a.groups) do net.WriteString(id) end
    net.WriteUInt(table.Count(a.jobs), 8)
    for cmd in pairs(a.jobs) do net.WriteString(cmd) end
    net.Send(ply)
end

local writeSave   -- defined below (staff locks saved per map)

net.Receive("RP1942_PadlockEdit", function(_, ply)
    if (ply.RP1942_NextLockEdit or 0) > CurTime() then return end
    ply.RP1942_NextLockEdit = CurTime() + 0.2
    local lock = net.ReadEntity()
    local action, arg = net.ReadString(), net.ReadString()
    if not IsValid(lock) or lock:GetClass() ~= "rp1942_padlock" or not lock.access then return end
    if lock:GetPos():DistToSqr(ply:GetPos()) > 400 * 400 then return end
    local owner = lock:GetLockOwner()
    if not canEdit(ply, lock) then return end
    local staff = lock:GetStaff()   -- staff editing a staff lock: any group or job
    local a = lock.access

    if action == "remove" then
        ServerLog(string.format("[1942] %s removed a padlock (owner %s)\n", ply:Nick(), lock:GetOwnerName()))
        if lock.saveId then writeSave(lock.saveId, nil) end
        if ply == owner then lock.refundTo = ply end   -- the owner gets it back (not when staff take it off)
        lock:Remove()
        return
    elseif action == "addplayer" then
        local target = player.GetBySteamID(arg)
        if not IsValid(target) or target == owner then return end
        if table.Count(a.players) >= S("maxAccess") then
            return DarkRP.notify(ply, 1, 4, "A padlock can list " .. S("maxAccess") .. " players at most.")
        end
        a.players[arg] = target:Nick()
    elseif action == "removeplayer" then
        a.players[arg] = nil
    elseif action == "group" then
        local valid = false
        for _, g in ipairs(RP1942.padlockGroups()) do if g.id == arg then valid = true end end
        if not valid then return end
        -- an owner may only let in their own faction, if the setting allows it
        if not staff and not (S("allowFaction") and IsValid(owner) and RP1942.getFaction(owner) == arg) then return end
        a.groups[arg] = (not a.groups[arg]) or nil
    elseif action == "job" then
        if not RP1942.getJobByCommand(arg) then return end
        local myJob = IsValid(owner) and RPExtraTeams[owner:Team()]
        if not staff and not (S("allowJob") and myJob and myJob.command == arg) then return end
        a.jobs[arg] = (not a.jobs[arg]) or nil
    else
        return
    end

    if lock.saveId then writeSave(lock.saveId, lock) end
    sendMenu(ply, lock)
end)

--[[ E: open, knock, or (Shift) the menu -------------------------------------]]
hook.Add("PlayerUse", "RP1942_Padlocks", function(ply, ent)
    local lock = RP1942.padlockOf(ent)
    if not lock then return end
    if (ply.RP1942_NextLockUse or 0) > CurTime() then return false end
    ply.RP1942_NextLockUse = CurTime() + 0.5

    if ply:KeyDown(IN_SPEED) and canEdit(ply, lock) then
        sendMenu(ply, lock)
        return false
    end
    if lock:GetOpen() then return false end

    if RP1942.padlockCanOpen(ply, lock) then
        RP1942.padlockOpen(lock)
    elseif S("knock") then
        local door = lock:GetDoor()
        if IsValid(door) then door:EmitSound("physics/wood/wood_box_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.random(95, 105)) end
        if (lock.nextKnockNotice or 0) <= CurTime() then
            lock.nextKnockNotice = CurTime() + 10
            tellOwner(lock, "Someone is knocking at your door.")
        end
    end
    return false
end)

-- Only staff move, tool or edit a staff lock's door; nobody grabs an open door
local function guarded(ply, ent)
    if not IsValid(ent) then return end
    local lock = RP1942.padlockOf(ent)
    if not lock then return end
    if ent:GetClass() == "rp1942_padlock" and not isStaff(ply) and lock:GetLockOwner() ~= ply then return false end
    if lock:GetOpen() then return false end
    if lock:GetStaff() and not isStaff(ply) then return false end
end
hook.Add("PhysgunPickup", "RP1942_Padlocks", function(ply, ent)
    if IsValid(ent) and ent:GetClass() == "rp1942_padlock" then return false end   -- it stays where it was fitted
    return guarded(ply, ent)
end)
hook.Add("CanTool", "RP1942_Padlocks", function(ply, tr, tool)
    local verdict = guarded(ply, tr.Entity)
    -- the owner using the remover on their padlock or its door gets the padlock back
    if verdict == nil and tool == "remover" then
        local lock = RP1942.padlockOf(tr.Entity)
        if lock and lock:GetLockOwner() == ply then lock.refundTo = ply end
    end
    return verdict
end)
hook.Add("CanProperty", "RP1942_Padlocks", function(ply, _, ent) return guarded(ply, ent) end)

--[[ Staff locks saved per map ----------------------------------------------]]
local function loadSaves() return util.JSONToTable(file.Read(savesFile(), "DATA") or "") or {} end

writeSave = function(id, lock)
    local saves = loadSaves()
    if not lock then
        saves[id] = nil
    else
        local door = lock:GetDoor()
        if not IsValid(door) then return end
        local pos, ang, col = door:GetPos(), door:GetAngles(), door:GetColor()
        local lp, la = lock:GetLocalPos(), lock:GetLocalAngles()
        local players = {}
        for sid, name in pairs(lock.access.players) do players[sid] = name end
        saves[id] = {
            model = door:GetModel(), skin = door:GetSkin(), material = door:GetMaterial(),
            color = { col.r, col.g, col.b, col.a },
            x = pos.x, y = pos.y, z = pos.z, p = ang.p, yaw = ang.y, r = ang.r,
            lock = { lp.x, lp.y, lp.z, la.p, la.y, la.r },
            groups = table.GetKeys(lock.access.groups),
            jobs = table.GetKeys(lock.access.jobs),
            players = players,
        }
    end
    file.CreateDir(DATA_DIR)
    file.Write(savesFile(), util.TableToJSON(saves, true))
end

-- A saved door is a fresh prop owned by nobody, so it outlives whoever placed it
local function spawnSaved(id, e)
    local door = ents.Create("prop_physics")
    if not IsValid(door) then return end
    door:SetModel(e.model)
    door:SetPos(Vector(e.x, e.y, e.z))
    door:SetAngles(Angle(e.p, e.yaw, e.r))
    door:Spawn()
    door:Activate()
    door:SetSkin(e.skin or 0)
    if e.material and e.material ~= "" then door:SetMaterial(e.material) end
    if e.color then door:SetColor(Color(e.color[1], e.color[2], e.color[3], e.color[4])) end
    local l = e.lock or { 0, 0, 0, 0, 0, 0 }
    local lock = newLock(door, door:LocalToWorld(Vector(l[1], l[2], l[3])), door:LocalToWorldAngles(Angle(l[4], l[5], l[6])), nil, true)
    if not IsValid(lock) then door:Remove() return end
    lock.saveId = id
    for _, g in ipairs(e.groups or {}) do lock.access.groups[g] = true end
    for _, j in ipairs(e.jobs or {}) do lock.access.jobs[j] = true end
    for sid, name in pairs(e.players or {}) do lock.access.players[sid] = name end
    return lock
end

local function spawnAllSaved()
    local n = 0
    for id, e in pairs(loadSaves()) do
        if IsValid(spawnSaved(id, e)) then n = n + 1 end
    end
    if n > 0 then MsgC(Color(160, 220, 120), "[1942] Padlocks: " .. n .. " saved staff lock(s) placed.\n") end
end
hook.Add("InitPostEntity", "RP1942_Padlocks", function() timer.Simple(2, spawnAllSaved) end)
hook.Add("PostCleanupMap", "RP1942_Padlocks", function() timer.Simple(1, spawnAllSaved) end)

--[[ Staff commands (ULX 42Bros) ---------------------------------------------]]
local function say(ply, msg, bad)
    if IsValid(ply) then DarkRP.notify(ply, bad and 1 or 0, 6, msg) else print("[1942 padlocks] " .. msg) end
end

local function lookedAtLock(ply)
    local tr = ply:GetEyeTrace()
    local lock = RP1942.padlockOf(tr.Entity)
    if not lock or tr.HitPos:DistToSqr(ply:EyePos()) > 400 * 400 then
        say(ply, "Look at a padlock, or the door it's on.", true)
        return nil
    end
    return lock
end

RP1942.defineStaffCommand("padlock", function(ply)
    if not isStaff(ply) then return say(ply, "You aren't allowed to do that.", true) end
    local wep = ply:GetWeapon(P.KIT)
    if not IsValid(wep) then wep = ply:Give(P.KIT) end
    if IsValid(wep) then
        wep:SetStaffKit(true)
        ply:SelectWeapon(P.KIT)
        say(ply, "Staff padlock: left click any prop to fit it. It doesn't run out.")
    end
end)

RP1942.defineStaffCommand("savelock", function(ply)
    if not isStaff(ply) then return say(ply, "You aren't allowed to do that.", true) end
    local lock = lookedAtLock(ply)
    if not lock then return end
    if not lock:GetStaff() then return say(ply, "Only staff locks (fitted with !padlock) can be saved. Players' locks belong to them.", true) end
    if lock.saveId then return say(ply, "That lock is already saved for this map.", true) end
    local id = tostring(os.time()) .. "_" .. math.random(1000, 9999)
    writeSave(id, lock)
    -- swap the placed prop for the saved copy, owned by nobody
    local old = lock:GetDoor()
    local fresh = spawnSaved(id, loadSaves()[id])
    if IsValid(fresh) and IsValid(old) then old:Remove() end
    say(ply, "Saved: this door and its padlock come back after every restart and cleanup.")
    ServerLog(string.format("[1942] %s saved a staff padlock on %s\n", ply:Nick(), game.GetMap()))
end)

RP1942.defineStaffCommand("removelock", function(ply)
    if not isStaff(ply) then return say(ply, "You aren't allowed to do that.", true) end
    local lock = lookedAtLock(ply)
    if not lock then return end
    local door = lock:GetDoor()
    if lock.saveId then
        writeSave(lock.saveId, nil)
        if IsValid(door) then door:Remove() end   -- a saved door was ours: it goes too
        say(ply, "Removed the saved door and its padlock from this map.")
    else
        lock:Remove()
        say(ply, "Padlock removed. The prop is a plain prop again.")
    end
    ServerLog(string.format("[1942] %s removed a padlock (owner %s)\n", ply:Nick(), lock:GetOwnerName()))
end)

RP1942.defineStaffCommand("doorlocks", function(ply)
    if not isStaff(ply) then return say(ply, "You aren't allowed to do that.", true) end
    local list = {}
    for lock in pairs(locks) do
        if IsValid(lock) then
            local who = lock:GetStaff() and (lock.saveId and "Staff lock (saved)" or "Staff lock") or (lock:GetOwnerName() .. "'s padlock")
            list[#list + 1] = { pos = lock:GetPos(), text = who }
        end
    end
    net.Start("RP1942_PadlockMarkers")
    net.WriteUInt(math.min(#list, 255), 8)
    for i = 1, math.min(#list, 255) do
        net.WriteVector(list[i].pos)
        net.WriteString(list[i].text)
    end
    net.Send(ply)
    say(ply, #list .. " padlock(s) on the map, highlighted for a minute.")
end)

RP1942.defineStaffCommand("locksettings", function(ply, args)
    if not isStaff(ply) then return say(ply, "You aren't allowed to do that.", true) end
    local key, value = string.match(tostring(args or ""), "^%s*(%S*)%s*(.-)%s*$")
    if key == "" then
        local parts = {}
        for _, k in ipairs(P.keys) do parts[#parts + 1] = k .. " " .. tostring(S(k)) end
        return say(ply, "Padlock settings: " .. table.concat(parts, ", "))
    end
    if P.defaults[key] == nil then return say(ply, "No such setting: " .. key .. ". They are: " .. table.concat(P.keys, ", "), true) end
    if value == "" then return say(ply, key .. " = " .. tostring(S(key)) .. " (default " .. tostring(P.defaults[key]) .. ")") end
    local ok, msg = RP1942.setPadlockSetting(key, value)
    say(ply, msg, not ok)
    if ok then ServerLog(string.format("[1942] %s set padlock setting %s\n", IsValid(ply) and ply:Nick() or "console", msg)) end
end)
