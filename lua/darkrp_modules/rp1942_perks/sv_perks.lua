--[[---------------------------------------------------------------------------
1942 DarkRP - the Führer's perks (server). Settings: sh_perks.lua
---------------------------------------------------------------------------]]
local CFG = RP1942.Perks
local MENU = "RP1942_FuhrerMenu"

-- The model, its paint and the vehicle script go to players who join
resource.AddFile(CFG.apc.model)
resource.AddFile("materials/models/props_vehicles/222_darkyellow44.vmt")

--[[---------------------------------------------------------------------------
The APC garage: one spot per map, set by staff with !setapcspot (look at the
floor; the car faces you). Saved in data/rp1942/apc_spot_<map>.json
---------------------------------------------------------------------------]]
local store = RP1942.mapStore("apc_spot")

RP1942.defineStaffCommand("setapcspot", function(ply)
    if not RP1942.staffCan(ply, "ulx setapcspot") then return end
    local tr = ply:GetEyeTrace()
    if not tr.Hit or tr.HitPos:Distance(ply:EyePos()) > 600 then
        return DarkRP.notify(ply, 1, 4, "Look at the floor where the armoured car should stand.")
    end
    local yaw = math.Round(ply:EyeAngles().y + 180)
    store.save({ x = tr.HitPos.x, y = tr.HitPos.y, z = tr.HitPos.z, yaw = yaw })
    DarkRP.notify(ply, 0, 5, "APC garage set for this map. A bought armoured car appears here, facing you.")
    ServerLog(string.format("[1942] %s set the APC garage at %s\n", ply:Nick(), tostring(tr.HitPos)))
end)

local function apcSpot()
    local s = store.load()
    if not tonumber(s.x) then return end
    return Vector(s.x, s.y, s.z), Angle(0, tonumber(s.yaw) or 0, 0)
end

--[[---------------------------------------------------------------------------
The armoured car
---------------------------------------------------------------------------]]
local function apc() local e = GetGlobal2Entity("RP1942_APC") return IsValid(e) and e or nil end

--[[---------------------------------------------------------------------------
Its owner: the Wehrmacht Driver. Owned through DarkRP's keys (so his keys
lock and unlock it, and it shows as his) and prop protection. If no driver
is on when it's bought it waits unowned; whoever takes the job next gets it,
and when the driver leaves the job or the server it passes to the next one.
---------------------------------------------------------------------------]]
local function isDriver(ply)
    local job = IsValid(ply) and RPExtraTeams[ply:Team()]
    return job ~= nil and CFG.apc.drivers[job.command] == true
end

local function findDriver(except)
    for _, p in ipairs(player.GetAll()) do
        if p ~= except and isDriver(p) then return p end
    end
end

local function giveAPC(car, ply)
    if not IsValid(car) then return end
    local old = car.RP1942_Owner
    if old == ply then return end
    if IsValid(old) and car.keysUnOwn then car:keysUnOwn(old) end
    car.RP1942_Owner = IsValid(ply) and ply or nil
    if IsValid(ply) then
        if car.keysOwn then car:keysOwn(ply) end
        if car.CPPISetOwner then car:CPPISetOwner(ply) end
        DarkRP.notify(ply, 0, 8, "The Reich's armoured car is yours to drive: it's at the APC garage. Your keys lock and unlock it.")
    elseif car.CPPISetOwner then
        car:CPPISetOwner(game.GetWorld())
    end
end

local function setCooldown(id, seconds)
    SetGlobal2Float("RP1942_PerkCD_" .. id, seconds > 0 and CurTime() + seconds or 0)
end

local function spawnAPC()
    local pos, ang = apcSpot()
    if not pos then return nil, "No APC garage on this map yet: staff set one with !setapcspot." end
    if not util.IsValidModel(CFG.apc.model) then return nil, "The armoured car's model isn't installed on the server." end

    local car = ents.Create("prop_vehicle_jeep")
    if not IsValid(car) then return nil, "The armoured car couldn't be made." end
    car:SetModel(CFG.apc.model)
    car:SetKeyValue("vehiclescript", CFG.apc.script)
    car:SetPos(pos + Vector(0, 0, 24))
    car:SetAngles(ang - Angle(0, 90, 0))   -- vehicle models face +Y: this turns its nose to the yaw that was set
    car:Spawn()
    car:Activate()
    car.RP1942_APC = true
    car.RP1942_Health = CFG.apc.health
    car:SetNW2Int("RP1942_APCHealth", CFG.apc.health)
    car:SetNW2Int("RP1942_APCMax", CFG.apc.health)
    SetGlobal2Entity("RP1942_APC", car)
    giveAPC(car, findDriver())
    return car
