AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local m = RP1942.radioSetting and RP1942.radioSetting("model") or "models/props_lab/citizenradio.mdl"
    if not util.IsValidModel(m) then m = "models/props_lab/citizenradio.mdl" end
    self:SetModel(m)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    if self:GetVolume() <= 0 then self:SetVolume(1) end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if RP1942.radioOpenMenu then RP1942.radioOpenMenu(ply, self) end
end

-- Tune it (server side; validated). name may be nil for a custom link.
function ENT:Tune(url, name, volume)
    url = string.Trim(url or "")
    if url ~= "" and not RP1942.radioValidUrl(url) then return false end
    self:SetURL(url)
    self:SetStation(url == "" and "" or (name and name ~= "" and name or "Custom station"))
    if volume then self:SetVolume(math.Clamp(tonumber(volume) or 1, 0, 1)) end
    if RP1942.prodUpdateSave then RP1942.prodUpdateSave(self) end   -- a saved set remembers its station
    return true
end

-- What !saveprod stores with it, and gets back on restart
function ENT:RP1942_SaveData()
    return { url = self:GetURL(), station = self:GetStation(), volume = self:GetVolume() }
end
function ENT:RP1942_LoadData(d)
    if not istable(d) then return end
    self:SetURL(d.url or "")
    self:SetStation(d.station or "")
    self:SetVolume(math.Clamp(tonumber(d.volume) or 1, 0, 1))
end

function ENT:OnTakeDamage(dmg)
    -- it can be broken: 200 damage and it's silent for good
    self.Health = (self.Health or 200) - dmg:GetDamage()
    if self.Health <= 0 and not self.Broken then
        self.Broken = true
        self:SetURL("")
        self:SetStation("BROKEN")
        self:EmitSound("physics/metal/metal_box_break1.wav", 70)
    end
end
