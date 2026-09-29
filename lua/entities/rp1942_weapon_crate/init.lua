AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local cfg = RP1942.ShopShipments or {}
    self:SetModel(cfg.model or "models/Items/item_item_crate.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    self.hp = cfg.health or 200
end

-- One weapon out, on top of the crate
function ENT:Use(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    if (self.nextUse or 0) > CurTime() then return end
    self.nextUse = CurTime() + 0.4
    local n = self:GetCount()
    if n <= 0 then return end
    local top = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 12)
    local wep = RP1942.makeSpawnedWeapon and RP1942.makeSpawnedWeapon(self:GetWeaponClass(), top)
    if not IsValid(wep) then return end
    if wep.CPPISetOwner and self.CPPIGetOwner then
        local owner = self:CPPIGetOwner()
        if IsValid(owner) then wep:CPPISetOwner(owner) end
    end
    self:SetCount(n - 1)
    self:EmitSound("items/ammocrate_open.wav", 60)
    if n - 1 <= 0 then SafeRemoveEntityDelayed(self, 0.1) end
end

-- Shot up: the crate breaks and what's left is lost
function ENT:OnTakeDamage(dmg)
    self.hp = (self.hp or 200) - dmg:GetDamage()
    if self.hp > 0 or self.broken then return end
    self.broken = true
    self:EmitSound("physics/wood/wood_crate_break" .. math.random(1, 5) .. ".wav", 75)
    SafeRemoveEntity(self)
end
