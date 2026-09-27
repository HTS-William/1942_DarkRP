include("shared.lua")

function ENT:LabelInfo()
    local good = self:GoodInfo()
    if not good then return end
    local q = self:GetQuality()
    local lines = {
        "Quality  ·  " .. q .. "/3 (" .. RP1942.qualityName(q) .. ")" .. (good.rarity and ("  ·  " .. good.rarity) or ""),
        "Market price  ·  " .. DarkRP.formatMoney(RP1942.marketPrice(self:GetGood(), q)),
    }
    if good.eat then
        lines[#lines + 1] = "E carry  ·  Shift+E " .. (good.eat.verb or "eat")
    end
    return { title = string.upper(good.name), lines = lines }
end

function ENT:Draw()
    self:DrawModel()
    -- Goods are small: only label them up close
    if LocalPlayer():EyePos():DistToSqr(self:GetPos()) < 150 * 150 and RP1942.drawProductionLabel then
        RP1942.drawProductionLabel(self)
    end
end