end

local function destroyAPC(car, attacker)
    if not IsValid(car) or car.RP1942_Dead then return end
    car.RP1942_Dead = true
    local driver = car:GetDriver()
    if IsValid(driver) then driver:ExitVehicle() end
    local pos = car:WorldSpaceCenter()
    local fx = EffectData() fx:SetOrigin(pos) util.Effect("Explosion", fx)
    util.BlastDamage(car, IsValid(attacker) and attacker or car, pos, CFG.apc.blastRadius, CFG.apc.blastDamage)
    car:Remove()
    local p = RP1942.getPerk("apc")
    setCooldown("apc", p and p.cooldown or 0)
    if RP1942.alert then RP1942.alert("The Reich's armoured car has been destroyed!", "wanted") end
    ServerLog(string.format("[1942] The APC was destroyed%s\n", IsValid(attacker) and attacker:IsPlayer() and (" by " .. attacker:Nick()) or ""))
end

-- Its own health (Source vehicles don't take damage by themselves)
hook.Add("EntityTakeDamage", "RP1942_APCDamage", function(ent, dmg)
    if not (IsValid(ent) and ent.RP1942_APC) then return end
    ent.RP1942_Health = (ent.RP1942_Health or CFG.apc.health) - dmg:GetDamage()
    ent:SetNW2Int("RP1942_APCHealth", math.max(math.floor(ent.RP1942_Health), 0))
    if ent.RP1942_Health <= 0 then destroyAPC(ent, dmg:GetAttacker()) end
end)

-- Hand it on when the driver changes
hook.Add("OnPlayerChangedTeam", "RP1942_APCOwner", function(ply)
    timer.Simple(0, function()
        local car = apc()
        if not car or not IsValid(ply) then return end
        if isDriver(ply) and not IsValid(car.RP1942_Owner) then
            giveAPC(car, ply)
        elseif car.RP1942_Owner == ply and not isDriver(ply) then
            if car:GetDriver() == ply then ply:ExitVehicle() end
            giveAPC(car, findDriver(ply))
        end
    end)
end)

hook.Add("PlayerDisconnected", "RP1942_APCOwner", function(ply)
    local car = apc()
    if car and car.RP1942_Owner == ply then giveAPC(car, findDriver(ply)) end
end)

-- (DarkRP removes a leaving player's vehicles by their SID, which this one
-- never gets: it's the Reich's, and stays when its driver goes.)

--[[---------------------------------------------------------------------------
The gun: the driver's left click fires a Panzerschreck rocket where he's
looking, from the top of the car, every few seconds (sh_perks.lua: apc.cannon)
---------------------------------------------------------------------------]]
local function fireCannon(ply, car)
    local c = CFG.apc.cannon
    if not c then return end
    local now = CurTime()
    if car:GetNW2Float("RP1942_APCReady", 0) > now then return end
    local cost = math.max(math.floor(c.shotCost or 0), 0)
    if cost > 0 and not ply:canAfford(cost) then
        if (ply.RP1942_NextShotWarn or 0) < now then
            ply.RP1942_NextShotWarn = now + 2
            DarkRP.notify(ply, 1, 4, "You can't afford a rocket: each shot costs " .. DarkRP.formatMoney(cost) .. ".")
        end
        return
    end

    local rocket = ents.Create(c.projectile)
    if not IsValid(rocket) then return end
    local wep = weapons.GetStored(c.weapon) or {}
    local speed = wep.ShootEntityForce or (110 / 0.0254)
    local dir = ply:GetAimVector()
    -- vehicle models face +Y in their own space: "forward" runs along it
    local m = c.muzzle or {}
    local mc = car:OBBCenter()
    local muzzle = car:LocalToWorld(Vector(mc.x, mc.y + (m.forward or 40), car:OBBMaxs().z + (m.up or -24)))

    rocket:SetPos(muzzle)
    rocket:SetAngles(dir:Angle())
    rocket:SetOwner(car)          -- its flight ignores the car it leaves from...
    rocket.Attacker = ply         -- ...and the driver is credited with what it hits
    rocket.Inflictor = car
    rocket:Spawn()
    if not IsValid(rocket) then return end
    if rocket.StartRocketFlight and wep.RocketGravity then
        rocket:StartRocketFlight(dir, speed, wep.RocketGravity, wep.RocketBoostSpeed or speed, wep.RocketBoostDelay, wep.RocketBoostDuration)
    else
        local phys = rocket:GetPhysicsObject()
        if IsValid(phys) then phys:SetVelocityInstantaneous(dir * speed) end
    end

    if cost > 0 then ply:addMoney(-cost) end   -- paid only once the rocket is actually out
    car.RP1942_Gunner = ply
    car:EmitSound(c.sound or "MCV_Weapon_RPG7.Single", 95)
    car:SetNW2Float("RP1942_APCReady", now + (c.reload or 6))
    car:SetNW2Float("RP1942_APCReload", c.reload or 6)
end

-- A direct hit is dealt in the car's name (the rocket's owner): credit the driver who fired
hook.Add("EntityTakeDamage", "RP1942_APCGunner", function(ent, dmg)
    local a = dmg:GetAttacker()
    if IsValid(a) and a.RP1942_APC and IsValid(a.RP1942_Gunner) then dmg:SetAttacker(a.RP1942_Gunner) end
end)

