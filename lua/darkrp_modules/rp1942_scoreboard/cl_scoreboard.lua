--[[---------------------------------------------------------------------------
1942 DarkRP - scoreboard (client)

Hold TAB. Everyone in one list, A to Z, in the same look as the F4 menu.
Click a player to see their card on the right: SteamID, Steam profile, a
private message, and for staff (only) every ULX command they're allowed to
use on that player (teleport, freeze, jail, gag, kick, ban, wanted...). Clicking
anything pins the board open; press TAB again to close it.

Undercover agents (Gestapo, Resistance Operative) show as their cover: the
job title they chose, in that job's colour and faction. Staff, the agent
themself and their own side (who already see the faction tag) see the truth,
marked UNDERCOVER.

ULX commands are only shown when ULX is installed and you have access to
them (ULX menu > Groups). They're run exactly like typing them in console.
---------------------------------------------------------------------------]]
local UI, C

-- The staff actions, in sections. { label, ulx command, extra }
--   prompt = "..."   asks for text first (the reason / message)
--   ban = true       asks for a length first, then a reason
--   danger = true    drawn in the warning colour
local ACTIONS = {
    { title = "Teleport", items = {
        { "Go to", "goto" }, { "Bring", "bring" }, { "Return", "return" }, { "Spectate", "spectate" },
    } },
    { title = "Control", items = {
        { "Freeze", "freeze" }, { "Unfreeze", "unfreeze" }, { "Jail", "jail" }, { "Unjail", "unjail" },
        { "Strip weapons", "strip" }, { "Slay", "slay", danger = true },
        { "God", "god" }, { "Ungod", "ungod" }, { "Cloak", "cloak" }, { "Uncloak", "uncloak" },
    } },
    { title = "Chat & voice", items = {
        { "Gag", "gag" }, { "Ungag", "ungag" }, { "Mute", "mute" }, { "Unmute", "unmute" },
    } },
    { title = "1942", items = {
        { "Make wanted", "makewanted", prompt = "Why are they wanted by the Reich?" },
        { "Clear wanted", "clearwanted" },
    } },
    { title = "Moderation", items = {
        { "Kick", "kick", prompt = "Reason for the kick", danger = true },
        { "Ban", "ban", ban = true, danger = true },
    } },
}

local BAN_LENGTHS = {
    { "1 hour", 60 }, { "1 day", 1440 }, { "3 days", 4320 }, { "1 week", 10080 }, { "1 month", 43200 }, { "Permanent", 0 },
}

--[[---------------------------------------------------------------------------
Helpers
---------------------------------------------------------------------------]]
local function hasULX() return ULib ~= nil and ULib.ucl ~= nil and ulx ~= nil end

local function can(cmd)
    if not hasULX() then return false end
    local ok, result = pcall(ULib.ucl.query, LocalPlayer(), "ulx " .. cmd)
    return ok and result == true
end

-- Run "ulx <cmd> <target> <args...>" on exactly this player
local function runULX(cmd, target, ...)
    if not IsValid(target) then return end
    RunConsoleCommand("ulx", cmd, "$" .. target:UserID(), ...)
    surface.PlaySound("ui/buttonclick.wav")
end

local function isStaff(ply)
    if RP1942.isF4Staff then return RP1942.isF4Staff(ply) end
    return ply:IsAdmin()
end

local function jobByName(name)
    for _, job in ipairs(RPExtraTeams or {}) do
        if job.name == name then return job end
    end
end

local FACTION_TITLE = { reich = "The Reich", resistance = "The Resistance", civilian = "Civilians" }

--[[---------------------------------------------------------------------------
What this viewer sees of a player: title, faction, colour, and whether they
see through a cover (true = shown as UNDERCOVER)
---------------------------------------------------------------------------]]
local function shownAs(ply, viewer)
    local job = RPExtraTeams[ply:Team()]
    local title = ply:getDarkRPVar("job") or (job and job.name) or team.GetName(ply:Team())
    local faction = job and job.faction or "civilian"
    local color = job and job.color or team.GetColor(ply:Team())

    local dis = RP1942.Config and RP1942.Config.Disguise
    local undercover = job and dis and dis.jobs and dis.jobs[job.command]
    if not undercover then return title, faction, color, false end

    local tags = RP1942.Config.FactionTags and RP1942.Config.FactionTags.jobs or {}
    local tag = tags[job.command]
    local seesTruth = ply == viewer or isStaff(viewer)
        or (tag and RP1942.isFaction and RP1942.isFaction(viewer, tag.seenBy))
    if seesTruth then return title, faction, color, true end

    local cover = jobByName(title)
    return title, cover and cover.faction or "civilian", cover and cover.color or Color(150, 150, 150), false
