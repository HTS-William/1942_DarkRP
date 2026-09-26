--[[---------------------------------------------------------------------------
1942 DarkRP - wanted by the Reich (client)

    - The WANTED tag above wanted players. DarkRP draws wanted players through
      Player:drawWantedInfo and lets it be replaced; this is the replacement.
    - "Reich Alert!" boxes, stacked in a corner (RP1942.Wanted.alertPosition).

Colours and text: RP1942.Wanted in sh_wanted.lua.
---------------------------------------------------------------------------]]
local CFG = RP1942.Wanted
local COLS = CFG.colors

local function buildFonts()
    local h = ScrH()
    local function font(name, scale, weight)
        surface.CreateFont(name, { font = "Roboto", size = math.max(12, math.floor(h * scale)), weight = weight, extended = true })
    end
    font("RP1942_WantedTag",    0.030, 900)
    font("RP1942_WantedReason", 0.016, 500)
    font("RP1942_AlertTitle",   0.015, 500)
    font("RP1942_AlertText",    0.026, 800)
end
buildFonts()
hook.Add("OnScreenSizeChanged", "RP1942_WantedFonts", buildFonts)

local function mix(a, b, t)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a or 255, b.a or 255))
end

-- alpha: 0-1, multiplies the colours' own transparency (for fading with distance)
local function withAlpha(col, alpha)
    return Color(col.r, col.g, col.b, (col.a or 255) * alpha)
end

local function shadowText(text, font, x, y, col, alignX, alignY, alpha)
    alpha = alpha or 1
    draw.SimpleText(text, font, x + 2, y + 2, withAlpha(COLS.tagShadow, alpha), alignX, alignY)
    draw.SimpleText(text, font, x, y, withAlpha(col, alpha), alignX, alignY)
end

--[[---------------------------------------------------------------------------
WANTED above the head. DarkRP calls this for every wanted player in view,
whether or not you're looking at them, so the name is drawn here too.
    WANTED            (pulsing)
    Killed Hans (...) (reason, optional)
    Noah Kruger       (name, in job colour, like DarkRP's)
---------------------------------------------------------------------------]]
local plyMeta = FindMetaTable("Player")

function plyMeta:drawWantedInfo()
    if not self:Alive() then return end
    local lp = LocalPlayer()
    local head = self:EyePos()
    local dist = lp:GetPos():Distance(head)
    if dist > CFG.tagMaxDistance then return end
    -- Full strength up close, fading out over the last quarter of the range
    local alpha = math.Clamp((CFG.tagMaxDistance - dist) / (CFG.tagMaxDistance * 0.25), 0, 1)
    if head.isInSight and not head:isInSight({ lp, self }) then return end

    head.z = head.z + 10
    local pos = head:ToScreen()
    if not pos.visible then return end
    local x, y = pos.x, pos.y

    -- Name, where DarkRP puts it
    if GAMEMODE.Config.showname then
        local job = RPExtraTeams[self:Team()]
        local nameCol = job and job.color or team.GetColor(self:Team())
        draw.DrawNonParsedText(self:Nick(), "DarkRPHUD2", x + 1, y + 1, withAlpha(color_black, alpha), 1)
        draw.DrawNonParsedText(self:Nick(), "DarkRPHUD2", x, y, withAlpha(nameCol, alpha), 1)
    end

    local bottom = y - 2
    if CFG.showReason then
        local reason = self:getDarkRPVar("wantedReason")
        if reason and reason ~= "" then
            shadowText(reason, "RP1942_WantedReason", x, bottom, COLS.reason, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, alpha)
            surface.SetFont("RP1942_WantedReason")
            local _, rh = surface.GetTextSize(reason)
            bottom = bottom - rh - 1
        end
    end

    local pulse = 0.5 + 0.5 * math.sin(CurTime() * 5)
    shadowText("WANTED", "RP1942_WantedTag", x, bottom, mix(COLS.tag, COLS.tagPulse, pulse * 0.6), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, alpha)
end

--[[---------------------------------------------------------------------------
Reich Alert! boxes

    ┌─────────────────────────────────────────┐
    │ Reich Alert!                            │   small, grey
    │─────────────────────────────────────────│   red line (green when cleared)
    │ Noah Kruger is now wanted by the Reich! │   large, white
    └─────────────────────────────────────────┘
Newest on top; each slides in, holds, then fades.
---------------------------------------------------------------------------]]
local alerts = {}
local indicatorH = 0   -- height of the wanted indicator, so alerts in the same corner sit below it

net.Receive("RP1942_Alert", function()
    local text, kind = net.ReadString(), net.ReadString()
    table.insert(alerts, 1, { text = text, kind = kind, start = RealTime() })
    while #alerts > CFG.alertMax do table.remove(alerts) end
    if CFG.alertSound then surface.PlaySound(CFG.alertSound) end
    MsgC(COLS.alertLine, "[" .. CFG.alertTitle .. "] ", color_white, text, "\n")
end)

hook.Add("HUDPaint", "RP1942_ReichAlerts", function()
    if #alerts == 0 then return end
    local sw, sh = ScrW(), ScrH()
    local s = math.Clamp(sh / 1080, 0.7, 1.6)
    local pad, margin, gap = math.floor(8 * s), math.floor(16 * s), math.floor(8 * s)

    surface.SetFont("RP1942_AlertTitle")
    local _, titleH = surface.GetTextSize(CFG.alertTitle)
    local titleW = surface.GetTextSize(CFG.alertTitle)
    surface.SetFont("RP1942_AlertText")
    local _, textH = surface.GetTextSize("Ag")

    local boxH = pad + titleH + math.floor(4 * s) + 2 + math.floor(4 * s) + textH + pad
    local y = margin
    if CFG.alertPosition == "topcenter" then y = math.floor(sh * 0.019) + math.floor(60 * s) end
    if CFG.alertPosition == CFG.selfPosition and indicatorH > 0 then y = y + indicatorH + gap end

    local now = RealTime()
    for i = #alerts, 1, -1 do
        if now - alerts[i].start > CFG.alertSeconds then table.remove(alerts, i) end
    end

    for _, a in ipairs(alerts) do
        local t = now - a.start
        local slide = math.Clamp(t / 0.3, 0, 1)
        slide = math.ease and math.ease.OutCubic(slide) or slide
        local fade = math.Clamp((CFG.alertSeconds - t) / 0.6, 0, 1) * slide

        surface.SetFont("RP1942_AlertText")
        local w = math.max(surface.GetTextSize(a.text), titleW) + pad * 2

        local x
        if CFG.alertPosition == "topright" then
            x = sw - margin - w + (1 - slide) * (w + margin)
        elseif CFG.alertPosition == "topcenter" then
            x = (sw - w) / 2
        else
            x = margin - (1 - slide) * (w + margin)
        end

        local function col(c) return Color(c.r, c.g, c.b, (c.a or 255) * fade) end
        draw.RoundedBox(4, x, y, w, boxH, col(COLS.alertBg))
        draw.SimpleText(CFG.alertTitle, "RP1942_AlertTitle", x + pad, y + pad, col(COLS.alertTitle))
        local lineY = y + pad + titleH + math.floor(4 * s)
        surface.SetDrawColor(col(a.kind == "clear" and COLS.alertClear or COLS.alertLine))
        surface.DrawRect(x, lineY, w, 2)
        draw.SimpleTextOutlined(a.text, "RP1942_AlertText", x + pad, lineY + 2 + math.floor(4 * s),
            col(COLS.alertText), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 200 * fade))

        y = y + boxH + gap
    end
end)

