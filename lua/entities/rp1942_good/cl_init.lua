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
        local lp = LocalPlayer()
        if self:IsForSale() and not self:IsOwnedBy(lp) then
            -- someone else's: for sale
            lines[2] = "For sale by " .. self:GetOwnerName() .. "  ·  " .. DarkRP.formatMoney(self:SalePrice())
            lines[#lines + 1] = "E buy  ·  it goes into your pocket"
        else
            if self:IsForSale() then lines[#lines + 1] = "Yours  ·  others pay you " .. DarkRP.formatMoney(self:SalePrice()) .. " with E" end
            lines[#lines + 1] = "E carry  ·  Shift+E " .. (good.eat.verb or "eat")
        end
    end
    if self:IsRadio() then
        local st = self:GetStation()
        lines[#lines + 1] = (st ~= "" and (st .. "  ·  ") or "") .. RP1942.radioStatus(self)
        lines[#lines + 1] = "E tune  ·  Shift+E carry"
    end
    return { title = string.upper(good.name), lines = lines }
end

function ENT:Think()
    if self:IsRadio() then RP1942.radioThink(self) end
    self:SetNextClientThink(CurTime() + 0.1)
    return true
end

function ENT:OnRemove()
    RP1942.radioStop(self)
end

function ENT:Draw()
    self:DrawModel()
    -- Goods are small: only label them up close
    if LocalPlayer():EyePos():DistToSqr(self:GetPos()) < 150 * 150 and RP1942.drawProductionLabel then
        RP1942.drawProductionLabel(self)
    end
end
