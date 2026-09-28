--[[---------------------------------------------------------------------------
1942 DarkRP - money printer, the shared base of rp1942_printer_bank (Banker,
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

-- What the upgrades make it do
-- Output's increase per tier for this printer (it differs by kind)
function ENT:OutputPer()
    local per = self:Config().upgrades.output.per
    return istable(per) and (per[self.Kind] or 0.25) or per
end

function ENT:PrintAmount()
    return math.floor(self:Config().amount * (1 + self:OutputPer() * self:Tier("output")))
end
function ENT:PrintInterval()
    local c = self:Config()
    return math.max(c.interval - c.upgrades.speed.per * self:Tier("speed"), 10)
end
function ENT:HeatRise()   -- degrees per second while running
    local c = self:Config()
    return math.max(c.heat.rise * (1 - c.upgrades.cooling.per * self:Tier("cooling")), 0)
end
function ENT:Volume()
    local c = self:Config()
    return math.max(1 - c.upgrades.muffler.per * self:Tier("muffler"), 0.3)
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
