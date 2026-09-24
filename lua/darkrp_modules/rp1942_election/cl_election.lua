--[[---------------------------------------------------------------------------
1942 DarkRP - Führer election (client)

The ballot window, the HUD notice while an election runs, and the chat
announcements. Nothing here decides anything - buttons only ask the server.

Open with /election, the console command rp1942_election (bindable), or by
clicking the Führer job in F4. It also opens by itself when voting starts.
---------------------------------------------------------------------------]]
local C = RP1942.ElectionConfig
local IDLE, REG, VOTING = RP1942.ELECTION_IDLE, RP1942.ELECTION_REGISTRATION, RP1942.ELECTION_VOTING

RP1942.ElectionState = RP1942.ElectionState or { phase = IDLE, endsAt = 0, candidates = {}, myVote = NULL }
local S = RP1942.ElectionState

--[[---------------------------------------------------------------------------
Look
---------------------------------------------------------------------------]]
local COL = {
    bg        = Color(22, 21, 19, 250),
    header    = Color(112, 22, 22),
    card      = Color(36, 34, 31),
    cardHover = Color(46, 43, 39),
    red       = Color(128, 26, 24),
    redHover  = Color(156, 36, 32),
    gold      = Color(201, 168, 92),
    text      = Color(236, 228, 212),
    sub       = Color(160, 152, 136),
    barBg     = Color(58, 54, 48),
    disabled  = Color(52, 49, 45),
    shade     = Color(0, 0, 0, 90),
}

local function buildFonts()
    local h = ScrH()
    local function font(name, scale, weight, face)
        surface.CreateFont(name, {
            font = face or "Roboto", size = math.max(12, math.floor(h * scale)),
            weight = weight, extended = true,   -- extended: the ü in Führer
        })
    end
    font("RP1942_ElTitle",  0.028, 800)
    font("RP1942_ElSub",    0.016, 300, "Roboto Light")
    font("RP1942_ElTimer",  0.030, 700)
    font("RP1942_ElName",   0.021, 600)
    font("RP1942_ElBody",   0.016, 400)
    font("RP1942_ElSmall",  0.014, 600)
    font("RP1942_ElButton", 0.018, 700)
    font("RP1942_ElAlert",  0.044, 900)
    font("RP1942_ElAlertSub", 0.020, 400)
    font("RP1942_ElAlertMsg", 0.024, 500)
end
buildFonts()
hook.Add("OnScreenSizeChanged", "RP1942_ElectionFonts", buildFonts)

local function clock(seconds)
    return string.FormattedTime(math.max(0, math.ceil(seconds)), "%01i:%02i")
end

local function mix(a, b, t)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a, b.a))
end

local function fee() return DarkRP.formatMoney(C.fee) end

local function send(action, ent)
    net.Start("RP1942_ElectionAction")
    net.WriteString(action)
    if ent then net.WriteEntity(ent) end
    net.SendToServer()
end

--[[---------------------------------------------------------------------------
What the window says (the server re-checks all of it)
---------------------------------------------------------------------------]]
local function isCandidate(ply)
    for _, c in ipairs(S.candidates) do
        if c.ply == ply then return true end
    end
    return false
end

local function enterState()
    if S.phase == VOTING then return false, "VOTING IN PROGRESS" end
    if IsValid(RP1942.getFuhrer()) then return false, "THE OFFICE IS OCCUPIED" end
    if isCandidate(LocalPlayer()) then return false, "YOU ARE STANDING IN THIS ELECTION" end
    if #S.candidates >= C.maxCandidates then return false, "THE BALLOT IS FULL" end
    if not LocalPlayer():canAfford(C.fee) then return false, "YOU NEED " .. fee() .. " TO STAND" end
    return true, "STAND FOR FÜHRER  ·  " .. fee()
end