hook.Add("KeyPress", "RP1942_APCCannon", function(ply, key)
    if key ~= IN_ATTACK or not ply:InVehicle() then return end
    local car = ply:GetVehicle()
    if IsValid(car) and car.RP1942_APC and car:GetDriver() == ply then fireCannon(ply, car) end
end)

-- Tuning where the shot leaves: rp1942_apc_muzzle <forward> <up> (superadmin; until restart)
concommand.Add("rp1942_apc_muzzle", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local m = CFG.apc.cannon.muzzle
    m.forward = tonumber(args[1]) or m.forward
    m.up = tonumber(args[2]) or m.up
    local line = string.format("muzzle     = { forward = %g, up = %g },", m.forward, m.up)
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, line) ply:ChatPrint("APC muzzle: forward " .. m.forward .. ", up " .. m.up .. " (line in console)") else print(line) end
end)

hook.Add("PlayerEnteredVehicle", "RP1942_APCCannon", function(ply, veh)
    if IsValid(veh) and veh.RP1942_APC and CFG.apc.cannon then
        local c = CFG.apc.cannon
        DarkRP.notify(ply, 0, 7, "Left click fires the gun: a Panzerschreck rocket where you look (" .. (c.reload or 6) .. " s to reload"
            .. ((c.shotCost or 0) > 0 and (", " .. DarkRP.formatMoney(c.shotCost) .. " a shot from your own money") or "") .. ").")
    end
end)

-- Only the Wehrmacht Driver drives it
hook.Add("CanPlayerEnterVehicle", "RP1942_APCDriver", function(ply, veh)
    if not (IsValid(veh) and veh.RP1942_APC) then return end
    local job = RPExtraTeams[ply:Team()]
    if job and CFG.apc.drivers[job.command] then return end
    DarkRP.notify(ply, 1, 4, "Only the Wehrmacht Driver may drive the armoured car.")
    return false
end)

-- Nobody picks it up, freezes it or tools it (staff with the remover aside)
local function isAPC(e) return IsValid(e) and e.RP1942_APC end
hook.Add("PhysgunPickup", "RP1942_APC", function(ply, e) if isAPC(e) and not ply:IsSuperAdmin() then return false end end)
hook.Add("CanTool", "RP1942_APC", function(ply, tr) if isAPC(tr.Entity) and not ply:IsSuperAdmin() then return false end end)
hook.Add("canPocket", "RP1942_APC", function(_, e) if isAPC(e) then return false, "That's an armoured car." end end)

