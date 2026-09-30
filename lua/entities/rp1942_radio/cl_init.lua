include("shared.lua")

surface.CreateFont("RP1942_RadioName", { font = "Roboto", size = 28, weight = 800, extended = true })
surface.CreateFont("RP1942_RadioSub",  { font = "Roboto", size = 20, weight = 600, extended = true })

local GOLD, TEXT, SUB = Color(201, 168, 92), Color(236, 228, 212), Color(170, 162, 146)
local master  = CreateClientConVar("rp1942_radio_volume", "1", true, false, "Your volume for every radio (0-1)", 0, 1)
local enabled = CreateClientConVar("rp1942_radio", "1", true, false, "Hear the radios (0 = silence them all)", 0, 1)

function ENT:Initialize()
    self.curURL = ""
end

-- Start / stop the stream when the station changes
function ENT:Think()
    local url = enabled:GetBool() and self:GetURL() or ""
    if url ~= self.curURL then
        self:StopStream()
        self.curURL = url
        if url ~= "" then self:StartStream(url) end
    end
    if IsValid(self.channel) then
        self.channel:SetPos(self:GetPos())
        local vol = self:GetVolume() * master:GetFloat()
        self.channel:SetVolume(vol)
    end
    self:SetNextClientThink(CurTime() + 0.1)
    return true
end

function ENT:StartStream(url)
    local range = RP1942.radioSetting and RP1942.radioSetting("range") or 900
    local near  = RP1942.radioSetting and RP1942.radioSetting("nearRange") or 150
    self.loading = true
    sound.PlayURL(url, "3d noblock", function(chan, err, name)
        if not IsValid(self) or self.curURL ~= url then
            if IsValid(chan) then chan:Stop() end
            return
        end
        self.loading = false
        if not IsValid(chan) then
            self.failed = name or tostring(err)
            return
        end
        self.failed = nil
        chan:Set3DFadeDistance(near, range)
        chan:SetPos(self:GetPos())
        chan:SetVolume(self:GetVolume() * master:GetFloat())
        chan:Play()
        self.channel = chan
    end)
end

function ENT:StopStream()
    if IsValid(self.channel) then self.channel:Stop() end
    self.channel = nil
    self.loading = false
    self.failed = nil
end

function ENT:OnRemove()
    self:StopStream()
end

function ENT:Draw()
    self:DrawModel()
    local eye = LocalPlayer():EyePos()
    local top = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 6)
    if eye:DistToSqr(top) > 350 * 350 then return end

    local ang = (eye - top):Angle()
    ang = Angle(0, ang.y + 90, 90)
    local station, line = self:GetStation(), "Press E to tune"
    local col = SUB
    if station == "BROKEN" then
        station, line, col = "Radio", "Broken", Color(220, 70, 60)
    elseif self:GetURL() ~= "" then
        if self.loading then line = "Tuning in..."
        elseif self.failed then line, col = "No signal (" .. tostring(self.failed) .. ")", Color(220, 70, 60)
        elseif not enabled:GetBool() then line = "Muted (rp1942_radio 0)"
        else line = "Playing  ·  E to tune" end
    else
        station = "Radio"
    end
    cam.Start3D2D(top, ang, 0.08)
        draw.SimpleTextOutlined(station ~= "" and station or "Radio", "RP1942_RadioName", 0, 0, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, 200))
        draw.SimpleTextOutlined(line, "RP1942_RadioSub", 0, 4, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 200))
    cam.End3D2D()
end
