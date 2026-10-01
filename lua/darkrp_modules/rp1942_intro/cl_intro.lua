--[[---------------------------------------------------------------------------
1942 DarkRP - intro card + vignette (client)

On first spawn:
    black screen -> title card fades in, holds, fades out
    -> world fades in -> dark vignette around the edges eases out slowly
Plays once per session, not on respawn. (FAdmin's MOTD is switched off in
sv_motd.lua in this same module.)

    rp1942_intro 0          player setting: turn the intro (and its music) off (saved)
    rp1942_intro_volume 0.5 player setting: intro music volume, 0-1 (saved)
    rp1942_intro_replay     replay it (for tuning the timings/text below)

Music settings (file path, fades) are in sh_music.lua.
---------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
THE CARD: edit the text here. Lines are drawn top to bottom, centred.
style: "title" | "subtitle" | "body"
---------------------------------------------------------------------------]]
local card = {
    lines = {
        { style = "title",    text = "1942" },
        { style = "subtitle", text = "Autumn. The third year of the occupation." },
        { style = "body",     text = "'Stettin, Polen' - Szczecin, Poland" },
    },
    color   = Color(230, 224, 208),   -- off-white, like old print
    spacing = 0.02,                   -- gap between lines, fraction of screen height

    -- Font FAMILY names must exist on the player's PC. Roboto ships with
    -- Garry's Mod, so it works everywhere. A period serif needs to be sent to
    -- clients as a resource (resource.AddFile) before you switch to it.
    fonts = {
        title    = { font = "Roboto",       size = 0.110, weight = 800 },
        subtitle = { font = "Roboto Light", size = 0.030, weight = 300 },
        body     = { font = "Roboto Light", size = 0.022, weight = 300 },
    },
}

--[[---------------------------------------------------------------------------
TIMING (seconds from when the player finishes loading)
---------------------------------------------------------------------------]]
local cfg = {
    cardDelay    = 0.6,   -- black before the card appears
    cardFadeIn   = 1.2,
    cardHold     = 4.0,
    cardFadeOut  = 1.2,
    blackFade    = 3.0,   -- world fades in after the card is gone
    vignetteTime = 12.0,  -- vignette eases out, starting with the world fade
    vignetteMax  = 235,   -- darkness at the screen edge, 0-255
    vignetteSize = 0.35,  -- how far in from each edge (fraction of screen)
    steps        = 32,    -- vignette smoothness (rings in the shade texture = 3x this)
}

-- Derived: black stays up until the card has faded out
local cardEnd   = cfg.cardDelay + cfg.cardFadeIn + cfg.cardHold + cfg.cardFadeOut
local blackHold = cardEnd
local totalTime = blackHold + math.max(cfg.blackFade, cfg.vignetteTime)

local enabled = CreateClientConVar("rp1942_intro", "1", true, false, "Play the intro when joining")
local musicVolume = CreateClientConVar("rp1942_intro_volume", "1", true, false, "Intro music volume (0-1)", 0, 1)
local startTime

--[[---------------------------------------------------------------------------
Fonts are sized from the screen height, and rebuilt if the resolution changes
---------------------------------------------------------------------------]]
for style, f in pairs(card.fonts) do   -- lua/autorun/client/rp1942_screenfonts.lua
    RP1942.screenFont("RP1942_Intro_" .. style, f.size, f.weight, { font = f.font, antialias = true })
end

--[[---------------------------------------------------------------------------
Easing
---------------------------------------------------------------------------]]
local function progress(elapsed, delay, duration)
    return math.Clamp((elapsed - delay) / duration, 0, 1)
end

