--[[---------------------------------------------------------------------------
1942 DarkRP - F4 menu window (client)

Tabs register themselves (any load order):
    RP1942.F4Tabs.jobs = { name = "Jobs", icon = "icon16/group.png", build = function(page) ... end }
and appear in the order of RP1942.F4Config.tabs.

Shared look for every tab: RP1942.F4UI (fonts, colours, buttons, category bars).
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local CFG = RP1942.F4Config
local C = CFG.colors
local UI = {}
RP1942.F4UI = UI
UI.C = C

function UI.scale() return math.Clamp(ScrH() / 1080, 0.75, 1.5) end

function UI.mix(a, b, t)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a or 255, b.a or 255))
end

local function buildFonts()
    local h = ScrH()
    local function font(name, scale, weight)
        surface.CreateFont(name, { font = "Roboto", size = math.max(12, math.floor(h * scale)), weight = weight, extended = true })
    end
    font("RP1942_F4Title",   0.026, 800)
    font("RP1942_F4Tab",     0.016, 600)
    font("RP1942_F4Big",     0.034, 800)
    font("RP1942_F4Head",    0.019, 700)
    font("RP1942_F4Body",    0.016, 400)
    font("RP1942_F4Small",   0.0135, 600)
    font("RP1942_F4Button",  0.017, 700)
end
buildFonts()
hook.Add("OnScreenSizeChanged", "RP1942_F4Fonts", buildFonts)

