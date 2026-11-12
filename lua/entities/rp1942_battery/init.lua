AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local POWERED = { rp1942_factory = true, rp1942_oil_rig = true }

function ENT:Initialize()
    self:SetModel(RP1942.Battery.model)
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

-- Pushed into a factory line or an oil rig: it charges it (a tick later,
-- never inside the physics callback). While the machine is more than half
-- charged it bounces off.
function ENT:PhysicsCollide(data)
    local machine = data.HitEntity
    if IsValid(machine) and POWERED[machine:GetClass()] and not self.RP1942_Used then
        timer.Simple(0, function()
            if IsValid(self) and IsValid(machine) and not self.RP1942_Used and RP1942.chargeMachine then
                RP1942.chargeMachine(machine, self)
            end
        end)
    end
end
