AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local FALLBACK = "models/props_wasteland/controlroom_storagecloset001a.mdl"

-- The model from the settings (or the fallback if it isn't installed)
function ENT:ApplyModel()
    local m = RP1942.bankSetting and RP1942.bankSetting("model") or FALLBACK
    if not util.IsValidModel(m) then m = FALLBACK end
    if self:GetModel() == m and IsValid(self:GetPhysicsObject()) then return end
    self:SetModel(m)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end   -- bolted to the floor
end

function ENT:Initialize()
    self:ApplyModel()
    self:SetUseType(SIMPLE_USE)
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() and RP1942.bankUse then RP1942.bankUse(ply, self) end
end

-- Nobody damages, moves or tools the bank (move it with /removevault + /addvault)
function ENT:OnTakeDamage() end
function ENT:CanTool() return false end
hook.Add("PhysgunPickup", "RP1942_BankVault", function(_, ent)
    if IsValid(ent) and ent:GetClass() == "rp1942_bank_vault" then return false end
end)
