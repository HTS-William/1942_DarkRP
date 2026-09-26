include("shared.lua")

surface.CreateFont("RP1942_TrainTitle", { font = "Roboto", size = 64, weight = 800, extended = true })
surface.CreateFont("RP1942_TrainLine",  { font = "Roboto", size = 40, weight = 500, extended = true })

local function colors()
    local f4 = RP1942 and RP1942.F4Config and RP1942.F4Config.colors or {}
    return {
        bg     = Color(14, 13, 12, 215),
        strip  = f4.category or Color(84, 18, 18),
        text   = f4.text or Color(236, 228, 212),
        dim    = Color(170, 160, 140),
        gold   = f4.gold or Color(201, 168, 92),
        red    = Color(210, 60, 50),
    }
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
            local left = math.max(0, (ent:GetConfig().stopTime or 20) - (CurTime() - ent:GetPhaseStart()))
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
