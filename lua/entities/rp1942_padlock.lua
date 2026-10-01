--[[---------------------------------------------------------------------------
1942 DarkRP - a padlock, fixed to a prop it turns into a door.
Fitted with the Padlock (rp1942_padlock_kit); everything it does is in
darkrp_modules/rp1942_padlocks. Removing it (remover tool, !removelock)
turns the prop back into a plain prop.
---------------------------------------------------------------------------]]
AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Padlock"
ENT.Author    = "1942 DarkRP"
ENT.Spawnable = false
ENT.DoNotDuplicate = true

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Door")
    self:NetworkVar("Entity", 1, "LockOwner")
    self:NetworkVar("String", 0, "OwnerName")
    self:NetworkVar("Bool",   0, "Staff")     -- a staff lock: no owner, opened by faction / unit
    self:NetworkVar("Bool",   1, "Open")
    self:NetworkVar("Bool",   2, "Broken")    -- shot off: the door is open until it's whole again
    self:NetworkVar("Int",    0, "LockHealth")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel(RP1942.Padlocks.MODEL)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_OBB)               -- small, but E and the lockpick can hit it
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:DrawShadow(false)
        self:SetUseType(SIMPLE_USE)
    end

    function ENT:OnRemove()
        if RP1942.padlockRemoved then RP1942.padlockRemoved(self) end
    end

    function ENT:OnTakeDamage(dmg)
        if RP1942.padlockDamaged then RP1942.padlockDamaged(self, dmg) end
    end
    return
end

-- Client: the label, up close
surface.CreateFont("RP1942_PadlockName", { font = "Roboto", size = 26, weight = 800, extended = true })
surface.CreateFont("RP1942_PadlockSub",  { font = "Roboto", size = 19, weight = 600, extended = true })
local GOLD, SUB, GREEN = RP1942.col("gold"), Color(200, 192, 176), Color(130, 190, 100)

function ENT:Draw()
    self:DrawModel()
    local eye = LocalPlayer():EyePos()
    local pos = self:GetPos() + Vector(0, 0, 9)
    if eye:DistToSqr(pos) > 140 * 140 then return end
    local ang = (eye - pos):Angle()
    ang = Angle(0, ang.y + 90, 90)

    local title = self:GetStaff() and "Padlock" or (self:GetOwnerName() ~= "" and (self:GetOwnerName() .. "'s padlock") or "Padlock")
    local line, col
    if self:GetBroken() then
        line, col = "Broken", Color(220, 80, 64)
    elseif self:GetOpen() then
        line, col = "Open", GREEN
    else
        line, col = "E  open / knock", SUB
        local lp = LocalPlayer()
        if self:GetLockOwner() == lp then line = "E  open   ·   Shift+E  settings" end
    end
    cam.Start3D2D(pos, ang, 0.06)
        draw.SimpleTextOutlined(title, "RP1942_PadlockName", 0, 0, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, 210))
        draw.SimpleTextOutlined(line, "RP1942_PadlockSub", 0, 4, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 210))
        -- Health bar, while padlocks can be shot (the "shootable" setting)
        if GetGlobal2Bool("RP1942_PadlockShootable", false) then
            local max = math.max(GetGlobal2Int("RP1942_PadlockHealth", 200), 1)
            local frac = self:GetBroken() and 0 or math.Clamp(self:GetLockHealth() / max, 0, 1)
            local bw, bh, by = 140, 10, 34
            draw.RoundedBox(3, -bw / 2 - 2, by - 2, bw + 4, bh + 4, Color(0, 0, 0, 200))
            draw.RoundedBox(2, -bw / 2, by, bw, bh, Color(58, 54, 48))
            if frac > 0 then
                local c = Color(Lerp(frac, 214, 120), Lerp(frac, 70, 176), Lerp(frac, 58, 92))
                draw.RoundedBox(2, -bw / 2, by, math.max(4, bw * frac), bh, c)
            end
        end
    cam.End3D2D()
end
