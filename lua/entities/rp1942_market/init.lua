AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(RP1942.Production.market.model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    -- a model without its own collision still gets a solid box, so goods can touch it
    if not IsValid(self:GetPhysicsObject()) then
        self:PhysicsInitBox(self:OBBMins(), self:OBBMaxs())
        self:SetSolid(SOLID_VPHYSICS)
    end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

-- E on the mailbox itself: sell everything in your pocket
function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if (ply.RP1942_NextMarket or 0) > CurTime() then return end
    ply.RP1942_NextMarket = CurTime() + 1
    RP1942.sellPocketGoods(ply)
end

-- Buttons on the board: "sellall", or "sell:<good>:<quality>"
function ENT:OnPanelPress(ply, id)
    if id == "sellall" then
        RP1942.sellPocketGoods(ply)
        return
    end
    local good, q = string.match(id, "^sell:([%w_]+):(%d)$")
    if good and RP1942.Goods[good] then
        RP1942.sellPocketGoods(ply, good, tonumber(q))
    end
end
