include("shared.lua")

function ENT:LabelInfo()
    return { title = "BATTERY", lines = { "Push it into a factory line or an oil rig to power it" } }
end

function ENT:Draw()
    self:DrawModel()
    if LocalPlayer():EyePos():DistToSqr(self:GetPos()) < 200 * 200 and RP1942.drawProductionLabel then
        RP1942.drawProductionLabel(self)
    end
end
