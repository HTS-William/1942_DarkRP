--[[---------------------------------------------------------------------------
1942 DarkRP - notifications in the HUD's style (client)

Every bottom-right notification (DarkRP.notify from any of our systems,
DarkRP's own, Garry's Mod's, other addons') is drawn like the rest of the
HUD instead of Garry's Mod's default boxes:

    ▌ Someone is knocking at your door.
    ▌ You can't afford that.          <- red strip: an error

They stack on the right side, a bit below the middle, newest at the bottom.
Each slides in, stays for its time, then fades. Long ones wrap (3 lines).
Strip colours by kind: notice / hint gold, error red, undo / cleanup grey.

Garry's Mod's "progress" notices (downloads...) keep their own look.
RP1942.HUDConfig.notices = false (sh_hud.lua) brings the default boxes back.
---------------------------------------------------------------------------]]
local CFG = RP1942.HUDConfig
if not CFG then return end

local function C(key) return RP1942.col(key) end   -- rp1942_core/cl_theme.lua

local STRIP = {
    [0] = "gold",                       -- NOTIFY_GENERIC
    [1] = Color(214, 64, 52),           -- NOTIFY_ERROR
    [2] = "sub",                        -- NOTIFY_UNDO
    [3] = "gold",                       -- NOTIFY_HINT
    [4] = "sub",                        -- NOTIFY_CLEANUP
}
local function stripColour(kind)
    local c = STRIP[kind] or "gold"
    return isstring(c) and C(c) or c
end

-- Its own font, a little bigger than the HUD's body text (lua/autorun/client/rp1942_screenfonts.lua)
RP1942.screenFont("RP1942_HudNotice", CFG.noticeText or 0.018, 500, { min = 14 })

local notices = {}   -- oldest first

local function wrap(text, font, maxW, maxLines)
    surface.SetFont(font)
    local lines, line = {}, ""
    for word in string.gmatch(text or "", "%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if surface.GetTextSize(try) <= maxW then
            line = try
        else
            if line ~= "" then lines[#lines + 1] = line end
            line = word
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    if #lines > maxLines then
        for i = #lines, maxLines + 1, -1 do lines[i] = nil end
        lines[maxLines] = lines[maxLines] .. " ..."
    end
    return lines
end

local function add(text, kind, length)
    text = tostring(text or "")
    if text == "" then return end
    notices[#notices + 1] = { text = text, kind = tonumber(kind) or 0, start = RealTime(), len = math.max(tonumber(length) or 4, 1) }
    while #notices > (CFG.noticeMax or 5) do table.remove(notices, 1) end
end

-- Take over Garry's Mod's notifications (DarkRP's go through here too).
-- Done again after load, in case another addon replaced it in the meantime.
local function takeOver()
    if not notification or notification.RP1942_Styled == notification.AddLegacy then return end
    local original = notification.RP1942_Original or notification.AddLegacy
    notification.RP1942_Original = original
    notification.AddLegacy = function(text, kind, length)
        if CFG.enabled == false or CFG.notices == false then return original(text, kind, length) end
        add(text, kind, length)
    end
    notification.RP1942_Styled = notification.AddLegacy
end
takeOver()
hook.Add("InitPostEntity", "RP1942_HUDNotices", function() timer.Simple(1, takeOver) end)

hook.Add("HUDPaint", "RP1942_HUDNotices", function()
    if #notices == 0 then return end
    local now = RealTime()
    local sw, sh = ScrW(), ScrH()
    local s = math.max(sh / 1080, 0.6)
    local areaW = math.min(sw, sh * (CFG.maxAspect or 21 / 9))
    local right = math.floor((sw + areaW) / 2) - math.floor(16 * s)
    local pad, gap = math.floor(13 * s), math.floor(7 * s)
    local strip = math.max(4, math.floor(5 * s))
    local maxW = math.floor(math.min((CFG.noticeWidth or 440) * s, areaW * 0.36))
    local font = "RP1942_HudNotice"
    local lineH = draw.GetFontHeight(font) + math.floor(2 * s)

    -- the stack's bottom edge: noticeY of the way down the screen (0.6 = a bit
    -- below the middle), never into the ammo panel. noticeY = false: right
    -- above the ammo panel.
    local ammo = RP1942.HUDRects and RP1942.HUDRects.ammo
    local lowest = (ammo and ammo.y or (sh - math.floor(16 * s))) - math.floor(8 * s)
    local y = CFG.noticeY and math.min(math.floor(sh * CFG.noticeY), lowest) or lowest

    for i = #notices, 1, -1 do
        local n = notices[i]
        local age = now - n.start
        if age > n.len + 0.5 then
            table.remove(notices, i)
        else
            if not n.lines or n.maxW ~= maxW then
                n.maxW = maxW
                n.lines = wrap(n.text, font, maxW - pad * 2 - strip, 3)
                surface.SetFont(font)
                local widest = 0
                for _, l in ipairs(n.lines) do widest = math.max(widest, (surface.GetTextSize(l))) end
                n.w = widest + pad * 2 + strip
                n.h = pad * 2 + #n.lines * lineH - math.floor(2 * s)
            end
            -- slide in from the right, fade out at the end, glide when the stack moves
            local slideIn = math.Clamp(age / 0.25, 0, 1)
            slideIn = 1 - (1 - slideIn) ^ 3
            local fade = math.Clamp((n.len + 0.5 - age) / 0.5, 0, 1)
            local targetY = y - n.h
            n.y = n.y and Lerp(math.min(FrameTime() * 12, 1), n.y, targetY) or targetY
            local x = right - n.w + math.floor((1 - slideIn) * (n.w + 30 * s))
            local a = 255 * fade

            local bg = C("bg")
            draw.RoundedBox(6, x, n.y, n.w, n.h, Color(bg.r, bg.g, bg.b, 235 * fade))
            local sc = stripColour(n.kind)
            draw.RoundedBoxEx(6, x, n.y, strip, n.h, Color(sc.r, sc.g, sc.b, a), true, false, true, false)
            local tc = C("text")
            local ty = n.y + pad
            for _, l in ipairs(n.lines) do
                draw.SimpleText(l, font, x + strip + pad, ty, Color(tc.r, tc.g, tc.b, a))
                ty = ty + lineH
            end
            y = targetY - gap * fade   -- a fading notice gives its room back gradually
        end
    end
end)
