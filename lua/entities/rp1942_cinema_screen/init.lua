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

-- E: the next camera on air (nearest first), then off
function ENT:Use(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    if not RP1942.broadcastCanUse(self, ply) then
        return DarkRP.notify(ply, 1, 3, "That's " .. (self:GetOwnerName() ~= "" and self:GetOwnerName() or "someone else") .. "'s screen.")
    end
    local cams = {}
    for _, c in ipairs(ents.FindByClass("rp1942_newsreel_camera")) do
        if c:Broadcasting() then cams[#cams + 1] = c end
    end
    local here = self:GetPos()
    table.sort(cams, function(a, b) return a:GetOwner():GetPos():DistToSqr(here) < b:GetOwner():GetPos():DistToSqr(here) end)
    local current, nextCam = self:GetCamera(), nil
    if not IsValid(current) then
        nextCam = cams[1]
    else
        for i, c in ipairs(cams) do
            if c == current then nextCam = cams[i + 1] break end
        end
    end
    self:SetCamera(nextCam or NULL)
    self:EmitSound("buttons/button9.wav", 55)
    if IsValid(nextCam) then
        DarkRP.notify(ply, 0, 4, "Showing " .. nextCam:GetOwner():Nick() .. "'s camera.")
    else
        DarkRP.notify(ply, 0, 4, #cams == 0 and "No camera is on air." or "Screen off.")
    end
end
