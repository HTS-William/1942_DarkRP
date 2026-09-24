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

local function shadowText(text, font, x, y, col, alignX, alignY)
    draw.SimpleText(text, font, x + 2, y + 2, COLS.tagShadow, alignX, alignY)
    draw.SimpleText(text, font, x, y, col, alignX, alignY)
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
    if lp:GetPos():DistToSqr(head) > CFG.tagMaxDistance ^ 2 then return end
    if head.isInSight and not head:isInSight({ lp, self }) then return end

    head.z = head.z + 10
    local pos = head:ToScreen()
    if not pos.visible then return end
    local x, y = pos.x, pos.y

    -- Name, where DarkRP puts it
    if GAMEMODE.Config.showname then
        local job = RPExtraTeams[self:Team()]
        local nameCol = job and job.color or team.GetColor(self:Team())
        draw.DrawNonParsedText(self:Nick(), "DarkRPHUD2", x + 1, y + 1, color_black, 1)
        draw.DrawNonParsedText(self:Nick(), "DarkRPHUD2", x, y, nameCol, 1)
    end

    local bottom = y - 2
    if CFG.showReason then
        local reason = self:getDarkRPVar("wantedReason")
        if reason and reason ~= "" then
            shadowText(reason, "RP1942_WantedReason", x, bottom, COLS.reason, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            surface.SetFont("RP1942_WantedReason")
            local _, rh = surface.GetTextSize(reason)
            bottom = bottom - rh - 1
        end
    end

    local pulse = 0.5 + 0.5 * math.sin(CurTime() * 5)
    shadowText("WANTED", "RP1942_WantedTag", x, bottom, mix(COLS.tag, COLS.tagPulse, pulse * 0.6), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
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