local function smootherstep(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

-- 0 -> 1 -> 0 over fade-in, hold, fade-out
local function cardAlpha(elapsed)
    local inT  = progress(elapsed, cfg.cardDelay, cfg.cardFadeIn)
    local outT = progress(elapsed, cfg.cardDelay + cfg.cardFadeIn + cfg.cardHold, cfg.cardFadeOut)
    return smootherstep(inT) * (1 - smootherstep(outT))
end

--[[---------------------------------------------------------------------------
Black + card: drawn on top of everything, HUD included
---------------------------------------------------------------------------]]
local function drawCard(alpha)
    local w, h = ScrW(), ScrH()
    local gap = h * card.spacing

    -- Measure the block so it's vertically centred as a whole
    local heights, total = {}, 0
    for i, line in ipairs(card.lines) do
        surface.SetFont("RP1942_Intro_" .. line.style)
        local _, lh = surface.GetTextSize(line.text)
        heights[i] = lh
        total = total + lh + (i > 1 and gap or 0)
    end

    local col = Color(card.color.r, card.color.g, card.color.b, 255 * alpha)
    local y = (h - total) / 2
    for i, line in ipairs(card.lines) do
        draw.SimpleText(line.text, "RP1942_Intro_" .. line.style, w / 2, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        y = y + heights[i] + gap
    end
end

hook.Add("DrawOverlay", "RP1942_IntroBlack", function()
    if not startTime then return end
    local elapsed = RealTime() - startTime

    local fade = progress(elapsed, blackHold, cfg.blackFade)
    if fade >= 1 then return end

    surface.SetDrawColor(0, 0, 0, 255 * (1 - smootherstep(fade)))
    surface.DrawRect(0, 0, ScrW(), ScrH())

    if elapsed < cardEnd then
        local a = cardAlpha(elapsed)
        if a > 0.004 then drawCard(a) end
    end
end)

--[[---------------------------------------------------------------------------
Vignette: behind the HUD so health/notifications stay readable.

A smooth elliptical shade: clear in the middle, darkening towards the edges
and fully dark in the corners. It's drawn ONCE into a texture (many thin
concentric rings, each a hair darker than the last, then bilinear-filtered
on screen), so there are no visible steps and no cross-hatching where the
old top/bottom and left/right bands overlapped. Every frame after that is a
single textured quad whose alpha is the fade.
---------------------------------------------------------------------------]]
local RT_SIZE = 512
local vignetteMat

local function buildVignette()
    if vignetteMat then return vignetteMat end
    local rt = GetRenderTargetEx("rp1942_intro_vignette", RT_SIZE, RT_SIZE, RT_SIZE_OFFSCREEN,
        MATERIAL_RT_DEPTH_NONE, bit.bor(2, 256), 0, IMAGE_FORMAT_RGBA8888)
    vignetteMat = CreateMaterial("rp1942_intro_vignette_mat", "UnlitGeneric", {
        ["$basetexture"] = rt:GetName(), ["$translucent"] = 1, ["$vertexalpha"] = 1, ["$vertexcolor"] = 1,
    })

    -- Elliptical distance from the centre: 0 there, 1 at the middle of an
    -- edge, ~1.41 in a corner. Clear inside `inner`, fully dark from `outer`.
    local inner = math.Clamp(1 - cfg.vignetteSize * 1.6, 0.2, 0.95)
    local outer = 1.38
    local rings, segs = math.max(cfg.steps * 3, 64), 48
    local c, r = RT_SIZE / 2, RT_SIZE / 2

    local function point(d, a) return { x = c + r * d * math.cos(a), y = c + r * d * math.sin(a) } end
    local function shade(d)   -- smoothstep from inner to outer
        local t = math.Clamp((d - inner) / (outer - inner), 0, 1)
        return t * t * (3 - 2 * t)
    end

    render.PushRenderTarget(rt)
    render.OverrideAlphaWriteEnable(true, true)
    render.Clear(0, 0, 0, 0, true, true)
    cam.Start2D()
        draw.NoTexture()
        local step = (outer - inner) / rings
        for i = 0, rings do
            local d0 = inner + i * step
            local d1 = (i == rings) and 1.6 or (d0 + step)   -- the last ring runs past the corners
            local a = math.floor(255 * shade(d0 + step / 2) + 0.5)
            if a > 0 then
                surface.SetDrawColor(0, 0, 0, a)
                for k = 0, segs - 1 do
                    local a0, a1 = k / segs * math.pi * 2, (k + 1) / segs * math.pi * 2
                    surface.DrawPoly({ point(d0, a0), point(d1, a0), point(d1, a1), point(d0, a1) })
                end
            end
        end
    cam.End2D()
    render.OverrideAlphaWriteEnable(false)
    render.PopRenderTarget()
    return vignetteMat
end

hook.Add("HUDPaintBackground", "RP1942_IntroVignette", function()
    if not startTime then return end
    local elapsed = RealTime() - startTime

    if elapsed >= totalTime then
        startTime = nil   -- whole intro finished: stop doing any work
        if not RP1942.IntroDone then
            RP1942.IntroDone = true
            hook.Run("RP1942_IntroFinished")   -- e.g. the RP name form (cl_rpname.lua)
        end
        return
    end

    local t = progress(elapsed, blackHold, cfg.vignetteTime)
    if t >= 1 then return end

    -- Cubic ease-out: most of the change early, slow tail
    local strength = cfg.vignetteMax * (1 - t) ^ 3
    if strength < 1 then return end

    surface.SetMaterial(buildVignette())
    surface.SetDrawColor(255, 255, 255, strength)
    surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end)

--[[---------------------------------------------------------------------------
Music
sound.PlayFile streams the downloaded file and gives us a channel whose
volume we can change every frame, which is what makes the fades possible.
---------------------------------------------------------------------------]]
local channel, musicStart
local musicToken = 0   -- guards against a replay while the previous file is still loading

local function stopMusic()
    musicToken = musicToken + 1
    if IsValid(channel) then channel:Stop() end
    channel, musicStart = nil, nil
end

local function startMusic()
    stopMusic()

    local music = RP1942.IntroMusic
    if not music or not music.path then return end

    -- Missing when the player skipped downloads or the server never sent it
    if not file.Exists(music.path, "GAME") then return end

    local token = musicToken
    sound.PlayFile(music.path, "noplay", function(ch, _, errName)
        if token ~= musicToken then
            if IsValid(ch) then ch:Stop() end
            return
        end
        if not IsValid(ch) then
            MsgC(Color(255, 170, 0), "[1942] Intro music failed to play: ", tostring(errName), "\n")
            return
        end

        channel, musicStart = ch, RealTime()
        ch:SetVolume(0)
        ch:Play()
    end)
end

hook.Add("Think", "RP1942_IntroMusic", function()
    if not channel then return end
    if not IsValid(channel) then channel, musicStart = nil, nil return end

    local music = RP1942.IntroMusic
    local elapsed = RealTime() - musicStart
    local fadeOutAt = music.fadeOutAt or (totalTime - music.fadeOut)

    -- Track finished on its own, or the fade-out is done
    if channel:GetState() == GMOD_CHANNEL_STOPPED or elapsed >= fadeOutAt + music.fadeOut then
        stopMusic()
        return
    end

    local fade = progress(elapsed, 0, music.fadeIn) * (1 - progress(elapsed, fadeOutAt, music.fadeOut))

    -- Respect the player's own music slider (Options > Audio) as well as ours
    local gameMusic = GetConVar("snd_musicvolume")
    local base = music.volume * musicVolume:GetFloat() * (gameMusic and gameMusic:GetFloat() or 1)

    channel:SetVolume(base * fade)
end)

--[[---------------------------------------------------------------------------
Triggers
---------------------------------------------------------------------------]]
local function play()
    startTime = RealTime()
    startMusic()
end

hook.Add("InitPostEntity", "RP1942_IntroStart", function()
    if enabled:GetBool() then
        play()
    else
        -- No intro: whatever waits for it goes a moment after spawning
        timer.Simple(3, function()
            if RP1942.IntroDone then return end
            RP1942.IntroDone = true
            hook.Run("RP1942_IntroFinished")
        end)
    end
end)

concommand.Add("rp1942_intro_replay", play)
