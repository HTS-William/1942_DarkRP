AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    -- face the buyer, and remember whose it is
    timer.Simple(0, function()
        if not IsValid(self) then return end
        local owner = self.RP1942_ShopOwner or (self.Getowning_ent and self:Getowning_ent())
        if IsValid(owner) then
            self:SetAngles(Angle(0, owner:EyeAngles().y + 180, 0))
            self:SetOwnerName(owner:Nick())
        end
    end)
end

-- E: the next camera on air (nearest first), then off (sv_broadcast.lua)
function ENT:Use(ply)
    RP1942.broadcastNextChannel(self, ply, "television")
end
