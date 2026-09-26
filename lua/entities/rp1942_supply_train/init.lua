AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local ROB_SOUND = "items/ammocrate_open.wav"

-- Called by the event before Spawn(): the start, station stop and end points
function ENT:SetRoute(start, stop, finish)
    self.routeStart, self.routeStop, self.routeFinish = start, stop, finish
end

function ENT:Initialize()
    local c = self:GetConfig()
    local start  = self.routeStart or self:GetPos()
    local finish = self.routeFinish or start
    self:SetModel(c.model)

    local line = finish - start
    local len = line:Length()
    self.dir = len > 0 and line:GetNormalized() or Vector(1, 0, 0)
    self.ang = Angle(0, line:Angle().y + (c.yawOffset or 0), 0)

    -- Spawn out of sight behind the start point: by default one train
    -- length back, so its nose is at the start point when it appears
    local behind = tonumber(c.spawnBehind)
    if not behind then
        local mins, maxs = self:GetModelBounds()
        behind = math.max(maxs.x - mins.x, maxs.y - mins.y) / 2 + 32
    end
    local spawn = start - self.dir * behind

    -- The station stop, projected onto the line so the path stays straight
    local stop = self.routeStop or start
    local stopAlong = math.Clamp((stop - start):Dot(self.dir), 0, len)
    self:SetRouteA(spawn)
    self:SetRouteS(start + self.dir * stopAlong)
    self:SetRouteB(finish)

    self:SetPos(spawn)
    self:SetAngles(self.ang)

    -- Moved by code, never by physics: the position is set directly every
    -- tick, and a solid "shadow" collision copy follows it so players can't
    -- walk through it and E / bullets hit it. Models without a collision
    -- mesh get a solid box of the model's size instead.
    if not self:PhysicsInitShadow(false, false) then
        local mins, maxs = self:GetModelBounds()
        self:PhysicsInitBox(mins, maxs)
        self:MakePhysicsObjectAShadow(false, false)
    end
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)   -- PhysicsInit* can change it; the code drives this entity
    self:MoveTo(spawn)

    self:SetUseType(SIMPLE_USE)
    self:SetCrates(c.crates or 0)
    self:SetPhaseNow(self.ARRIVING)
    self.robbers = {}
end

function ENT:SetPhaseNow(phase)
    self:SetPhase(phase)
    self:SetPhaseStart(CurTime())
end

-- The current leg: from, to (nil while standing still)
function ENT:Leg()
    local phase = self:GetPhase()
    if phase == self.ARRIVING then return self:GetRouteA(), self:GetRouteS() end
    if phase == self.DEPARTING then return self:GetRouteS(), self:GetRouteB() end
end

-- Where the train should be right now, and whether it finished its leg
function ENT:TargetPos()
    local from, to = self:Leg()
    if not from then
        return self:GetPhase() == self.STOPPED and self:GetRouteS() or self:GetRouteB(), true
    end
    local c = self:GetConfig()
    local dist = (to - from):Length()
    local s, arrived = self.Travelled(CurTime() - self:GetPhaseStart(), dist, c.speed or 200, c.accelTime or 4)
    return from + self.dir * s, arrived
end

-- Put the train (and its collision) at pos
function ENT:MoveTo(pos)
    self:SetPos(pos)
    self:SetAngles(self.ang)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:UpdateShadow(pos, self.ang, FrameTime())
    end
end

