--[[---------------------------------------------------------------------------
1942 DarkRP - a good (bread, wine, ...). Which one is its "Good" value, a key
of RP1942.Goods (rp1942_production/sh_production.lua); its quality is 1-3 stars.
    E           pick it up and carry it
    Shift + E   eat / drink it
    Radio Set   E tunes it (it's a working radio), Shift + E carries it
    pocket it, hand it over, or push it into a market to sell it
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Goods"
ENT.Author    = "Claude & William"
ENT.Spawnable = false
ENT.LabelHeight = 8

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "Good")
    self:NetworkVar("Int", 0, "Quality")   -- 1-3 stars (RP1942.Quality)
    -- the Radio Set good is a working radio (rp1942_radio module): these are its dial
    self:NetworkVar("String", 1, "URL")        -- "" = off
    self:NetworkVar("String", 2, "Station")
    self:NetworkVar("Float",  0, "Volume")
end

-- Is this good a radio (the factory's Radio Set)? It plays like the wireless set.
function ENT:IsRadio()
    local good = self:GoodInfo()
    return good ~= nil and good.radio == true
end

function ENT:GoodInfo()
    return RP1942 and RP1942.Goods and RP1942.Goods[self:GetGood()]
end
