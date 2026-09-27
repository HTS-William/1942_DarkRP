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
    if IsValid(phys) then phys:Wake() end
end

-- A sack of flour pushed in (from rp1942_flour)
function ENT:AddFlour(flour)
    if self:GetFlour() >= self:Config().queue then return end   -- full: the sack bounces off
    flour.RP1942_Used = true
    flour:Remove()
    self:SetFlour(self:GetFlour() + 1)
    self:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav", 65)
    self:TryStart()
end

-- Start the next sack if the oven is free and the tray is empty
function ENT:TryStart()
    if self:GetOff() or self:IsBaking() or self:GetReady() > 0 or self:GetFlour() <= 0 then return end
    local c = self:Config()
    local now = CurTime()
    self:SetFlour(self:GetFlour() - 1)
    self:SetBakeStart(now)
    self:SetDoneAt(now + c.bakeTime)
    self:SetHeatBase(c.heat.start)
    self:SetHeatTime(now)
    self:SetGreen(0)
    self.lastTick = now

    self:EmitSound("ambient/fire/mtov_flame2.wav", 65)
    self:FireSound(true)
end

function ENT:FireSound(on)
    if self.fire then self.fire:Stop() self.fire = nil end
    if on then
        self.fire = CreateSound(self, "ambient/fire/fire_small_loop1.wav")
        self.fire:SetSoundLevel(55)
        self.fire:PlayEx(0.4, 100)
    end
end

-- The POWER lever: off pauses the bake and the fire, on carries on
function ENT:SetPower(on)
    if not RP1942.setMachinePower(self, on, { "DoneAt", "BakeStart", "HeatTime" }) then return end
    self.lastTick = CurTime()
    if on then
        self:EmitSound("buttons/lever1.wav", 65)
        if self:IsBaking() then self:FireSound(true) end
        self:TryStart()
    else
        self:EmitSound("buttons/lever4.wav", 65)
        self:FireSound(false)
    end
end

function ENT:Think()
    local now = CurTime()
    if self:IsBaking() and not self:GetOff() then
        local dt = now - (self.lastTick or now)
        self.lastTick = now
        if self:HeatZone() == "right" then self:SetGreen(self:GetGreen() + dt) end

        if now >= self:GetDoneAt() then
            local c = self:Config()
            local loaves = self:Grade(self:GetGreen() / c.bakeTime)
            self:SetDoneAt(0)
            self:SetReady(loaves)
            self:SetReadyQuality(loaves)
            self:FireSound(false)
            self:EmitSound("buttons/bell1.wav", 70, 110)
        end
    end
    self:NextThink(now + 0.25)
    return true
end

-- Buttons on the panel (rp1942_production: look + E)
function ENT:OnPanelPress(ply, id)
    if id == "power" then
        self:SetPower(self:GetOff())

    elseif id == "stoke" then
        if not self:IsBaking() or self:GetOff() then return end
        local now = CurTime()
        self:SetHeatBase(math.min(100, self:Heat() + self:Config().heat.stoke))
        self:SetHeatTime(now)
        self:EmitSound("ambient/fire/ignite.wav", 60, math.random(95, 110))

    elseif id == "collect" then
        local loaves = self:GetReady()
        if loaves <= 0 then return end
        local q = self:GetReadyQuality()
        self:SetReady(0)
        local top = self:LocalToWorld(Vector(self:OBBCenter().x, self:OBBCenter().y, self:OBBMaxs().z + 8))
        local pocketed, dropped = RP1942.giveGoods(ply, self:Config().good, q, loaves, top)
        local what = loaves .. (loaves == 1 and " loaf" or " loaves") .. " of " .. RP1942.qualityName(q) .. " bread"
        if dropped == 0 then
            DarkRP.notify(ply, 0, 4, "Collected " .. what .. " into your pocket.")
        else
            DarkRP.notify(ply, 0, 5, "Collected " .. what .. ". Your pocket is full: " .. dropped .. " left on top of the oven.")
        end
        self:EmitSound("physics/cardboard/cardboard_box_impact_soft5.wav", 60)
        self:TryStart()   -- the next sack goes in
    end
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() then
        DarkRP.notify(ply, 0, 3, "Look at a button on the oven's panel and press E. Push sacks of flour into the oven to bake.")
    end
end

function ENT:OnRemove()
    self:FireSound(false)
end
