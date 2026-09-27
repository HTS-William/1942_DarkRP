include("shared.lua")

function ENT:LabelInfo()
    return { title = "SACK OF FLOUR", lines = { "Push it into a bread oven" } }
end

function ENT:Draw()
    self:DrawModel()
    if LocalPlayer():EyePos():DistToSqr(self:GetPos()) < 200 * 200 and RP1942.drawProductionLabel then
        RP1942.drawProductionLabel(self)
    end
end