-- A flat button. isEnabled (optional) is checked every frame.
function UI.button(parent, text, onClick, isEnabled)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn.label = text
    btn.hover = 0
    btn.DoClick = function(b)
        if isEnabled and not isEnabled() then return end
        surface.PlaySound("ui/buttonclick.wav")
        onClick(b)
    end
    btn.Paint = function(b, w, h)
        local ok = not isEnabled or isEnabled()
        b.hover = Lerp(FrameTime() * 12, b.hover, (ok and b:IsHovered()) and 1 or 0)
        draw.RoundedBox(4, 0, 0, w, h, ok and UI.mix(C.button, C.buttonHover, b.hover) or C.disabled)
        draw.SimpleText(isfunction(b.label) and b.label() or b.label, "RP1942_F4Button", w / 2, h / 2,
            ok and C.text or C.sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        b:SetCursor(ok and "hand" or "no")
    end
    return btn
end

-- A dark red bar (or `color`) with a name on the left and optional text on the right
function UI.categoryBar(parent, name, right, color)
    local bar = vgui.Create("DPanel", parent)
    bar:SetTall(math.floor(34 * UI.scale()))
    bar.Paint = function(_, w, h)
        draw.RoundedBoxEx(4, 0, 0, w, h, color or C.category, true, true, false, false)
        surface.SetDrawColor(C.gold.r, C.gold.g, C.gold.b, 90)
        surface.DrawRect(0, h - 1, w, 1)
        draw.SimpleText(name, "RP1942_F4Head", 10, h / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if right then draw.SimpleText(right, "RP1942_F4Small", w - 10, h / 2, C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
    end
    return bar
end

-- A text box. Typing needs keyboard focus, which the menu normally leaves
-- with the game (so you can still move, and F4 closes it): the box takes it
-- while you're typing and gives it back after Enter or clicking away.
function UI.textEntry(parent, value, onEnter)
    local s = UI.scale()
    local e = vgui.Create("DTextEntry", parent)
    e:SetFont("RP1942_F4Body")
    e:SetTall(math.floor(34 * s))
    e:SetText(value or "")
    e:SetTextColor(C.text)
    e:SetCursorColor(C.gold)
    e:SetHighlightColor(Color(C.gold.r, C.gold.g, C.gold.b, 90))
    e:SetPaintBackground(false)
    e:SetUpdateOnType(false)
    local function keyboard(on)
        if IsValid(RP1942.F4Panel) then RP1942.F4Panel:SetKeyboardInputEnabled(on) end
    end
    e.OnGetFocus = function() keyboard(true) end
    e.OnLoseFocus = function(self) keyboard(false); DTextEntry.OnLoseFocus(self) end
    e.OnEnter = function(self)
        local text = string.Trim(self:GetValue() or "")
        if text ~= "" then onEnter(text) end
        self:KillFocus()
        keyboard(false)
    end
    e.PaintOver = function(self, w, h)
        surface.SetDrawColor(self:HasFocus() and C.gold or C.tabHover)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    e.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, C.entry)
        self:DrawTextEntryText(C.text, self:GetHighlightColor(), C.gold)
    end
    return e
end

-- A thin, dark scrollbar for a DScrollPanel
function UI.styleScroll(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(6)
    bar:SetHideButtons(true)
    bar.Paint = function(_, w, h) draw.RoundedBox(3, 0, 0, w, h, Color(0, 0, 0, 90)) end
    bar.btnGrip.Paint = function(_, w, h) draw.RoundedBox(3, 0, 0, w, h, C.sub) end
end

-- Shortens text with "..." until it fits (UTF-8 safe)
function UI.fit(text, font, maxW)
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxW then return text end
    while #text > 0 and surface.GetTextSize(text .. "...") > maxW do
        local last = utf8.offset(text, -1)
        text = string.sub(text, 1, (last or #text) - 1)
    end
    return text .. "..."
end

-- Runs a DarkRP chat command, like typing /command args in chat
function UI.command(...)
    RunConsoleCommand("darkrp", ...)
end

--[[---------------------------------------------------------------------------
The window
---------------------------------------------------------------------------]]
local PANEL = {}

function PANEL:Init()
    local s = UI.scale()
    self.titleH = math.floor(46 * s)
    self.tabH = math.floor(36 * s)
    self:SetSize(math.min(ScrW() * 0.86, 1320 * s), math.min(ScrH() * 0.86, 860 * s))
    self:Center()
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)   -- keys still reach the game, so F4 closes it
    self:SetAlpha(0)
    self:AlphaTo(255, 0.12)

    local close = vgui.Create("DButton", self)
    close:SetText("")
    close:SetSize(self.titleH, self.titleH)
    close.DoClick = function() RP1942.closeF4() end
    close.Paint = function(b, w, h)
        surface.SetDrawColor(b:IsHovered() and C.text or C.sub)
        local p = math.floor(w * 0.36)
        surface.DrawLine(p, p, w - p, h - p)
        surface.DrawLine(w - p, p, p, h - p)
    end
    self.closeBtn = close

    self.tabBar = vgui.Create("Panel", self)
    self.body = vgui.Create("Panel", self)

    self.tabButtons, self.pages = {}, {}
    for _, id in ipairs(CFG.tabs) do
        if id == "pages" then
            -- one tab per text page (sh_f4_pages.lua)
            for pid, def in ipairs(RP1942.F4PageTabs and RP1942.F4PageTabs() or {}) do
                RP1942.F4Tabs["page:" .. pid] = def
                self:AddTab("page:" .. pid, def)
            end
        elseif RP1942.F4Tabs[id] then
            self:AddTab(id, RP1942.F4Tabs[id])
        end
    end
    self:SelectTab(RP1942.F4LastTab and self.tabButtons[RP1942.F4LastTab] and RP1942.F4LastTab or CFG.tabs[1])
end

function PANEL:AddTab(id, def)
    local s = UI.scale()
    local btn = vgui.Create("DButton", self.tabBar)
    btn:SetText("")
    btn:Dock(LEFT)
    btn:DockMargin(0, 0, 4, 0)
    surface.SetFont("RP1942_F4Tab")
    btn:SetWide(surface.GetTextSize(def.name) + math.floor(46 * s))
    btn.icon = def.icon and Material(def.icon)
    btn.hover = 0
    btn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self:SelectTab(id)
    end
    btn.Paint = function(b, w, h)
        local active = self.activeTab == id
        b.hover = Lerp(FrameTime() * 12, b.hover, b:IsHovered() and 1 or 0)
        draw.RoundedBoxEx(4, 0, 0, w, h, active and C.tabActive or UI.mix(C.tab, C.tabHover, b.hover), true, true, false, false)
        if active then
            surface.SetDrawColor(C.gold)
            surface.DrawRect(0, h - 2, w, 2)
        end
        local x = math.floor(12 * s)
        if b.icon and not b.icon:IsError() then
            surface.SetDrawColor(255, 255, 255, active and 255 or 170)
            surface.SetMaterial(b.icon)
            surface.DrawTexturedRect(x, h / 2 - 8, 16, 16)
            x = x + 22
        end
        draw.SimpleText(def.name, "RP1942_F4Tab", x, h / 2, active and C.text or C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    self.tabButtons[id] = btn
end

function PANEL:SelectTab(id)
    if not id or not self.tabButtons[id] then return end
    self.activeTab = id
    RP1942.F4LastTab = id
    for pid, page in pairs(self.pages) do page:SetVisible(pid == id) end
    if not self.pages[id] then
        local page = vgui.Create("Panel", self.body)
        page:Dock(FILL)
        self.pages[id] = page
        local ok, err = pcall(RP1942.F4Tabs[id].build, page)
        if not ok then ErrorNoHalt("[1942] F4 tab '" .. id .. "' failed: " .. tostring(err) .. "\n") end
    end
end

function PANEL:PerformLayout(w, h)
    local pad = math.floor(12 * UI.scale())
    self.closeBtn:SetPos(w - self.titleH, 0)
    self.tabBar:SetPos(pad, self.titleH + math.floor(8 * UI.scale()))
    self.tabBar:SetSize(w - pad * 2, self.tabH)
    local top = self.titleH + math.floor(8 * UI.scale()) + self.tabH
    self.body:SetPos(pad, top)
    self.body:SetSize(w - pad * 2, h - top - pad)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, C.bg)
    draw.RoundedBoxEx(8, 0, 0, w, self.titleH, C.titleBar, true, true, false, false)
    surface.SetDrawColor(C.tabActive)
    surface.DrawRect(0, self.titleH - 2, w, 2)

    local pad = math.floor(16 * UI.scale())
    draw.SimpleText(CFG.title, "RP1942_F4Title", pad, self.titleH / 2, C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetFont("RP1942_F4Title")
    local tw = surface.GetTextSize(CFG.title .. " ")
    draw.SimpleText(CFG.subtitle, "RP1942_F4Title", pad + tw, self.titleH / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Who you are, on the right
    local lp = LocalPlayer()
    local job = RPExtraTeams[lp:Team()]
    local info = string.format("%s   ·   %s   ·   %s", lp:Nick(), job and job.name or "",
        DarkRP.formatMoney(lp:getDarkRPVar("money") or 0))
    draw.SimpleText(info, "RP1942_F4Tab", w - self.titleH - pad / 2, self.titleH / 2, C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

vgui.Register("RP1942_F4", PANEL, "EditablePanel")

--[[---------------------------------------------------------------------------
Opening and closing. F4 is DarkRP's "gm_showspare2"; this hook runs before
DarkRP's own F4 handler and takes over (unless a job has its own F4 action).
---------------------------------------------------------------------------]]
function RP1942.openF4()
    if IsValid(RP1942.F4Panel) then return end
    RP1942.F4Panel = vgui.Create("RP1942_F4")
end

function RP1942.closeF4()
    if IsValid(RP1942.F4Panel) then RP1942.F4Panel:Remove() end
    RP1942.F4Panel = nil
end

function RP1942.toggleF4()
    if IsValid(RP1942.F4Panel) then RP1942.closeF4() else RP1942.openF4() end
end

hook.Add("ShowSpare2", "RP1942_F4", function()
    local job = RPExtraTeams[LocalPlayer():Team()]
    if job and job.ShowSpare2 then return end   -- that job has its own F4 action
    RP1942.toggleF4()
    return true
end)

-- Anything that opens "the F4 menu" through DarkRP gets this one instead
hook.Add("InitPostEntity", "RP1942_F4Takeover", function()
    DarkRP.openF4Menu = RP1942.openF4
    DarkRP.closeF4Menu = RP1942.closeF4
    DarkRP.toggleF4Menu = RP1942.toggleF4
end)

concommand.Add("rp1942_f4", RP1942.toggleF4)
