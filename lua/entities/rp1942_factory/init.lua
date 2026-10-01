AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(self:Config().model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    -- a model without its own collision still gets a solid box, so scrap can be pushed in
    if not IsValid(self:GetPhysicsObject()) then
        self:PhysicsInitBox(self:OBBMins(), self:OBBMaxs())
        self:SetSolid(SOLID_VPHYSICS)
    end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    self:SetScrap(0)
    self:Idle()
end

-- Nothing to work on: waits for scrap
function ENT:Idle()
    self:SetState(self.STATE_IDLE)
    self:SetRunBase(0)
    self:SetDownBase(0)
    self:SetHaltedAt(0)
    self:SetHalts(0)
    self:SetFault("")
    self:SetReadyList("")
    self:Engine(false)
end

-- Idle with scrap in the hopper: take a load and start a run
function ENT:TryStart()
    if self:GetState() ~= self.STATE_IDLE or self:GetScrap() <= 0 then return false end
    self:SetScrap(self:GetScrap() - 1)
    self:StartRun()
    return true
end

-- A load of scrap pushed in (from rp1942_scrap)
function ENT:AddScrap(scrap)
    if self:GetScrap() >= (self:Config().hopper or 4) then return end   -- full: it bounces off
    scrap.RP1942_Used = true
    scrap:Remove()
    self:SetScrap(self:GetScrap() + 1)
    self:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 65)
    self:TryStart()
end

function ENT:StartRun()
    local c = self:Config()
    local now = self:Now()   -- switched off: the new run waits, paused
    self:SetState(self.STATE_RUNNING)
    self:SetRunBase(0)
    self:SetRunTime(now)
    self:SetDownBase(0)
    self:SetHaltedAt(0)
    self:SetHalts(0)
    self:SetFault("")
    self:SetReadyList("")

    -- When it'll halt (seconds of running), spread over the run
    self.haltAt = {}
    local n = math.max(c.halts or 0, 0)
    for i = 1, n do
        local from, to = (i - 1) / n, i / n
        self.haltAt[i] = c.runTime * math.Rand(from + (to - from) * 0.2, from + (to - from) * 0.85)
    end

    self:Engine(not self:GetOff())
end

function ENT:Engine(on)
    if self.engine then self.engine:Stop() self.engine = nil end
    if on then
        self.engine = CreateSound(self, "ambient/machines/turbine_loop_2.wav")
        self.engine:SetSoundLevel(60)
        self.engine:PlayEx(0.35, 110)
    end
end

-- The POWER lever: off pauses the run (and any downtime), on carries on
function ENT:SetPower(on)
    if not RP1942.setMachinePower(self, on, { "RunTime", "HaltedAt" }) then return end
    if on then
        self:EmitSound("buttons/lever1.wav", 65)
        self:Engine(self:GetState() == self.STATE_RUNNING)
    else
        self:EmitSound("buttons/lever4.wav", 65)
        self:Engine(false)
    end
end

function ENT:Halt()
    local faults = RP1942.FactoryFaults
    self:SetRunBase(self:Progress())
    self:SetState(self.STATE_HALTED)
    self:SetHaltedAt(CurTime())
    self:SetHalts(self:GetHalts() + 1)
    self:SetFault(faults[math.random(#faults)].id)
    self:Engine(false)
    self:EmitSound("ambient/alarms/klaxon1.wav", 70, 110)
end

-- Rarity by the run's stars, then a good of that rarity
local function rollGood(stars)
    local odds = RP1942.Production.factory.odds[stars] or RP1942.Production.factory.odds[1]
    local byRarity = {}
    for id, g in pairs(RP1942.Goods) do
        if g.rarity then
            byRarity[g.rarity] = byRarity[g.rarity] or {}
            table.insert(byRarity[g.rarity], id)
        end
    end
    local total = 0
    for rarity, w in pairs(odds) do if byRarity[rarity] then total = total + w end end
    if total <= 0 then return nil end
    local roll = math.Rand(0, total)
    for rarity, w in SortedPairs(odds) do
        if byRarity[rarity] then
            roll = roll - w
            if roll <= 0 then
                local list = byRarity[rarity]
                return list[math.random(#list)]
            end
        end
    end
end

function ENT:Finish()
    local c = self:Config()
    local stars = self:Grade(self:Downtime())
    local made = {}
    for i = 1, c.items do
        local id = rollGood(stars)
        if id then made[#made + 1] = id end
    end
    self:SetRunBase(c.runTime)
    self:SetState(self.STATE_DONE)
    self:SetReadyQuality(stars)
    self:SetReadyList(table.concat(made, ","))
    self:Engine(false)
    self:EmitSound("buttons/bell1.wav", 70, 95)
end

function ENT:Think()
    local now = CurTime()
    if self:GetState() == self.STATE_RUNNING and not self:GetOff() then
        local run = self:Progress()
        local nextHalt = self.haltAt and self.haltAt[self:GetHalts() + 1]
        if nextHalt and run >= nextHalt then
            self:Halt()
        elseif run >= self:Config().runTime then
            self:Finish()
        end
    end
    self:NextThink(now + 0.25)
    return true
end

-- Buttons on the panel: "fix:<fault>" and "collect"
function ENT:OnPanelPress(ply, id)
    if id == "power" then
        self:SetPower(self:GetOff())
        return
    end

    local fault = string.match(id, "^fix:(%w+)$")
    if fault then
        if self:GetState() ~= self.STATE_HALTED or self:GetOff() then return end
        local now = CurTime()
        if fault == self:GetFault() then
            self:SetDownBase(self:GetDownBase() + (now - self:GetHaltedAt()))
            self:SetHaltedAt(0)
            self:SetFault("")
            self:SetRunTime(now)
            self:SetState(self.STATE_RUNNING)
            self:Engine(true)
            self:EmitSound("buttons/lever1.wav", 65)
        else
            -- The wrong repair: more downtime, and it's still broken
            self:SetDownBase(self:GetDownBase() + self:Config().wrongFix)
            self:EmitSound("buttons/button8.wav", 65)
            DarkRP.notify(ply, 1, 3, "That's not the fault. Look at which lamp is flashing.")
        end
        return
    end

    if id == "collect" then
        if self:GetState() ~= self.STATE_DONE then return end
        local goods, q = self:ReadyGoods(), self:GetReadyQuality()
        if #goods == 0 then self:Idle() self:TryStart() return end
        self:SetReadyList("")
        local top = self:LocalToWorld(Vector(self:OBBCenter().x, self:OBBCenter().y, self:OBBMaxs().z + 8))
        local names, droppedAll = {}, 0
        for _, g in ipairs(goods) do
            local _, dropped = RP1942.giveGoods(ply, g, q, 1, top)
            droppedAll = droppedAll + dropped
            local good = RP1942.Goods[g]
            names[#names + 1] = good.name .. " (" .. good.rarity .. ")"
        end
        local what = table.concat(names, ", ")
        if droppedAll == 0 then
            DarkRP.notify(ply, 0, 5, "Collected " .. what .. " into your pocket.")
        else
            DarkRP.notify(ply, 0, 5, "Collected " .. what .. ". Your pocket is full: " .. droppedAll .. " left on top of the line.")
        end
        self:EmitSound("physics/metal/metal_box_impact_soft2.wav", 60)
        self:Idle()
        self:TryStart()   -- the next run, if there's scrap in the hopper
    end
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() then
        DarkRP.notify(ply, 0, 3, "Look at a button on the factory's panel and press E. Push scrap metal into the line to run it.")
    end
end

function ENT:OnRemove()
    self:Engine(false)
end
