--[[---------------------------------------------------------------------------
1942 DarkRP - RP1942_MenuBase (client)

The boilerplate every job menu inherits: window, faction theme, header,
scrolling content area, helper widgets, and sending actions to the server.

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

Then in jobs.lua:   menu = "RP1942_BakerMenu",

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
local function buildFonts()
    local h = ScrH()
    surface.CreateFont("RP1942_MenuTitle",   { font = "Roboto",       size = math.max(20, math.floor(h * 0.030)), weight = 700 })
    surface.CreateFont("RP1942_MenuSub",     { font = "Roboto Light", size = math.max(14, math.floor(h * 0.017)), weight = 300 })
    surface.CreateFont("RP1942_MenuSection", { font = "Roboto",       size = math.max(15, math.floor(h * 0.019)), weight = 700 })
    surface.CreateFont("RP1942_MenuBody",    { font = "Roboto Light", size = math.max(14, math.floor(h * 0.018)), weight = 300 })
end
buildFonts()
hook.Add("OnScreenSizeChanged", "RP1942_MenuFonts", buildFonts)

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
    if LocalPlayer():Team() ~= self.openedTeam then self:Close() end
end

-- An open menu has keyboard focus, so F3 never reaches the F3 bind (see the
-- ShowSpare1 hook below). Catch it here: the key bound to F3's action closes it.
function PANEL:OnKeyCodePressed(key)
    local bind = input.LookupKeyBinding(key)
    if bind and string.find(string.lower(bind), "gm_showspare1", 1, true) then
        self:Close()
        return true
    end
end

vgui.Register("RP1942_MenuBase", PANEL, "DFrame")

--[[---------------------------------------------------------------------------
Opening (toggle): console command, and /jobmenu via the server
---------------------------------------------------------------------------]]
function RP1942.openJobMenu()
    if IsValid(RP1942.ActiveMenu) then
        RP1942.ActiveMenu:Close()
        return
    end

    local job = RPExtraTeams[LocalPlayer():Team()]
    local class = job and job.menu

    if not class then
        chat.AddText(Color(200, 190, 170), "Your job has no menu.")
        return
    end
    if not vgui.GetControlTable(class) then
        MsgC(Color(255, 170, 0), "[1942] Job '", job.name, "' uses menu '", class,
            "' but no panel with that name is registered. Check the cl_menu_*.lua file.\n")
        return
    end

    local menu = vgui.Create(class)
    menu:Setup(job)
    RP1942.ActiveMenu = menu
end

concommand.Add("rp1942_menu", RP1942.openJobMenu)
net.Receive("RP1942_OpenMenu", RP1942.openJobMenu)

--[[---------------------------------------------------------------------------
F3: one handler for both the cursor and job menus

DarkRP's own F3 toggles the mouse cursor, but a job with ShowSpare1 (every job
with a menu) replaces that completely. So a cursor turned on before switching
to such a job could never be turned off again. This hook runs before DarkRP's
F3 and decides everything itself, in this order:

    1. a job menu is open           -> close it
    2. the cursor is toggled on     -> turn it off
    3. the job has a menu           -> open it
    4. otherwise                    -> turn the cursor on (DarkRP's normal F3)
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
    if IsValid(RP1942.ActiveMenu) then
        RP1942.ActiveMenu:Close()
    elseif cursorOn then
        setCursor(false)
    else
        local job = RPExtraTeams[LocalPlayer():Team()]
        if job and job.menu then
            RP1942.openJobMenu()
        else
            setCursor(true)
        end
    end
    return true   -- handled: skip DarkRP's own F3
end)

