--[[---------------------------------------------------------------------------
42Bros - animations (client): the radial menu and the player-moved camera.
See sh_animations.lua.

Built from the F4 menu's colours and fonts (RP1942.F4UI), so it looks like
the rest of the server's menus.
---------------------------------------------------------------------------]]
local A = RP1942.Animations

local CAM = {
    distance  = 95,     -- units from the player to start with
    minDist   = 45,     -- the mouse wheel moves it between these
    maxDist   = 170,
    wheelStep = 12,     -- units per notch of the wheel
    height    = 44,     -- the point it looks at, above the player's feet
    pitch     = 8,      -- degrees down at the player to start with
    minPitch  = -35,    -- how far it can go under / over the player
    maxPitch  = 70,
    sensitivity = 0.022,  -- degrees per mouse count (GMod's own m_yaw)
    startYaw  = 150,    -- where it starts, from straight behind (180 = facing you)
    zoomIn    = 0.55,   -- seconds to swing out of first person
    zoomOut   = 0.45,   -- seconds to come back in
    minTime   = 1.5,    -- shortest and longest an animation is shown for
    maxTime   = 8,
}

--[[---------------------------------------------------------------------------
The radial menu
---------------------------------------------------------------------------]]
local menu          -- the open menu panel, if any

local function colors()
    local C = RP1942.F4UI and RP1942.F4UI.C
    return C or {
        bg = Color(20, 19, 17, 248), panel = Color(28, 26, 23), card = Color(38, 35, 31),
        cardHover = Color(52, 48, 42), category = Color(84, 18, 18), button = Color(128, 26, 24),
        gold = Color(201, 168, 92), text = Color(236, 228, 212), sub = Color(160, 152, 136),
    }
end

-- A filled ring segment from angle a1 to a2 (radians, 0 = up, clockwise),
-- drawn as small convex quads (surface.DrawPoly needs convex shapes)
local function ringSegment(cx, cy, r1, r2, a1, a2, col)
    surface.SetDrawColor(col)
    draw.NoTexture()
    local steps = math.max(2, math.ceil((a2 - a1) / math.rad(4)))
    for i = 0, steps - 1 do
        local s = a1 + (a2 - a1) * i / steps
        local e = a1 + (a2 - a1) * (i + 1) / steps
        surface.DrawPoly({
            { x = cx + math.sin(s) * r1, y = cy - math.cos(s) * r1 },
            { x = cx + math.sin(s) * r2, y = cy - math.cos(s) * r2 },
            { x = cx + math.sin(e) * r2, y = cy - math.cos(e) * r2 },
            { x = cx + math.sin(e) * r1, y = cy - math.cos(e) * r1 },
        })
    end
end

local function closeMenu()
    if IsValid(menu) then menu:Remove() end
    menu = nil
end

local function choose(i)
    closeMenu()
    if i then RunConsoleCommand("rp1942_animation", tostring(i)) end
end

--[[---------------------------------------------------------------------------
Reading R ourselves. The menu used to open from the keys SWEP's Reload, which
the game calls every predicted tick R is held (and again when ticks are
replayed), so presses were missed, doubled or opened and shut it at once.
Now a Think hook watches the reload key (whatever it's bound to, a mouse
button too) and acts only on the moment it goes down and the moment it
comes up:

    R down, menu shut      open it (unless you're at a door: that's the
                           keys' door menu, as before)
    R up, held > 0.25 s    play the one you're pointing at (hold, flick, let go)
    R up, a quick tap      leave it open to click
    R down, menu open      close it
---------------------------------------------------------------------------]]
local HOLD = 0.25    -- seconds: held longer than this, letting go picks
local wasDown = false

local function reloadCode()
    local key = input.LookupBinding("+reload")
    local code = key and input.GetKeyCode(key)
    return (code and code > 0) and code or KEY_R
end

local function reloadDown()
    return input.IsButtonDown(reloadCode())
end

-- Typing somewhere (chat, a text box, the console): R is a letter, not a key
local function typing()
    local ply = LocalPlayer()
    if IsValid(ply) and ply.IsTyping and ply:IsTyping() then return true end
    if gui.IsConsoleVisible() or gui.IsGameUIVisible() then return true end
    local focus = vgui.GetKeyboardFocus()
    return IsValid(focus) and focus:GetClassName() == "TextEntry"
end

-- The keys' own R at a door (the door menu): DarkRP opens it within 200 units
local function lookingAtDoor(ply)
    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or not ent.isKeysOwnable then return false end
    local ok, own = pcall(ent.isKeysOwnable, ent)
    return ok and own and ent:GetPos():DistToSqr(ply:GetPos()) <= 40000
end

local function openMenu()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local s = math.Clamp(ScrH() / 1080, 0.75, 1.5)
    local n = #A.list
    local slice = math.pi * 2 / n
    local r1, r2 = math.floor(78 * s), math.floor(230 * s)
    local gap = math.rad(1.2)

    menu = vgui.Create("DPanel")
    menu:SetSize(ScrW(), ScrH())
    menu:SetPos(0, 0)
    menu:MakePopup()
    menu:SetKeyboardInputEnabled(false)   -- keys still reach the game (move, R)
    menu.heldSince = RealTime()           -- R is down right now (it just opened it)
    menu.hover = nil
    menu.fade = 0
    local cx, cy = ScrW() / 2, ScrH() / 2
    input.SetCursorPos(cx, cy)

    function menu:Think()
        local p = LocalPlayer()
        if not (IsValid(p) and p:Alive()) or gui.IsGameUIVisible() then return closeMenu() end
        local w = p:GetActiveWeapon()
        if not (IsValid(w) and w:GetClass() == "keys") then return closeMenu() end

        local mx, my = input.GetCursorPos()
        local dx, dy = mx - cx, my - cy
        local d = math.sqrt(dx * dx + dy * dy)
        if d < r1 * 0.75 then
            self.hover = nil
        else
            local ang = math.atan2(dx, -dy)   -- 0 = up, clockwise
            if ang < 0 then ang = ang + math.pi * 2 end
            self.hover = math.floor((ang + slice / 2) / slice) % n + 1
        end
        self.fade = math.min(1, self.fade + FrameTime() * 8)
    end

    function menu:OnMousePressed(code)
        if code == MOUSE_LEFT then choose(self.hover) else closeMenu() end
    end

    function menu:Paint(w, h)
        local C = colors()
        local f = self.fade
        surface.SetDrawColor(0, 0, 0, 90 * f)
        surface.DrawRect(0, 0, w, h)

        local grow = 0.92 + 0.08 * f
        local a1r, a2r = r1 * grow, r2 * grow
        for i = 1, n do
            local mid = (i - 1) * slice
            local hov = self.hover == i
            local bg = hov and C.button or Color(C.card.r, C.card.g, C.card.b, 235)
            ringSegment(cx, cy, a1r, a2r + (hov and 8 * s or 0), mid - slice / 2 + gap, mid + slice / 2 - gap, bg)
            -- a thin gold edge on the outside of the hovered one
            if hov then ringSegment(cx, cy, a2r + 8 * s - 3, a2r + 8 * s, mid - slice / 2 + gap, mid + slice / 2 - gap, C.gold) end
            local lr = (a1r + a2r) / 2
            draw.SimpleText(A.list[i].name, "RP1942_F4Button", cx + math.sin(mid) * lr, cy - math.cos(mid) * lr,
                hov and C.text or C.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- the middle: what's picked, or how to close it
        ringSegment(cx, cy, 0, a1r - 6 * s, 0, math.pi * 2, Color(C.panel.r, C.panel.g, C.panel.b, 245))
        local title = self.hover and A.list[self.hover].name or "Animations"
        draw.SimpleText(title, "RP1942_F4Head", cx, cy - 8 * s, self.hover and C.gold or C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(self.hover and "Click to play" or "Right click to close", "RP1942_F4Small", cx, cy + 14 * s,
            C.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

hook.Add("Think", "RP1942_AnimMenuKey", function()
    local down = reloadDown()
    if down == wasDown then return end
    wasDown = down
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if down then
        -- pressed
        if IsValid(menu) then return closeMenu() end
        if typing() or not ply:Alive() or ply:InVehicle() then return end
        local w = ply:GetActiveWeapon()
        if not (IsValid(w) and w:GetClass() == "keys") then return end
        if lookingAtDoor(ply) then return end   -- the keys' door menu
        openMenu()
    elseif IsValid(menu) and menu.heldSince then
        -- let go: a hold picks what you're pointing at, a tap leaves it open
        local held = RealTime() - menu.heldSince
        menu.heldSince = nil
        if held > HOLD then choose(menu.hover) end
    end
end)

-- The keys SWEP still runs DarkRP's menu command on every tick R is held:
-- it does nothing now (the Think hook above opens the menu), and replacing it
-- keeps DarkRP's own button list from opening.
local function noop() end
concommand.Add("_DarkRP_AnimationMenu", noop)
hook.Add("Initialize", "RP1942_Animations", function() concommand.Add("_DarkRP_AnimationMenu", noop) end)

--[[---------------------------------------------------------------------------
Playing one: everyone sees the gesture; the player who did it also gets the
camera, which they turn with the mouse.
---------------------------------------------------------------------------]]
local cam   -- { start, finish, out } while the camera is out

local function smooth(t) t = math.Clamp(t, 0, 1) return t * t * (3 - 2 * t) end

local function animLength(ply, act)
    local seq = ply:SelectWeightedSequence(act)
    local len = (seq and seq >= 0) and ply:SequenceDuration(seq) or 3
    return math.Clamp(len > 0 and len or 3, CAM.minTime, CAM.maxTime)
end

net.Receive("RP1942_Anim", function()
    local ply = net.ReadEntity()
    local i = net.ReadUInt(8)
    local a = A.list[i]
    if not (IsValid(ply) and a) then return end
    ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, a.act, true)

    if ply == LocalPlayer() then
        local now = RealTime()
        cam = { start = now, finish = now + animLength(ply, a.act),
            yaw = ply:EyeAngles().y + CAM.startYaw, pitch = CAM.pitch, dist = CAM.distance }
    end
end)

local function endCamEarly()
    if cam and not cam.leaving then
        local now = RealTime()
        if now < cam.finish then cam.finish = now end
        cam.leaving = true
    end
end

hook.Add("CalcView", "RP1942_AnimCam", function(ply, origin, angles, fov)
    if not cam then return end
    local now = RealTime()
    if not ply:Alive() or ply:InVehicle() or now > cam.finish + CAM.zoomOut then
        cam = nil
        return
    end

    -- where the player has put it (InputMouseApply / the wheel, below)
    local center = ply:GetPos() + Vector(0, 0, CAM.height)
    local dir = Angle(cam.pitch, cam.yaw, 0):Forward()
    local tr = util.TraceHull({
        start = center, endpos = center - dir * cam.dist,
        mins = Vector(-6, -6, -6), maxs = Vector(6, 6, 6),
        mask = MASK_SOLID, filter = function(e) return not e:IsPlayer() end,
    })
    local orbitPos = tr.HitPos
    local orbitAng = (center - orbitPos):Angle()

    -- out of first person at the start, back into it at the end
    local t
    if now < cam.finish then
        t = smooth((now - cam.start) / CAM.zoomIn)
    else
        t = 1 - smooth((now - cam.finish) / CAM.zoomOut)
    end
    cam.drawn = t > 0.08   -- (right at first person the body would fill the screen)
    return {
        origin = LerpVector(t, origin, orbitPos),
        angles = LerpAngle(t, angles, orbitAng),
        fov = fov,
        drawviewer = cam.drawn,
    }
end)

hook.Add("ShouldDrawLocalPlayer", "RP1942_AnimCam", function()
    if cam and cam.drawn then return true end
end)
-- no floating weapon in front of the camera while it's out
hook.Add("PreDrawViewModel", "RP1942_AnimCam", function()
    if cam then return true end
end)

-- The mouse turns the camera around you instead of turning you
local mYaw, mPitch = GetConVar("m_yaw"), GetConVar("m_pitch")
hook.Add("InputMouseApply", "RP1942_AnimCam", function(cmd, x, y)
    if not cam or RealTime() > cam.finish then return end
    local yawScale = mYaw and mYaw:GetFloat() or CAM.sensitivity
    local pitchScale = mPitch and mPitch:GetFloat() or CAM.sensitivity   -- (negative = inverted mouse, kept)
    local sens = GetConVar("sensitivity")
    local k = sens and sens:GetFloat() or 1
    cam.yaw = cam.yaw - x * yawScale * k
    cam.pitch = math.Clamp(cam.pitch + y * pitchScale * k, CAM.minPitch, CAM.maxPitch)
    cmd:SetMouseX(0)
    cmd:SetMouseY(0)
    return true   -- your own view doesn't move
end)

-- attacking or pressing E: straight back to first person. The wheel: closer / further.
hook.Add("PlayerBindPress", "RP1942_AnimCam", function(_, bind, pressed)
    if not (pressed and cam) then return end
    if bind:find("+attack", 1, true) or bind:find("+use", 1, true) then return endCamEarly() end
    if bind:find("invprev", 1, true) then
        cam.dist = math.max(CAM.minDist, cam.dist - CAM.wheelStep)
        return true   -- (not switching weapons)
    elseif bind:find("invnext", 1, true) then
        cam.dist = math.min(CAM.maxDist, cam.dist + CAM.wheelStep)
        return true
    end
end)
