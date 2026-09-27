--[[---------------------------------------------------------------------------
1942 DarkRP - oil derrick (Petroleum Producer). Settings: RP1942.Production.oil
(rp1942_production/sh_production.lua).

    Bought in the F4 Shop, but not placed by hand: it's built on a free oil
    site (admins mark them with /addoilsite; rp1942_production/sv_oil_sites.lua)
    and it's bolted down: no physgun, gravity gun, pocket or tools.

    It pumps on its own. The well pressure drifts up or down, changing
    direction every so often; OPEN VALVE lowers it, CLOSE VALVE raises it.
    Time spent in the green decides the tank: more canisters and more stars.
    When the tank is full, FILL CANISTERS and it starts pumping again.
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Oil Derrick"
ENT.Author    = "Claude & William"
ENT.Spawnable = false

-- Bolted down (GMod's own flags; sv_oil_sites.lua also blocks the rest)
ENT.PhysgunDisabled    = true
ENT.m_tblToolsAllowed  = { "remover" }
ENT.DisableDuplicator  = true

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")   -- set by DarkRP when bought
    self:NetworkVar("Int",    0, "Ready")        -- canisters in the full tank (0 = pumping)
    self:NetworkVar("Int",    1, "ReadyQuality")
    self:NetworkVar("Float",  0, "DoneAt")       -- 0 = not pumping
    self:NetworkVar("Float",  1, "PumpStart")
    self:NetworkVar("Float",  2, "PressBase")    -- the pressure was PressBase at PressTime,
    self:NetworkVar("Float",  3, "PressTime")    -- and moves PressRate per second from there
    self:NetworkVar("Float",  4, "PressRate")
    self:NetworkVar("Float",  5, "Green")        -- seconds in the green so far this tank
end

function ENT:Config() return RP1942.Production.oil end

function ENT:IsPumping() return self:GetDoneAt() > 0 end

-- The pressure right now, 0-100 (the same sum on server and client)
function ENT:Pressure()
    if not self:IsPumping() then return 0 end
    return math.Clamp(self:GetPressBase() + self:GetPressRate() * (CurTime() - self:GetPressTime()), 0, 100)
end

-- "low", "right" or "high"
function ENT:PressureZone(p)
    local c = self:Config().pressure
    p = p or self:Pressure()
    if p < c.low then return "low" elseif p > c.high then return "high" end
    return "right"
end

-- Canisters (= stars) for a share of the pumping spent in the green
function ENT:Grade(share)
    for _, g in ipairs(self:Config().grades) do
        if share >= g.share then return g.count end
    end
    return 1
end
