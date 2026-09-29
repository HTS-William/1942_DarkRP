AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(self.boxModel or "models/Items/BoxSRounds.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

function ENT:Use(ply)
    if not (IsValid(ply) and ply:IsPlayer()) or self.used then return end
    self.used = true
    ply:GiveAmmo(self:GetAmount(), self:GetAmmoType())
    self:EmitSound("items/ammo_pickup.wav", 60)
    self:Remove()
end

-- The box model the F4 Shop uses for that ammo type
local function boxModel(ammoType)
    local o = RP1942.F4Shop and RP1942.F4Shop.ammo and RP1942.F4Shop.ammo.overrides and RP1942.F4Shop.ammo.overrides[ammoType]
    return o and o.model or "models/Items/BoxSRounds.mdl"
end

function RP1942.makeAmmoBox(ammoType, amount, pos)
    local box = ents.Create("rp1942_ammo_box")
    if not IsValid(box) then return end
    box.boxModel = boxModel(ammoType)
    box:SetAmmoType(ammoType)
    box:SetAmount(math.max(1, math.floor(amount)))
    box:SetPos(pos)
    box:Spawn()
    return box
end
