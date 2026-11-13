--[[---------------------------------------------------------------------------
42Bros - money printer, the shared base of rp1942_printer_bank (Banker,
legal) and rp1942_printer_illegal. Settings: RP1942.Printers
(rp1942_printers/sh_printers.lua).
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Printer"
ENT.Author    = "Claude & William"
ENT.Spawnable = false
ENT.Kind      = "illegal"   -- "bank" or "illegal", set by the two printers

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")    -- set by DarkRP when bought
    self:NetworkVar("Int",    0, "Stored")        -- money in the tray
    self:NetworkVar("Int",    1, "TierOutput")
    self:NetworkVar("Int",    2, "TierSpeed")
    self:NetworkVar("Int",    3, "TierCooling")
    self:NetworkVar("Int",    4, "TierMuffler")
    self:NetworkVar("Int",    5, "LastTreasury")  -- bank: the treasury's cut of the last print
    self:NetworkVar("Bool",   0, "Off")
    self:NetworkVar("Float",  0, "NextPrint")
    self:NetworkVar("Float",  1, "PrintStart")
    self:NetworkVar("Float",  2, "PausedAt")
    self:NetworkVar("Float",  3, "HeatBase")      -- the heat was HeatBase at HeatTime,
    self:NetworkVar("Float",  4, "HeatTime")      -- and moves HeatRate per second from there
    self:NetworkVar("Float",  5, "HeatRate")
end

function ENT:Config() return RP1942.Printers end
function ENT:IsBank() return self.Kind == "bank" end

-- The printer's clock: stands still while it's off
function ENT:Now() return self:GetOff() and self:GetPausedAt() or CurTime() end

function ENT:Tier(id)
    local get = self["GetTier" .. id:sub(1, 1):upper() .. id:sub(2)]
    return get and get(self) or 0
end

-- A setting for this printer: { bank = ..., illegal = ... } or the same number for both
function ENT:Val(v, default)
    if istable(v) then v = v[self.Kind] end
    if v == nil then return default end
    return v
end

-- What the upgrades make it do
-- Output's increase per tier for this printer (it differs by kind)
function ENT:OutputPer()
    return self:Val(self:Config().upgrades.output.per, 0.25)
end

function ENT:PrintAmount()
    return math.floor(self:Val(self:Config().amount, 1000) * (1 + self:OutputPer() * self:Tier("output")))
end
function ENT:PrintInterval()
    local c = self:Config()
    return math.max(self:Val(c.interval, 120) - self:Val(c.upgrades.speed.per, 15) * self:Tier("speed"), 10)
end
function ENT:HeatRise()   -- degrees per second while running
    local c = self:Config()
    return math.max(c.heat.rise * (1 - self:Val(c.upgrades.cooling.per, 0.2) * self:Tier("cooling")), 0)
end
function ENT:Volume()
    local c = self:Config()
    return math.max(1 - self:Val(c.upgrades.muffler.per, 0.13) * self:Tier("muffler"), 0.3)
end
-- What the next tier of an upgrade costs on this printer (nil: maxed)
function ENT:UpgradeCost(id)
    local c = self:Config()
    local def = c.upgrades[id]
    local base = def and def.cost[self:Tier(id) + 1]
    if not base then return nil end
    return math.floor(base * self:Val(c.upgradeCostMult, 1))
end

-- Most the tray holds (nil: no limit): trayMax if it's set, else trayHours
-- of what a fully upgraded printer of this kind makes (sh_printers.lua)
function ENT:TrayMax()
    local c = self:Config()
    local fixed = self:Val(c.trayMax, nil)
    if fixed then return fixed end
    local hours = self:Val(c.trayHours, nil)
    return hours and math.floor(RP1942.printerMaxPerHour(self.Kind) * hours) or nil
end
function ENT:TrayFull()
    local max = self:TrayMax()
    return max ~= nil and self:GetStored() >= max
end

-- Heat right now, 0-100 (the same sum on server and client)
function ENT:Heat()
    return math.Clamp(self:GetHeatBase() + self:GetHeatRate() * (CurTime() - self:GetHeatTime()), 0, 100)
end

-- Seconds until it blows (nil if it isn't heating)
function ENT:TimeToBlow()
    local rate = self:GetHeatRate()
    if rate <= 0 then return nil end
    return (100 - self:Heat()) / rate
end
