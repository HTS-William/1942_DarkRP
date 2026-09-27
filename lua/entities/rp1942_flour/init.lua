AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(RP1942.Production.flour.model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() then ply:PickupObject(self) end
end

-- Pushed into an oven: it goes in (a tick later, never inside the physics callback)
function ENT:PhysicsCollide(data)
    local oven = data.HitEntity
    if IsValid(oven) and oven:GetClass() == "rp1942_oven" and not self.RP1942_Used then
        timer.Simple(0, function()
            if IsValid(self) and IsValid(oven) and not self.RP1942_Used then oven:AddFlour(self) end
        end)
    end
end
