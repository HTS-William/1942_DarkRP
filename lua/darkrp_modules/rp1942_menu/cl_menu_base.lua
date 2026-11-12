--[[---------------------------------------------------------------------------
42Bros - RP1942_MenuBase (client)

The boilerplate every job menu inherits: faction theme, header, scrolling
content area, helper widgets, and sending actions to the server. Job menus
are shown inside the F4 menu, in a tab of their own (SetupEmbedded below,
rp1942_f4/cl_f4_job.lua); they can still be opened as a window with Setup.

TO MAKE A JOB MENU (see cl_menu_baker.lua for a full example):

    local BaseClass = baseclass.Get("RP1942_MenuBase")
    local PANEL = {}

    function PANEL:GetSubtitle() return "Bakery ledger" end     -- optional

    function PANEL:Populate()                                   -- required
        self:AddSection("Shop")
        self:AddButton("Announce fresh bread", function()
            self:Request("announce_bread")                      -- server handler
        end)
    end

    vgui.Register("RP1942_BakerMenu", PANEL, "RP1942_MenuBase")

Then in jobs.lua:   menu = "RP1942_BakerMenu", menuTab = "Bakery",
(the job gets an F4 tab called "Bakery" holding the menu)

OVERRIDABLE (all optional except Populate):
    PANEL:GetTitle()          window title          default: job name
    PANEL:GetSubtitle()       small line under it   default: none
    PANEL:GetMenuSize()       width, height         default: 40% x 60% of screen
    PANEL:GetTheme()          colour table          default: by the job's faction
    PANEL:Populate()          fill self.content     default: "nothing here" note
    PANEL:Paint(w, h)         call BaseClass.Paint(self, w, h) to keep the frame

HELPERS (use inside Populate):
    self:AddSection(text)
    self:AddText(text)
    self:AddButton(label, onClick)       -> DButton
    self:Request(action, optionalText)   -> runs the server handler
    self.job                             -> the player's job table
    self.content                         -> DScrollPanel; add anything to it
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

--[[---------------------------------------------------------------------------
Themes by faction. Menus can override GetTheme() for a one-off look.
---------------------------------------------------------------------------]]
RP1942.MenuThemes = {
    reich = {
        bg = Color(28, 30, 26, 248), header = Color(58, 64, 50),
        accent = Color(70, 78, 60), accentHover = Color(92, 102, 80),
        text = Color(230, 224, 208), sub = Color(170, 166, 150),
    },
    resistance = {
        bg = Color(30, 24, 22, 248), header = Color(84, 36, 30),
        accent = Color(96, 48, 40), accentHover = Color(122, 62, 52),
        text = Color(232, 222, 206), sub = Color(176, 160, 146),
    },
    civilian = {
        bg = Color(34, 32, 28, 248), header = Color(92, 78, 58),
        accent = Color(104, 90, 68), accentHover = Color(128, 112, 86),
        text = Color(236, 228, 212), sub = Color(180, 170, 152),
    },
}

--[[---------------------------------------------------------------------------
Fonts (sized from screen height, rebuilt on resolution change)
---------------------------------------------------------------------------]]
-- fonts sized from the screen: lua/autorun/client/rp1942_screenfonts.lua
RP1942.screenFont("RP1942_MenuTitle", 0.030, 700, { min = 20 })
RP1942.screenFont("RP1942_MenuSub", 0.017, 300, { min = 14, font = "Roboto Light" })
RP1942.screenFont("RP1942_MenuSection", 0.019, 700, { min = 15 })
RP1942.screenFont("RP1942_MenuBody", 0.018, 300, { min = 14, font = "Roboto Light" })

local HEADER_H = 58

-- Explicit parent reference. Never use self.BaseClass inside a base class:
-- in a subclass instance it points at THIS class, and calling it recurses forever.
local DFrameBase = baseclass.Get("DFrame")

--[[---------------------------------------------------------------------------
The base class
---------------------------------------------------------------------------]]
local PANEL = {}

function PANEL:Init()
    self:SetTitle("")
    self.btnMaxim:SetVisible(false)
    self.btnMinim:SetVisible(false)
    self:SetDraggable(true)
    self:DockPadding(14, HEADER_H + 10, 14, 14)

    self.content = vgui.Create("DScrollPanel", self)
    self.content:Dock(FILL)

    self.openedTeam = LocalPlayer():Team()
end

-- Called by the opener right after creation. Subclass fields exist by now,
-- so this is where overridden methods are safe to call.
function PANEL:Setup(job)
    self.job = job
    self.theme = self:GetTheme()

    local w, h = self:GetMenuSize()
    self:SetSize(w, h)
    self:Center()
    self:KeepClearOfHUD()
    self:MakePopup()

    self:Populate()
end

-- Inside the F4 menu (its job tab, rp1942_f4/cl_f4_job.lua): no window of
-- its own, the F4 menu's colours, a slim header with the subtitle.
local EMBED_HEADER = 44
function PANEL:SetupEmbedded(job, theme)
    self.job = job
    self.embedded = true
    self.theme = theme or self:GetTheme()
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetSizable(false)
    self:DockPadding(0, self:GetSubtitle() and EMBED_HEADER or 0, 0, 0)
    self:Populate()
end

-- Don't open on top of the HUD (economy bar, player panel, ammo): if the menu
-- would overlap one, move it up above it, and shrink it if it still won't fit.
function PANEL:KeepClearOfHUD()
    local rects = RP1942.HUDRects
    if not rects then return end

    local x, y = self:GetPos()
    local w, h = self:GetSize()
    local gap, top = 8, 8
    local limit = ScrH()
    for _, r in pairs(rects) do
        if r.x < x + w and x < r.x + r.w then limit = math.min(limit, r.y - gap) end
    end
    if y + h <= limit then return end

    h = math.min(h, limit - top)
    self:SetSize(w, h)
    self:SetPos(x, math.max(top, limit - h))
end

-- Overridable defaults -------------------------------------------------------
function PANEL:GetTitle()
    return self.job and self.job.name or "Menu"
end

function PANEL:GetSubtitle()
    return nil
end

function PANEL:GetMenuSize()
    return math.Clamp(ScrW() * 0.40, 420, 720), math.Clamp(ScrH() * 0.60, 360, 760)
end

function PANEL:GetTheme()
    local faction = self.job and self.job.faction or "civilian"
    return RP1942.MenuThemes[faction] or RP1942.MenuThemes.civilian
end

function PANEL:Populate()
    self:AddText("This menu has no contents yet.")
end

-- Helpers --------------------------------------------------------------------
function PANEL:AddSection(text)
    local lbl = self.content:Add("DLabel")
    lbl:Dock(TOP)
    lbl:DockMargin(0, 8, 0, 4)
    lbl:SetFont("RP1942_MenuSection")
    lbl:SetTextColor(self.theme.text)
    lbl:SetText(string.upper(text))
    lbl:SizeToContentsY()
    return lbl
end

function PANEL:AddText(text)
    local lbl = self.content:Add("DLabel")
    lbl:Dock(TOP)
    lbl:DockMargin(0, 0, 0, 6)
    lbl:SetFont("RP1942_MenuBody")
    lbl:SetTextColor(self.theme.sub)
    lbl:SetWrap(true)
    lbl:SetAutoStretchVertical(true)
    lbl:SetText(text)
    return lbl
end

function PANEL:AddButton(label, onClick)
    local theme = self.theme
    local btn = self.content:Add("DButton")
    btn:Dock(TOP)
    btn:DockMargin(0, 0, 0, 6)
    btn:SetTall(34)
    btn:SetFont("RP1942_MenuBody")
    btn:SetTextColor(theme.text)
    btn:SetText(label)
    btn.Paint = function(s, w, h)
        surface.SetDrawColor(s:IsHovered() and theme.accentHover or theme.accent)
        surface.DrawRect(0, 0, w, h)
    end
    btn.DoClick = function(s)
        surface.PlaySound("ui/buttonclick.wav")
        if onClick then onClick(s) end
    end
    return btn
end

-- Ask the server to run this menu's handler for `action`
function PANEL:Request(action, arg)
    net.Start("RP1942_MenuAction")
    net.WriteString(action)
    net.WriteString(arg or "")
    net.SendToServer()
end

-- Drawing --------------------------------------------------------------------
function PANEL:Paint(w, h)
    local theme = self.theme
    if not theme then return end
    if self.embedded then
        -- in the F4 menu: a bar like its category bars, with the subtitle
        local subtitle = self:GetSubtitle()
        if subtitle then
            draw.RoundedBoxEx(4, 0, 0, w, EMBED_HEADER - 8, theme.header, true, true, false, false)
            draw.SimpleText(subtitle, "RP1942_MenuSection", 12, (EMBED_HEADER - 8) / 2, theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return
    end

    surface.SetDrawColor(theme.bg)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(theme.header)
    surface.DrawRect(0, 0, w, HEADER_H)

    local subtitle = self:GetSubtitle()
    local titleY = subtitle and 8 or (HEADER_H / 2 - 12)
    draw.SimpleText(self:GetTitle(), "RP1942_MenuTitle", 14, titleY, theme.text)
    if subtitle then
        draw.SimpleText(subtitle, "RP1942_MenuSub", 14, HEADER_H - 22, theme.sub)
    end
end

-- A menu belongs to a job: close it if the player changes job while it's open
function PANEL:Think()
    DFrameBase.Think(self)
    if not self.embedded and LocalPlayer():Team() ~= self.openedTeam then self:Close() end
end

vgui.Register("RP1942_MenuBase", PANEL, "DFrame")

--[[---------------------------------------------------------------------------
Opening: job menus live in the F4 menu now (a tab named after the job's
`menuTab`, rp1942_f4/cl_f4_job.lua). /jobmenu and the rp1942_menu console
command open F4 on that tab.
---------------------------------------------------------------------------]]
function RP1942.openJobMenu()
    local job = RPExtraTeams[LocalPlayer():Team()]
    if not (job and job.menu) then
        chat.AddText(Color(200, 190, 170), "Your job has no menu of its own.")
        return
    end
    if RP1942.openF4 then RP1942.openF4("job") end
end

concommand.Add("rp1942_menu", RP1942.openJobMenu)
net.Receive("RP1942_OpenMenu", RP1942.openJobMenu)

--[[---------------------------------------------------------------------------
F3: DarkRP's cursor toggle. Handled here so a cursor turned on in one job can
always be turned off again (DarkRP's own F3 can get out of step).
---------------------------------------------------------------------------]]
local cursorOn = false
local mouseX, mouseY = ScrW() / 2, ScrH() / 2

local function setCursor(on)
    if on then
        gui.SetMousePos(mouseX, mouseY)
    else
        mouseX, mouseY = gui.MousePos()
    end
    cursorOn = on
    gui.EnableScreenClicker(on)
end

hook.Add("ShowSpare1", "RP1942_F3", function()
    setCursor(not cursorOn)
    return true   -- handled: skip DarkRP's own F3
end)
