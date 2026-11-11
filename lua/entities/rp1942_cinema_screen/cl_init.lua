include("shared.lua")

surface.CreateFont("RP1942_CinemaBig", { font = "Roboto", size = 120, weight = 800, extended = true })
surface.CreateFont("RP1942_CinemaSmall", { font = "Roboto", size = 56, weight = 600, extended = true })

local SCALE = 0.05   -- units per pixel on the screen

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    local eye = LocalPlayer():EyePos()
    local normal = self:GetUp()   -- the face (stood up, it faces sideways)
    local center = self:WorldSpaceCenter()
    if (eye - center):Dot(normal) < 0 then normal = -normal end   -- draw on whichever face we're looking at
    local mins, maxs = self:OBBMins(), self:OBBMaxs()
    local xSize, ySize = maxs.x - mins.x, maxs.y - mins.y
    -- whichever side stands upright is the height
    local xUp = math.abs(self:GetForward().z) > math.abs(self:GetRight().z)
    local wUnits = (xUp and ySize or xSize) - 4
    local hUnits = (xUp and xSize or ySize) - 4
    local W, H = wUnits / SCALE, hUnits / SCALE
    local pos = center + normal * ((maxs.z - mins.z) / 2 + 0.3)
    local ang = Angle(0, normal:Angle().y + 90, 90)

    local cam_ = self:GetCamera()
    local live = IsValid(cam_) and cam_.Broadcasting and cam_:Broadcasting()
    local feed = live and RP1942.broadcastFeed and RP1942.broadcastFeed(cam_)
    local far = eye:DistToSqr(center) > RP1942.Broadcast.viewRange ^ 2

    cam.Start3D2D(pos, ang, SCALE)
        surface.SetDrawColor(8, 8, 8, 255)
        surface.DrawRect(-W / 2, -H / 2, W, H)
        if feed and not far then
            -- the picture, 16:9, as big as fits
            local pw, ph = W, W * 9 / 16
            if ph > H then ph = H pw = H * 16 / 9 end
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(feed.mat)
            surface.DrawTexturedRect(-pw / 2, -ph / 2, pw, ph)
            draw.SimpleText("LIVE", "RP1942_CinemaSmall", -pw / 2 + 40, -ph / 2 + 30, Color(235, 235, 235, 200))
        elseif live then
            draw.SimpleText("LIVE", "RP1942_CinemaBig", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("NO SIGNAL", "RP1942_CinemaBig", 0, -30, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("E: change channel", "RP1942_CinemaSmall", 0, 80, Color(130, 130, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end
