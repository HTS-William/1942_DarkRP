--[[---------------------------------------------------------------------------
42Bros - a good (bread, wine, ...). Which one is its "Good" value, a key
of RP1942.Goods (rp1942_production/sh_production.lua); its quality is 1-3 stars.
    E           pick it up and carry it
    Shift + E   eat / drink it
    Radio Set   E tunes it (it's a working radio), Shift + E carries it
    pocket it, hand it over, or push it into a market to sell it

Food and drink (goods that can be eaten: bread, wine, rations) have an
OWNER: whoever made them, or last bought them. Anyone else can't pocket,
carry or eat them: pressing E BUYS it at today's market price. The money
goes to the owner (taxed like a market sale), the good goes into the
buyer's pocket, and the buyer is its owner now: eat it, sell it on, or take
it to a market. A good whose owner has left the server is free to take.
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
    -- food and drink: who owns it (SteamID and name; "" = nobody). Kept in a pocket.
    self:NetworkVar("String", 3, "OwnerID")
    self:NetworkVar("String", 4, "OwnerName")
end

-- Food or drink with an owner: anyone else buys it with E
function ENT:IsForSale()
    local good = self:GoodInfo()
    return good ~= nil and good.eat ~= nil and self:GetOwnerID() ~= ""
end

function ENT:IsOwnedBy(ply)
    return IsValid(ply) and self:GetOwnerID() == ply:SteamID()
end

function ENT:SalePrice()
    return RP1942.marketPrice(self:GetGood(), self:GetQuality())
end

-- Is this good a radio (the factory's Radio Set)? It plays like the wireless set.
function ENT:IsRadio()
    local good = self:GoodInfo()
    return good ~= nil and good.radio == true
end

function ENT:GoodInfo()
    return RP1942 and RP1942.Goods and RP1942.Goods[self:GetGood()]
end
