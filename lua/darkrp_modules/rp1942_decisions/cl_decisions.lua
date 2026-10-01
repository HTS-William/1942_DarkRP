--[[---------------------------------------------------------------------------
1942 DarkRP - the Führer's decisions (client)

The window: the situation, three answers tagged by impact, a countdown.
Closing it ("Decide later") leaves a reminder at the top of the screen;
/decision reopens it. After answering, the same window shows the outcome.
Everyone else gets a banner: the Führer chose wisely / poorly.
---------------------------------------------------------------------------]]
local D = RP1942.Decisions

-- fonts sized from the screen: lua/autorun/client/rp1942_screenfonts.lua
RP1942.screenFont("RP1942_DecTitle", 0.024, 900, { min = 18 })
RP1942.screenFont("RP1942_DecText", 0.019, 500, { min = 15 })
RP1942.screenFont("RP1942_DecAnswer", 0.017, 500, { min = 14 })
RP1942.screenFont("RP1942_DecTag", 0.0135, 800)
RP1942.screenFont("RP1942_DecBig", 0.036, 900, { min = 24 })

local COL = {
    bg = Color(22, 21, 19, 250), title = Color(30, 28, 25), rule = Color(128, 26, 24),
    card = Color(36, 34, 31), cardHover = Color(48, 45, 40), gold = Color(201, 168, 92),
    text = Color(236, 228, 212), sub = Color(160, 152, 136), good = Color(120, 176, 92), bad = Color(214, 70, 58),
    bar = Color(58, 54, 48),
}

local function wrap(text, font, maxW)
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
    return lines
end

local function fh(font) return draw.GetFontHeight(font) end

