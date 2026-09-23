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
        { style = "body",     text = "Keep your papers in order. Curfew is enforced." },
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
    cardHold     = 3.5,
    cardFadeOut  = 1.2,
    blackFade    = 3.0,   -- world fades in after the card is gone
    vignetteTime = 12.0,  -- vignette eases out, starting with the world fade
    vignetteMax  = 235,   -- darkness at the screen edge, 0-255
    vignetteSize = 0.35,  -- how far in from each edge (fraction of screen)
    steps        = 32,    -- vignette smoothness
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
local function buildFonts()
    for style, f in pairs(card.fonts) do
        surface.CreateFont("RP1942_Intro_" .. style, {
            font = f.font,
            size = math.max(12, math.floor(ScrH() * f.size)),
            weight = f.weight,
            antialias = true,
        })
    end
end
buildFonts()
hook.Add("OnScreenSizeChanged", "RP1942_IntroFonts", buildFonts)

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
Alpha strips instead of a gradient texture: identical on every client.
---------------------------------------------------------------------------]]
hook.Add("HUDPaintBackground", "RP1942_IntroVignette", function()
    if not startTime then return end
    local elapsed = RealTime() - startTime

    if elapsed >= totalTime then
        startTime = nil   -- whole intro finished: stop doing any work
        return
    end

    local t = progress(elapsed, blackHold, cfg.vignetteTime)
    if t >= 1 then return end

    -- Cubic ease-out: most of the change early, slow tail
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
    if enabled:GetBool() then play() end
end)

concommand.Add("rp1942_intro_replay", play)
