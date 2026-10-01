include("shared.lua")

function ENT:LabelInfo()
    return { title = "SCRAP METAL", lines = { "Push it into a factory line" } }
end

function ENT:Draw()
    self:DrawModel()
    if LocalPlayer():EyePos():DistToSqr(self:GetPos()) < 200 * 200 and RP1942.drawProductionLabel then
        RP1942.drawProductionLabel(self)
    end
end