local function clock(sec)
    sec = math.max(0, math.ceil(sec))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local state = {}   -- index, endsAt, test (what's waiting); frame
local frame

local function scale() return math.Clamp(ScrH() / 1080, 0.75, 1.5) end

-- A text block that paints wrapped lines (height set from its width)
local function textBlock(parent, text, font, color, width)
    local lines = wrap(text, font, width)
    local p = parent:Add("DPanel")
    p:SetTall(#lines * fh(font) + 2)
    p.Paint = function(_, w)
        local y = 0
        for _, l in ipairs(lines) do
            draw.SimpleText(l, font, 0, y, color)
            y = y + fh(font)
        end
    end
    return p
end

local function makeFrame(height, titleText, rightText)
    if IsValid(frame) then frame:Remove() end
    local s = scale()
    local w = math.floor(math.min(ScrW() * 0.9, 760 * s))
    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame:SetSize(w, height)
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)   -- you can still walk while it's open
    frame.titleH = math.floor(50 * s)
    frame.pad = math.floor(18 * s)
    frame.Paint = function(f, fw, fh2)
        draw.RoundedBox(8, 0, 0, fw, fh2, COL.bg)
        draw.RoundedBoxEx(8, 0, 0, fw, f.titleH, COL.title, true, true, false, false)
        surface.SetDrawColor(COL.rule)
        surface.DrawRect(0, f.titleH - 3, fw, 3)
        draw.SimpleText(titleText, "RP1942_DecTitle", f.pad, f.titleH / 2, COL.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local r = isfunction(rightText) and rightText() or rightText
        if r then draw.SimpleText(r, "RP1942_DecTag", fw - f.pad, f.titleH / 2, COL.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
    end
    return frame, w, s
end

local function flatButton(parent, text, onClick)
    local b = parent:Add("DButton")
    b:SetText("")
    b.hover = 0
    b.DoClick = function() surface.PlaySound("ui/buttonclick.wav") onClick() end
    b.Paint = function(btn, w, h)
        btn.hover = Lerp(FrameTime() * 12, btn.hover, btn:IsHovered() and 1 or 0)
        draw.RoundedBox(4, 0, 0, w, h, Color(Lerp(btn.hover, 64, 128), Lerp(btn.hover, 30, 26), Lerp(btn.hover, 28, 24)))
        draw.SimpleText(text, "RP1942_DecTag", w / 2, h / 2, COL.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return b
end

--[[ The question ------------------------------------------------------------]]
local function openQuestion()
    local q = D.questions[state.index]
    if not q then return end
    local s = scale()
    local w = math.floor(math.min(ScrW() * 0.9, 760 * s))
    local pad = math.floor(18 * s)
    local inner = w - pad * 2
    local gap = math.floor(8 * s)

    -- Work out each answer card's height first, then the window's
    local cardPad = math.floor(12 * s)
    local strip = math.max(4, math.floor(5 * s))
    local answerW = inner - cardPad * 2 - strip
    local cards, cardsH = {}, 0
    for i, a in ipairs(q.answers) do
        local lines = wrap(a.text, "RP1942_DecAnswer", answerW)
        local h = cardPad + fh("RP1942_DecTag") + math.floor(6 * s) + #lines * fh("RP1942_DecAnswer") + cardPad
        cards[i] = { answer = a, lines = lines, h = h }
        cardsH = cardsH + h + gap
    end
    local situation = wrap(q.text, "RP1942_DecText", inner)
    local barH = math.floor(4 * s)
    local testH = state.test and (fh("RP1942_DecTag") + gap) or 0
    local titleH = math.floor(50 * s)
    local height = titleH + barH + pad + testH + #situation * fh("RP1942_DecText") + pad + cardsH + math.floor(34 * s) + pad

    local f = makeFrame(math.min(height, ScrH() * 0.92), "A DECISION FOR THE FÜHRER", function()
        return "Answer within " .. clock(state.endsAt - CurTime())
    end)
    f.PaintOver = function(_, fw)
        -- time left, as a bar under the title
        local frac = math.Clamp((state.endsAt - CurTime()) / D.settings.answerTime, 0, 1)
        surface.SetDrawColor(COL.bar)
        surface.DrawRect(0, titleH, fw, barH)
        surface.SetDrawColor(frac > 0.25 and COL.gold or COL.bad)
        surface.DrawRect(0, titleH, fw * frac, barH)
    end
    f.Think = function(self)
        if state.endsAt and CurTime() > state.endsAt + 1 then self:Remove() end
    end

    local body = vgui.Create("DScrollPanel", f)
    body:SetPos(pad, titleH + barH + pad)
    body:SetSize(inner, f:GetTall() - titleH - barH - pad * 2)
    if RP1942.F4UI and RP1942.F4UI.styleScroll then RP1942.F4UI.styleScroll(body) end

    if state.test then
        local t = textBlock(body, "TEST: you aren't the Führer, but the economy really changes.", "RP1942_DecTag", COL.bad, inner)
        t:Dock(TOP) t:DockMargin(0, 0, 0, gap)
    end
    local sit = textBlock(body, q.text, "RP1942_DecText", COL.text, inner)
    sit:Dock(TOP)
    sit:DockMargin(0, 0, 0, pad)

    for i, c in ipairs(cards) do
        local imp = RP1942.decisionImpact(c.answer.impact)
        local card = body:Add("DButton")
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, gap)
        card:SetTall(c.h)
        card:SetText("")
        card.hover = 0
        card.DoClick = function()
            surface.PlaySound("buttons/button14.wav")
            net.Start("RP1942_DecisionAnswer")
            net.WriteUInt(state.index, 8)
            net.WriteUInt(i, 2)
            net.SendToServer()
            card.DoClick = function() end
        end
        local odds = D.settings.showOdds and string.format("%d–%d%% odds   ·   ±%d–%d economy",
            math.Round(imp.chance[1] * 100), math.Round(imp.chance[2] * 100), imp.points[1], imp.points[2]) or nil
        card.Paint = function(btn, cw, ch)
            btn.hover = Lerp(FrameTime() * 12, btn.hover, btn:IsHovered() and 1 or 0)
            local bg = Color(Lerp(btn.hover, COL.card.r, COL.cardHover.r), Lerp(btn.hover, COL.card.g, COL.cardHover.g), Lerp(btn.hover, COL.card.b, COL.cardHover.b))
            draw.RoundedBox(4, 0, 0, cw, ch, bg)
            surface.SetDrawColor(imp.color)
            surface.DrawRect(0, 0, strip, ch)
            local x, y = strip + cardPad, cardPad
            draw.SimpleText(i .. ".  " .. imp.name, "RP1942_DecTag", x, y, imp.color)
            if odds then draw.SimpleText(odds, "RP1942_DecTag", cw - cardPad, y, COL.sub, TEXT_ALIGN_RIGHT) end
            y = y + fh("RP1942_DecTag") + math.floor(6 * s)
            for _, l in ipairs(c.lines) do
                draw.SimpleText(l, "RP1942_DecAnswer", x, y, COL.text)
                y = y + fh("RP1942_DecAnswer")
            end
        end
    end

    local later = flatButton(body, "Decide later   (/decision)", function() f:Remove() end)
    later:Dock(TOP)
    later:SetTall(math.floor(30 * s))
end

--[[ The outcome (the Führer only) ------------------------------------------]]
local function openResult(index, choice, success, chance, moved)
    local q = D.questions[index]
    local a = q and q.answers[choice]
    if not a then return end
    local s = scale()
    local w = math.floor(math.min(ScrW() * 0.9, 760 * s))
    local pad = math.floor(18 * s)
    local inner = w - pad * 2
    local said = wrap("“" .. a.text .. "”", "RP1942_DecAnswer", inner)
    local what = wrap(success and a.success or a.failure, "RP1942_DecText", inner)
    local titleH = math.floor(50 * s)
    local height = titleH + pad + #said * fh("RP1942_DecAnswer") + pad + fh("RP1942_DecBig") + math.floor(8 * s)
        + #what * fh("RP1942_DecText") + pad + fh("RP1942_DecText") + pad + math.floor(32 * s) + pad

    local f = makeFrame(height, "A DECISION FOR THE FÜHRER", RP1942.decisionImpact(a.impact).name)
    local closeAt = RealTime() + 40
    f.Think = function(self) if RealTime() > closeAt then self:Remove() end end

    local y = titleH + pad
    local function place(p) p:SetPos(pad, y) p:SetWide(inner) y = y + p:GetTall() end
    place(textBlock(f, "“" .. a.text .. "”", "RP1942_DecAnswer", COL.sub, inner))
    y = y + pad
    local head = vgui.Create("DPanel", f)
    head:SetTall(fh("RP1942_DecBig") + math.floor(8 * s))
    head.Paint = function()
        draw.SimpleText(success and "SUCCESS!" or "FAILURE!", "RP1942_DecBig", 0, 0, success and COL.good or COL.bad)
    end
    place(head)
    place(textBlock(f, success and a.success or a.failure, "RP1942_DecText", COL.text, inner))
    y = y + pad
    local econ = moved == 0 and (success and "The economy can't grow any further." or "The economy can't fall any further.")
        or string.format("Economy %s%d   ·   the odds were %d%%", success and "+" or "−", moved, math.Round(chance * 100))
    place(textBlock(f, econ, "RP1942_DecText", success and COL.good or COL.bad, inner))
    y = y + pad
    local ok = flatButton(f, "Close", function() f:Remove() end)
    ok:SetSize(math.floor(120 * s), math.floor(32 * s))
    ok:SetPos(w - pad - ok:GetWide(), y)
end

--[[ Messages ----------------------------------------------------------------]]
net.Receive("RP1942_DecisionOpen", function()
    state.index = net.ReadUInt(8)
    state.endsAt = net.ReadFloat()
    state.test = net.ReadBool()
    surface.PlaySound("ambient/levels/prison/radio_random11.wav")
    openQuestion()
end)

net.Receive("RP1942_DecisionResult", function()
    local index, choice = net.ReadUInt(8), net.ReadUInt(2)
    local success, chance, moved = net.ReadBool(), net.ReadFloat(), net.ReadUInt(8)
    state.index = nil
    surface.PlaySound(success and "buttons/button9.wav" or "buttons/button8.wav")
    openResult(index, choice, success, chance, moved)
end)

net.Receive("RP1942_DecisionClose", function()
    local reason, ignored = net.ReadString(), net.ReadBool()
    state.index = nil
    if IsValid(frame) then frame:Remove() end
    if reason ~= "" then chat.AddText(COL.gold, "[Führer] ", COL.text, reason) end
    if ignored then surface.PlaySound("ambient/alarms/klaxon1.wav") end
end)

net.Receive("RP1942_DecisionBanner", function()
    local kind, moved = net.ReadUInt(2), net.ReadUInt(8)   -- 0 poorly, 1 wisely, 2 ignored
    local success = kind == 1
    local T = D.text
    local title, bodyFmt, capped
    if kind == 1 then title, bodyFmt, capped = T.wiseTitle, T.wiseBody, T.wiseCapped
    elseif kind == 2 then title, bodyFmt, capped = T.ignoredTitle, T.ignoredBody, T.ignoredCapped
    else title, bodyFmt, capped = T.poorTitle, T.poorBody, T.poorCapped end
    local body = moved == 0 and capped or string.format(bodyFmt, moved)
    if RP1942.showAlertBanner then
        RP1942.showAlertBanner(success and "decisionGood" or "decisionBad", title, body, D.settings.resultTime)
    end
    chat.AddText(success and COL.good or COL.bad, "[Reich] ", COL.text, body)
    surface.PlaySound(success and "ambient/alarms/warningbell1.wav" or "ambient/alarms/klaxon1.wav")
end)

-- A reminder while a decision waits and its window is closed
hook.Add("HUDPaint", "RP1942_DecisionReminder", function()
    if not state.index or IsValid(frame) then return end
    local left = (state.endsAt or 0) - CurTime()
    if left <= 0 then state.index = nil return end
    local text = "A decision awaits you   ·   " .. clock(left) .. "   ·   /decision"
    surface.SetFont("RP1942_DecTag")
    local tw, th = surface.GetTextSize(text)
    local w, h = tw + 40, th + 14
    local x = ScrW() / 2 - w / 2
    local y = math.floor(ScrH() * 0.019) + 20
    if RP1942.BannerBottom then y = math.max(y, RP1942.BannerBottom + 8) end
    draw.RoundedBox(h / 2, x, y, w, h, Color(112, 22, 22, 235))
    local pulse = 0.5 + 0.5 * math.sin(CurTime() * 5)
    draw.RoundedBox(4, x + 14, y + h / 2 - 4, 8, 8, Color(COL.gold.r, COL.gold.g, COL.gold.b, 120 + 135 * pulse))
    draw.SimpleText(text, "RP1942_DecTag", ScrW() / 2 + 8, y + h / 2, COL.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