-- Knock players on the line out of the way (and hurt them a bit)
function ENT:ShoveAhead(c)
    local mins, maxs = self:WorldSpaceAABB()
    local pad = Vector(24, 24, 0)
    local side = Vector(-self.dir.y, self.dir.x, 0)
    local now = CurTime()
    self.lastHit = self.lastHit or {}

    for _, ply in ipairs(ents.FindInBox(mins - pad, maxs + pad)) do
        if ply:IsPlayer() and ply:Alive() and ply:GetPos().z < maxs.z - 8 then   -- not riders on the roof
            local away = (ply:GetPos() - self:GetPos()):Dot(side) >= 0 and 1 or -1
            ply:SetVelocity(side * away * (c.shoveForce or 450) + Vector(0, 0, 180))
            if (c.hitDamage or 0) > 0 and (self.lastHit[ply] or 0) < now - 1 then
                self.lastHit[ply] = now
                local dmg = DamageInfo()
                dmg:SetDamage(c.hitDamage)
                dmg:SetDamageType(DMG_CRUSH)
                dmg:SetAttacker(self)
                dmg:SetInflictor(self)
                ply:TakeDamageInfo(dmg)
            end
        end
    end
end

function ENT:StartWheels(c)
    if self.wheels then self.wheels:Stop() end
    self.wheels = CreateSound(self, c.wheelSound)
    self.wheels:SetSoundLevel(c.wheelLevel or 90)
    self.wheels:Play()
end

function ENT:Think()
    local c = self:GetConfig()
    local now = CurTime()
    local phase = self:GetPhase()

    -- Horn and wheels on the first think, once clients know the entity exists
    if not self.started then
        self.started = true
        self:EmitSound(c.hornSound, c.hornLevel or 140)
        self:StartWheels(c)
    end

    if phase == self.ARRIVING or phase == self.DEPARTING then
        local pos, arrived = self:TargetPos()
        self:MoveTo(pos)
        self:ShoveAhead(c)
        if arrived then
            if self.wheels then self.wheels:FadeOut(1) end
            if phase == self.ARRIVING then
                self:SetPhaseNow(self.STOPPED)
            else
                self:Finish()
            end
        end

    elseif phase == self.STOPPED then
        if now - self:GetPhaseStart() >= (c.stopTime or 20) then
            if c.hornOnDepart then self:EmitSound(c.hornSound, c.hornLevel or 140) end
            self:StartWheels(c)
            self:SetPhaseNow(self.DEPARTING)
        end

    elseif phase == self.LEAVING then
        local fade = math.max(c.fadeTime or 0.5, 0.01)
        local elapsed = now - self:GetPhaseStart()
        self:SetColor(Color(255, 255, 255, math.Clamp(1 - elapsed / fade, 0, 1) * 255))
        if elapsed >= fade then self:Remove() return end
    end

    self:ThinkRobbers(c, now)

    -- Every tick while moving (smooth motion), otherwise 10x a second
    self:NextThink(now + ((phase == self.ARRIVING or phase == self.DEPARTING) and 0 or 0.1))
    return true
end

-- End of the line: the leftover cargo goes to the Reich, then it vanishes
function ENT:Finish()
    local c = self:GetConfig()
    local left = self:GetCrates()
    self:SetCrates(0)

    local reich = self:ReichPlayers()
    if left > 0 then
        local money = c.money or { min = 0, max = 0 }
        local amount = math.floor(left * (money.min + money.max) / 2)
        if c.leftoverToTreasury and RP1942.treasuryDeposit then
            RP1942.treasuryDeposit(amount, "supply train")
            if RP1942.alert and c.msgDone and #reich > 0 then
                RP1942.alert(string.format(c.msgDone, amount), "clear", reich)
            end
        end
    elseif RP1942.alert and c.msgEmpty and #reich > 0 then
        RP1942.alert(c.msgEmpty, "wanted", reich)
    end

    self:SetPhaseNow(self.LEAVING)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetNotSolid(true)
end

