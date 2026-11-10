include("shared.lua")

function ENT:LabelInfo()
    local good = self:GoodInfo()
    if not good then return end
    local q, n = self:GetQuality(), self:GetCount()
    local each = RP1942.marketPrice(self:GetGood(), q)
    local lines = {
        "Quality  ·  " .. q .. "/3 (" .. RP1942.qualityName(q) .. ")" .. (good.rarity and ("  ·  " .. good.rarity) or ""),
        "Market price  ·  " .. DarkRP.formatMoney(each) .. " each, " .. DarkRP.formatMoney(each * n) .. " for all",
    }
    if good.eat and self:IsForSale() and not self:IsOwnedBy(LocalPlayer()) then
        lines[2] = "For sale by " .. self:GetOwnerName() .. "  ·  " .. DarkRP.formatMoney(self:SalePrice()) .. " each"
        lines[#lines + 1] = "E buy one  ·  it goes into your pocket"
    else
        lines[#lines + 1] = "E take one into your pocket  ·  Shift+E carry"
    end
    return { title = string.upper(good.name) .. "  x" .. n, lines = lines }
end

function ENT:Draw()
    self:DrawModel()
    if LocalPlayer():EyePos():DistToSqr(self:GetPos()) < 200 * 200 and RP1942.drawProductionLabel then
        RP1942.drawProductionLabel(self)
    end
end
