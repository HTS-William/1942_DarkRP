--[[---------------------------------------------------------------------------
42Bros - our changes to Military Conflict: Vietnam, kept separate (shared)

The MCV weapons come straight from the Workshop (Part 1 - Eastern and
Part 2 - Western), untouched, so they can update without wiping our
changes. Everything 42Bros changes about them lives here and is applied
on top while the Workshop's weapons and entities are loading:

    WEAPONS     per weapon: our ammo types (rp1942_core/sh_ammo.lua),
                names, door breaching, the MP40's rate of fire...
    ENTITIES    the crossbow bolt's ammo, and which explosives blow doors
                and free frozen props
    door breaching   a DestroyDoor weapon's shot (shotguns, the PTRD) that
                hits a door close enough blows the lock and swings it
                open, away from the shooter
    explosives  DestroyDoors / UnfreezeProps explosives take doors off
                their hinges (back after 25 s) and free frozen props
    fire        rockets light fires at their own chance and burst into
                flame; the flamethrower can set the ground alight
                (rp1942_fire)

To change a weapon, edit its line in WEAPONS: any SWEP field works
("Primary.Ammo" for the ammo type). Nothing here edits a Workshop file, so
after a Workshop update the only thing to check is that the functions
wrapped below still exist; if one is renamed, that one change stops
(a line in the console says which) and nothing breaks.

Our own extra weapon, the belt-fed MG 42 (lua/weapons/mcv_mg42b.lua), is a
separate file on the Workshop base.
---------------------------------------------------------------------------]]
AddCSLuaFile()

RP1942 = RP1942 or {}
RP1942.MCVPatches = RP1942.MCVPatches or {}
local P = RP1942.MCVPatches

local function warn(msg)
    MsgC(Color(230, 170, 60), "[42Bros] MCV patch: ", color_white, msg, "\n")
end

