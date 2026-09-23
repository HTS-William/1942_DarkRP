--[[---------------------------------------------------------------------------
1942 DarkRP - intro vignette (client)

On first spawn: the screen holds black, fades in, and a dark vignette around
the edges lingers and eases out slowly. Plays once per session, not on respawn.

    rp1942_intro 0          player setting: turn the intro off (saved)
    rp1942_intro_replay     replay it (for tuning the timings below)
---------------------------------------------------------------------------]]
local cfg = {
    blackHold    = 1.5,   -- seconds of full black before the fade starts
    blackFade    = 3.0,   -- seconds to fade in from black
    vignetteTime = 12.0,  -- seconds for the vignette to fade away (starts with the fade-in)
    vignetteMax  = 235,   -- darkness at the screen edge, 0-255
    vignetteSize = 0.35,  -- how far in from each edge it reaches (fraction of screen)
    steps        = 32,    -- gradient smoothness (more = smoother, slightly more cost)
}

local enabled = CreateClientConVar("rp1942_intro", "1", true, false, "Play the intro vignette when joining")

local startTime

local function progress(elapsed, delay, duration)
    return math.Clamp((elapsed - delay) / duration, 0, 1)
end

-- Gentle at both ends: used for the fade-in
local function smootherstep(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

--[[---------------------------------------------------------------------------
Black fade: drawn on top of everything, HUD included
---------------------------------------------------------------------------]]
hook.Add("DrawOverlay", "RP1942_IntroBlack", function()
    if not startTime then return end

    -- Fully black for blackHold, then fade over blackFade
    local fade = progress(RealTime() - startTime, cfg.blackHold, cfg.blackFade)
    if fade >= 1 then return end

    surface.SetDrawColor(0, 0, 0, 255 * (1 - smootherstep(fade)))
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)

--[[---------------------------------------------------------------------------
Vignette: drawn behind the HUD so health/notifications stay readable.
Built from alpha strips instead of a gradient texture, so it looks the same
on every client and needs no content.
---------------------------------------------------------------------------]]
hook.Add("HUDPaintBackground", "RP1942_IntroVignette", function()
    if not startTime then return end

    local elapsed = RealTime() - startTime
    local t = progress(elapsed, cfg.blackHold, cfg.vignetteTime)

    -- Whole intro finished (black fade AND vignette): stop doing any work
    if elapsed >= cfg.blackHold + math.max(cfg.blackFade, cfg.vignetteTime) then
        startTime = nil
        return
    end
    if t >= 1 then return end

    -- Cubic ease-out: most of the change happens early, the tail is slow
    local strength = cfg.vignetteMax * (1 - t) ^ 3
    if strength < 1 then return end

    local w, h = ScrW(), ScrH()
    local bandH = (h * cfg.vignetteSize) / cfg.steps
    local bandW = (w * cfg.vignetteSize) / cfg.steps

    for i = 0, cfg.steps - 1 do
        local edge = 1 - i / cfg.steps              -- 1 at the screen edge, 0 inside
        surface.SetDrawColor(0, 0, 0, strength * edge * edge)

        local y, x = math.floor(i * bandH), math.floor(i * bandW)
        local bh, bw = math.ceil(bandH), math.ceil(bandW)

        surface.DrawRect(0, y, w, bh)               -- top
        surface.DrawRect(0, h - y - bh, w, bh)      -- bottom
        surface.DrawRect(x, 0, bw, h)               -- left
        surface.DrawRect(w - x - bw, 0, bw, h)      -- right
    end
end)

--[[---------------------------------------------------------------------------
Triggers
---------------------------------------------------------------------------]]
local function play()
    if not enabled:GetBool() then return end
    startTime = RealTime()
end

-- Fires once, when the client has finished loading into the map
hook.Add("InitPostEntity", "RP1942_IntroStart", play)

concommand.Add("rp1942_intro_replay", function()
    startTime = RealTime()
end)
