--[[---------------------------------------------------------------------------
1942 DarkRP - production (client): the drunk effect after a bottle of wine
The server sends how many seconds; more bottles stack (up to a minute).
---------------------------------------------------------------------------]]
local drunkUntil = 0

net.Receive("RP1942_Drunk", function()
    local seconds = net.ReadFloat()
    drunkUntil = math.min(math.max(drunkUntil, CurTime()) + seconds, CurTime() + 60)
end)

hook.Add("RenderScreenspaceEffects", "RP1942_Drunk", function()
    local left = drunkUntil - CurTime()
    if left <= 0 then return end
    local strength = math.Clamp(left / 20, 0, 1)   -- fades out over the last 20 seconds
    DrawMotionBlur(0.08, 0.85 * strength, 0.01)
    DrawColorModify({
        ["$pp_colour_addr"] = 0.02 * strength, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0, ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 1 + 0.25 * strength,
        ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
    })
end)

-- Dying sobers you up
gameevent.Listen("entity_killed")
hook.Add("entity_killed", "RP1942_DrunkReset", function(data)
    if data.entindex_killed == LocalPlayer():EntIndex() then drunkUntil = 0 end
end)

--[[---------------------------------------------------------------------------
The floating card over ovens, barrels, markets and goods (same style as the
dumpster's). An entity only says what's on it:

    function ENT:LabelInfo()
        return { title = "BREAD OVEN", lines = { "Baking  ·  1:23" },
                 progress = 0.4, accent = Color(...) }   -- progress / accent optional
    end
    function ENT:Draw() self:DrawModel(); RP1942.drawProductionLabel(self) end
---------------------------------------------------------------------------]]
surface.CreateFont("RP1942_ProdTitle", { font = "Roboto", size = 32, weight = 800, extended = true })
surface.CreateFont("RP1942_ProdLine",  { font = "Roboto", size = 24, weight = 500, extended = true })

local Label
local function getLabel()
    if Label or not RP1942.Floater then return Label end
    Label = RP1942.Floater:extend{
        scale    = 0.08,
        maxDist  = RP1942.Production.labelDistance or 350,
        fadeDist = 80,
    }
    function Label:GetDrawPos(ent)
        local c = ent:OBBCenter()
        return ent:LocalToWorld(Vector(c.x, c.y, ent:OBBMaxs().z)) + Vector(0, 0, ent.LabelHeight or 16)
    end
    function Label:Paint(ent)
        local info = ent:LabelInfo()
        if not info then return end
        local C = RP1942.col   -- rp1942_core/cl_theme.lua
        local lines = info.lines or {}
        surface.SetFont("RP1942_ProdTitle")   -- the title in its own (bigger) font
        local w = select(1, surface.GetTextSize(info.title or "")) + 44
        surface.SetFont("RP1942_ProdLine")
        for _, l in ipairs(lines) do w = math.max(w, select(1, surface.GetTextSize(l)) + 44) end
        w = math.max(w, 260)
        local h = 50 + #lines * 30 + (info.progress and 18 or 0)
        local x, y = -w / 2, -h

        draw.RoundedBox(0, x, y, w, h, C("labelBg"))
        surface.SetDrawColor(info.accent or C("gold"))
        surface.DrawRect(x, y, 6, h)
        draw.SimpleText(info.title or "", "RP1942_ProdTitle", x + 22, y + 8, C("text"))
        for i, l in ipairs(lines) do
            draw.SimpleText(l, "RP1942_ProdLine", x + 22, y + 14 + i * 30, C("dim"))
        end
        if info.progress then
            local bx, by, bw = x + 22, y + h - 20, w - 44
            surface.SetDrawColor(C("well"))
            surface.DrawRect(bx, by, bw, 8)
            surface.SetDrawColor(info.accent or C("gold"))
            surface.DrawRect(bx, by, math.floor(bw * math.Clamp(info.progress, 0, 1)), 8)
        end
    end
    return Label
end

function RP1942.drawProductionLabel(ent)
    local label = getLabel()
    if label then label:Draw(ent) end
end

-- "1:23"
function RP1942.clock(seconds)
    return string.FormattedTime(math.max(0, seconds), "%01i:%02i")
end

--[[---------------------------------------------------------------------------
Interactive panels (ovens, wine barrels, markets): look at a button, press E.

An entity's cl_init.lua sets:
    ENT.PanelSize  = { w = 560, h = 600 }     canvas size in pixels
    ENT.PanelScale = 0.045                    world units per pixel
    function ENT:PaintPanel(P, w, h) ... end  draw with P's helpers (below)
    function ENT:Draw() self:DrawModel(); RP1942.drawPanel(self) end

Where it sits: RP1942.PanelSpots[class] = { pos = Vector(...), ang = Angle(...) }
(local to the prop) fixes it ONTO the prop, e.g. on the oven door. Without a
spot it floats above the prop, turned towards you.

P's helpers (all positions in canvas pixels):
    P:Title(text, accent)                        header strip
    P:Text(text, font, x, y, color, alignX)
    P:Bar(x, y, w, h, fraction, color)
    P:Stars(x, y, quality, size)
    P:Button(id, x, y, w, h, label, { enabled =, color = })
        pressing E while it's highlighted sends id to ENT:OnPanelPress(ply, id)
        on the server
---------------------------------------------------------------------------]]
RP1942.PanelSpots = RP1942.PanelSpots or {}

local function font(name, size, weight)
    surface.CreateFont(name, { font = "Roboto", size = size, weight = weight, extended = true })
end
font("RP1942_PanelTitle",  34, 800)
font("RP1942_PanelHead",   21, 800)
font("RP1942_PanelBody",   22, 500)
font("RP1942_PanelSmall",  18, 500)
font("RP1942_PanelButton", 23, 800)

local COL = {
    bg      = Color(18, 17, 15, 235),
    header  = Color(30, 28, 25, 250),
    text    = Color(236, 228, 212),
    dim     = Color(170, 160, 142),
    faint   = Color(110, 104, 94),
    well    = Color(40, 37, 33),
    gold    = Color(214, 176, 92),
    button  = Color(52, 48, 42),
    disabled= Color(34, 32, 29),
}
RP1942.PanelColors = COL

local Painter = {}
Painter.__index = Painter

function Painter:Title(text, accent)
    self.accent = accent or COL.gold
    surface.SetDrawColor(COL.header)
    surface.DrawRect(0, 0, self.w, 58)
    surface.SetDrawColor(self.accent)
    surface.DrawRect(0, 0, 8, self.h)
    draw.SimpleText(text, "RP1942_PanelTitle", 28, 29, COL.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function Painter:Text(text, fnt, x, y, color, alignX)
    draw.SimpleText(text, fnt or "RP1942_PanelBody", x, y, color or COL.text, alignX or TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function Painter:Bar(x, y, w, h, frac, color)
    surface.SetDrawColor(COL.well)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(color or self.accent or COL.gold)
    surface.DrawRect(x, y, math.floor(w * math.Clamp(frac or 0, 0, 1)), h)
end

-- A five-pointed star as triangles (fonts may not have the star character)
local function star(cx, cy, r, color)
    draw.NoTexture()
    surface.SetDrawColor(color)
    local pts = {}
    for i = 0, 9 do
        local a = math.rad(-90 + i * 36)
        local rr = (i % 2 == 0) and r or r * 0.45
        pts[i] = { x = cx + math.cos(a) * rr, y = cy + math.sin(a) * rr }
    end
    for i = 0, 9 do
        local a, b = pts[i], pts[(i + 1) % 10]
        surface.DrawPoly({ { x = cx, y = cy }, a, b })
        surface.DrawPoly({ { x = cx, y = cy }, b, a })   -- either winding shows
    end
end

function Painter:Stars(x, y, quality, size)
    size = size or 24
    for i = 1, 3 do
        star(x + (i - 1) * (size + 6) + size / 2, y + size / 2, size / 2, i <= (quality or 0) and COL.gold or COL.well)
    end
    return 3 * (size + 6)
end

function Painter:Button(id, x, y, w, h, label, opts)
    opts = opts or {}
    local enabled = opts.enabled ~= false
    local hot = enabled and self.cx and self.cx >= x and self.cx <= x + w and self.cy >= y and self.cy <= y + h
    if hot then self.hover = id end

    local base = enabled and (opts.color or self.accent or COL.button) or COL.disabled
    local fill = hot and Color(math.min(base.r + 40, 255), math.min(base.g + 40, 255), math.min(base.b + 40, 255)) or base
    surface.SetDrawColor(fill)
    surface.DrawRect(x, y, w, h)
    if hot then
        surface.SetDrawColor(COL.text)
        surface.DrawOutlinedRect(x, y, w, h, 3)
    end
    draw.SimpleText(label, "RP1942_PanelButton", x + w / 2, y + h / 2, enabled and COL.text or COL.faint,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- A control you draw yourself (a round push-button, a dial...): registers
-- the hover like P:Button does, and says whether it's highlighted
function Painter:Hot(id, x, y, w, h, enabled)
    local hot = enabled ~= false and self.cx and self.cx >= x and self.cx <= x + w and self.cy >= y and self.cy <= y + h
    if hot then self.hover = id end
    return hot
end

-- Which way each side of the model's box faces (local yaw). Source props face +X.
local FACE_YAW = { front = 0, left = 90, back = 180, right = -90 }

--[[---------------------------------------------------------------------------
Where the panel is: its top-left corner, angles and scale, fitted to the
model's box so it works for any prop. RP1942.PanelSpots[class]:
    mount = "backguard"  standing up along the back edge of the top, facing
                         front, like a cooker's control panel (default)
            "face"       flat on one side of the box
            "top"        lying flat on top, readable from the `face` side
    face  = "front" | "left" | "back" | "right"   which way it faces
    width = share of that side's width the panel takes (0.45)
    top   = "face" only: its top edge, as a share of the side's height (0.95)
    nudge = { right, up, out } in units, from the tuning commands
    size  = extra size multiplier, from the tuning commands
No spot for a class: the panel floats above the prop, turned towards you.
---------------------------------------------------------------------------]]
local function spotPlacement(ent, spot, size)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local c = (mins + maxs) / 2
    local yaw = FACE_YAW[spot.face or "front"] or 0
    local n = Angle(0, yaw, 0):Forward()         -- out of that side
    local t = Angle(0, yaw + 90, 0):Forward()    -- to the viewer's right (Source's +Y is left, so facing -X it's +Y)

    -- Extent of the box along n (depth) and t (half width)
    local depth, halfW = 0, 0
    for _, x in ipairs({ mins.x, maxs.x }) do for _, y in ipairs({ mins.y, maxs.y }) do
        local v = Vector(x, y, c.z) - c
        depth = math.max(depth, v:Dot(n)); halfW = math.max(halfW, math.abs(v:Dot(t)))
    end end

    local nudge = spot.nudge or { 0, 0, 0 }

    if spot.mount == "top" then
        -- Lying on the top face: canvas x to the viewer's right, canvas y
        -- towards the viewer (so its top edge is at the back). Fitted to the
        -- top face (width share of both its sides), then scaled by size.
        local share = spot.width or 0.9
        local scale = math.min(2 * halfW * share / size.w, 2 * depth * share / size.h) * (spot.size or 1)
        local pw, ph = size.w * scale, size.h * scale
        local topCenter = Vector(c.x, c.y, maxs.z + 0.3)
        local origin = topCenter - t * (pw / 2) - n * (ph / 2) + t * nudge[1] + n * nudge[3] + Vector(0, 0, nudge[2])
        return ent:LocalToWorld(origin), ent:LocalToWorldAngles(Angle(0, yaw + 90, 0)), scale, true
    end

    local pw = 2 * halfW * (spot.width or 0.45) * (spot.size or 1)
    local scale = pw / size.w
    local ph = size.h * scale

    local base
    if (spot.mount or "backguard") == "backguard" then
        -- Standing on the top surface, at the back, rising upwards
        base = c - n * (depth - 1.5) + Vector(0, 0, maxs.z - c.z + ph)
    else
        local height = maxs.z - mins.z
        local topZ = mins.z + height * (spot.top or 0.95)
        base = c + n * (depth + 0.4) + Vector(0, 0, topZ - c.z)
    end
    local origin = base - t * (pw / 2) + t * nudge[1] + Vector(0, 0, nudge[2]) + n * nudge[3]
    local ang = Angle(0, yaw + 90, 90)
    return ent:LocalToWorld(origin), ent:LocalToWorldAngles(ang), scale, true
end

local function placement(ent)
    local size, scale = ent.PanelSize, ent.PanelScale or 0.045
    local spot = RP1942.PanelSpots[ent:GetClass()]
    if spot then return spotPlacement(ent, spot, size) end
    -- Floating: centred above the prop, turned towards the viewer
    local c = ent:OBBCenter()
    local top = ent:LocalToWorld(Vector(c.x, c.y, ent:OBBMaxs().z)) + Vector(0, 0, (ent.PanelLift or 10) + size.h * scale)
    local yaw = (top - LocalPlayer():EyePos()):Angle().y
    local ang = Angle(0, yaw - 90, 90)
    return top - ang:Forward() * (size.w * scale / 2), ang, scale, false
end

-- The crosshair's position on the panel, in pixels (nil = not on it / too far)
local function cursor(pos, ang, scale, w, h)
    local lp = LocalPlayer()
    local eye, dir = lp:EyePos(), lp:GetAimVector()
    local normal = ang:Up()
    if dir:Dot(normal) >= 0 then return end   -- looking at the back of it
    local hit = util.IntersectRayWithPlane(eye, dir, pos, normal)
    local reach = RP1942.Production.useDistance or 120
    if not hit or hit:DistToSqr(eye) > reach * reach then return end
    local d = hit - pos
    local x, y = d:Dot(ang:Forward()) / scale, d:Dot(ang:Right()) / scale
    if x < 0 or y < 0 or x > w or y > h then return end
    return x, y
end

--[[---------------------------------------------------------------------------
Drawing a panel. Painting a brass plate is hundreds of shapes, so it isn't
painted every frame: each panel is painted into its own texture (a render
target) a few times a second, and every frame just shows that texture
(one quad). It repaints quickly while you're looking at it, so buttons still
react at once, and slowly otherwise. ENT:PanelFast() returning true (e.g. a
wheel turning) makes it repaint quickly too.

    rp1942_panel_cache 0     paint every frame instead (to compare)
    rp1942_panel_idlefps 8   repaints per second when nobody's looking at it
---------------------------------------------------------------------------]]
local cacheCvar = CreateClientConVar("rp1942_panel_cache", "1", true, false, "Cache production panels in textures (faster)")
local idleCvar = CreateClientConVar("rp1942_panel_idlefps", "8", true, false, "Production panel repaints per second when not looked at", 1, 30)
local LOOK_FPS, FAST_FPS = 30, 20

-- Coverage-correct alpha while painting into a texture (so see-through
-- touches like the brass sheen don't punch holes in the panel)
local function blendOn()
    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD)
end
local function blendOff() render.OverrideBlend(false) end

--[[---------------------------------------------------------------------------
Textures are pooled by SIZE, not owned by an entity for good: a render target
can never be freed, so one per machine ever seen would keep growing. A panel
that hasn't been drawn for a few seconds (out of range, behind you, removed)
gives its texture back, and the next panel of that size takes it. So the
pool only ever holds as many textures as panels on screen at once.
---------------------------------------------------------------------------]]
local pools = {}          -- "WxH" -> list of { rt =, mat =, owner =, used = }
local RELEASE_AFTER = 4   -- seconds unseen before a texture may be reused

local function panelTexture(ent, w, h)
    local key = w .. "x" .. h
    local pool = pools[key]
    if not pool then pool = {} pools[key] = pool end
    local now = RealTime()
    local free
    for _, t in ipairs(pool) do
        if t.owner == ent then t.used = now return t end
        if not free and (not IsValid(t.owner) or now - t.used > RELEASE_AFTER) then free = t end
    end
    local t = free
    if not t then
        local id = key .. "_" .. (#pool + 1)
        local rt = GetRenderTargetEx("rp1942_panel_" .. id, w, h, RT_SIZE_OFFSCREEN, MATERIAL_RT_DEPTH_NONE,
            bit.bor(4, 8, 256), 0, IMAGE_FORMAT_RGBA8888)   -- clamp S/T, no mipmaps
        local mat = CreateMaterial("rp1942_panelmat_" .. id, "UnlitGeneric", {
            ["$basetexture"] = rt:GetName(), ["$translucent"] = "1", ["$vertexalpha"] = "1", ["$vertexcolor"] = "1",
        })
        t = { rt = rt, mat = mat }
        pool[#pool + 1] = t
    end
    t.owner, t.used = ent, now
    ent._panelPainted = nil   -- a texture that was someone else's: paint before showing
    return t
end

-- Hidden behind a wall (or a prop)? Checked a few times a second, not every
-- frame: ENT:Draw only culls what's outside the view, not what's behind
-- something, so without this a panel in the next room still repaints.
local function occluded(ent, eye, pos)
    local now = RealTime()
    local o = ent._panelOcc
    if o and now - o.t < 0.3 then return o.hidden end
    local tr = util.TraceLine({ start = eye, endpos = pos, filter = { LocalPlayer(), ent }, mask = MASK_OPAQUE })
    ent._panelOcc = { t = now, hidden = tr.Hit and tr.Fraction < 0.98 }
    return ent._panelOcc.hidden
end

local function paint(ent, P, w, h)
    if not ent.PanelNoBackground then   -- a panel that draws its own shape (e.g. a brass plate) skips this
        surface.SetDrawColor(COL.bg)
        surface.DrawRect(0, 0, w, h)
    end
    local ok, err = pcall(ent.PaintPanel, ent, P, w, h)
    if P.cx then   -- a small ring where you're looking
        surface.DrawCircle(P.cx, P.cy, 6, COL.text.r, COL.text.g, COL.text.b, 200)
    end
    if not ok and err ~= ent._panelError then
        ent._panelError = err
        ErrorNoHalt("[1942] Panel error on " .. tostring(ent) .. ": " .. tostring(err) .. "\n")
    end
end

function RP1942.drawPanel(ent)
    if not ent.PanelSize or not ent.PaintPanel then return end
    local eye = LocalPlayer():EyePos()
    local maxDist = RP1942.Production.labelDistance or 350
    -- far away: skip before working out where the panel sits
    local reach = maxDist + ent:BoundingRadius() + 60   -- the panel can sit a little above / off the prop
    if eye:DistToSqr(ent:GetPos()) > reach * reach then return end
    local pos, ang, scale, mounted = placement(ent)
    if mounted and (eye - pos):Dot(ang:Up()) <= 0 then return end   -- behind a mounted panel
    local dist = eye:Distance(pos)
    if dist > maxDist then return end
    local alpha = math.Clamp((maxDist - dist) / 80, 0, 1)
    local w, h = ent.PanelSize.w, ent.PanelSize.h
    local cx, cy = cursor(pos, ang, scale, w, h)
    if not cx and occluded(ent, eye, pos) then return end

    -- A texture bigger than the screen can come out cut off on some setups:
    -- such a panel (a small window, a tall panel) is painted directly instead
    if not cacheCvar:GetBool() or w > ScrW() or h > ScrH() then
        -- The old way: paint it all, every frame
        local P = setmetatable({ w = w, h = h, ent = ent, cx = cx, cy = cy }, Painter)
        cam.Start3D2D(pos, ang, scale)
            surface.SetAlphaMultiplier(alpha)
            paint(ent, P, w, h)
            surface.SetAlphaMultiplier(1)
        cam.End3D2D()
        ent._panelHover = P.hover
    else
        -- Repaint the texture when it's due
        local now = RealTime()
        -- Looked at: smooth. Otherwise the idle rate, and slower still the
        -- further away it is (a panel across the room at 2 fps is plenty)
        local fps
        if cx then
            fps = LOOK_FPS
        elseif ent.PanelFast and ent:PanelFast() then
            fps = FAST_FPS
        else
            local far = math.Clamp((dist - maxDist * 0.4) / (maxDist * 0.6), 0, 1)
            fps = math.max(2, idleCvar:GetFloat() * (1 - far * 0.75))
        end
        local tex = panelTexture(ent, w, h)
        if not ent._panelPainted or now - ent._panelPainted >= 1 / fps or ent._panelTex ~= tex then
            ent._panelPainted, ent._panelTex = now, tex
            local P = setmetatable({ w = w, h = h, ent = ent, cx = cx, cy = cy }, Painter)
            render.PushRenderTarget(tex.rt)
                render.Clear(0, 0, 0, 0, true, true)
                cam.Start2D()
                    blendOn()
                    paint(ent, P, w, h)
                    blendOff()
                cam.End2D()
            render.PopRenderTarget()
            ent._panelHover = P.hover
        end
        -- Show it: one textured quad
        cam.Start3D2D(pos, ang, scale)
            surface.SetMaterial(tex.mat)
            surface.SetDrawColor(255, 255, 255, 255 * alpha)
            surface.DrawTexturedRect(0, 0, w, h)
        cam.End3D2D()
    end

    if cx then
        RP1942.PanelLook = { ent = ent, t = RealTime() }   -- the crosshair is somewhere on it
        if ent._panelHover then RP1942.PanelHover = { ent = ent, id = ent._panelHover, t = RealTime() } end
    end
end

-- E while a button is highlighted presses it (and doesn't also "use" the prop).
-- Buttons whose id starts with "local:" only change this player's view (e.g.
-- scrolling a list): they go to ENT:OnLocalPress(id) here, not the server.
-- The mouse wheel over a panel calls ENT:OnPanelScroll(+1 / -1) if it has one
-- (instead of switching weapons).
hook.Add("PlayerBindPress", "RP1942_PanelPress", function(ply, bind, pressed)
    if not pressed then return end
    if bind == "invnext" or bind == "invprev" then
        local l = RP1942.PanelLook
        if l and IsValid(l.ent) and l.ent.OnPanelScroll and RealTime() - l.t < 0.15 then
            l.ent:OnPanelScroll(bind == "invnext" and 1 or -1)
            return true
        end
        return
    end
    if not string.find(bind, "+use", 1, true) then return end
    local h = RP1942.PanelHover
    if not (h and IsValid(h.ent) and RealTime() - h.t < 0.15) then return end
    if string.sub(h.id, 1, 6) == "local:" then
        if h.ent.OnLocalPress then h.ent:OnLocalPress(string.sub(h.id, 7)) end
        surface.PlaySound("buttons/lightswitch2.wav")
        return true
    end
    net.Start("RP1942_PanelPress")
    net.WriteEntity(h.ent)
    net.WriteString(h.id)
    net.SendToServer()
    surface.PlaySound("buttons/lightswitch2.wav")
    return true
end)

-- The goods in my pocket, "good|quality" = count (sent by the server; the market board lists them)
RP1942.MyPocketGoods = RP1942.MyPocketGoods or {}
net.Receive("RP1942_PocketGoods", function()
    RP1942.MyPocketGoods = net.ReadTable()
end)

--[[---------------------------------------------------------------------------
Tuning a mounted panel in game (only changes what YOU see, until you copy the
printed line into RP1942.PanelSpots in sh_production.lua). Look at the prop:
    rp1942_panel_face  front|left|back|right     which side it faces
    rp1942_panel_mount backguard|face            standing on top, or flat on the side
    rp1942_panel_move  <right> <up> <out>        nudge it, in units (adds up)
    rp1942_panel_size  <multiplier>              e.g. 0.9 smaller, 1.1 bigger (multiplies)
    rp1942_panel_top   <0-1>                     "face" mount: height of its top edge
    rp1942_panel_float                           no mount: float above the prop
    rp1942_panel_print                           print the line to paste in the config
---------------------------------------------------------------------------]]
local function lookedClass()
    local ent = LocalPlayer():GetEyeTrace().Entity
    if IsValid(ent) and ent.PanelSize then return ent:GetClass() end
    print("[1942] Look at a prop with a panel (oven, barrel, market) first.")
end

local function tune(fn)
    return function(_, _, args)
        local class = lookedClass()
        if not class then return end
        RP1942.PanelSpots[class] = RP1942.PanelSpots[class] or { mount = "backguard", face = "front", width = 0.45 }
        fn(RP1942.PanelSpots[class], args, class)
        print("[1942] " .. class .. " panel updated. rp1942_panel_print shows the config line.")
    end
end

concommand.Add("rp1942_panel_face", tune(function(spot, a) if FACE_YAW[a[1] or ""] then spot.face = a[1] end end))
concommand.Add("rp1942_panel_mount", tune(function(spot, a) if a[1] == "face" or a[1] == "backguard" or a[1] == "top" then spot.mount = a[1] end end))
concommand.Add("rp1942_panel_move", tune(function(spot, a)
    local n = spot.nudge or { 0, 0, 0 }
    spot.nudge = { n[1] + (tonumber(a[1]) or 0), n[2] + (tonumber(a[2]) or 0), n[3] + (tonumber(a[3]) or 0) }
end))
concommand.Add("rp1942_panel_size", tune(function(spot, a) spot.size = (spot.size or 1) * (tonumber(a[1]) or 1) end))
concommand.Add("rp1942_panel_top", tune(function(spot, a) spot.top = math.Clamp(tonumber(a[1]) or 0.95, 0, 1) end))
concommand.Add("rp1942_panel_float", function()
    local class = lookedClass()
    if class then RP1942.PanelSpots[class] = nil print("[1942] " .. class .. " panel now floats.") end
end)
concommand.Add("rp1942_panel_print", function()
    local class = lookedClass()
    if not class then return end
    local s = RP1942.PanelSpots[class]
    if not s then print("RP1942.PanelSpots." .. class .. " = nil   -- floats") return end
    local n = s.nudge or { 0, 0, 0 }
    print(string.format('RP1942.PanelSpots.%s = { mount = "%s", face = "%s", width = %.2f, top = %.2f, size = %.2f, nudge = { %.1f, %.1f, %.1f } }',
        class, s.mount or "backguard", s.face or "front", s.width or 0.45, s.top or 0.95, s.size or 1, n[1], n[2], n[3]))
end)

--[[---------------------------------------------------------------------------
Brass & enamel: a machine control plate (the oven's style; the barrel and
market can use it too). Everything draws in canvas pixels inside PaintPanel.
    B.Plate(w, h, enamel)                  brass rim, enamel face, rivets
    B.Plaque(cx, y, w, h, text, font)      engraved brass nameplate
    B.Dial(cx, cy, r, value, zones, label, live, face)   needle gauge, value 0-100
                                           (face: the dial's colour; default ivory)
    B.Counter(x, y, text, size)            mechanical digit wheels -> width
    B.Lamp(cx, cy, r, on, color)           indicator lamp
    B.Stars(x, y, quality, size)           embossed brass stars
    B.PushButton(P, id, cx, cy, r, color, label, enabled)   round button (look + E)
    B.Toggle(P, id, cx, cy, on, enabled)   a power lever: up = ON, down = OFF (look + E)
---------------------------------------------------------------------------]]
local B = {}
RP1942.Brass = B
B.BRASS, B.DARK, B.LIGHT = Color(181, 146, 72), Color(120, 92, 40), Color(226, 196, 120)
B.WHITE, B.INK = Color(236, 232, 218), Color(52, 38, 16)

local function serif(name, size) surface.CreateFont(name, { font = "Times New Roman", size = size, weight = 800, extended = true }) end
serif("RP1942_BrassPlaque", 24)
serif("RP1942_BrassLabel", 19)
serif("RP1942_BrassSmall", 16)
surface.CreateFont("RP1942_BrassDigits", { font = "Courier New", size = 40, weight = 900, extended = true })

-- A convex polygon in either winding (DrawPoly only fills clockwise ones)
local function poly(pts)
    local area = 0
    for i = 1, #pts do
        local a, b = pts[i], pts[i % #pts + 1]
        area = area + (a.x * b.y - b.x * a.y)
    end
    if area < 0 then
        local r = {}
        for i = #pts, 1, -1 do r[#r + 1] = pts[i] end
        pts = r
    end
    surface.DrawPoly(pts)
end
B.Poly = poly

function B.Circle(x, y, r, col, segs)
    segs = segs or math.Clamp(math.floor(r), 16, 48)
    local pts = {}
    for i = 0, segs - 1 do
        local a = math.rad(i / segs * 360)
        pts[#pts + 1] = { x = x + math.cos(a) * r, y = y + math.sin(a) * r }
    end
    draw.NoTexture()
    surface.SetDrawColor(col)
    poly(pts)
end

-- A thick arc between two angles (degrees, clockwise on screen; 0 = right)
function B.Arc(x, y, r1, r2, a0, a1, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    local steps = math.max(2, math.ceil(math.abs(a1 - a0) / 6))
    for i = 0, steps - 1 do
        local u, v = math.rad(a0 + (a1 - a0) * i / steps), math.rad(a0 + (a1 - a0) * (i + 1) / steps)
        poly({
            { x = x + math.cos(u) * r2, y = y + math.sin(u) * r2 }, { x = x + math.cos(v) * r2, y = y + math.sin(v) * r2 },
            { x = x + math.cos(v) * r1, y = y + math.sin(v) * r1 }, { x = x + math.cos(u) * r1, y = y + math.sin(u) * r1 },
        })
    end
end

-- A line of some thickness (the dial's needle and ticks)
function B.Line(x1, y1, x2, y2, width, col)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
    local nx, ny = -dy / len * width / 2, dx / len * width / 2
    draw.NoTexture()
    surface.SetDrawColor(col)
    poly({ { x = x1 + nx, y = y1 + ny }, { x = x2 + nx, y = y2 + ny }, { x = x2 - nx, y = y2 - ny }, { x = x1 - nx, y = y1 - ny } })
end

function B.Rivet(x, y)
    B.Circle(x, y, 7, B.DARK)
    B.Circle(x, y, 6, B.BRASS)
    B.Circle(x - 1.5, y - 2, 2.5, B.LIGHT)
end

function B.Plate(w, h, enamel)
    -- bevelled brass rim: light towards the edge, dark inside
    for i = 0, 9 do
        local t = math.abs(i / 9 - 0.4) * 1.6
        local c = Color(Lerp(1 - t, B.DARK.r, B.LIGHT.r), Lerp(1 - t, B.DARK.g, B.LIGHT.g), Lerp(1 - t, B.DARK.b, B.LIGHT.b))
        draw.RoundedBox(16, i, i, w - i * 2, h - i * 2, c)
    end
    draw.RoundedBox(10, 12, 12, w - 24, h - 24, enamel)
    -- a soft sheen across the top of the enamel
    for i = 0, 30 do
        surface.SetDrawColor(255, 255, 255, 10 - i / 3)
        surface.DrawRect(12, 12 + i * 4, w - 24, 4)
    end
    for _, p in ipairs({ { 28, 28 }, { w - 28, 28 }, { 28, h - 28 }, { w - 28, h - 28 } }) do B.Rivet(p[1], p[2]) end
end

function B.Plaque(cx, y, w, h, text, font)
    draw.RoundedBox(6, cx - w / 2, y, w, h, B.DARK)
    draw.RoundedBox(6, cx - w / 2 + 2, y + 2, w - 4, h - 4, B.BRASS)
    surface.SetDrawColor(B.LIGHT)
    surface.DrawRect(cx - w / 2 + 6, y + 4, w - 12, 2)
    draw.SimpleText(text, font or "RP1942_BrassPlaque", cx, y + h / 2, B.INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- value 0-100 over a 240-degree sweep; zones = { { from, to, color }, ... }
function B.Dial(cx, cy, r, value, zones, label, live, face)
    B.Circle(cx, cy, r + 11, B.DARK)
    B.Circle(cx, cy, r + 8, B.BRASS)
    B.Circle(cx, cy, r, face or B.WHITE)
    local function ang(v) return 150 + 240 * v / 100 end
    for _, z in ipairs(zones) do B.Arc(cx, cy, r - 22, r - 10, ang(z[1]), ang(z[2]), z[3]) end
    for v = 0, 100, 5 do
        local a = math.rad(ang(v))
        local len = (v % 25 == 0) and 18 or 9
        B.Line(cx + math.cos(a) * (r - 24), cy + math.sin(a) * (r - 24), cx + math.cos(a) * (r - 24 - len), cy + math.sin(a) * (r - 24 - len), 2, Color(30, 30, 30))
    end
    draw.SimpleText(label, "RP1942_BrassSmall", cx, cy + r * 0.45, Color(70, 64, 56), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local a = math.rad(ang(math.Clamp(value, 0, 100)))
    B.Line(cx - math.cos(a) * 14, cy - math.sin(a) * 14, cx + math.cos(a) * (r - 30), cy + math.sin(a) * (r - 30), 5, live and Color(20, 20, 20) or Color(120, 116, 108))
    B.Circle(cx, cy, 10, B.DARK)
    B.Circle(cx, cy, 8, B.BRASS)
end

-- Digit wheels: "1:12" -> width drawn
function B.Counter(x, y, text, size)
    size = size or 40
    local cw, ch = math.floor(size * 0.72), math.floor(size * 1.15)
    local cx = x
    for i = 1, #text do
        local c = string.sub(text, i, i)
        if c == ":" or c == " " then
            draw.SimpleText(c, "RP1942_BrassDigits", cx + 8, y + ch / 2, B.WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cx = cx + 16
        else
            draw.RoundedBox(3, cx, y, cw, ch, B.DARK)
            draw.RoundedBox(2, cx + 2, y + 2, cw - 4, ch - 4, Color(18, 18, 18))
            surface.SetDrawColor(50, 50, 50)
            surface.DrawRect(cx + 2, y + ch / 2, cw - 4, 1)
            draw.SimpleText(c, "RP1942_BrassDigits", cx + cw / 2, y + ch / 2, B.WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cx = cx + cw + 4
        end
    end
    return cx - x
end

function B.Lamp(cx, cy, r, on, col)
    B.Circle(cx, cy, r + 5, B.DARK)
    B.Circle(cx, cy, r + 3, B.BRASS)
    B.Circle(cx, cy, r, on and col or Color(col.r * 0.25, col.g * 0.25, col.b * 0.25))
    if on then
        B.Circle(cx, cy, r + 9, Color(col.r, col.g, col.b, 30))   -- glow
        B.Circle(cx - r * 0.3, cy - r * 0.35, r * 0.3, Color(255, 255, 230, 200))
    end
end

function B.Stars(x, y, q, s)
    s = s or 26
    for i = 1, 3 do
        local cx, cy, r = x + (i - 1) * (s + 8) + s / 2, y + s / 2, s / 2
        local pts = {}
        for k = 0, 9 do
            local a = math.rad(-90 + k * 36)
            local rr = (k % 2 == 0) and r or r * 0.45
            pts[k] = { x = cx + math.cos(a) * rr, y = cy + math.sin(a) * rr }
        end
        draw.NoTexture()
        surface.SetDrawColor(i <= (q or 0) and B.LIGHT or Color(60, 80, 70))
        for k = 0, 9 do poly({ { x = cx, y = cy }, pts[k], pts[(k + 1) % 10] }) end
    end
    return 3 * (s + 8)
end

-- A round push-button with its nameplate underneath
function B.PushButton(P, id, cx, cy, r, col, label, enabled)
    local hot = P:Hot(id, cx - r - 12, cy - r - 12, (r + 12) * 2, (r + 12) * 2 + 60, enabled)
    local c = enabled and col or Color(70, 70, 66)
    if hot then c = Color(math.min(c.r + 45, 255), math.min(c.g + 45, 255), math.min(c.b + 45, 255)) end
    if hot then B.Circle(cx, cy, r + 19, B.WHITE) end
    B.Circle(cx, cy, r + 13, B.DARK)
    B.Circle(cx, cy, r + 11, B.BRASS)
    B.Circle(cx, cy, r + 1, Color(20, 20, 20))
    B.Circle(cx, cy, r, c)
    B.Circle(cx - r * 0.25, cy - r * 0.35, r * 0.45, Color(math.min(c.r + 60, 255), math.min(c.g + 60, 255), math.min(c.b + 60, 255), 160))
    B.Plaque(cx, cy + r + 20, 180, 38, label, "RP1942_BrassLabel")
    return hot
end

-- A power lever on a brass mount: up = ON (green lamp), down = OFF
function B.Toggle(P, id, cx, cy, on, enabled)
    local hot = P:Hot(id, cx - 40, cy - 44, 80, 132, enabled)
    if hot then draw.RoundedBox(10, cx - 36, cy - 42, 72, 84, B.WHITE) end
    draw.RoundedBox(8, cx - 32, cy - 38, 64, 76, B.DARK)
    draw.RoundedBox(8, cx - 30, cy - 36, 60, 72, B.BRASS)
    B.Rivet(cx - 20, cy - 26); B.Rivet(cx + 20, cy + 26)
    draw.RoundedBox(4, cx - 7, cy - 26, 14, 52, Color(20, 20, 20))           -- the slot
    local ky = on and cy - 22 or cy + 22
    B.Line(cx, cy, cx, ky, 8, Color(60, 60, 60))                             -- the lever
    B.Circle(cx, ky, 12, Color(25, 25, 25))                                  -- bakelite knob
    B.Circle(cx - 3, ky - 4, 4, Color(120, 120, 120))
    B.Lamp(cx + 20, cy - 24, 5, on, Color(90, 220, 90))
    draw.RoundedBox(6, cx - 52, cy + 48, 104, 34, B.DARK)
    draw.RoundedBox(6, cx - 50, cy + 50, 100, 30, B.BRASS)
    draw.SimpleText(on and "POWER  ON" or "POWER  OFF", "RP1942_BrassSmall", cx, cy + 65, B.INK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return hot
end

-- (Markers on the screen moved to rp1942_core/cl_markers.lua)
