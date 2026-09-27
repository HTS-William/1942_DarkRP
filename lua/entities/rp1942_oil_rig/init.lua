AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(self:Config().model)
    self:PhysicsInit(SOLID_VPHYSICS)
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

-- A new direction and speed for the pressure, starting from where it is now
function ENT:NewDrift()
    local c = self:Config().pressure
    local now = CurTime()
    local p = self:Pressure()
    local sign = math.random() < 0.5 and -1 or 1
    -- Pinned against an end: head back the other way
    if p >= 99 then sign = -1 elseif p <= 1 then sign = 1 end
    self:SetPressBase(p)
    self:SetPressTime(now)
    self:SetPressRate(sign * c.drift * math.Rand(0.5, 1))
    self.nextDrift = now + math.Rand(c.changeEvery[1], c.changeEvery[2])
end

function ENT:StartPump()
    if self:IsPumping() or self:GetReady() > 0 then return end
    local c = self:Config()
    local now = CurTime()
    self:SetPumpStart(now)
    self:SetDoneAt(now + c.pumpTime)
    self:SetPressBase(c.pressure.start)
    self:SetPressTime(now)
    self:SetPressRate(0)
    self:SetGreen(0)
    self.lastTick = now
    self:NewDrift()

    if self.engine then self.engine:Stop() end
    self.engine = CreateSound(self, "ambient/machines/turbine_loop_1.wav")
    self.engine:SetSoundLevel(60)
    self.engine:PlayEx(0.35, 80)
end

function ENT:Think()
    local now = CurTime()

    -- Bolted down: back to its site if something shifted it
    if self.anchorPos and (self:GetPos():DistToSqr(self.anchorPos) > 1 or math.abs(math.AngleDifference(self:GetAngles().y, self.anchorAng.y)) > 1) then
        self:Anchor(self.anchorPos, self.anchorAng)
    end

    if self:IsPumping() then
        local dt = now - (self.lastTick or now)
        self.lastTick = now
        if self:PressureZone() == "right" then self:SetGreen(self:GetGreen() + dt) end
        if now >= (self.nextDrift or 0) then self:NewDrift() end

        if now >= self:GetDoneAt() then
            local cans = self:Grade(self:GetGreen() / self:Config().pumpTime)
            self:SetDoneAt(0)
            self:SetReady(cans)
            self:SetReadyQuality(cans)
            if self.engine then self.engine:Stop() self.engine = nil end
            self:EmitSound("ambient/machines/thumper_shutdown1.wav", 70)
        end
    end
    self:NextThink(now + 0.25)
    return true
end

-- Buttons on the panel (rp1942_production: look + E)
function ENT:OnPanelPress(ply, id)
    local c = self:Config()
    if id == "open" or id == "close" then
        if not self:IsPumping() then return end
        local p = self:Pressure() + (id == "open" and -c.pressure.valve or c.pressure.valve)
        self:SetPressBase(math.Clamp(p, 0, 100))
        self:SetPressTime(CurTime())
        self:EmitSound(id == "open" and "ambient/gas/steam2.wav" or "buttons/lever7.wav", 60, math.random(95, 110))

    elseif id == "fill" then
        local cans = self:GetReady()
        if cans <= 0 then return end
        local q = self:GetReadyQuality()
        self:SetReady(0)
        local top = self:LocalToWorld(Vector(self:OBBCenter().x, self:OBBCenter().y, self:OBBMaxs().z + 8))
        local pocketed, dropped = RP1942.giveGoods(ply, c.good, q, cans, top)
        local what = cans .. (cans == 1 and " canister" or " canisters") .. " of " .. RP1942.qualityName(q) .. " crude oil"
        if dropped == 0 then
            DarkRP.notify(ply, 0, 4, "Filled " .. what .. " into your pocket.")
        else
            DarkRP.notify(ply, 0, 5, "Filled " .. what .. ". Your pocket is full: " .. dropped .. " left on top of the derrick.")
        end
        self:EmitSound("ambient/water/water_splash2.wav", 60)
        self:StartPump()
    end
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() then
        DarkRP.notify(ply, 0, 3, "Look at a button on the derrick's panel and press E.")
    end
end

function ENT:OnRemove()
    if self.engine then self.engine:Stop() end
    if RP1942.updateOilSites then timer.Simple(0, RP1942.updateOilSites) end   -- its site is free again
end