function ENT:ReichPlayers()
    local list = {}
    for _, p in ipairs(player.GetAll()) do
        if RP1942.getFaction and RP1942.getFaction(p) == "reich" then list[#list + 1] = p end
    end
    return list
end

--[[---------------------------------------------------------------------------
Robbing: press E to start, keep holding E and looking at the train
---------------------------------------------------------------------------]]
local function setHold(ply, startTime, endTime, text)
    ply:SetNW2Float("RP1942_HoldStart", startTime)
    ply:SetNW2Float("RP1942_HoldEnd", endTime)
    ply:SetNW2String("RP1942_HoldText", text or "")
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if self:GetPhase() == self.LEAVING or self:GetCrates() <= 0 then return end
    if self.robbers[ply] then return end
    if ply.isArrested and ply:isArrested() then return end

    if not self:CanRob(ply) then
        DarkRP.notify(ply, 1, 4, "This is the Reich's own cargo. Guard it.")
        return
    end

    local c = self:GetConfig()
    local now = CurTime()
    self.robbers[ply] = now + (c.holdTime or 4)
    setHold(ply, now, self.robbers[ply], "Robbing a crate...")
end

function ENT:ThinkRobbers(c, now)
    for ply, doneAt in pairs(self.robbers) do
        local ok = IsValid(ply) and ply:Alive() and ply:KeyDown(IN_USE)
            and self:GetCrates() > 0 and self:GetPhase() ~= self.LEAVING
        if ok then
            local tr = ply:GetEyeTrace()
            ok = tr.Entity == self and tr.HitPos:Distance(ply:EyePos()) <= (c.useRange or 140)
        end

        if not ok then
            self.robbers[ply] = nil
            if IsValid(ply) then setHold(ply, 0, 0) end
        elseif now >= doneAt then
            self.robbers[ply] = nil
            setHold(ply, 0, 0)
            self:GiveCrate(ply, c)
        end
    end
end

-- Weighted random pick among the installed weapon classes
local function pickWeapon(list)
    local total, pool = 0, {}
    for class, w in pairs(list or {}) do
        if w > 0 and weapons.GetStored(class) then
            total = total + w
            pool[#pool + 1] = { class = class, w = w }
        end
    end
    if total <= 0 then return end
    local roll = math.random() * total
    for _, p in ipairs(pool) do
        roll = roll - p.w
        if roll <= 0 then return p.class end
    end
    return pool[#pool].class
end

-- The weapon goes into the robber's DarkRP pocket (so duplicates are fine).
-- Pocket full: it's dropped at their feet instead.
local function giveWeapon(ply, class)
    local stored = weapons.GetStored(class)
    local name = (stored and stored.PrintName) or class
    local wep = RP1942.makeSpawnedWeapon and RP1942.makeSpawnedWeapon(class, ply:GetPos() + Vector(0, 0, 16))
    if not IsValid(wep) then return nil end
    if RP1942.pocketOrLeave(ply, wep) then
        return "a " .. name .. " (in your pocket)"
    end
    return "a " .. name .. " (pocket full, it's at your feet)"
end

function ENT:GiveCrate(ply, c)
    self:SetCrates(self:GetCrates() - 1)
    self:EmitSound(ROB_SOUND)

    local money = c.money or { min = 0, max = 0 }
    local amount = math.random(money.min, money.max)
    if amount > 0 then ply:addMoney(amount) end

    local got = DarkRP.formatMoney(amount)
    if math.random(1, 100) <= (c.weaponChance or 0) then
        local class = pickWeapon(c.weapons)
        local item = class and giveWeapon(ply, class)
        if item then got = got .. " and " .. item end
    end
    DarkRP.notify(ply, 0, 5, "You robbed a crate: " .. got .. ".")

    if c.wantedOnRob and RP1942.makeWanted then
        local reasons = RP1942.Wanted and RP1942.Wanted.reasons
        RP1942.makeWanted(ply, (reasons and reasons.train_robbery) and "train_robbery" or "For robbing a Reich supply train")
    end

    if not self.alerted and RP1942.alert and c.msgRobbed then
        self.alerted = true
        local reich = self:ReichPlayers()
        if #reich > 0 then RP1942.alert(c.msgRobbed, "wanted", reich) end
    end
end

function ENT:OnRemove()
    if self.wheels then self.wheels:Stop() end
    for ply in pairs(self.robbers or {}) do
        if IsValid(ply) then setHold(ply, 0, 0) end
    end
end
