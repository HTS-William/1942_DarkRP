--[[---------------------------------------------------------------------------
42Bros - a crate of goods: several of the same good, at the same quality,
merged into one thing (like DarkRP's shipments merge).

Goods on the ground that touch become a crate, and a good that touches a
crate goes into it (rp1942_production/sv_goods_stack.lua says when):
same good, same quality, same owner. Radio Sets never go in a crate.

    E               one good out, into your pocket
    E (someone      buy one (food and drink with an owner), into your pocket
      else's food)
    Shift + E       carry the crate
    pocket it       it's one pocket item; the inventory stores what's in it
    a market        push it in and everything in it is sold
---------------------------------------------------------------------------]]
ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Crate of goods"
ENT.Author    = "Claude & William"
ENT.Spawnable = false
ENT.LabelHeight = 22

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "Good")
    self:NetworkVar("Int", 0, "Quality")
    self:NetworkVar("Int", 1, "Count")
    -- food and drink: whose it is, as on a single good (rp1942_good)
    self:NetworkVar("String", 1, "OwnerID")
    self:NetworkVar("String", 2, "OwnerName")
end

function ENT:GoodInfo()
    return RP1942 and RP1942.Goods and RP1942.Goods[self:GetGood()]
end

function ENT:IsRadio() return false end

function ENT:IsForSale()
    local good = self:GoodInfo()
    return good ~= nil and good.eat ~= nil and self:GetOwnerID() ~= ""
end

function ENT:IsOwnedBy(ply)
    return IsValid(ply) and self:GetOwnerID() == ply:SteamID()
end

-- the price of ONE of them
function ENT:SalePrice()
    return RP1942.marketPrice(self:GetGood(), self:GetQuality())
end
