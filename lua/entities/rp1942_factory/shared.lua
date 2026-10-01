--[[---------------------------------------------------------------------------
1942 DarkRP - factory line (Factory Owner). Settings: RP1942.Production.factory
(rp1942_production/sh_production.lua).

    It runs on scrap metal (rp1942_scrap, bought in the F4 shop): push loads
    into it and they wait in its hopper (up to `hopper`). Each run uses one
    load; with the hopper empty the line stands idle until more goes in.
    A run halts twice with a fault: the BELT, BOILER or FUSE lamp flashes and
    the line stops until someone presses the matching repair button (the
    wrong one costs extra downtime). The run's stars come from its downtime,
    and better runs have better odds of rare goods. When the run is done,
    COLLECT, and the next run starts if there's scrap in the hopper.
    The POWER lever switches it off: the run (and any downtime) pause where
    they are. Repairs need the power on.
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Factory Line"
ENT.Author    = "Claude & William"
ENT.Spawnable = false

ENT.STATE_DONE, ENT.STATE_RUNNING, ENT.STATE_HALTED, ENT.STATE_IDLE = 0, 1, 2, 3   -- IDLE: no scrap, waiting

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")   -- set by DarkRP when bought
    self:NetworkVar("Int",    0, "State")        -- STATE_*
    self:NetworkVar("Int",    1, "ReadyQuality")
    self:NetworkVar("Int",    2, "Halts")        -- faults so far this run
    self:NetworkVar("Int",    3, "Scrap")        -- loads of scrap waiting in the hopper
    self:NetworkVar("Float",  0, "RunBase")      -- seconds run before RunTime,
    self:NetworkVar("Float",  1, "RunTime")      -- when it last (re)started
    self:NetworkVar("Float",  2, "DownBase")     -- seconds halted before HaltedAt
    self:NetworkVar("Float",  3, "HaltedAt")
    self:NetworkVar("String", 0, "Fault")        -- the fault's id while halted
    self:NetworkVar("String", 1, "ReadyList")    -- "clock,rations": goods waiting to be collected
    self:NetworkVar("Bool",   0, "Off")          -- switched off: everything paused
    self:NetworkVar("Float",  4, "PausedAt")     -- when it was switched off
end

-- The line's clock: stands still while it's switched off
function ENT:Now() return self:GetOff() and self:GetPausedAt() or CurTime() end

function ENT:Config() return RP1942.Production.factory end

-- Seconds of running this run (the clock stops while halted)
function ENT:Progress()
    if self:GetState() == self.STATE_IDLE then return 0 end
    local run = self:GetRunBase()
    if self:GetState() == self.STATE_RUNNING then run = run + (self:Now() - self:GetRunTime()) end
    return math.min(run, self:Config().runTime)
end

-- Seconds halted this run
function ENT:Downtime()
    local down = self:GetDownBase()
    if self:GetState() == self.STATE_HALTED then down = down + (self:Now() - self:GetHaltedAt()) end
    return down
end

-- Stars for this much downtime
function ENT:Grade(downtime)
    for _, g in ipairs(self:Config().grades) do
        if downtime <= g.downtime then return g.stars end
    end
    return 1
end

-- The goods waiting to be collected, as a list of ids
function ENT:ReadyGoods()
    local list = {}
    for id in string.gmatch(self:GetReadyList() or "", "[^,]+") do
        if RP1942.Goods[id] then list[#list + 1] = id end
    end
    return list
end