-- Sets "Primary.Ammo" style keys inside nested tables
local function setField(tbl, key, value)
    local parts = string.Explode(".", key)
    for i = 1, #parts - 1 do
        tbl[parts[i]] = tbl[parts[i]] or {}
        tbl = tbl[parts[i]]
    end
    tbl[parts[#parts]] = value
end

--[[---------------------------------------------------------------------------
Weapons: what 42Bros changes on each one
---------------------------------------------------------------------------]]
-- (HasRifleGrenade = false: the Workshop added rifle grenade launchers to the
-- G43, M38 and M91; the server has never had them. Remove it to allow them.)
P.WEAPONS = {
    mcv_avt40 = { ["Primary.Ammo"] = "762soviet" },
    mcv_babybrowning = { ["Primary.Ammo"] = "25acp" },
    mcv_bazooka = { ["Primary.Ammo"] = "bazookarocket" },
    mcv_blackhawk = { ["Primary.Ammo"] = "38special" },
    mcv_bren = { ["Primary.Ammo"] = "303brit" },
    mcv_browning_auto = { DestroyDoor = 1 },
    mcv_c96 = { ["Primary.Ammo"] = "763mauser" },
    mcv_c96_stock = { ["Primary.Ammo"] = "763mauser" },
    mcv_crossbow = { ["Primary.Ammo"] = "mcv_crossbowbolt" },
    mcv_dp28 = { ["Primary.Ammo"] = "762soviet" },
    mcv_fm24 = { ["Primary.Ammo"] = "75french" },
    mcv_fusil_robust = { Country = "Unknown", DestroyDoor = 1, PrintName = "Double Barrel Shotgun" },
    mcv_fusil_robust_short = { Country = "Unknown", DestroyDoor = 1, PrintName = "Sawed-Off Double Barrel Shotgun" },
    mcv_g43 = { HasRifleGrenade = false, ["Primary.Ammo"] = "792x57mm" },
    mcv_hipower = { ["Primary.Ammo"] = "9mmluger" },
    mcv_kar98 = { ["Primary.Ammo"] = "792x57mm" },
    mcv_kar98_s = { ["Primary.Ammo"] = "792x57mm" },
    mcv_lebel = { ["Primary.Ammo"] = "8mmfrench" },
    mcv_luger = { ["Primary.Ammo"] = "9mmluger" },
    mcv_m1895 = { ["Primary.Ammo"] = "762nagantr" },
    mcv_m1897 = { DestroyDoor = 1 },
    mcv_m1911a1 = { ["Primary.Ammo"] = "45acp" },
    mcv_m1917 = { ["Primary.Ammo"] = "45acp" },
    mcv_m1918 = { ["Primary.Ammo"] = "30cal" },
    mcv_m1918_bar = { ["Primary.Ammo"] = "30cal" },
    mcv_m1919 = { ["Primary.Ammo"] = "30cal" },
    mcv_m1c = { ["Primary.Ammo"] = "30carbine" },
    mcv_m1c_sog = { ["Primary.Ammo"] = "30carbine", PrintName = "M1A1 Carbine Sawn-Off" },
    mcv_m1d = { ["Primary.Ammo"] = "30cal" },
    mcv_m1g = { ["Primary.Ammo"] = "30cal" },
    mcv_m2c = { ["Primary.Ammo"] = "30carbine" },
    mcv_m2c_sog = { ["Primary.Ammo"] = "30carbine", PrintName = "M2 Carbine Sawn Off" },
    mcv_m37 = { DestroyDoor = 1 },
    mcv_m38 = { HasRifleGrenade = false, ["Primary.Ammo"] = "762soviet" },
    mcv_m38_s = { ["Primary.Ammo"] = "762soviet" },
    mcv_m3a1 = { ["Primary.Ammo"] = "45acp" },
    mcv_m3a1_sog = { ["Primary.Ammo"] = "45acp", PrintName = "M3A1 Grease Gun Suppressed" },
    mcv_m45 = { ["Primary.Ammo"] = "9mmluger" },
    mcv_m50r = { ["Primary.Ammo"] = "45acp" },
    mcv_m55r = { ["Primary.Ammo"] = "45acp" },
    mcv_m91 = { HasRifleGrenade = false, ["Primary.Ammo"] = "762soviet" },
    mcv_m9a1 = { PrintName = "M2 Flamethrower" },
    mcv_mas36 = { ["Primary.Ammo"] = "75french" },
    mcv_mas36_cr39 = { ["Primary.Ammo"] = "75french" },
    mcv_mas38 = { ["Primary.Ammo"] = "765french" },
    mcv_mg43 = { ["Primary.Ammo"] = "792x57mm" },
    mcv_mg43b = { ["Primary.Ammo"] = "792x57mm" },
    mcv_mg43d = { ["Primary.Ammo"] = "792x57mm" },
    mcv_mle1935 = { ["Primary.Ammo"] = "765french" },
    mcv_mp40 = { FireRate = 560, ["Primary.Ammo"] = "9mmluger" },
    mcv_owen = { ["Primary.Ammo"] = "9mmluger" },
    mcv_p38 = { ["Primary.Ammo"] = "9mmluger" },
    mcv_panzerschreck = { ["Primary.Ammo"] = "panzerschreckrocket" },
    mcv_ppk = { ["Primary.Ammo"] = "380acp" },
    mcv_pps43 = { ["Primary.Ammo"] = "762tokarev" },
    mcv_ppsh41 = { ["Primary.Ammo"] = "762tokarev" },
    mcv_ppsh41_drum = { ["Primary.Ammo"] = "762tokarev" },
    mcv_ppsh41dd = { ["Primary.Ammo"] = "762tokarev" },
    mcv_ptrd = { DestroyDoor = 1, DestroyDoorRange = 4000, ["Primary.Ammo"] = "145x114" },
    mcv_ptrd_sniper = { DestroyDoor = 1, DestroyDoorRange = 4000 },
    mcv_rp46 = { ["Primary.Ammo"] = "762soviet" },
    mcv_rpd = { ["Primary.Ammo"] = "762x39" },
    mcv_rpdb = { ["Primary.Ammo"] = "762x39" },
    mcv_ruby = { ["Primary.Ammo"] = "32acp" },
    mcv_shovel_vc = { Spawnable = false },
    mcv_springfield = { ["Primary.Ammo"] = "30cal", PrintName = "M1903 Springfield" },
    mcv_springfield_s = { ["Primary.Ammo"] = "30cal", PrintName = "M1903A4 Springfield" },
    mcv_sten = { ["Primary.Ammo"] = "9mmluger" },
    mcv_sten_sog = { ["Primary.Ammo"] = "9mmluger", PrintName = "Sten Mk2 Suppressed" },
    mcv_stg44 = { ["Primary.Ammo"] = "792x33mmkurz" },
    mcv_stg44_s = { ["Primary.Ammo"] = "792x33mmkurz" },
    mcv_svt40 = { ["Primary.Ammo"] = "762soviet" },
    mcv_svt40_s = { ["Primary.Ammo"] = "762soviet" },
    mcv_swm10 = { ["Primary.Ammo"] = "38special" },
    mcv_thompson = { ["Primary.Ammo"] = "45acp" },
    mcv_thompson_m1928 = { ["Primary.Ammo"] = "45acp" },
    mcv_thompson_sog = { ["Primary.Ammo"] = "45acp", PrintName = "M1A1 Thompson Stockless" },
    mcv_tt33 = { ["Primary.Ammo"] = "762tokarev" },
    mcv_type14 = { ["Primary.Ammo"] = "8mmnambu" },
    mcv_vccarbine = { ["Primary.Ammo"] = "30carbine" },
    mcv_vcpistol = { ["Primary.Ammo"] = "45acp" },
    mcv_vcpistol2 = { ["Primary.Ammo"] = "45acp" },
    mcv_vcshotgun = { DestroyDoor = 1 },
    mcv_vcsmg = { ["Primary.Ammo"] = "9mmluger" },
    mcv_vz24 = { ["Primary.Ammo"] = "792x57mm" },
    mcv_welrod = { ["Primary.Ammo"] = "32acp" },
}

--[[---------------------------------------------------------------------------
Entities
DestroyDoors: prop doors within DestroyDoorsRadius come off their hinges,
brush doors unlock. UnfreezeProps: frozen props within UnfreezePropsRadius
are freed. Both only through open space (walls block them).
---------------------------------------------------------------------------]]
local BLAST = { DestroyDoors = 1, DestroyDoorsRadius = 100, UnfreezeProps = 1, UnfreezePropsRadius = 250 }
P.ENTITIES = {
    mcv_proj_bolt          = { PickupAmmo = "mcv_crossbowbolt" },   -- was HL2 "XBowBolt"
    mcv_placed_dynamite    = BLAST,
    mcv_proj_bazooka       = BLAST,
    mcv_proj_panzerschreck = BLAST,
    mcv_proj_lunge_mine    = BLAST,
}

-- Rockets: their own fire chance (rp1942_fire: rocketBlastChance) and a burst of flame
P.ROCKETS = { mcv_proj_bazooka = true, mcv_proj_panzerschreck = true }

--[[---------------------------------------------------------------------------
Doors and props
---------------------------------------------------------------------------]]
-- A breaching shot: the lock blows and the door swings open, away from the shooter
function P.breachDoor(door, shooter)
    if not IsValid(door) then return end
    local smoke = EffectData()
    smoke:SetOrigin(door:GetPos())
    util.Effect("effect_smokedoor", smoke)
    door:EmitSound("physics/wood/wood_crate_break" .. math.random(1, 5) .. ".wav", 80)
    door:Fire("unlock", "", 0)
    if IsValid(shooter) then door:Fire("openawayfrom", "!activator", 0.01, shooter) end
    door:Fire("open", "", 0.02)
end

-- An explosion: the door is swapped for a flying physics prop of itself and the
-- real one (hidden, not solid) comes back after 25 seconds
function P.blastDoor(door, sourcePos)
    if not IsValid(door) then return end
    door:Fire("open", "", 0.001)
    door:Fire("unlock", "", 0.001)
    local pos, ang, model, skin = door:GetPos(), door:GetAngles(), door:GetModel(), door:GetSkin()
    local smoke = EffectData()
    smoke:SetOrigin(pos)
    util.Effect("effect_smokedoor", smoke)
    door:SetNotSolid(true)
    door:SetNoDraw(true)

    local norm = (pos - (sourcePos or pos)):GetNormalized()
    if norm:LengthSqr() == 0 then norm = VectorRand() end
    local push = 10000 * norm
    local fake = ents.Create("prop_physics")
    if IsValid(fake) then
        fake:SetPos(pos)
        fake:SetAngles(ang)
        fake:SetModel(model)
        if skin then fake:SetSkin(skin) end
        fake:Spawn()
        timer.Simple(0.01, function()
            if not IsValid(fake) then return end
            fake:SetVelocity(push)
            local phys = fake:GetPhysicsObject()
            if IsValid(phys) then phys:ApplyForceCenter(push) end
        end)
    end
    timer.Simple(25, function()
        if IsValid(door) then
            door:SetNotSolid(false)
            door:SetNoDraw(false)
        end
        if IsValid(fake) then fake:Remove() end
    end)
end

-- Nothing of the world's (walls, floors) between pos and ent
local function clearLine(pos, ent)
    local tr = util.TraceLine({ start = pos, endpos = ent:WorldSpaceCenter(), mask = MASK_SOLID_BRUSHONLY, filter = ent })
    return not tr.Hit or tr.Fraction >= 0.99
end

local BRUSH_DOORS = { func_door = true, func_door_rotating = true }

-- What an explosive with DestroyDoors / UnfreezeProps does around it
function P.blastWorld(ent)
    local pos = ent.GetImpactPos and ent:GetImpactPos() or ent:GetPos()
    if ent.UnfreezeProps and ent.UnfreezeProps ~= 0 then
        local radius = ent.UnfreezePropsRadius or ent.ExplosionRadius or 0
        for _, e in ipairs(radius > 0 and ents.FindInSphere(pos, radius) or {}) do
            if IsValid(e) and string.StartWith(e:GetClass(), "prop_physics") then
                local phys = e:GetPhysicsObject()
                if IsValid(phys) and not phys:IsMotionEnabled() and clearLine(pos, e) then
                    phys:EnableMotion(true)
                    phys:Wake()
                end
            end
        end
    end
    if ent.DestroyDoors and ent.DestroyDoors ~= 0 then
        local radius = ent.DestroyDoorsRadius or ent.ExplosionRadius or 0
        for _, e in ipairs(radius > 0 and ents.FindInSphere(pos, radius) or {}) do
            if IsValid(e) then
                local class = e:GetClass()
                if class == "prop_door_rotating" and clearLine(pos, e) then
                    P.blastDoor(e, pos)
                elseif BRUSH_DOORS[class] and clearLine(pos, e) then
                    e:Fire("unlock", "", 0)
                end
            end
        end
    end
end

--[[---------------------------------------------------------------------------
Applying it while the Workshop's weapons and entities load
---------------------------------------------------------------------------]]
-- Wraps tbl[name]; says so in the console if the Workshop no longer has it
local function wrap(tbl, class, name, make)
    local orig = tbl[name]
    if not isfunction(orig) then
        warn(class .. ":" .. name .. "() isn't in this version of the Workshop pack; that 42Bros change is off.")
        return
    end
    if tbl["RP1942_Wrapped_" .. name] then return end   -- (a Lua refresh registers again)
    tbl["RP1942_Wrapped_" .. name] = true
    tbl[name] = make(orig)
end

hook.Add("PreRegisterSWEP", "RP1942_MCVPatches", function(swep, class)
    if not (istable(swep) and isstring(class)) then return end
    local changes = P.WEAPONS[class]
    if changes then
        for key, value in pairs(changes) do setField(swep, key, value) end
    end

    -- The flamethrower: the ground where the stream lands can catch (rp1942_fire)
    if class == "mcv_flamethrower" then
        wrap(swep, class, "FlameTick", function(orig)
            return function(self, ...)
                local r = orig(self, ...)
                if SERVER and RP1942.startFire and RP1942.fireSetting then
                    local owner = self:GetOwner()
                    if IsValid(owner) and math.random() < (RP1942.fireSetting("flamethrowerChance") or 0) then
                        local src, dir = owner:GetShootPos(), self:GetAimVector()
                        local tr = util.TraceLine({ start = src, endpos = src + dir * (self.FlameRange or 420), filter = owner, mask = MASK_SHOT })
                        if tr.HitWorld then
                            RP1942.startFire(tr.HitPos, { spots = 1, attacker = owner, inflictor = self })
                        end
                    end
                end
                return r
            end
        end)
    end
end)

hook.Add("PreRegisterSENT", "RP1942_MCVPatches", function(ent, class)
    if not (istable(ent) and isstring(class)) then return end
    local changes = P.ENTITIES[class]
    if changes then
        for key, value in pairs(changes) do setField(ent, key, value) end
    end

    -- Every MCV explosive goes through the base's PreDetonate once: doors and props first
    if class == "mcv_proj_base" then
        wrap(ent, class, "PreDetonate", function(orig)
            return function(self, ...)
                if SERVER and not self.Detonated and (self.DestroyDoors or self.UnfreezeProps) then
                    local ok, err = pcall(P.blastWorld, self)
                    if not ok then warn("blast: " .. tostring(err)) end
                end
                return orig(self, ...)
            end
        end)
    end

    if P.ROCKETS[class] then
        wrap(ent, class, "Detonate", function(orig)
            return function(self, ...)
                if SERVER then
                    -- this rocket's blast lights fires at the rocket chance (rp1942_fire)
                    if RP1942.Fire then RP1942.Fire.nextBlastChance = "rocketBlastChance" end
                    -- and bursts into flame like a molotov (the burst, not the pool)
                    if self:WaterLevel() == 0 and MCV and MCV.SurfaceAngle and self.GetImpactPos then
                        ParticleEffect("Molotov_Explosion", self:GetImpactPos(), MCV.SurfaceAngle(self:GetImpactNormal()))
                    end
                end
                return orig(self, ...)
            end
        end)
    end
end)

--[[---------------------------------------------------------------------------
Door breaching: every MCV shot ends in the engine's FireBullets, so a
DestroyDoor weapon's bullets get one more check when they hit something
(once per shot, not once per pellet)
---------------------------------------------------------------------------]]
if SERVER then
    hook.Add("EntityFireBullets", "RP1942_MCVBreach", function(shooter, data)
        local wep = data.Inflictor
        if not (IsValid(wep) and wep:IsWeapon()) then
            wep = IsValid(shooter) and shooter.GetActiveWeapon and shooter:GetActiveWeapon() or nil
        end
        if not IsValid(wep) or (wep.DestroyDoor or 0) == 0 then return end

        local range = wep.DestroyDoorRange or 200   -- shotguns: about 4 m
        local callback = data.Callback
        data.Callback = function(attacker, tr, dmginfo)
            local result
            if callback then result = callback(attacker, tr, dmginfo) end
            local door = tr.Entity
            if IsValid(door) and door:GetClass() == "prop_door_rotating" and (door.RP1942_BreachedAt or 0) ~= CurTime() then
                local from = (IsValid(shooter) and shooter.GetShootPos) and shooter:GetShootPos() or tr.StartPos
                if from:Distance(tr.HitPos) <= range then
                    door.RP1942_BreachedAt = CurTime()
                    P.breachDoor(door, shooter)
                end
            end
            return result
        end
        return true   -- (use the changed callback)
    end)
end
