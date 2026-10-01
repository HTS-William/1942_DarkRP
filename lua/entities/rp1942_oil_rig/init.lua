AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local c = self:Config()
    self:SetModel(c.model)
    -- The model's own physics, or a box round it if it has none
    if not self:PhysicsInit(SOLID_VPHYSICS) or not IsValid(self:GetPhysicsObject()) then
        self:PhysicsInitBox(self:OBBMins(), self:OBBMaxs())
    end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetDoneAt(0)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    -- Starts pumping once it's been set on its site (RP1942.buildOilRig)
end

-- Where it belongs; it's put back there if anything ever moves it
function ENT:Anchor(pos, ang)
    self.anchorPos, self.anchorAng = pos, ang
    self:SetPos(pos)
    self:SetAngles(ang)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) phys:Sleep() end
end

--[[---------------------------------------------------------------------------
Sounds: the pump engine while pumping, a steam hiss only while the valve is
open. Both stop when it's closed / done / removed.
---------------------------------------------------------------------------]]
function ENT:Engine(on)
    if self.engine then self.engine:Stop() self.engine = nil end
    if on then
        self.engine = CreateSound(self, "ambient/machines/turbine_loop_1.wav")
        self.engine:SetSoundLevel(60)
        self.engine:PlayEx(0.35, 80)
    end
end

function ENT:Alarm(on)
    if self.alarm then self.alarm:Stop() self.alarm = nil end
    if on then
        self.alarm = CreateSound(self, "ambient/alarms/alarm_citizen_loop1.wav")
        self.alarm:SetSoundLevel(90)
        self.alarm:PlayEx(0.8, 100)
    end
end

-- Left in the red too long: it blows up, and it's gone
function ENT:Blowout()
    if self.blownUp then return end
    self.blownUp = true
    local b = self:Config().blowout
    local pos = self:WorldSpaceCenter()
    local owner = self.Getowning_ent and self:Getowning_ent()
    self:Alarm(false)
    RP1942.explode(pos, { damage = b.damage, radius = b.radius, inflictor = self })
    -- A second, smaller blast from the top a moment later
    local top = self:LocalToWorld(Vector(self:OBBCenter().x, self:OBBCenter().y, self:OBBMaxs().z))
    timer.Simple(0.35, function() RP1942.explode(top, { damage = 0, shake = false }) end)
    if IsValid(owner) then
        DarkRP.notify(owner, 1, 8, "Your oil rig was left in the red too long and exploded.")
    end
    ServerLog(string.format("[1942] An oil rig (owner: %s) exploded at %s\n", IsValid(owner) and owner:Nick() or "none", tostring(pos)))
    SafeRemoveEntity(self)
end

function ENT:Steam(on)
    if self.steam then self.steam:Stop() self.steam = nil end
    if on then
        self.steam = CreateSound(self, "ambient/gas/steam_loop1.wav")
        self.steam:SetSoundLevel(65)
        self.steam:PlayEx(0.45, 100)
    end
end

-- The pressure's speed from now on: up with the valve shut, down with it
-- open, each wandering a little (self.speed, re-rolled every so often)
function ENT:Rebase()
    local c = self:Config().pressure
    local now = CurTime()
    self:SetPressBase(self:Pressure())
    self:SetPressTime(now)
    local k = self.speed or 1
    self:SetPressRate(self:GetValveOpen() and -c.fall * k or c.rise * k)
end

function ENT:StartPump()
    if self:GetOff() or self:IsPumping() or self:GetReady() > 0 then return end
    local c = self:Config()
    local now = CurTime()
    self:SetPumpStart(now)
    self:SetDoneAt(now + c.pumpTime)
    self:SetValveOpen(false)
    self:SetPressBase(c.pressure.start)
    self:SetPressTime(now)
    self:SetGreen(0)
    self.lastTick = now
    self.speed = 1
    self.nextSpeed = now + math.Rand(c.pressure.changeEvery[1], c.pressure.changeEvery[2])
    self:Rebase()
    self:Engine(true)
    self:Steam(false)
end

-- The POWER lever: off pauses everything, on carries on (or starts a tank)
function ENT:SetPower(on)
    local d = CurTime() - self:GetPausedAt()
    if not RP1942.setMachinePower(self, on, { "DoneAt", "PumpStart", "PressTime", "RedSince" }) then return end
    self.lastTick = CurTime()
    if on then
        if self.nextSpeed then self.nextSpeed = self.nextSpeed + d end
        self:SetStalled(false)
        self:EmitSound("buttons/lever1.wav", 65)
        if self:IsPumping() then
            self:Engine(true)
            self:Steam(self:GetValveOpen())
        else
            self:StartPump()
        end
        if self:Alarming() then self:Alarm(true) end
    else
        self:EmitSound("buttons/lever4.wav", 65)
        self:Engine(false)
        self:Steam(false)
        self:Alarm(false)
    end
