--[[---------------------------------------------------------------------------
1942 DarkRP - wine barrel (Winemaker). Settings: RP1942.Production.wine
(rp1942_production/sh_production.lua).

    START on its panel sets it fermenting. A few times along the way the must
    needs stirring: press STIR before the timer runs out. Every stir it gets
    raises the vintage (stars). When it's done, BOTTLE pours the bottles
    (into your pocket while there's room) and the barrel is used up.
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Wine Barrel"
ENT.Author    = "Claude & William"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")    -- set by DarkRP when bought
    self:NetworkVar("Float",  0, "DoneAt")        -- 0 = not fermenting
    self:NetworkVar("Float",  1, "StartedAt")
    self:NetworkVar("Float",  2, "StirBy")        -- 0 = no stir needed right now
    self:NetworkVar("Int",    0, "Stirs")         -- stirs made
    self:NetworkVar("Int",    1, "Calls")         -- times it has called for stirring
    self:NetworkVar("Int",    2, "Quality")       -- 0 = not done yet
end

function ENT:Config() return RP1942.Production.wine end
function ENT:IsFermenting() return self:GetDoneAt() > 0 end
function ENT:IsDone() return self:GetQuality() > 0 end
function ENT:NeedsStir() return self:GetStirBy() > CurTime() end

-- Stars for a number of stirs made
function ENT:Vintage(stirs)
    local total = self:Config().stirs
    if stirs >= total then return 3 elseif stirs >= total - 1 then return 2 end
    return 1
end
