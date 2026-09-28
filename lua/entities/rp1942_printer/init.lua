AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local c = self:Config()
    self:SetModel(c.model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.hp = c.health
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    local now = CurTime()
    self:SetPrintStart(now)
    self:SetNextPrint(now + self:PrintInterval())
    self:SetHeatBase(0)
    self:SetHeatTime(now)
    self:SetHeatRate(self:HeatRise())
    self:Hum(true)
end

-- The printing noise (quieter and shorter-range with the Muffler)
function ENT:Hum(on)
    if self.hum then self.hum:Stop() self.hum = nil end
    if on then
        self.hum = CreateSound(self, self:Config().sound)
        self.hum:SetSoundLevel(math.floor(75 - 3 * self:Tier("muffler")))
        self.hum:PlayEx(self:Volume(), 100)
    end
end

-- Heat from now on: rising while running, falling while off
function ENT:RebaseHeat()
    local now = CurTime()
    self:SetHeatBase(self:Heat())
    self:SetHeatTime(now)
    self:SetHeatRate(self:GetOff() and -self:Config().heat.cool or self:HeatRise())
end

function ENT:SetPower(on)
    if on == not self:GetOff() then return end
    local now = CurTime()
    if on then
        local d = now - self:GetPausedAt()
        self:SetNextPrint(self:GetNextPrint() + d)
        self:SetPrintStart(self:GetPrintStart() + d)
        self:SetPausedAt(0)
        self:SetOff(false)
        self:EmitSound("buttons/button1.wav", 60)
    else
        self:SetPausedAt(now)
        self:SetOff(true)
        self:EmitSound("buttons/button19.wav", 60)
    end
    self:RebaseHeat()
    self:Hum(on)
end

function ENT:DoPrint()
    local amount = self:PrintAmount()
    if self:IsBank() then
        local cut = math.floor(amount * RP1942.printerTreasuryShare())
        if cut > 0 and RP1942.treasuryDeposit then RP1942.treasuryDeposit(cut, "Banking Printer") end
        self:SetLastTreasury(cut)
        amount = amount - cut
    end
    self:SetStored(self:GetStored() + amount)
    local now = CurTime()
    self:SetPrintStart(now)
    self:SetNextPrint(now + self:PrintInterval())
    self:EmitSound("ambient/levels/labs/coinslot1.wav", 60, 100, self:Volume())
end

-- The Reich took this illegal printer down: the owner pays the fine into the
-- treasury, and the Reich member gets the reward
function ENT:ReichTakedown(officer, how)
    local c = self:Config()
    local owner = self:Getowning_ent()
    local fine = 0
    if IsValid(owner) and (c.seizeFine or 0) > 0 then
        fine = math.min(c.seizeFine, math.max(owner:getDarkRPVar("money") or 0, 0))
        if fine > 0 then
            owner:addMoney(-fine)
            if RP1942.treasuryDeposit then RP1942.treasuryDeposit(fine, "illegal printer fine") end
        end
        DarkRP.notify(owner, 1, 8, "The Reich " .. how .. " your illegal printer. You were fined " .. DarkRP.formatMoney(fine) .. ", paid to the Reich treasury.")
    end
    local reward = c.seizeReward or 0
    if IsValid(officer) then
        if reward > 0 then officer:addMoney(reward) end
        DarkRP.notify(officer, 0, 7, "You " .. how .. " an illegal printer" .. (reward > 0 and (" and earned " .. DarkRP.formatMoney(reward)) or "")
            .. (fine > 0 and (". Its owner was fined " .. DarkRP.formatMoney(fine) .. " for the treasury.") or "."))
    end
    ServerLog(string.format("[1942] %s %s %s's illegal printer (fine %d to the treasury)\n",
        IsValid(officer) and officer:Nick() or "?", how, IsValid(owner) and owner:Nick() or "?", fine))
end

function ENT:Blow()
    if self.blown then return end
    self.blown = true
    local owner = self:Getowning_ent()
    local b = self:Config().heat.blast
    if RP1942.explode then RP1942.explode(self:WorldSpaceCenter(), { damage = b.damage, radius = b.radius, inflictor = self }) end
    if IsValid(owner) then DarkRP.notify(owner, 1, 7, "Your " .. self.PrintName .. " overheated and exploded, with its money.") end
    SafeRemoveEntity(self)
end

function ENT:Think()
    local now = CurTime()
    if not self:GetOff() then
        if now >= self:GetNextPrint() then self:DoPrint() end
    end
    local heat = self:Heat()
    if heat >= 100 then
        self:Blow()
        return
    end
    local warn = self:Config().heat.warn
    if heat >= warn and not self.warned and not self:GetOff() then
        self.warned = true
        local owner = self:Getowning_ent()
        if IsValid(owner) then DarkRP.notify(owner, 1, 7, "Your " .. self.PrintName .. " is overheating! Switch it off to let it cool.") end
    elseif heat < warn - 10 then
        self.warned = nil
    end
    self:NextThink(now + 0.5)
    return true
end

-- Panel buttons (look + E): collect, power, buy:<upgrade>, seize
function ENT:OnPanelPress(ply, id)
    local c = self:Config()
    local owner = self:Getowning_ent()

    if id == "collect" then
        local money = self:GetStored()
        if money <= 0 then return end
        self:SetStored(0)
        ply:addMoney(money)
        DarkRP.notify(ply, 0, 4, "You took " .. DarkRP.formatMoney(money) .. " from the " .. self.PrintName .. ".")
        if IsValid(owner) and owner ~= ply then
            DarkRP.notify(owner, 1, 6, "Someone emptied your " .. self.PrintName .. "!")
        end
        self:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav", 60)

    elseif id == "power" then
        self:SetPower(self:GetOff())

    elseif string.StartWith(id, "buy:") then
        local up = string.sub(id, 5)
        local def = c.upgrades[up]
        if not def then return end
        if ply ~= owner then return DarkRP.notify(ply, 1, 4, "Only the owner can upgrade this printer.") end
        local tier = self:Tier(up)
        if tier >= c.tiers then return end
        local cost = def.cost[tier + 1] or 0
        if not ply:canAfford(cost) then return DarkRP.notify(ply, 1, 4, "You can't afford that (" .. DarkRP.formatMoney(cost) .. ").") end
        ply:addMoney(-cost)
        self["SetTier" .. up:sub(1, 1):upper() .. up:sub(2)](self, tier + 1)
        if up == "cooling" then self:RebaseHeat() end
        if up == "muffler" and not self:GetOff() then self:Hum(true) end
        DarkRP.notify(ply, 0, 4, def.name .. " upgraded to tier " .. (tier + 1) .. ".")
        self:EmitSound("buttons/lever7.wav", 60)

    elseif id == "seize" then
        if self:IsBank() then return end
        if not (RP1942.isFaction and RP1942.isFaction(ply, "reich")) or ply == owner then return end
        self:ReichTakedown(ply, "seized")
        self:EmitSound("physics/metal/metal_box_break1.wav", 70)
        SafeRemoveEntity(self)
    end
end

-- The Reich destroying the Reichsbank's own printer pays for it, into the treasury
function ENT:FineReich(attacker)
    local fine = self:Config().bankFine or 0
    local paid = math.min(fine, math.max(attacker:getDarkRPVar("money") or 0, 0))
    if paid > 0 then
        attacker:addMoney(-paid)
        if RP1942.treasuryDeposit then RP1942.treasuryDeposit(paid, "Banking Printer destroyed by " .. attacker:Nick()) end
    end
    DarkRP.notify(attacker, 1, 7, "You destroyed a Reichsbank printer. " .. DarkRP.formatMoney(paid) .. " was taken from you to pay for it"
        .. (paid < fine and (" (all you had; the fine is " .. DarkRP.formatMoney(fine) .. ")") or "") .. ".")
    local owner = self:Getowning_ent()
    if IsValid(owner) then DarkRP.notify(owner, 1, 6, attacker:Nick() .. " destroyed your Banking Printer and was fined " .. DarkRP.formatMoney(paid) .. ".") end
    ServerLog(string.format("[1942] %s destroyed a Banking Printer and paid %d to the treasury\n", attacker:Nick(), paid))
end

-- Shot to pieces: a small blast. A Reich member who destroys an illegal one
-- gets the reward; one who destroys a Banking Printer pays the fine
function ENT:OnTakeDamage(dmg)
    if self.blown then return end
    self.hp = (self.hp or self:Config().health) - dmg:GetDamage()
    if self.hp > 0 then return end
    local attacker = dmg:GetAttacker()
    if not self:IsBank() and IsValid(attacker) and attacker:IsPlayer() and RP1942.isFaction and RP1942.isFaction(attacker, "reich")
        and attacker ~= self:Getowning_ent() then
        self:ReichTakedown(attacker, "destroyed")
    elseif self:IsBank() and IsValid(attacker) and attacker:IsPlayer() and RP1942.isFaction and RP1942.isFaction(attacker, "reich") then
        self:FineReich(attacker)
    end
    self:Blow()
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() then
        DarkRP.notify(ply, 0, 3, "Look at a button on the printer's panel and press E.")
    end
end

function ENT:OnRemove()
    self:Hum(false)
end
