AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate3x5.mdl")
    self:SetMaterial("models/debug/debugwhite")
    self:SetColor(Color(20, 20, 20))
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    -- stand it up, its face toward the buyer (the plate's long side across)
    timer.Simple(0, function()
        if not IsValid(self) then return end
        local owner = self.RP1942_ShopOwner or (self.Getowning_ent and self:Getowning_ent())
        if IsValid(owner) then
            local mins, maxs = self:OBBMins(), self:OBBMaxs()
            local yaw = owner:EyeAngles().y
            if (maxs.x - mins.x) > (maxs.y - mins.y) then
                self:SetAngles(Angle(0, yaw + 90, 90))   -- long side along x: x across, y up
            else
                self:SetAngles(Angle(-90, yaw, 0))       -- long side along y: y across, x up
            end
            self:SetPos(self:GetPos() + Vector(0, 0, 60))
            self:SetOwnerName(owner:Nick())
        end
    end)
end

-- E: the next camera on air (nearest first), then off (sv_broadcast.lua)
function ENT:Use(ply)
    RP1942.broadcastNextChannel(self, ply, "screen")
end