local function statusText()
    if S.phase == VOTING then
        if isCandidate(LocalPlayer()) then return "You are standing, so you can't vote. Watch the count come in." end
        if IsValid(S.myVote) then return "You voted for " .. S.myVote:Nick() .. ". Results when voting closes." end
        return "Choose one candidate. Your vote is final."
    elseif S.phase == REG then
        return string.format("Registration is open  ·  %d of %d candidates", #S.candidates, C.maxCandidates)
    end
    local f = RP1942.getFuhrer()
    if IsValid(f) then return f:Nick() .. " is Führer. Elections open when the office falls vacant." end
    return "The office is vacant. Stand for " .. fee() .. " to open an election."
end

local function phaseLabel()
    if S.phase == VOTING then return "VOTING" end
    if S.phase == REG then return "REGISTRATION" end
    return IsValid(RP1942.getFuhrer()) and "IN OFFICE" or "VACANT"
end

--[[---------------------------------------------------------------------------
The ballot: a banner across the top of the screen, candidates side by side.
Sized from the screen height, so it fits any resolution. Slides down from the
top on open and back up on close; closes by itself when an election ends.
---------------------------------------------------------------------------]]
local PANEL = {}

-- Shortens text with "..." until it fits (UTF-8 safe, so names like Jörg work)
local function fit(text, font, maxW)
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxW then return text end
    while #text > 0 and surface.GetTextSize(text .. "...") > maxW do
        local last = utf8.offset(text, -1)
        text = string.sub(text, 1, (last or #text) - 1)
    end
    return text .. "..."
end

function PANEL:Init()
    self.fracs = {}   -- animated bar widths, kept across refreshes
    self.anim = 0
    self:SetAlpha(0)
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)   -- players can still walk while it's open

    self.closeBtn = vgui.Create("DButton", self)
    self.closeBtn:SetText("")
    self.closeBtn.DoClick = function() self:Close() end
    self.closeBtn.Paint = function(btn, bw, bh)
        surface.SetDrawColor(btn:IsHovered() and COL.text or COL.sub)
        local p = math.floor(bw * 0.3)
        surface.DrawLine(p, p, bw - p, bh - p)
        surface.DrawLine(bw - p, p, p, bh - p)
    end

    self.row = vgui.Create("Panel", self)

    self.enterBtn = vgui.Create("DButton", self)
    self.enterBtn:SetText("")
    self.enterBtn.hover = 0
    self.enterBtn.DoClick = function()
        if enterState() then
            send("enter")
            surface.PlaySound("buttons/button14.wav")
        end
    end
    self.enterBtn.Paint = function(btn, bw, bh)
        local ok, label = enterState()
        btn.hover = Lerp(FrameTime() * 12, btn.hover, (ok and btn:IsHovered()) and 1 or 0)
        draw.RoundedBox(6, 0, 0, bw, bh, ok and mix(COL.red, COL.redHover, btn.hover) or COL.disabled)
        draw.SimpleText(label, "RP1942_ElButton", bw / 2, bh / 2, ok and COL.text or COL.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        btn:SetCursor(ok and "hand" or "no")
    end

    self:Refresh()
end

-- All sizes in one place, scaled to the screen (1.0 at 1080p)
function PANEL:Metrics()
    local s = math.Clamp(ScrH() / 1080, 0.7, 1.6)
    return {
        s = s,
        pad    = math.floor(14 * s),
        gap    = math.floor(14 * s),
        header = math.floor(54 * s),
        status = math.floor(36 * s),
        cardW  = math.floor(190 * s),
        btnH   = math.floor(40 * s),
        minW   = math.floor(620 * s),
        maxW   = math.min(ScrW() * 0.94, 1180 * s),
        top    = math.floor(ScrH() * 0.019) + 18,   -- just under the economy line
    }
end

function PANEL:Close()
    self.closing = true
    self:SetMouseInputEnabled(false)
end

function PANEL:Think()
    -- Slide down from the top on open, back up on close
    self.anim = math.Approach(self.anim, self.closing and 0 or 1, FrameTime() * 5)
    local e = math.ease and math.ease.OutCubic(self.anim) or self.anim
    self:SetAlpha(255 * e)
    self:SetPos(self.restX, Lerp(e, -self:GetTall(), self.restY))
    if self.closing and self.anim <= 0 then self:Remove() end
end

function PANEL:Paint(w, h)
    local m = self.m
    draw.RoundedBox(10, 0, 0, w, h, COL.bg)

    -- Header band
    draw.RoundedBoxEx(10, 0, 0, w, m.header, COL.header, true, true, false, false)
    surface.SetDrawColor(COL.gold)
    surface.DrawRect(0, m.header - 2, w, 2)

    local cy = m.header / 2 - 1

    -- Right side first (countdown, phase pill), clear of the close button
    local right = w - m.header
    if S.phase ~= IDLE then
        draw.SimpleText(clock(S.endsAt - CurTime()), "RP1942_ElTimer", right, cy, COL.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        surface.SetFont("RP1942_ElTimer")
        right = right - surface.GetTextSize("0:00") - m.gap
    end
    local label = phaseLabel()
    surface.SetFont("RP1942_ElSmall")
    local pw, ph = surface.GetTextSize(label)
    pw, ph = pw + 20, ph + 8
    local pillX = right - pw
    draw.RoundedBox(ph / 2, pillX, cy - ph / 2, pw, ph, COL.shade)
    draw.SimpleText(label, "RP1942_ElSmall", right - pw / 2, cy, COL.gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Then the title, and the subtitle only if it fits before the pill
    local x = m.pad + 4
    draw.SimpleText("REICHSTAGSWAHL", "RP1942_ElTitle", x, cy, COL.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetFont("RP1942_ElTitle")
    x = x + surface.GetTextSize("REICHSTAGSWAHL") + m.gap
    surface.SetFont("RP1942_ElSub")
    if x + surface.GetTextSize("Election for Führer") + m.gap <= pillX then
        draw.SimpleText("Election for Führer", "RP1942_ElSub", x, cy + 2, COL.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Status line, centred under the header
    draw.SimpleText(statusText(), "RP1942_ElBody", w / 2, m.header + m.status / 2, COL.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Where everything sits inside a card, stacked top to bottom from the real
-- height of each font, so lines can never run into each other at any
-- resolution. Every card uses the same layout, so the row lines up.
function PANEL:CardLayout(canVote)
    local s = self.m.s
    local function textH(font)
        surface.SetFont(font)
        local _, h = surface.GetTextSize("Ag")
        return h
    end

    local L = { inset = math.floor(14 * s), avatar = math.floor(56 * s), btnH = math.floor(32 * s) }
    local y = L.inset
    L.avatarY = y;                 y = y + L.avatar + math.floor(10 * s)
    L.nameY = y;                   y = y + textH("RP1942_ElName") + math.floor(2 * s)
    L.jobY = y;                    y = y + textH("RP1942_ElBody")

    L.showVotes = S.phase == VOTING and C.showLiveVotes
    if L.showVotes then
        y = y + math.floor(16 * s)
        L.votesY = y;              y = y + textH("RP1942_ElSmall") + math.floor(6 * s)
        L.barY = y;                y = y + 6
    elseif S.phase == VOTING then  -- votes hidden: just room for "YOUR VOTE"
        y = y + math.floor(12 * s)
        L.votesY = y;              y = y + textH("RP1942_ElSmall")
    end

    if canVote then
        y = y + math.floor(14 * s)
        L.btnY = y;                y = y + L.btnH
    end
    L.h = y + L.inset
    return L
end

-- One candidate, as a column card
function PANEL:AddCard(c, totalVotes, x, cardW, L, canVote)
    local panel, ply = self, c.ply
    local card = vgui.Create("DPanel", self.row)
    card:SetPos(x, 0)
    card:SetSize(cardW, L.h)
    card.hover = 0

    local avatar = vgui.Create("AvatarImage", card)
    avatar:SetMouseInputEnabled(false)
    avatar:SetSize(L.avatar, L.avatar)
    avatar:SetPos(math.floor((cardW - L.avatar) / 2), L.avatarY)
    avatar:SetPlayer(ply, 64)

    if canVote then
        local vote = vgui.Create("DButton", card)
        vote:SetText("")
        vote:SetSize(cardW - L.inset * 2, L.btnH)
        vote:SetPos(L.inset, L.btnY)
        vote.hover = 0
        vote.DoClick = function()
            send("vote", ply)
            surface.PlaySound("buttons/button9.wav")
        end
        vote.Paint = function(btn, bw, bh)
            btn.hover = Lerp(FrameTime() * 12, btn.hover, btn:IsHovered() and 1 or 0)
            draw.RoundedBox(5, 0, 0, bw, bh, mix(COL.red, COL.redHover, btn.hover))
            draw.SimpleText("VOTE", "RP1942_ElButton", bw / 2, bh / 2, COL.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    card.Paint = function(pnl, w, h)
        if not IsValid(ply) then return end
        pnl.hover = Lerp(FrameTime() * 10, pnl.hover, (pnl:IsHovered() or pnl:IsChildHovered()) and 1 or 0)
        local mine = S.myVote == ply

        draw.RoundedBox(8, 0, 0, w, h, mix(COL.card, COL.cardHover, pnl.hover))
        if mine then   -- gold frame around the one you voted for
            surface.SetDrawColor(COL.gold)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end

        local textW = w - L.inset * 2
        draw.SimpleText(fit(ply:Nick(), "RP1942_ElName", textW), "RP1942_ElName", w / 2, L.nameY, COL.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        local job = RPExtraTeams[ply:Team()]
        draw.SimpleText(fit(job and job.name or "", "RP1942_ElBody", textW), "RP1942_ElBody", w / 2, L.jobY, COL.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        if L.showVotes then
            local share = totalVotes > 0 and c.votes / totalVotes or 0
            panel.fracs[ply] = Lerp(FrameTime() * 5, panel.fracs[ply] or 0, share)
            local votesText = string.format("%d vote%s  ·  %d%%", c.votes, c.votes == 1 and "" or "s", math.Round(share * 100))
            draw.SimpleText(votesText, "RP1942_ElSmall", w / 2, L.votesY, mine and COL.gold or COL.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.RoundedBox(3, L.inset, L.barY, textW, 6, COL.barBg)
            draw.RoundedBox(3, L.inset, L.barY, textW * panel.fracs[ply], 6, mine and COL.gold or COL.redHover)
        elseif mine and L.votesY then
            draw.SimpleText("YOUR VOTE", "RP1942_ElSmall", w / 2, L.votesY, COL.gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end
end

-- Rebuilds the cards and resizes the banner to fit them
function PANEL:Refresh()
    local m = self:Metrics()
    self.m = m
    self.row:Clear()

    local list = {}
    for _, c in ipairs(S.candidates) do
        if IsValid(c.ply) then list[#list + 1] = c end
    end
    local n = #list

    -- Card width shrinks if many candidates would not fit across the screen
    local cardW = m.cardW
    if n > 0 then
        cardW = math.min(m.cardW, math.floor((m.maxW - m.pad * 2 - m.gap * (n - 1)) / n))
    end
    local canVote = S.phase == VOTING and not IsValid(S.myVote) and not isCandidate(LocalPlayer())
    local L = self:CardLayout(canVote)
    local rowW = n > 0 and (cardW * n + m.gap * (n - 1)) or math.floor(460 * m.s)
    local rowH = n > 0 and L.h or math.floor(70 * m.s)
    local showEnter = S.phase ~= VOTING   -- nobody can stand once voting starts

    local w = math.max(rowW + m.pad * 2, m.minW)
    local h = m.header + m.status + rowH + m.pad + (showEnter and (m.btnH + m.pad) or 0)
    self:SetSize(w, h)
    self.restX, self.restY = math.floor((ScrW() - w) / 2), m.top

    local closeSize = math.floor(m.header * 0.6)
    self.closeBtn:SetSize(closeSize, closeSize)
    self.closeBtn:SetPos(w - closeSize - math.floor((m.header - closeSize) / 2), math.floor((m.header - closeSize) / 2))

    self.row:SetPos(math.floor((w - rowW) / 2), m.header + m.status)
    self.row:SetSize(rowW, rowH)

    self.enterBtn:SetVisible(showEnter)
    self.enterBtn:SetPos(m.pad, m.header + m.status + rowH + m.pad)
    self.enterBtn:SetSize(w - m.pad * 2, m.btnH)

    if n == 0 then
        local empty = vgui.Create("DPanel", self.row)
        empty:Dock(FILL)
        empty.Paint = function(_, pw, ph)
            draw.RoundedBox(8, 0, 0, pw, ph, COL.card)
            local text = IsValid(RP1942.getFuhrer()) and "No election while the office is held."
                or "No candidates yet. Be the first to stand."
            draw.SimpleText(text, "RP1942_ElBody", pw / 2, ph / 2, COL.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end

    local total = 0
    for _, c in ipairs(list) do total = total + c.votes end
    for i, c in ipairs(list) do
        self:AddCard(c, total, (i - 1) * (cardW + m.gap), cardW, L, canVote)
    end
end

vgui.Register("RP1942_Election", PANEL, "EditablePanel")

function RP1942.openElection()
    if IsValid(RP1942.ElectionPanel) and not RP1942.ElectionPanel.closing then
        RP1942.ElectionPanel:Refresh()
        return
    end
    RP1942.ElectionPanel = vgui.Create("RP1942_Election")
end

concommand.Add("rp1942_election", function()
    send("sync")
    RP1942.openElection()
end)

--[[---------------------------------------------------------------------------
Network
---------------------------------------------------------------------------]]
net.Receive("RP1942_ElectionSync", function()
    local wasRunning = S.phase ~= IDLE
    S.phase = net.ReadUInt(2)
    S.endsAt = net.ReadFloat()
    S.candidates = {}
    for i = 1, net.ReadUInt(8) do
        local ply = net.ReadEntity()
        local votes = net.ReadUInt(10)
        if IsValid(ply) then S.candidates[#S.candidates + 1] = { ply = ply, votes = votes } end
    end
    S.myVote = net.ReadEntity()

    local panel = RP1942.ElectionPanel
    if IsValid(panel) and not panel.closing then
        if wasRunning and S.phase == IDLE then
            panel:Close()   -- the election is over (won or cancelled)
        else
            panel:Refresh()
        end
    end
end)

net.Receive("RP1942_ElectionOpen", function()
    RP1942.openElection()
end)

net.Receive("RP1942_ElectionChat", function()
    chat.AddText(COL.gold, "[Election] ", COL.text, net.ReadString())
    surface.PlaySound("buttons/blip1.wav")
end)

--[[---------------------------------------------------------------------------
Sounds (paths and volumes: RP1942.ElectionSounds in sh_election.lua)
---------------------------------------------------------------------------]]
local soundsOn = CreateClientConVar("rp1942_election_sounds", "1", true, false,
    "Play Führer election sounds (voting bell, anthem)", 0, 1)

-- Playing channels are kept here: a channel nothing refers to can be
-- garbage collected, which silently cuts the sound off mid-play.
local channels = {}

local function playElectionSound(key)
    local cfg = RP1942.ElectionSounds
    local path = cfg[key]
    if not path or not soundsOn:GetBool() then return end

    if not file.Exists(path, "GAME") then
        -- An addon file this player doesn't have: it wasn't downloaded on join
        if string.find(path, "^sounds?/") then
            MsgC(Color(255, 170, 0), "[1942] Can't play election sound '", key, "': ", path,
                " was not downloaded to this computer. See the server's content/download setup.\n")
            return
        end
        surface.PlaySound(path)   -- a stock game sound: no volume control
        return
    end

    local volume = cfg[key .. "Volume"] or 1
    if key == "anthem" then
        local music = GetConVar("snd_musicvolume")
        volume = volume * (music and music:GetFloat() or 1)
    end

    if IsValid(channels[key]) then channels[key]:Stop() end   -- never two anthems at once
    sound.PlayFile(path, "noplay", function(ch, _, err)
        if not IsValid(ch) then
            MsgC(Color(255, 170, 0), "[1942] Election sound '", key, "' failed to play: ", tostring(err), "\n")
            return
        end
        channels[key] = ch
        ch:SetVolume(volume)
        ch:Play()
    end)
end

net.Receive("RP1942_ElectionSound", function()
    playElectionSound(net.ReadString())
end)

-- Joined mid-election: ask for the current state
hook.Add("InitPostEntity", "RP1942_ElectionSync", function()
    send("sync")
end)

--[[---------------------------------------------------------------------------
HUD notice while an election is running (under the economy line)
---------------------------------------------------------------------------]]
hook.Add("HUDPaint", "RP1942_ElectionHUD", function()
    if S.phase == IDLE or IsValid(RP1942.ElectionPanel) then return end

    local what = S.phase == REG and "registration" or "voting"
    local hint = (S.phase == VOTING and (IsValid(S.myVote) or isCandidate(LocalPlayer()))) and "" or "   ·   /election"
    local text = string.format("Führer election  ·  %s  %s%s", what, clock(S.endsAt - CurTime()), hint)

    surface.SetFont("RP1942_ElSmall")
    local tw, th = surface.GetTextSize(text)
    local w, h = tw + 32, th + 12
    local x, y = ScrW() / 2 - w / 2, math.floor(ScrH() * 0.019) + 20

    draw.RoundedBox(h / 2, x, y, w, h, Color(COL.header.r, COL.header.g, COL.header.b, 235))
    local pulse = 0.5 + 0.5 * math.sin(CurTime() * 4)
    draw.RoundedBox(4, x + 12, y + h / 2 - 4, 8, 8, Color(COL.gold.r, COL.gold.g, COL.gold.b, 120 + 135 * pulse))
    draw.SimpleText(text, "RP1942_ElSmall", ScrW() / 2 + 6, y + h / 2, COL.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

--[[---------------------------------------------------------------------------
Headline banners across the top of the screen, in three styles:
    death      red flash, red rules, title throbs red    (the Führer died)
    elected    gold glow, gold rules, title shimmers     (a Führer was elected)
    broadcast  red rules, gold title, the message below  (/broadcast)
Body lines word-wrap and the banner grows to fit them.
---------------------------------------------------------------------------]]
local STYLES = {
    death = {
        flash = Color(140, 0, 0, 110), rule = COL.header,
        pulse = Color(230, 60, 50), bodyCol = COL.gold, bodyFont = "RP1942_ElAlertSub",
    },
    elected = {
        flash = Color(201, 168, 92, 55), rule = COL.gold,
        pulse = Color(255, 226, 150), bodyCol = COL.text, bodyFont = "RP1942_ElAlertSub",
    },
    broadcast = {
        rule = COL.red, titleCol = COL.gold, titleFont = "RP1942_ElAlertSub",
        pulse = Color(255, 226, 150), bodyCol = COL.text, bodyFont = "RP1942_ElAlertMsg",
    },
}

local banner   -- { style, title, body, footer, seconds, start } while showing

local function showBanner(style, title, body, seconds, footer)
    banner = { style = STYLES[style], title = title, body = body, footer = footer,
               seconds = seconds, start = RealTime() }
end

-- Splits text into lines no wider than maxW (words longer than a line are cut)
local function wrap(text, font, maxW, maxLines)
    surface.SetFont(font)
    local lines, line = {}, ""
    for word in string.gmatch(text, "%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if surface.GetTextSize(try) <= maxW then
            line = try
        else
            if line ~= "" then lines[#lines + 1] = line end
            line = fit(word, font, maxW)
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    if maxLines and #lines > maxLines then
        lines[maxLines] = fit(lines[maxLines] .. " " .. lines[maxLines + 1], font, maxW)
        for i = #lines, maxLines + 1, -1 do lines[i] = nil end
    end
    return lines
end

local function fontH(font)
    surface.SetFont(font)
    local _, h = surface.GetTextSize("Ag")
    return h
end

net.Receive("RP1942_FuhrerKilled", function()
    local name, murdered, killer = net.ReadString(), net.ReadBool(), net.ReadString()

    -- A victory anthem still playing would be in poor taste now
    if IsValid(channels.anthem) then channels.anthem:Stop() end

    local sub = killer ~= "" and ("Führer " .. name .. " was killed by " .. killer .. ".")
        or ("Führer " .. name .. " is dead.")
    showBanner("death",
        murdered and "THE FÜHRER HAS BEEN ASSASSINATED" or "THE FÜHRER IS DEAD",
        sub .. "  The office is vacant  ·  /election",
        RP1942.FuhrerDeathAlert.seconds)
end)

net.Receive("RP1942_FuhrerElected", function()
    local name = net.ReadString()
    local votes, total = net.ReadUInt(10), net.ReadUInt(10)
    local how = net.ReadUInt(2)   -- 0 won the vote, 1 unopposed, 2 tie drawn by lot

    local detail
    if how == 1 then
        detail = "stood unopposed"
    elseif how == 2 then
        detail = string.format("won a tied vote by lot  ·  %d of %d votes", votes, total)
    else
        detail = string.format("elected with %d of %d vote%s", votes, total, total == 1 and "" or "s")
    end
    showBanner("elected", string.upper(name) .. " IS THE NEW FÜHRER",
        "Congratulations!  " .. name .. " " .. detail .. ".", C.resultSeconds or 10)
end)

net.Receive("RP1942_FuhrerBroadcast", function()
    local name, text = net.ReadString(), net.ReadString()
    chat.AddText(COL.gold, "[Broadcast] ", COL.red, "Führer " .. name .. ": ", COL.text, text)
    -- Longer messages stay up longer, so they can be read
    local seconds = math.Clamp(5 + utf8.len(text) / 12, 6, 16)
    showBanner("broadcast", "MESSAGE FROM THE FÜHRER", text, seconds, "- Führer " .. name)
end)

hook.Add("HUDPaint", "RP1942_FuhrerAlert", function()
    if not banner then return end
    local st = banner.style
    local duration = banner.seconds
    local t = RealTime() - banner.start
    if t > duration then banner = nil return end

    local sw, sh = ScrW(), ScrH()

    -- Screen flash, fading over the first second or so (not every style has one)
    local flash = 1 - t / 1.2
    if st.flash and flash > 0 then
        surface.SetDrawColor(st.flash.r, st.flash.g, st.flash.b, st.flash.a * flash)
        surface.DrawRect(0, 0, sw, sh)
    end

    -- Size: title, wrapped body lines, optional footer
    local s = math.Clamp(sh / 1080, 0.7, 1.6)
    local w = math.min(sw * 0.9, 1150 * s)
    local pad, ruleH = math.floor(18 * s), math.floor(6 * s)
    local titleFont = st.titleFont or "RP1942_ElAlert"
    banner.lines = banner.lines or wrap(banner.body, st.bodyFont, w - pad * 4, 4)
    local titleH, bodyH, footH = fontH(titleFont), fontH(st.bodyFont), fontH("RP1942_ElSmall")
    local h = ruleH + pad + titleH + math.floor(8 * s) + #banner.lines * bodyH
        + (banner.footer and (math.floor(8 * s) + footH) or 0) + pad + ruleH

    -- Headline: slides down, holds, fades out
    local slide = math.Clamp(t / 0.4, 0, 1)
    slide = math.ease and math.ease.OutBack(slide) or slide
    local fade = math.Clamp((duration - t) / 0.8, 0, 1)
    local x = (sw - w) / 2
    local y = Lerp(slide, -h, math.floor(sh * 0.019) + 18)
    local a = 255 * fade

    draw.RoundedBox(8, x, y, w, h, Color(COL.bg.r, COL.bg.g, COL.bg.b, 240 * fade))
    surface.SetDrawColor(st.rule.r, st.rule.g, st.rule.b, a)
    surface.DrawRect(x, y, w, ruleH)                 -- rule, top
    surface.DrawRect(x, y + h - ruleH, w, ruleH)     -- and bottom

    -- The title pulses for the first few seconds, then settles
    local pulse = math.max(0, 1 - t / 4) * (0.5 + 0.5 * math.sin(t * 10))
    local titleCol = mix(st.titleCol or COL.text, st.pulse, pulse)
    titleCol.a = a
    local cy = y + ruleH + pad
    draw.SimpleText(fit(banner.title, titleFont, w - pad * 2), titleFont, sw / 2, cy, titleCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    cy = cy + titleH + math.floor(8 * s)

    local bodyCol = Color(st.bodyCol.r, st.bodyCol.g, st.bodyCol.b, a)
    for _, line in ipairs(banner.lines) do
        draw.SimpleText(line, st.bodyFont, sw / 2, cy, bodyCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        cy = cy + bodyH
    end
    if banner.footer then
        draw.SimpleText(banner.footer, "RP1942_ElSmall", sw / 2, cy + math.floor(8 * s),
            Color(COL.sub.r, COL.sub.g, COL.sub.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end)
