--[[---------------------------------------------------------------------------
42Bros - Newsreel Camera: a hand-held film camera (the Propaganda Minister's)

    Left click      on air / off air: cinema screens tuned to you show what
                    you're looking at, live, and people at them hear what's
                    said and done around you
    Right click     hold to zoom in (the picture on the screen zooms too)

It goes off air when you put it away, drop it or die. While it's on air a
red ON AIR light shows on the camera for everyone. The screens, the sound and
the settings: darkrp_modules/rp1942_broadcast.

The model (models/dav0r/camera.mdl) is held up in the right hand, seen in
third person only: not in your own first person view, and not in the
picture it films. If it sits wrong in someone's hand, move it with HOLD below.
---------------------------------------------------------------------------]]
AddCSLuaFile()

SWEP.PrintName     = "Newsreel Camera"
SWEP.Author        = "42Bros"
SWEP.Instructions  = "Left click: on air / off air. Right click (hold): zoom."
SWEP.Category      = "42Bros"
SWEP.Spawnable     = true
SWEP.AdminOnly     = true

SWEP.ViewModel     = "models/weapons/c_arms.mdl"
SWEP.WorldModel    = "models/dav0r/camera.mdl"
SWEP.UseHands      = false   -- (just the camera in first person, no arms)
SWEP.HoldType      = "camera"
SWEP.Slot          = 5
SWEP.SlotPos       = 1
SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = false

SWEP.Primary   = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

local FOV_WIDE, FOV_ZOOM = 62, 28   -- the picture's field of view, normal and zoomed all the way

-- Where the camera sits in the right hand (seen in third person only)
local HOLD  = { pos = Vector(6, -3, -2), ang = Angle(0, 0, 180) }

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "OnAir")
    self:NetworkVar("Float", 0, "Zoom")   -- 0 = wide, 1 = zoomed in
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- What the broadcast films: from just in front of the holder's eyes
function SWEP:BroadcastView()
    local owner = self:GetOwner()
    if not IsValid(owner) then return self:GetPos(), self:GetAngles(), FOV_WIDE end
    local ang = owner:EyeAngles()
    return owner:EyePos() + ang:Forward() * 16, ang, Lerp(self:GetZoom(), FOV_WIDE, FOV_ZOOM)
end

-- Whose camera, for the screen's "Showing ...'s camera"
function SWEP:BroadcastName()
    local owner = self:GetOwner()
    return IsValid(owner) and owner:Nick() or "a"
end

-- On air only while it's out in someone's hands
function SWEP:Broadcasting()
    local owner = self:GetOwner()
    return self:GetOnAir() and IsValid(owner) and owner:Alive() and owner:GetActiveWeapon() == self
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.6)
    if CLIENT then return end
    self:SetOnAir(not self:GetOnAir())
    local owner = self:GetOwner()
    owner:EmitSound(self:GetOnAir() and "buttons/lever7.wav" or "buttons/lever8.wav", 60)
    DarkRP.notify(owner, 0, 4, self:GetOnAir()
        and "On air: cinema screens tuned to you show what you film, and people near them hear what's said around you."
        or "Off air.")
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end

function SWEP:Think()
    -- zoom: smoothly in while right click is held, back out when let go
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local want = owner:KeyDown(IN_ATTACK2) and 1 or 0
    local z = self:GetZoom()
    if z ~= want then
        z = math.Approach(z, want, FrameTime() * 1.5)
        self:SetZoom(z)
    end
end

-- Putting it away, dropping it or dying takes it off air
function SWEP:Holster()
    if SERVER then self:SetOnAir(false) end
    self:SetZoom(0)
    return true
end
function SWEP:OnDrop() self:SetOnAir(false) end
function SWEP:OwnerChanged() if SERVER then self:SetOnAir(false) end end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")
    local model

    local function cameraModel()
        if not IsValid(model) then
            model = ClientsideModel("models/dav0r/camera.mdl", RENDERGROUP_OPAQUE)
            if IsValid(model) then model:SetNoDraw(true) end
        end
        return model
    end

    local function redLight(pos)
        if math.floor(RealTime() * 2) % 2 == 0 then
            render.SetMaterial(glow)
            render.DrawSprite(pos, 8, 8, Color(255, 40, 30))
        end
    end

    -- In someone's hand: seen in third person only, never in the picture it's filming
    function SWEP:DrawWorldModel()
        if RP1942.broadcastFilming == self then return end
        local owner = self:GetOwner()
        local m = cameraModel()
        if not IsValid(m) then return end
        local pos, ang
        if IsValid(owner) then
            local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            local matrix = bone and owner:GetBoneMatrix(bone)
            if matrix then
                pos, ang = LocalToWorld(HOLD.pos, HOLD.ang, matrix:GetTranslation(), matrix:GetAngles())
                -- point it where they're looking, whatever the hand does
                ang = Angle(owner:EyeAngles().p, owner:EyeAngles().y, 0)
            end
        end
        if not pos then pos, ang = self:GetPos(), self:GetAngles() end
        m:SetPos(pos)
        m:SetAngles(ang)
        m:SetupBones()
        m:DrawModel()
        if self:GetOnAir() then redLight(pos + ang:Up() * 7 - ang:Forward() * 2) end
    end

    -- Not drawn in first person (just the viewfinder, below)
    function SWEP:PreDrawViewModel() return true end

    -- Zooming your own view along with the picture
    function SWEP:TranslateFOV(fov)
        return fov * Lerp(self:GetZoom(), 1, FOV_ZOOM / FOV_WIDE)
    end
    function SWEP:AdjustMouseSensitivity()
        return Lerp(self:GetZoom(), 1, FOV_ZOOM / FOV_WIDE)
    end

    -- The viewfinder: the 16:9 frame the screens show, and ON AIR
    function SWEP:DrawHUD()
        local W, H = ScrW(), ScrH()
        local fw = math.min(W * 0.8, H * 0.8 * 16 / 9)
        local fh = fw * 9 / 16
        local x, y = (W - fw) / 2, (H - fh) / 2
        local len = math.floor(fh * 0.08)
        surface.SetDrawColor(236, 228, 212, 180)
        for _, c in ipairs({ { x, y, 1, 1 }, { x + fw, y, -1, 1 }, { x, y + fh, 1, -1 }, { x + fw, y + fh, -1, -1 } }) do
            surface.DrawRect(c[3] > 0 and c[1] or c[1] - len, c[2] - (c[4] > 0 and 0 or 2), len, 2)
            surface.DrawRect(c[1] - (c[3] > 0 and 0 or 2), c[4] > 0 and c[2] or c[2] - len, 2, len)
        end
        surface.DrawRect(W / 2 - 8, H / 2, 16, 1)
        surface.DrawRect(W / 2, H / 2 - 8, 1, 16)
        local font = "RP1942_F4Head"
        if self:GetOnAir() then
            if math.floor(RealTime() * 2) % 2 == 0 then
                draw.RoundedBox(6, x + 14, y + 16, 12, 12, Color(235, 50, 40))
            end
            draw.SimpleText("ON AIR", font, x + 34, y + 22, Color(235, 70, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Off air  ·  left click to go on air", font, x + 14, y + 22, Color(236, 228, 212, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        if self:GetZoom() > 0.01 then
            draw.SimpleText(string.format("Zoom %.1fx", FOV_WIDE / Lerp(self:GetZoom(), FOV_WIDE, FOV_ZOOM)), "RP1942_F4Body",
                x + fw - 14, y + 22, Color(236, 228, 212, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end
