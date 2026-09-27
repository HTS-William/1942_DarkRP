--[[---------------------------------------------------------------------------
1942 DarkRP - bread oven (Baker). Settings: RP1942.Production.oven
(rp1942_production/sh_production.lua).

    Push sacks of flour in: it holds a queue and bakes them one at a time.
    While it bakes the fire cools; STOKE FIRE (on its panel) heats it up.
    Time spent with the fire "just right" decides the batch: more loaves and
    more stars. The bread waits inside until someone presses COLLECT BREAD,
    and the next sack only goes in once the tray is empty.
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Bread Oven"
ENT.Author    = "Claude & William"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")   -- set by DarkRP when bought
    self:NetworkVar("Int",    0, "Flour")        -- sacks waiting in the queue
    self:NetworkVar("Int",    1, "Ready")        -- loaves waiting to be collected
    self:NetworkVar("Int",    2, "ReadyQuality")
    self:NetworkVar("Float",  0, "DoneAt")       -- 0 = not baking
    self:NetworkVar("Float",  1, "BakeStart")
    self:NetworkVar("Float",  2, "HeatBase")     -- the fire was HeatBase at HeatTime,
    self:NetworkVar("Float",  3, "HeatTime")     -- and cools steadily from there
    self:NetworkVar("Float",  4, "Green")        -- seconds "just right" so far this bake
end

function ENT:Config() return RP1942.Production.oven end

function ENT:IsBaking() return self:GetDoneAt() > 0 end

-- The fire right now, 0-100 (the same sum on server and client)
function ENT:Heat()
    if not self:IsBaking() then return 0 end
    local c = self:Config().heat
    return math.Clamp(self:GetHeatBase() - c.cool * (CurTime() - self:GetHeatTime()), 0, 100)
end

-- "cold", "right" or "hot"
function ENT:HeatZone(heat)
    local c = self:Config().heat
    heat = heat or self:Heat()
    if heat < c.cold then return "cold" elseif heat > c.hot then return "hot" end
    return "right"
end

-- Loaves (= stars) for a share of the bake spent "just right"
function ENT:Grade(share)
    for _, g in ipairs(self:Config().grades) do
        if share >= g.share then return g.loaves end
    end
    return 1
end