--[[---------------------------------------------------------------------------
Buying (the Perks section of the Führer's menu: "perk_buy", arg = perk id)
---------------------------------------------------------------------------]]
local soldiers = function()
    local list = {}
    for _, p in ipairs(player.GetAll()) do if RP1942.isReichSoldier(p) then list[#list + 1] = p end end
    return list
end

local BUY = {
    apc = function(ply)
        if apc() then return false, "The armoured car is already out." end
        local car, why = spawnAPC()
        if not car then return false, why end
        local owner = car.RP1942_Owner
        return true, IsValid(owner) and ("An armoured car is waiting at the APC garage for " .. owner:Nick() .. ", the Wehrmacht Driver.")
            or "An armoured car is waiting at the APC garage. No Wehrmacht Driver is on duty: the next one gets it."
    end,
    kevlar = function(ply)
        local list = soldiers()
        if #list == 0 then return false, "No Reich soldiers are online to issue it to." end
        for _, p in ipairs(list) do
            if p:Alive() then
                p:SetArmor(math.max(p:GetMaxArmor(), 100))
                DarkRP.notify(p, 0, 6, "Kevlar issued by order of the Führer: full armour.")
            end
        end
        return true, "Kevlar issued to " .. #list .. (#list == 1 and " soldier." or " soldiers.")
    end,
    paybonus = function(ply, perk)
        local now = CurTime()
        local untilT = math.max(GetGlobal2Float("RP1942_PayBonusUntil", 0), now) + perk.minutes * 60
        SetGlobal2Float("RP1942_PayBonusUntil", untilT)
        return true, string.format("Soldiers' pay raised by %d%% for %s.", math.Round((perk.mult - 1) * 100), RP1942.perkClock(untilT - now))
    end,
}

local ALERT = {
    apc = "The Führer has funded an armoured car for the Wehrmacht.",
    kevlar = "By order of the Führer, Reich soldiers have been issued kevlar.",
    paybonus = "The Führer has raised Reich soldiers' pay.",
}

local function handler(ply, id)
    local perk, buy = RP1942.getPerk(id), BUY[id]
    if not (perk and buy) then return end
    if RP1942.treasuryFrozen and RP1942.treasuryFrozen() then
        return DarkRP.notify(ply, 1, 6, RP1942.TreasuryFrozenText)
    end
    if RP1942.perkCooldown(id) > 0 then
        return DarkRP.notify(ply, 1, 5, perk.name .. " can be bought again in " .. RP1942.perkClock(RP1942.perkCooldown(id)) .. ".")
    end
    if not RP1942.getTreasury or RP1942.getTreasury() < perk.price then
        return DarkRP.notify(ply, 1, 6, "The treasury can't afford " .. perk.name .. ": it costs " .. DarkRP.formatMoney(perk.price) .. ".")
    end
    -- Check first, pay second: a perk that can't happen right now costs nothing
    local ok, msg = buy(ply, perk)
    if not ok then return DarkRP.notify(ply, 1, 6, msg) end
    if not RP1942.treasuryWithdraw(perk.price, "perk: " .. id .. " by " .. ply:Nick()) then
        -- (only if the treasury changed in the same instant; undo what can be undone)
        if id == "apc" and apc() then apc():Remove() end
        return DarkRP.notify(ply, 1, 6, "The treasury can't afford " .. perk.name .. ".")
    end
    if id ~= "apc" and (perk.cooldown or 0) > 0 then setCooldown(id, perk.cooldown) end
    DarkRP.notify(ply, 0, 6, msg .. " (" .. DarkRP.formatMoney(perk.price) .. " from the treasury)")
    local reich = {}
    for _, p in ipairs(player.GetAll()) do if RP1942.getFaction(p) == "reich" then reich[#reich + 1] = p end end
    if RP1942.alert and #reich > 0 then RP1942.alert(ALERT[id], "clear", reich) end
    ServerLog(string.format("[1942] %s bought the perk %s for %d\n", ply:Nick(), id, perk.price))
end

-- rp1942_menu loads after this module, so its handler table may not exist yet
RP1942.MenuHandlers = RP1942.MenuHandlers or {}
RP1942.MenuHandlers[MENU] = RP1942.MenuHandlers[MENU] or {}
RP1942.MenuHandlers[MENU].perk_buy = handler
