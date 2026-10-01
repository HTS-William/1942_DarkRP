--[[---------------------------------------------------------------------------
1942 DarkRP - oil rig (Petroleum Producer). Settings: RP1942.Production.oil
(rp1942_production/sh_production.lua).

    Bought in the F4 Shop, but not placed by hand: it's built on a free oil
    site (admins mark them with !addoilsite; rp1942_production/sv_oil_sites.lua)
    and it's bolted down: no physgun, gravity gun, pocket or tools.

    It pumps on its own. With the valve shut the well pressure climbs; turn
    the wheel to open the valve and it falls (steam hisses while it's open).
    Time spent in the green decides the tank: more barrels and more stars.
    When the tank is full, FILL BARRELS and it starts pumping again.
    The POWER lever switches it off (everything pauses). If the pressure ever
    drops to nothing, the pump stalls and switches itself off: shut valve,
    and someone has to switch it back on (the pressure then builds from 0).
    Left in the red too long, an alarm sounds; left longer, it explodes.
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Oil Rig"
ENT.Author    = "Claude & William"
ENT.Spawnable = false

-- Bolted down (GMod's own flags; sv_oil_sites.lua also blocks the rest)
ENT.PhysgunDisabled    = true
ENT.m_tblToolsAllowed  = { "remover" }
ENT.DisableDuplicator  = true

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")   -- the buyer (set in RP1942.buildOilRig, or by the spawner)
    self:NetworkVar("Int",    0, "Ready")        -- barrels in the full tank (0 = pumping)
    self:NetworkVar("Int",    1, "ReadyQuality")
    self:NetworkVar("Bool",   0, "ValveOpen")
    self:NetworkVar("Float",  0, "DoneAt")       -- 0 = not pumping
    self:NetworkVar("Float",  1, "PumpStart")
    self:NetworkVar("Float",  2, "PressBase")    -- the pressure was PressBase at PressTime,
    self:NetworkVar("Float",  3, "PressTime")    -- and moves PressRate per second from there
    self:NetworkVar("Float",  4, "PressRate")
    self:NetworkVar("Float",  5, "Green")        -- seconds in the green so far this tank
    self:NetworkVar("Float",  6, "WheelTurnedAt")-- when the wheel was last turned (its animation)
    self:NetworkVar("Bool",   1, "Off")          -- switched off: everything paused
    self:NetworkVar("Bool",   2, "Stalled")      -- switched itself off: the pressure hit 0
    self:NetworkVar("Float",  7, "PausedAt")     -- when it was switched off
    self:NetworkVar("Float",  8, "RedSince")     -- when the pressure went into the red (0 = it isn't)
end

-- Seconds in the red so far (0 = not in the red)
function ENT:RedTime()
    local since = self:GetRedSince()
    return since > 0 and math.max(self:Now() - since, 0) or 0
end

-- Is the alarm going?
function ENT:Alarming()
    return self:RedTime() >= self:Config().blowout.warnAfter
end

-- The rig's clock: stands still while it's switched off
function ENT:Now() return self:GetOff() and self:GetPausedAt() or CurTime() end

function ENT:Config() return RP1942.Production.oil end

function ENT:IsPumping() return self:GetDoneAt() > 0 end

-- The pressure right now, 0-100 (the same sum on server and client)
function ENT:Pressure()
    if not self:IsPumping() then return 0 end
    return math.Clamp(self:GetPressBase() + self:GetPressRate() * (self:Now() - self:GetPressTime()), 0, 100)
end

-- "low", "right" or "high"
function ENT:PressureZone(p)
    local c = self:Config().pressure
    p = p or self:Pressure()
    if p < c.low then return "low" elseif p > c.high then return "high" end
    return "right"
end

-- Is the wheel still turning? (it can't be turned again until it stops)
function ENT:WheelTurning()
    return CurTime() - self:GetWheelTurnedAt() < (self:Config().wheelTime or 1.2)
end

-- Barrels (= stars) for a share of the pumping spent in the green
function ENT:Grade(share)
    for _, g in ipairs(self:Config().grades) do
        if share >= g.share then return g.count end
    end
    return 1
end
