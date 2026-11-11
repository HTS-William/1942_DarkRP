AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/dav0r/camera.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end   -- stays where it's put (aim it with the physgun)
    -- point it the way its buyer is looking
    timer.Simple(0, function()
        if not IsValid(self) then return end
        local owner = self.RP1942_ShopOwner or (self.Getowning_ent and self:Getowning_ent())
        if IsValid(owner) then
            self:SetAngles(Angle(0, owner:EyeAngles().y, 0))
            self:SetOwnerName(owner:Nick())
        end
    end)
end

function ENT:Use(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    if not RP1942.broadcastCanUse(self, ply) then
        return DarkRP.notify(ply, 1, 3, "That's " .. (self:GetOwnerName() ~= "" and self:GetOwnerName() or "someone else") .. "'s camera.")
    end
    self:SetOnAir(not self:GetOnAir())
    self:EmitSound(self:GetOnAir() and "buttons/lever7.wav" or "buttons/lever8.wav", 60)
    DarkRP.notify(ply, 0, 4, self:GetOnAir() and "On air: cinema screens tuned to this camera show it, and people near them hear what's said here."
        or "Off air.")
end