end

-- The usergroup as a short badge ("" for plain users)
local function rankBadge(ply)
    local g = ply:GetUserGroup() or "user"
    if g == "user" or g == "" then return nil end
    return string.upper(g)
end

-- Job colours as text on the dark board: very dark ones are lifted so they read
local function readable(col)
    local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
    if lum >= 110 then return col end
    local t = math.Clamp((110 - lum) / 110, 0.35, 0.7)
    return Color(Lerp(t, col.r, 230), Lerp(t, col.g, 225), Lerp(t, col.b, 215))
end

local function pingColor(ping)
    if ping < 80 then return Color(120, 200, 100) elseif ping < 160 then return Color(220, 190, 80) end
    return Color(220, 90, 70)
end

--[[---------------------------------------------------------------------------
A small themed text prompt (reason for a kick, a private message...)
---------------------------------------------------------------------------]]
local function prompt(title, placeholder, onOK)
    local s = UI.scale()
    local f = vgui.Create("EditablePanel")
    f:SetSize(math.floor(460 * s), math.floor(150 * s))
    f:Center()
    f:MakePopup()
    f:DoModal()
    f.Paint = function(_, w, h)
        draw.RoundedBox(6, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(6, 0, 0, w, math.floor(36 * s), C.titleBar, true, true, false, false)
        surface.SetDrawColor(C.tabActive)
        surface.DrawRect(0, math.floor(36 * s) - 2, w, 2)
        draw.SimpleText(title, "RP1942_F4Head", math.floor(12 * s), math.floor(18 * s), C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local entry = vgui.Create("DTextEntry", f)
    entry:SetPos(math.floor(12 * s), math.floor(48 * s))
    entry:SetSize(f:GetWide() - math.floor(24 * s), math.floor(34 * s))
    entry:SetFont("RP1942_F4Body")
    entry:SetTextColor(C.text)
    entry:SetCursorColor(C.gold)
    entry:SetPlaceholderText(placeholder or "")
    entry:SetPaintBackground(false)
    entry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, C.entry)
        surface.SetDrawColor(self:HasFocus() and C.gold or C.tabHover)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        self:DrawTextEntryText(C.text, Color(C.gold.r, C.gold.g, C.gold.b, 90), C.gold)
        if self:GetValue() == "" then
            draw.SimpleText(placeholder or "", "RP1942_F4Body", 6, h / 2, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    entry:RequestFocus()

    local function done(ok)
        local text = string.Trim(entry:GetValue() or "")
        f:Remove()
        if ok then onOK(text) end
    end
    entry.OnEnter = function() done(true) end

    local bw, bh = math.floor(120 * s), math.floor(34 * s)
    local ok = UI.button(f, "OK", function() done(true) end)
    ok:SetSize(bw, bh)
    ok:SetPos(f:GetWide() - bw * 2 - math.floor(20 * s), f:GetTall() - bh - math.floor(12 * s))
    local cancel = UI.button(f, "Cancel", function() done(false) end)
    cancel:SetSize(bw, bh)
    cancel:SetPos(f:GetWide() - bw - math.floor(12 * s), f:GetTall() - bh - math.floor(12 * s))
end

--[[---------------------------------------------------------------------------
The board
---------------------------------------------------------------------------]]
local PANEL = {}

function PANEL:Init()
    UI, C = RP1942.F4UI, RP1942.F4UI.C
    local s = UI.scale()
    self.titleH = math.floor(46 * s)
    self:SetSize(math.min(ScrW() * 0.76, 1240 * s), math.min(ScrH() * 0.82, 820 * s))
    self:Center()

    self.list = vgui.Create("DScrollPanel", self)
    UI.styleScroll(self.list)
    self.list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end

    self.detail = vgui.Create("DPanel", self)
    self.detail.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end

    self.signature = ""
    self:Rebuild()
end

function PANEL:PerformLayout(w, h)
    local s = UI.scale()
    local pad = math.floor(12 * s)
    local top = self.titleH + pad
    local detailW = math.floor(w * 0.34)
    self.list:SetPos(pad, top)
    self.list:SetSize(w - detailW - pad * 3, h - top - pad)
    self.detail:SetPos(w - detailW - pad, top)
    self.detail:SetSize(detailW, h - top - pad)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, C.bg)
    draw.RoundedBoxEx(8, 0, 0, w, self.titleH, C.titleBar, true, true, false, false)
    surface.SetDrawColor(C.tabActive)
    surface.DrawRect(0, self.titleH - 2, w, 2)

    local s = UI.scale()
    local pad = math.floor(16 * s)
    local CFG = RP1942.F4Config
    draw.SimpleText(CFG.title, "RP1942_F4Title", pad, self.titleH / 2, C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetFont("RP1942_F4Title")
    local tw = surface.GetTextSize(CFG.title .. " ")
    draw.SimpleText(CFG.subtitle, "RP1942_F4Title", pad + tw, self.titleH / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local right = string.format("%d / %d players   ·   %s", player.GetCount(), game.MaxPlayers(), game.GetMap())
    if self.pinned then right = "Pinned: TAB closes   ·   " .. right end
    draw.SimpleText(right, "RP1942_F4Tab", w - pad, self.titleH / 2, C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end


-- Rebuild the list when players, jobs or what this viewer may see change
function PANEL:Think()
    if (self.nextCheck or 0) > RealTime() then return end
    self.nextCheck = RealTime() + 0.5
    local lp, parts = LocalPlayer(), {}
    for _, p in ipairs(player.GetAll()) do
        local title, faction = shownAs(p, lp)
        parts[#parts + 1] = p:UserID() .. faction .. title .. p:GetUserGroup() .. p:Nick()
    end
    local sig = table.concat(parts, "|")
    if sig ~= self.signature then self:Rebuild() end
end

function PANEL:Rebuild()
    local lp = LocalPlayer()
    local s = UI.scale()
    local gap = math.floor(8 * s)
    self.list:Clear()
    self.list:GetCanvas():DockPadding(gap, gap, gap, gap)

    -- Everyone in one list, A to Z by name
    local list, parts = {}, {}
    for _, p in ipairs(player.GetAll()) do
        local title, faction, color, undercover = shownAs(p, lp)
        parts[#parts + 1] = p:UserID() .. faction .. title .. p:GetUserGroup() .. p:Nick()
        list[#list + 1] = { ply = p, title = title, color = color, undercover = undercover }
    end
    self.signature = table.concat(parts, "|")
    table.sort(list, function(a, b) return string.lower(a.ply:Nick()) < string.lower(b.ply:Nick()) end)

    local rowH = math.floor(40 * s)
    for _, entry in ipairs(list) do self:AddRow(entry, rowH) end

    if not IsValid(self.selected) then self:Select(lp) else self:Select(self.selected) end
end

function PANEL:AddRow(entry, rowH)
    local s = UI.scale()
    local ply = entry.ply
    local row = self.list:Add("DButton")
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 3)
    row:SetTall(rowH)
    row:SetText("")
    row.hover = 0
    row.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self.pinned = true
        self:Select(ply)
    end

    local avatar = vgui.Create("AvatarImage", row)
    avatar:SetSize(rowH - 8, rowH - 8)
    avatar:SetPos(4, 4)
    avatar:SetPlayer(ply, 64)
    avatar:SetMouseInputEnabled(false)

    row.Paint = function(r, w, h)
        if not IsValid(ply) then return end
        r.hover = Lerp(FrameTime() * 12, r.hover, r:IsHovered() and 1 or 0)
        local selected = self.selected == ply
        draw.RoundedBox(4, 0, 0, w, h, selected and C.cardSelected or UI.mix(C.card, C.cardHover, r.hover))
        -- job colour strip
        surface.SetDrawColor(entry.color)
        surface.DrawRect(0, 0, 4, h)

        local x = rowH + 6
        local nameW = math.floor(w * 0.38)
        draw.SimpleText(UI.fit(ply:Nick(), "RP1942_F4Head", nameW - 10), "RP1942_F4Head", x, h / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- job title, then tags
        local jx = x + nameW
        local jobText = UI.fit(entry.title, "RP1942_F4Body", math.floor(w * 0.3))
        draw.SimpleText(jobText, "RP1942_F4Body", jx, h / 2, readable(entry.color), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local tx = w - math.floor(70 * s)
        local function tag(text, col, textCol)
            surface.SetFont("RP1942_F4Small")
            local tw, th = surface.GetTextSize(text)
            tx = tx - tw - 14
            draw.RoundedBox(3, tx, h / 2 - th / 2 - 2, tw + 10, th + 4, col)
            draw.SimpleText(text, "RP1942_F4Small", tx + 5, h / 2, textCol or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local badge = rankBadge(ply)
        if badge then tag(badge, C.gold, C.titleBar) end
        if ply:getDarkRPVar("wanted") then tag("WANTED", C.unavailable) end
        if entry.undercover then tag("UNDERCOVER", C.tabActive) end
        if ply:IsMuted() then tag("MUTED FOR YOU", C.disabled) end

        -- ping
        local ping = ply:Ping()
        draw.SimpleText(ply:IsBot() and "BOT" or tostring(ping), "RP1942_F4Small", w - 10, h / 2, pingColor(ping), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

--[[---------------------------------------------------------------------------
The player card on the right
---------------------------------------------------------------------------]]
function PANEL:Select(ply)
    self.selected = ply
    local d = self.detail
    d:Clear()
    if not IsValid(ply) then return end

    local s = UI.scale()
    local pad = math.floor(12 * s)
    d:DockPadding(pad, pad, pad, pad)
    local lp = LocalPlayer()
    local title, faction, color, undercover = shownAs(ply, lp)

    local scroll = vgui.Create("DScrollPanel", d)
    scroll:Dock(FILL)
    UI.styleScroll(scroll)

    -- Head: avatar, name, job
    local head = scroll:Add("DPanel")
    head:Dock(TOP)
    head:SetTall(math.floor(84 * s))
    head.Paint = function(_, w, h)
        if not IsValid(ply) then return end
        local x = h + pad
        draw.SimpleText(UI.fit(ply:Nick(), "RP1942_F4Big", w - x), "RP1942_F4Big", x, h * 0.32, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(UI.fit(title, "RP1942_F4Body", w - x), "RP1942_F4Body", x, h * 0.66, readable(color), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local badge = rankBadge(ply)
        draw.SimpleText((badge or "PLAYER") .. "   ·   " .. (FACTION_TITLE[faction] or faction), "RP1942_F4Small", x, h * 0.9, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local av = vgui.Create("AvatarImage", head)
    av:SetSize(math.floor(84 * s), math.floor(84 * s))
    av:SetPlayer(ply, 184)

    local function label(text, font, col, top)
        local l = scroll:Add("DLabel")
        l:Dock(TOP)
        l:DockMargin(0, top or 0, 0, 0)
        l:SetFont(font)
        l:SetTextColor(col)
        l:SetText(text)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        return l
    end

    if undercover and ply ~= lp then
        local real = RPExtraTeams[ply:Team()]
        label("UNDERCOVER: really a " .. (real and real.name or "?") .. ". Others see the title above.", "RP1942_F4Small", C.unavailable, pad)
    end

    label("SteamID", "RP1942_F4Small", C.sub, pad)
    label(ply:IsBot() and "BOT" or ply:SteamID(), "RP1942_F4Body", C.text)

    -- Buttons in a grid, `cols` across
    local function grid(items, cols)
        local g = scroll:Add("Panel")
        g:Dock(TOP)
        g:DockMargin(0, math.floor(6 * s), 0, 0)
        local bh, bgap = math.floor(32 * s), math.floor(6 * s)
        local buttons = {}
        for _, it in ipairs(items) do
            local b = UI.button(g, it.label, it.fn)
            if it.danger then
                b.Paint = function(btn, w, h)
                    btn.hover = Lerp(FrameTime() * 12, btn.hover or 0, btn:IsHovered() and 1 or 0)
                    draw.RoundedBox(4, 0, 0, w, h, UI.mix(Color(110, 30, 26), Color(170, 40, 34), btn.hover))
                    surface.SetDrawColor(C.gold.r, C.gold.g, C.gold.b, 120)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    draw.SimpleText(btn.label, "RP1942_F4Button", w / 2, h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            buttons[#buttons + 1] = b
        end
        g.PerformLayout = function(_, w)
            local bw = math.floor((w - bgap * (cols - 1)) / cols)
            for i, b in ipairs(buttons) do
                local c, r = (i - 1) % cols, math.floor((i - 1) / cols)
                b:SetPos(c * (bw + bgap), r * (bh + bgap))
                b:SetSize(bw, bh)
            end
            local rows = math.ceil(#buttons / cols)
            g:SetTall(rows * bh + math.max(rows - 1, 0) * bgap)
        end
        return g
    end

    -- For everyone
    local basics = {
        { label = "Copy SteamID", fn = function() SetClipboardText(ply:SteamID()) notification.AddLegacy("SteamID copied.", NOTIFY_GENERIC, 3) end },
        { label = "Steam profile", fn = function() ply:ShowProfile() end },
    }
    if ply ~= lp then
        basics[#basics + 1] = { label = ply:IsMuted() and "Unmute voice" or "Mute voice (me)", fn = function()
            ply:SetMuted(not ply:IsMuted())
            self:Select(ply)
        end }
        if can("psay") then
            basics[#basics + 1] = { label = "Message", fn = function()
                prompt("Private message to " .. ply:Nick(), "Your message", function(text)
                    if text ~= "" then runULX("psay", ply, text) end
                end)
            end }
        end
    end
    grid(basics, 2)

    -- Staff only: every ULX command this viewer may use
    if hasULX() and isStaff(lp) then
        for _, section in ipairs(ACTIONS) do
            local items = {}
            for _, a in ipairs(section.items) do
                local label, cmd = a[1], a[2]
                if can(cmd) then
                    local fn
                    if a.ban then
                        fn = function()
                            local menu = DermaMenu()
                            for _, len in ipairs(BAN_LENGTHS) do
                                menu:AddOption(len[1], function()
                                    prompt("Ban " .. ply:Nick() .. " (" .. len[1] .. ")", "Reason", function(reason)
                                        runULX("ban", ply, tostring(len[2]), reason ~= "" and reason or "Banned by staff")
                                    end)
                                end)
                            end
                            menu:Open()
                        end
                    elseif a.prompt then
                        fn = function()
                            prompt(label .. ": " .. ply:Nick(), a.prompt, function(text)
                                if text ~= "" then runULX(cmd, ply, text) else runULX(cmd, ply) end
                            end)
                        end
                    else
                        fn = function() runULX(cmd, ply) end
                    end
                    items[#items + 1] = { label = label, fn = fn, danger = a.danger }
                end
            end
            if #items > 0 then
                local bar = UI.categoryBar(scroll, string.upper(section.title), nil, C.tab)
                bar:Dock(TOP)
                bar:DockMargin(0, pad, 0, 0)
                bar:SetTall(math.floor(28 * s))
                grid(items, 2)
            end
        end
    end
end

vgui.Register("RP1942_Scoreboard", PANEL, "EditablePanel")

--[[---------------------------------------------------------------------------
TAB: show while held; once clicked it stays pinned until TAB is pressed again
---------------------------------------------------------------------------]]
local board

hook.Add("ScoreboardShow", "RP1942_Scoreboard", function()
    if not RP1942.F4UI then return end   -- the F4 look isn't loaded: leave the default
    if IsValid(board) then
        if board.pinned then board.pinned = false end   -- this press closes it on release
        board:Show()
    else
        board = vgui.Create("RP1942_Scoreboard")
    end
    board:MakePopup()
    board:SetKeyboardInputEnabled(false)   -- keys still reach the game
    return true
end)

-- Clicking anything on the board keeps it open after TAB is let go
hook.Add("VGUIMousePressed", "RP1942_Scoreboard", function(pnl)
    if IsValid(board) and IsValid(pnl) and (pnl == board or pnl:HasParent(board)) then board.pinned = true end
end)

hook.Add("ScoreboardHide", "RP1942_Scoreboard", function()
    if not IsValid(board) then return end
    if board.pinned then return true end
    board:Remove()
    board = nil
    CloseDermaMenus()
    return true
end)
