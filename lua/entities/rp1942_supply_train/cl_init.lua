include("shared.lua")

surface.CreateFont("RP1942_TrainTitle", { font = "Roboto", size = 64, weight = 800, extended = true })
surface.CreateFont("RP1942_TrainLine",  { font = "Roboto", size = 40, weight = 500, extended = true })

local function colors()   -- the shared palette (rp1942_core/cl_theme.lua)
    local C = RP1942.col
    return { bg = C("labelBg"), strip = C("category"), text = C("text"), dim = C("dim"), gold = C("gold"), red = C("bad") }
end

local STATUS = {
    [0] = "Arriving",
    [1] = "At the station",
    [2] = "In transit",
}

local Label
local function getLabel()
    if Label or not (RP1942 and RP1942.Floater) then return Label end

    Label = RP1942.Floater:extend{
        scale    = 0.12,
        maxDist  = 1400,
        fadeDist = 300,
    }

    -- Sit above the middle of the train, whatever the model's size
    function Label:GetDrawPos(ent)
        local center = ent:OBBCenter()
        return ent:LocalToWorld(Vector(center.x, center.y, ent:OBBMaxs().z)) + Vector(0, 0, 40)
    end

    function Label:ShouldDraw(ent)
        return ent:GetPhase() ~= ent.LEAVING
    end

    function Label:Paint(ent)
        local C = colors()
        local w, h = 760, 230
        local x, y = -w / 2, -h

        draw.RoundedBox(0, x, y, w, h, C.bg)
        surface.SetDrawColor(C.strip)
        surface.DrawRect(x, y, 10, h)

        draw.SimpleText("REICH SUPPLY TRAIN", "RP1942_TrainTitle", x + 40, y + 20, C.gold)

        local status = STATUS[ent:GetPhase()] or ""
        if ent:GetPhase() == ent.STOPPED then
            local left = math.max(0, (ent:GetConfig().stopTime or 30) - (CurTime() - ent:GetPhaseStart()))
            status = status .. "  " .. string.FormattedTime(left, "%01i:%02i")
        end
        local crates = ent:GetCrates()
        draw.SimpleText(status .. "   ·   " .. crates .. (crates == 1 and " crate" or " crates") .. " aboard",
            "RP1942_TrainLine", x + 40, y + 100, C.text)

        local hint, col
        if crates <= 0 then
            hint, col = "Nothing left to take", C.dim
        elseif ent:CanRob(LocalPlayer()) then
            hint, col = "Hold E to rob a crate", C.red
        else
            hint, col = "Guard the cargo", C.dim
        end
        draw.SimpleText(hint, "RP1942_TrainLine", x + 40, y + 155, col)
    end

    return Label
end

function ENT:Draw()
    self:DrawModel()
end

-- Drawn in the translucent pass so the label layers over the model properly
function ENT:DrawTranslucent()
    local label = getLabel()
    if label then label:Draw(self) end
end

--[[---------------------------------------------------------------------------
The wheels' rumble, played here (not by the server) so it's already running
the moment the train appears for you, and for anyone who comes into range
mid-journey. On while it moves, fading out when it stops or vanishes.
---------------------------------------------------------------------------]]
function ENT:UpdateWheels()
    local c = self:GetConfig()
    local moving = self:GetPhase() == self.ARRIVING or self:GetPhase() == self.DEPARTING
    if moving and c.wheelSound then
        if not (self.wheels and self.wheels:IsPlaying()) then
            self.wheels = CreateSound(self, c.wheelSound)
            self.wheels:SetSoundLevel(c.wheelLevel or 90)
            self.wheels:Play()
        end
    elseif self.wheels and self.wheels:IsPlaying() and not self.wheelsFading then
        self.wheelsFading = true
        self.wheels:FadeOut(1)
        timer.Simple(1.1, function() if IsValid(self) then self.wheelsFading = nil end end)
    end
end

function ENT:Think()
    self:UpdateWheels()
end

function ENT:OnRemove()
    if self.wheels then self.wheels:Stop() end
end

