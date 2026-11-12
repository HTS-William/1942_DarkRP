include("shared.lua")

surface.CreateFont("RP1942_TVBig", { font = "Roboto", size = 90, weight = 800, extended = true })
surface.CreateFont("RP1942_TVSmall", { font = "Roboto", size = 44, weight = 600, extended = true })

local SCALE = 0.02   -- units per pixel on the glass

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    local eye = LocalPlayer():EyePos()
    local center = self:WorldSpaceCenter()
    if eye:DistToSqr(center) > 900 ^ 2 then return end
    local mins, maxs = self:OBBMins(), self:OBBMaxs()
    local A = self.ScreenArea
    local width, height = maxs.y - mins.y, maxs.z - mins.z
    -- the front is +X; only drawn when we're in front of it
    local localPos = Vector(maxs.x + A.out,
        (mins.y + maxs.y) / 2 + A.right * width,      -- (+Y is to the right, seen from the front)
        (mins.z + maxs.z) / 2 + A.up * height)
    local pos = self:LocalToWorld(localPos)
    if (eye - pos):Dot(self:GetForward()) < 0 then return end
    local ang = self:LocalToWorldAngles(Angle(0, 90, 90))
    local W, H = width * A.width / SCALE, height * A.height / SCALE

    local cam_ = self:GetCamera()
    local live = IsValid(cam_) and cam_.Broadcasting and cam_:Broadcasting()
    local feed = live and RP1942.broadcastFeed and RP1942.broadcastFeed(cam_)
    local far = eye:DistToSqr(center) > RP1942.Broadcast.viewRange ^ 2

    cam.Start3D2D(pos, ang, SCALE)
        surface.SetDrawColor(10, 10, 10, 255)
        surface.DrawRect(-W / 2, -H / 2, W, H)
        if feed and not far then
            -- the picture, 16:9, as big as fits (letterboxed on the 4:3 set)
            local pw, ph = W, W * 9 / 16
            if ph > H then ph = H pw = H * 16 / 9 end
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(feed.mat)
            surface.DrawTexturedRect(-pw / 2, -ph / 2, pw, ph)
            draw.SimpleText("LIVE", "RP1942_TVSmall", -pw / 2 + 24, -ph / 2 + 16, Color(235, 235, 235, 200))
        elseif live then
            draw.SimpleText("LIVE", "RP1942_TVBig", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            -- a little snow while there's nothing on
            for _ = 1, 40 do
                local g = math.random(40, 140)
                surface.SetDrawColor(g, g, g, 60)
                surface.DrawRect(math.random(-W / 2, W / 2 - 6), math.random(-H / 2, H / 2 - 6), 6, 6)
            end
            draw.SimpleText("NO SIGNAL", "RP1942_TVBig", 0, -24, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("E: change channel", "RP1942_TVSmall", 0, 52, Color(130, 130, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end
