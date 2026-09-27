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

function ENT:Begin()
    local c = self:Config()
    local now = CurTime()
    self:SetStartedAt(now)
    self:SetDoneAt(now + c.time)
    -- When it'll call for stirring: spread across the middle of the ferment,
    -- each call finishing before the next and before the end
    self.callAt = {}
    local slot = (c.time * 0.8) / c.stirs
    for i = 1, c.stirs do
        local from = c.time * 0.1 + (i - 1) * slot
        self.callAt[i] = now + from + math.Rand(0, math.max(slot - c.stirWindow - 2, 0))
    end
    self:EmitSound("ambient/water/water_splash1.wav", 65)
end

function ENT:Think()
    local now = CurTime()
    if self:IsFermenting() then
        local c = self:Config()
        -- A call for stirring
        local nextCall = self.callAt and self.callAt[self:GetCalls() + 1]
        if nextCall and now >= nextCall and not self:NeedsStir() then
            self:SetCalls(self:GetCalls() + 1)
            self:SetStirBy(now + c.stirWindow)
            self:EmitSound("ambient/water/drip" .. math.random(1, 4) .. ".wav", 70)
        end
        -- Done
        if now >= self:GetDoneAt() then
            self:SetDoneAt(0)
            self:SetStirBy(0)
            self:SetQuality(self:Vintage(self:GetStirs()))
            self:EmitSound("ambient/water/water_pour1.wav", 70)
        end
    end
    self:NextThink(now + 0.25)
    return true
end

-- Buttons on the panel (rp1942_production: look + E)
function ENT:OnPanelPress(ply, id)
    if id == "start" then
        if self:IsFermenting() or self:IsDone() then return end
        self:Begin()

    elseif id == "stir" then
        if not self:NeedsStir() then return end
        self:SetStirBy(0)
        self:SetStirs(self:GetStirs() + 1)
        self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 65)

    elseif id == "bottle" then
        if not self:IsDone() or self.bottled then return end
        self.bottled = true
        local c, q = self:Config(), self:GetQuality()
        local top = self:LocalToWorld(Vector(self:OBBCenter().x, self:OBBCenter().y, self:OBBMaxs().z + 8))
        local _, dropped = RP1942.giveGoods(ply, c.good, q, c.bottles, top)
        local what = c.bottles .. " bottles of " .. RP1942.qualityName(q) .. " wine"
        if dropped == 0 then
            DarkRP.notify(ply, 0, 4, "Bottled " .. what .. " into your pocket.")
        else
            DarkRP.notify(ply, 0, 5, "Bottled " .. what .. ". Your pocket is full: " .. dropped .. " left where the barrel stood.")
        end
        self:EmitSound("physics/glass/glass_bottle_impact_hard1.wav", 65)
        self:Remove()   -- the barrel is used up
    end
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() then
        DarkRP.notify(ply, 0, 3, "Look at a button on the barrel's panel and press E.")
    end
end