end

-- The pressure hit 0 with the valve open: the pump stalls and switches off.
-- The valve shuts, so once it's switched back on the pressure builds from 0.
function ENT:Stall()
    self:SetValveOpen(false)
    self:Rebase()
    self:SetPower(false)
    self:SetStalled(true)
    self:EmitSound("ambient/machines/thumper_shutdown1.wav", 75, 90)
    local owner = self.Getowning_ent and self:Getowning_ent()
    if IsValid(owner) then
        DarkRP.notify(owner, 1, 6, "Your oil rig lost all its pressure and stalled. Switch it back on at its panel.")
    end
end

function ENT:Think()
    local now = CurTime()

    -- Bolted down: back to its site if something shifted it
    if self.anchorPos and (self:GetPos():DistToSqr(self.anchorPos) > 1 or math.abs(math.AngleDifference(self:GetAngles().y, self.anchorAng.y)) > 1) then
        self:Anchor(self.anchorPos, self.anchorAng)
    end

    if self:IsPumping() and not self:GetOff() then
        local c = self:Config()
        local dt = now - (self.lastTick or now)
        self.lastTick = now
        if self:PressureZone() == "right" then self:SetGreen(self:GetGreen() + dt) end

        if now >= (self.nextSpeed or 0) then
            local v = c.pressure.vary or 0
            self.speed = math.Rand(1 - v, 1 + v)
            self.nextSpeed = now + math.Rand(c.pressure.changeEvery[1], c.pressure.changeEvery[2])
            self:Rebase()
        end

        -- In the red: count, then the alarm, then the blowout
        local b = c.blowout
        if self:PressureZone() == "high" then
            if self:GetRedSince() <= 0 then self:SetRedSince(now) end
            local red = self:RedTime()
            if red >= b.explodeAfter then
                self:Blowout()
                return
            elseif red >= b.warnAfter and not self.alarm then
                self:Alarm(true)
                local owner = self.Getowning_ent and self:Getowning_ent()
                if IsValid(owner) then
                    DarkRP.notify(owner, 1, 8, "DANGER: your oil rig's pressure is in the red! Open the valve, or it will explode.")
                end
            end
        elseif self:GetRedSince() > 0 then
            self:SetRedSince(0)
            self:Alarm(false)
        end

        if self:GetValveOpen() and self:Pressure() <= 0 then
            self:Stall()
            self:NextThink(now + 0.25)
            return true
        end

        if now >= self:GetDoneAt() then
            local cans = self:Grade(self:GetGreen() / c.pumpTime)
            self:SetDoneAt(0)
            self:SetValveOpen(false)
            self:SetReady(cans)
            self:SetReadyQuality(cans)
            self:SetRedSince(0)
            self:Alarm(false)
            self:Engine(false)
            self:Steam(false)
            self:EmitSound("ambient/machines/thumper_shutdown1.wav", 70)
        end
    end
    self:NextThink(now + 0.25)
    return true
end

-- Buttons on the panel (rp1942_production: look + E)
function ENT:OnPanelPress(ply, id)
    local c = self:Config()
    if id == "power" then
        self:SetPower(self:GetOff())

    elseif id == "wheel" then
        if not self:IsPumping() or self:GetOff() or self:WheelTurning() then return end
        self:SetValveOpen(not self:GetValveOpen())
        self:SetWheelTurnedAt(CurTime())
        self:Rebase()
        self:Steam(self:GetValveOpen())
        self:EmitSound("buttons/lever7.wav", 60, self:GetValveOpen() and 90 or 110)

    elseif id == "fill" then
        local cans = self:GetReady()
        if cans <= 0 then return end
        local q = self:GetReadyQuality()
        self:SetReady(0)
        local top = self:LocalToWorld(Vector(self:OBBCenter().x, self:OBBCenter().y, self:OBBMaxs().z + 8))
        local pocketed, dropped = RP1942.giveGoods(ply, c.good, q, cans, top)
        local what = cans .. (cans == 1 and " barrel" or " barrels") .. " of " .. RP1942.qualityName(q) .. " crude oil"
        if dropped == 0 then
            DarkRP.notify(ply, 0, 4, "Filled " .. what .. " into your pocket.")
        else
            DarkRP.notify(ply, 0, 5, "Filled " .. what .. ". Your pocket is full: " .. dropped .. " left on top of the rig.")
        end
        self:EmitSound("ambient/water/water_splash2.wav", 60)
        self:StartPump()
    end
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() then
        DarkRP.notify(ply, 0, 3, "Look at a button on the rig's panel and press E.")
    end
end

function ENT:OnRemove()
    self:Engine(false)
    self:Steam(false)
    self:Alarm(false)
    self:StopSound("ambient/gas/steam_loop1.wav")
    if RP1942.updateOilSites then timer.Simple(0, RP1942.updateOilSites) end   -- its site is free again
end
