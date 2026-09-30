AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local good = self:GoodInfo()
    local models = good and (istable(good.model) and good.model or { good.model }) or { "models/props_junk/cardboard_box004a.mdl" }
    -- Keep the model it already has (taken out of a pocket), otherwise pick one
    local current = string.lower(self:GetModel() or "")
    local keep = false
    for _, m in ipairs(models) do if string.lower(m) == current then keep = true end end
    if not keep then self:SetModel(models[math.random(#models)]) end
    if self:GetQuality() < 1 then self:SetQuality(2) end
    if self:IsRadio() and self:GetVolume() <= 0 then self:SetVolume(1) end
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local good = self:GoodInfo()
    if not good then return end

    -- Shift + E: eat or drink it
    if ply:KeyDown(IN_SPEED) and good.eat then
        local eat = good.eat
        if eat.heal and eat.heal > 0 then
            ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + eat.heal))
        end
        if eat.drunk and eat.drunk > 0 then
            net.Start("RP1942_Drunk")
            net.WriteFloat(eat.drunk)
            net.Send(ply)
        end
        self:EmitSound(eat.verb == "drink" and "npc/barnacle/barnacle_gulp1.wav" or "npc/barnacle/barnacle_crunch2.wav", 65)
        self:Remove()
        return
    end

    -- A radio: E tunes it, Shift + E carries it
    if self:IsRadio() and not ply:KeyDown(IN_SPEED) then
        if RP1942.radioOpenMenu then RP1942.radioOpenMenu(ply, self) end
        return
    end

    -- E: carry it
    self.RP1942_Holder = ply
    ply:PickupObject(self)
end

-- Radio Set: tune it (server side; validated). Same as rp1942_radio's.
function ENT:Tune(url, name, volume)
    if not self:IsRadio() then return false end
    url = string.Trim(url or "")
    if url ~= "" and not RP1942.radioValidUrl(url) then return false end
    self:SetURL(url)
    self:SetStation(url == "" and "" or (name and name ~= "" and name or "Custom station"))
    if volume then self:SetVolume(math.Clamp(tonumber(volume) or 1, 0, 1)) end
    return true
end

-- Pushed into a market: sold (a tick later, never inside the physics callback)
function ENT:PhysicsCollide(data)
    local other = data.HitEntity
    if IsValid(other) and other:GetClass() == "rp1942_market" and not self.RP1942_Sold then
        timer.Simple(0, function()
            if IsValid(self) and RP1942.sellGoodEntity then RP1942.sellGoodEntity(self) end
        end)
    end
end