--[[---------------------------------------------------------------------------
The wanted player's own indicator (they can't see the tag over their head):
a small tag in a corner, with a red bar and a pulsing dot:   ▌● WANTED
---------------------------------------------------------------------------]]
local wasWanted = false

local function indicatorLayout()
    local s = math.Clamp(ScrH() / 1080, 0.7, 1.6)
    surface.SetFont("RP1942_AlertText")
    local tw, th = surface.GetTextSize(CFG.selfText)
    local pad, dot, bar = math.floor(8 * s), math.floor(10 * s), math.floor(4 * s)
    return s, pad, dot, bar, bar + pad + dot + pad + tw + pad * 2, th + pad * 2
end

hook.Add("HUDPaint", "RP1942_WantedSelf", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local wanted = lp:getDarkRPVar("wanted") and true or false
    if wanted and not wasWanted and CFG.selfSound then surface.PlaySound(CFG.selfSound) end
    wasWanted = wanted

    indicatorH = 0
    if not (wanted and CFG.selfIndicator and lp:Alive()) then return end
    -- The 1942 HUD shows WANTED as a status tag instead (rp1942_hud)
    if RP1942.HUDConfig and RP1942.HUDConfig.enabled then return end

    local sw = ScrW()
    local s, pad, dot, bar, w, h = indicatorLayout()
    local margin = math.floor(16 * s)
    local x
    if CFG.selfPosition == "topleft" then x = margin
    elseif CFG.selfPosition == "topcenter" then x = math.floor((sw - w) / 2)
    else x = sw - margin - w end
    local y = margin
    if CFG.selfPosition == "topcenter" then y = math.floor(ScrH() * 0.019) + math.floor(60 * s) end
    indicatorH = h

    draw.RoundedBox(4, x, y, w, h, COLS.selfBg)
    surface.SetDrawColor(COLS.selfAccent)
    surface.DrawRect(x, y, bar, h)

    local pulse = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(CurTime() * 4))
    local dx = x + bar + pad
    draw.RoundedBox(dot / 2, dx, y + (h - dot) / 2, dot, dot,
        Color(COLS.selfAccent.r, COLS.selfAccent.g, COLS.selfAccent.b, 255 * pulse))

    draw.SimpleTextOutlined(CFG.selfText, "RP1942_AlertText", dx + dot + pad, y + h / 2, COLS.selfText,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
end)
