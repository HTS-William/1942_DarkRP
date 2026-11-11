--[[---------------------------------------------------------------------------
42Bros - Weapon Checker (instead of DarkRP's weaponchecker)

Look at a player up close:
    Left click    pat them down: the weapons they carry
    Right click   search their pockets too (takes longer)
    Reload        give back what was confiscated from them
Stay next to them while the bar fills. The list that opens lets you
confiscate weapons, shipments and ammo. Settings and the rest:
darkrp_modules/rp1942_search.
---------------------------------------------------------------------------]]
AddCSLuaFile()

SWEP.PrintName     = "Weapon Checker"
SWEP.Author        = "42Bros"
SWEP.Instructions  = "Left click: pat down. Right click: search pockets. Reload: give back what was confiscated."
SWEP.Category      = "42Bros"
SWEP.Spawnable     = true
SWEP.AdminOnly     = true

SWEP.ViewModel     = "models/weapons/c_arms.mdl"
SWEP.WorldModel    = ""
SWEP.UseHands      = true
SWEP.HoldType      = "normal"
SWEP.Slot          = 1
SWEP.SlotPos       = 4
SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = true

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:SetupDataTables()
    self:NetworkVar("Entity", 0, "Target")
    self:NetworkVar("Float", 0, "SearchStart")
    self:NetworkVar("Float", 1, "SearchEnd")
    self:NetworkVar("Bool", 0, "Pockets")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- The player we're looking at, close enough to search
function SWEP:Aimed()
    local owner = self:GetOwner()
    local range = RP1942.Search and RP1942.Search.range or 110
    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * range,
        filter = owner,
    })
    local ent = tr.Entity
    if IsValid(ent) and ent:IsPlayer() and ent:Alive() then return ent end
end

function SWEP:Begin(pockets)
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self:SetNextSecondaryFire(CurTime() + 0.5)
    if IsValid(self:GetTarget()) then return end
    local target = self:Aimed()
    if not target then return end
    if CLIENT then return end
    local secs = RP1942.searchBegin(self:GetOwner(), target, pockets and "pocket" or "pat")
    self:SetTarget(target)
    self:SetPockets(pockets)
    self:SetSearchStart(CurTime())
    self:SetSearchEnd(CurTime() + secs)
    self:GetOwner():EmitSound("npc/combine_soldier/gear" .. math.random(1, 6) .. ".wav", 55)
end

function SWEP:PrimaryAttack() self:Begin(false) end
function SWEP:SecondaryAttack() self:Begin(true) end

function SWEP:Reload()
    if CLIENT or (self.nextReload or 0) > CurTime() then return end
    self.nextReload = CurTime() + 1
    local target = self:Aimed()
    if target then RP1942.searchGiveBack(self:GetOwner(), target) end
end

function SWEP:Cancel(reason)
    local target = self:GetTarget()
    if SERVER and IsValid(target) then RP1942.searchStop(self:GetOwner(), target, reason) end
    self:SetTarget(NULL)
end

function SWEP:Think()
    if CLIENT then return end
    local target = self:GetTarget()
    if not IsValid(target) then
        if target ~= NULL then self:SetTarget(NULL) end
        return
    end
    if not RP1942.searchValid(self:GetOwner(), target) then
        return self:Cancel("They're too far away: the search stopped.")
    end
    if CurTime() >= self:GetSearchEnd() then
        self:SetTarget(NULL)
        RP1942.searchFinish(self:GetOwner(), target, self:GetPockets() and "pocket" or "pat")
    end
end

function SWEP:Holster()
    if IsValid(self:GetTarget()) then self:Cancel("You put the checker away: the search stopped.") end
    return true
end
function SWEP:OnRemove() if IsValid(self:GetTarget()) then self:Cancel() end end

if CLIENT then
    -- the bar while searching, or what to do
    function SWEP:DrawHUD()
        local UI = RP1942.F4UI
        local C = UI and UI.C or { text = color_white, sub = Color(160, 152, 136), card = Color(38, 35, 31), button = Color(128, 26, 24), gold = Color(201, 168, 92) }
        local w, h = math.floor(ScrW() * 0.22), math.max(18, math.floor(ScrH() * 0.022))
        local x, y = ScrW() / 2 - w / 2, ScrH() * 0.62
        local target = self:GetTarget()
        if IsValid(target) then
            local f = math.Clamp((CurTime() - self:GetSearchStart()) / math.max(0.01, self:GetSearchEnd() - self:GetSearchStart()), 0, 1)
            draw.RoundedBox(4, x, y, w, h, C.card)
            draw.RoundedBox(4, x, y, w * f, h, C.button)
            draw.SimpleText((self:GetPockets() and "Searching the pockets of " or "Patting down ") .. target:Nick(), "RP1942_F4Body",
                ScrW() / 2, y - 4, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        elseif self:Aimed() then
            draw.SimpleText("Left click: pat down    Right click: search pockets    R: give back", "RP1942_F4Body",
                ScrW() / 2, y, C.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end
end
