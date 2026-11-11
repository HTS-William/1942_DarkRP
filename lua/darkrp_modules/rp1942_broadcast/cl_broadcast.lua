--[[---------------------------------------------------------------------------
42Bros - live broadcasts (client). See sh_broadcast.lua.

Each camera on air that a nearby screen is showing is filmed into its own
render target (at most 2 at once, `fps` times a second), turned black and
white with a little grain, flicker and dark corners, and the screen draws it.
---------------------------------------------------------------------------]]
local CFG = RP1942.Broadcast

local feeds = {}       -- [camera entindex] = { rt, mat, last }
local rendering = false

function RP1942.broadcastFeed(camera)
    if not IsValid(camera) then return nil end
    local f = feeds[camera:EntIndex()]
    return f and f.ready and f or nil
end

local function feedFor(camera)
    local id = camera:EntIndex()
    local f = feeds[id]
    if not f then
        local rt = GetRenderTarget("rp1942_bcast_" .. id, CFG.width, CFG.height)
        local mat = CreateMaterial("rp1942_bcast_mat_" .. id, "UnlitGeneric", {
            ["$basetexture"] = rt:GetName(),
            ["$vertexcolor"] = 1,
        })
        f = { rt = rt, mat = mat, last = 0 }
        feeds[id] = f
    end
    return f
end

local BW = {
    ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0, ["$pp_colour_contrast"] = 1.15, ["$pp_colour_colour"] = 0,
    ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
}

local function film(camera, f)   -- (not `cam`: that's the cam library)
    local W, H = CFG.width, CFG.height
    render.PushRenderTarget(f.rt)
    render.Clear(0, 0, 0, 255, true, true)
    rendering = true
    local origin, angles, fov = camera:BroadcastView()
    render.RenderView({
        origin = origin,
        angles = angles,
        x = 0, y = 0, w = W, h = H,
        fov = fov or CFG.fov,
        drawviewer = true, drawhud = false, drawmonitors = false, drawviewmodel = false,
        dopostprocess = false,
        znear = 4,
    })
    rendering = false

    -- black and white, with a slight flicker
    BW["$pp_colour_brightness"] = math.Rand(-0.04, 0.02)
    DrawColorModify(BW)

    -- grain, scratches and dark corners
    cam.Start2D()
        for _ = 1, 60 do
            local g = math.random(0, 255)
            surface.SetDrawColor(g, g, g, math.random(10, 35))
            surface.DrawRect(math.random(0, W), math.random(0, H), 1, 1)
        end
        if math.random() < 0.15 then
            surface.SetDrawColor(220, 220, 220, 40)
            surface.DrawRect(math.random(0, W), 0, 1, H)
        end
        for i = 0, 5 do
            local a = 60 - i * 10
            surface.SetDrawColor(0, 0, 0, a)
            surface.DrawOutlinedRect(i * 4, i * 4, W - i * 8, H - i * 8, 4)
        end
    cam.End2D()
    render.PopRenderTarget()
    f.ready = true
end

-- Film the cameras the nearby screens are showing (not from inside another render)
hook.Add("PreRender", "RP1942_Broadcast", function()
    if rendering then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local eye = lp:EyePos()
    local range = CFG.viewRange ^ 2
    local wanted, n = {}, 0
    for _, screen in ipairs(ents.FindByClass("rp1942_cinema_screen")) do
        local camera = screen:GetCamera()
        if IsValid(camera) and camera.Broadcasting and camera:Broadcasting() and not wanted[camera] and eye:DistToSqr(screen:GetPos()) <= range then
            -- only if the screen is somewhere in front of us
            if (screen:GetPos() - eye):GetNormalized():Dot(lp:EyeAngles():Forward()) > -0.2 then
                wanted[camera] = true
                n = n + 1
                if n > 2 then break end
            end
        end
    end
    local now = RealTime()
    for camera in pairs(wanted) do
        local f = feedFor(camera)
        if now - f.last >= 1 / CFG.fps then
            f.last = now
            film(camera, f)
        end
    end
end)

-- Sounds from around a camera, played at the screen
net.Receive("RP1942_BcastSound", function()
    local screen = net.ReadEntity()
    local name = net.ReadString()
    local level = net.ReadUInt(8)
    local pitch = net.ReadUInt(8)
    local volume = net.ReadFloat()
    if not IsValid(screen) then return end
    sound.Play(name, screen:GetPos() + screen:GetUp() * 10, math.min(level, 80), pitch, volume * 0.85)
end)
