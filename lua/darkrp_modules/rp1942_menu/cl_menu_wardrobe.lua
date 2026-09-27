--[[---------------------------------------------------------------------------
F3 menu for undercover jobs: the wardrobe.
jobs.lua (Gestapo Agent, Resistance Operative):  menu = "RP1942_WardrobeMenu",
Colours follow the job's faction (Reich / Resistance), like every job menu.
Server side of the buttons: rp1942_core/sv_disguise.lua ("preset" and "model").

Tabs (RP1942.Config.Disguise.presets): one per faction, with one card per
job from jobs.lua (a badge shows how many outfits it has). Clicking a job with
one outfit puts it on and sets your title to that job's name, silently. A job
with several outfits opens its model selection: a large turning preview, the
outfits beside it, and WEAR THIS. An optional "Wardrobe" tab
(RP1942.Config.Disguise.models) offers plain models without touching the title.
---------------------------------------------------------------------------]]
local PANEL = {}

-- Card captions: a size smaller than the menu's body text, so names like
-- "Leibstandarte Rifleman" fit on two lines
local function buildFonts()
    surface.CreateFont("RP1942_WardrobeCaption", { font = "Roboto", size = math.max(12, math.floor(ScrH() * 0.0145)), weight = 500, extended = true })
end
buildFonts()
hook.Add("OnScreenSizeChanged", "RP1942_WardrobeFonts", buildFonts)

function PANEL:GetSubtitle()
    return "Wardrobe"
end

-- Every tab this job gets: the presets, then the plain-model tab if configured
function PANEL:GetTabs()
    local tabs = table.Copy(RP1942.disguisePresets(LocalPlayer()))

    local cfg = RP1942.Config.Disguise
    local own = cfg.models and cfg.models[self.job.command]
    if istable(own) and #own > 0 then
        tabs[#tabs + 1] = { id = "wardrobe", name = "Wardrobe", plain = own }
    elseif #tabs == 0 then
        -- Nothing configured: the old behaviour, every civilian model
        tabs[1] = { id = "wardrobe", name = "Wardrobe", plain = RP1942.disguiseModels(LocalPlayer()) }
    end
    return tabs
end

function PANEL:Rebuild()
    self.content:Clear()
    self:Populate()
end

-- Cover title: a text box and "Set title". (No reveal button: your own side
-- already sees your faction tag over your head.)
function PANEL:AddTitleBox()
    local theme = self.theme
    local row = self.content:Add("DPanel")
    row:Dock(TOP)
    row:DockMargin(0, 2, 0, 6)
    row:SetTall(34)
    row.Paint = nil

    local function button(label, width, onClick)
        local btn = row:Add("DButton")
        btn:Dock(RIGHT)
        btn:DockMargin(4, 0, 0, 0)
        btn:SetWide(width)
        btn:SetFont("RP1942_MenuBody")
        btn:SetTextColor(theme.text)
        btn:SetText(label)
        btn.Paint = function(s, w, h)
            surface.SetDrawColor(s:IsHovered() and theme.accentHover or theme.accent)
            surface.DrawRect(0, 0, w, h)
        end
        btn.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            onClick()
        end
        return btn
    end

    local entry = row:Add("DTextEntry")
    local function submit(text)
        text = string.Trim(text or "")
        if text == "" then return end
        self:Request("title", text)
        timer.Simple(0.3, function() if IsValid(self) then self:Rebuild() end end)
    end

    button("Set title", 100, function() submit(entry:GetValue()) end)

    entry:Dock(FILL)
    entry:SetFont("RP1942_MenuBody")
    entry:SetPlaceholderText("New cover title, e.g. Baker")
    entry:SetTextColor(theme.text)
    entry:SetCursorColor(theme.text)
    entry:SetPaintBackground(false)
    entry.Paint = function(s, w, h)
        surface.SetDrawColor(0, 0, 0, 90)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(s:HasFocus() and theme.accentHover or theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.text, theme.accentHover, theme.text)
        if s:GetValue() == "" and not s:HasFocus() then
            draw.SimpleText(s:GetPlaceholderText(), "RP1942_MenuBody", 6, h / 2, theme.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    entry.OnEnter = function(s) submit(s:GetValue()) end
end

-- A row of tab buttons, as wide as the menu
function PANEL:AddTabBar(tabs)
    local theme = self.theme
    local bar = self.content:Add("DPanel")
    bar:Dock(TOP)
    bar:DockMargin(0, 4, 0, 8)
    bar:SetTall(32)
    bar.Paint = nil

    for i, tab in ipairs(tabs) do
        local btn = bar:Add("DButton")
        btn:Dock(LEFT)
        btn:DockMargin(0, 0, i < #tabs and 4 or 0, 0)
        btn:SetFont("RP1942_MenuBody")
        btn:SetTextColor(theme.text)
        btn:SetText(tab.name)
        local active = self.activeTab == tab.id
        btn.Paint = function(s, w, h)
            surface.SetDrawColor((active or s:IsHovered()) and theme.accentHover or theme.accent)
            surface.DrawRect(0, 0, w, h)
            if active then
                surface.SetDrawColor(theme.text)
                surface.DrawRect(0, h - 2, w, 2)
            end
        end
        btn.DoClick = function()
            if active then return end
            surface.PlaySound("ui/buttonclick.wav")
            self.activeTab = tab.id
            self.picking = nil
            self:Rebuild()
        end
    end

    bar.PerformLayout = function(s, w)
        local n = #tabs
        local each = math.floor((w - 4 * (n - 1)) / n)
        for _, child in ipairs(s:GetChildren()) do child:SetWide(each) end
    end
end

-- A grid of cards: a model icon with a caption under it.
-- cards = { { model =, caption =, worn = bool, count = n (badge), onClick = fn }, ... }
function PANEL:AddCardGrid(cards)
    local theme = self.theme
    local grid = self.content:Add("DIconLayout")
    grid:Dock(TOP)
    grid:DockMargin(0, 2, 0, 10)
    grid:SetSpaceX(6)
    grid:SetSpaceY(6)

    local size = math.Clamp(math.floor(ScrH() * 0.095), 80, 130)
    local capH = draw.GetFontHeight("RP1942_WardrobeCaption") * 2 + 6   -- room for a two-line name

    for _, card in ipairs(cards) do
        local cell = grid:Add("DButton")
        cell:SetSize(size, size + capH)
        cell:SetText("")
        cell:SetTooltip(card.caption)
        cell.Paint = function(s, w, h)
            surface.SetDrawColor(s:IsHovered() and theme.accentHover or theme.accent)
            surface.DrawRect(0, 0, w, h)
            if card.worn then
                surface.SetDrawColor(theme.text)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
        end
        -- Outfit count badge, drawn over the picture
        if card.count and card.count > 1 then
            cell.PaintOver = function(s, w, h)
                local txt = card.count .. " outfits"
                surface.SetFont("RP1942_WardrobeCaption")
                local tw, th = surface.GetTextSize(txt)
                surface.SetDrawColor(0, 0, 0, 170)
                surface.DrawRect(w - tw - 10, 4, tw + 6, th + 2)
                draw.SimpleText(txt, "RP1942_WardrobeCaption", w - 7, 5, theme.text, TEXT_ALIGN_RIGHT)
            end
        end
        cell.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            card.onClick()
        end

        local icon = cell:Add("ModelImage")   -- the model's picture, clicks pass to the card
        icon:SetPos(2, 2)
        icon:SetSize(size - 4, size - 4)
        icon:SetModel(card.model)
        icon:SetMouseInputEnabled(false)

        local lbl = cell:Add("DLabel")
        lbl:SetPos(4, size)
        lbl:SetSize(size - 8, capH - 2)
        lbl:SetFont("RP1942_WardrobeCaption")
        lbl:SetTextColor(card.worn and theme.text or theme.sub)
        lbl:SetContentAlignment(8)
        lbl:SetWrap(true)
        lbl:SetText(card.caption)
        lbl:SetMouseInputEnabled(false)
    end
end

-- Put on one of a job's outfits and take its title
function PANEL:WearPreset(tabId, job, index)
    self:Request("preset", tabId .. "|" .. job.command .. "|" .. index)
    -- Redraw once the server has changed the title and model
    timer.Simple(0.3, function() if IsValid(self) then self:Rebuild() end end)
end

-- Model selection for one job: a large turning preview on the left, the
-- job's outfits on the right. Click an outfit to preview it, double-click or
-- WEAR THIS to put it on.
function PANEL:AddModelPicker(tab, job)
    local theme = self.theme
    local lp = LocalPlayer()
    local isCover = lp:getDarkRPVar("job") == job.name
    local function worn(model)
        return isCover and string.lower(lp:GetModel() or "") == string.lower(model)
    end

    -- Start on the outfit you're wearing, otherwise the first
    if not self.pickIndex or not job.models[self.pickIndex] or self.pickFor ~= job.command then
        self.pickIndex = 1
        for i, model in ipairs(job.models) do if worn(model) then self.pickIndex = i end end
        self.pickFor = job.command
    end

    -- Header row: back, and the job's name
    local head = self.content:Add("DPanel")
    head:Dock(TOP)
    head:DockMargin(0, 4, 0, 8)
    head:SetTall(32)
    head.Paint = function(s, w, h)
        draw.SimpleText(string.upper(job.name) .. "  ·  " .. #job.models .. " OUTFITS", "RP1942_MenuSection", 110, h / 2, theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local back = head:Add("DButton")
    back:Dock(LEFT)
    back:SetWide(98)
    back:SetFont("RP1942_MenuBody")
    back:SetTextColor(theme.text)
    back:SetText("« All jobs")
    back.Paint = function(s, w, h)
        surface.SetDrawColor(s:IsHovered() and theme.accentHover or theme.accent)
        surface.DrawRect(0, 0, w, h)
    end
    back.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self.picking = nil
        self:Rebuild()
    end

    -- Body: preview + outfits
    local bodyH = math.Clamp(math.floor(ScrH() * 0.34), 240, 380)
    local body = self.content:Add("DPanel")
    body:Dock(TOP)
    body:DockMargin(0, 0, 0, 8)
    body:SetTall(bodyH)
    body.Paint = nil

    local preview = body:Add("DModelPanel")
    preview:Dock(LEFT)
    preview:DockMargin(0, 0, 8, 0)
    preview:SetWide(math.floor(bodyH * 0.72))
    local function showModel(model)
        preview:SetModel(model)
        local ent = preview:GetEntity()
        if not IsValid(ent) then return end
        local seq = ent:LookupSequence("idle_all_01")
        if seq and seq > 0 then ent:ResetSequence(seq) end
        preview:SetFOV(32)
        preview:SetCamPos(Vector(95, 0, 44))
        preview:SetLookAt(Vector(0, 0, 36))
    end
    local basePaint = preview.Paint
    preview.Paint = function(s, w, h)
        surface.SetDrawColor(theme.accent)
        surface.DrawRect(0, 0, w, h)
        basePaint(s, w, h)
        if worn(job.models[self.pickIndex]) then
            surface.SetDrawColor(theme.text)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            draw.SimpleText("WEARING", "RP1942_WardrobeCaption", w / 2, h - 8, theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end
    -- Turn slowly, and keep the idle animation playing
    preview.LayoutEntity = function(s, ent)
        ent:SetAngles(Angle(0, RealTime() * 25 % 360, 0))
        s:RunAnimation()
    end
    showModel(job.models[self.pickIndex])

    local list = body:Add("DScrollPanel")
    list:Dock(FILL)
    local grid = list:Add("DIconLayout")
    grid:Dock(TOP)
    grid:SetSpaceX(6)
    grid:SetSpaceY(6)

    local size = math.Clamp(math.floor(ScrH() * 0.075), 64, 100)
    local function pick(i)
        self.pickIndex = i
        showModel(job.models[i])
    end
    for i, model in ipairs(job.models) do
        local cell = grid:Add("DButton")
        cell:SetSize(size, size)
        cell:SetText("")
        cell:SetTooltip("Outfit " .. i .. (worn(model) and " (wearing)" or ""))
        cell.Paint = function(s, w, h)
            local on = self.pickIndex == i
            surface.SetDrawColor((on or s:IsHovered()) and theme.accentHover or theme.accent)
            surface.DrawRect(0, 0, w, h)
            if on then
                surface.SetDrawColor(theme.text)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
        end
        cell.PaintOver = function(s, w, h)
            if worn(model) then
                surface.SetDrawColor(theme.text)
                surface.DrawRect(w - 12, 4, 8, 8)   -- small mark: the one you have on
            end
        end
        cell.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            pick(i)
        end
        cell.DoDoubleClick = function()
            pick(i)
            self:WearPreset(tab.id, job, i)
        end
        local icon = cell:Add("ModelImage")
        icon:SetPos(2, 2)
        icon:SetSize(size - 4, size - 4)
        icon:SetModel(model)
        icon:SetMouseInputEnabled(false)
    end

    local wear = self:AddButton("", function()
        self:WearPreset(tab.id, job, self.pickIndex)
    end)
    wear.Think = function(s)
        s:SetText(worn(job.models[self.pickIndex]) and ("You're wearing this  ·  cover: " .. job.name)
            or ("WEAR THIS  ·  become \"" .. job.name .. "\""))
    end
end

function PANEL:Populate()
    local lp = LocalPlayer()
    local tabs = self:GetTabs()
    local current
    for _, tab in ipairs(tabs) do
        if tab.id == self.activeTab then current = tab end
    end
    current = current or tabs[1]
    self.activeTab = current.id

    local function worn(model)
        return string.lower(LocalPlayer():GetModel() or "") == string.lower(model)
    end

    self:AddSection("Cover")
    self:AddText("You appear to everyone as: " .. (lp:getDarkRPVar("job") or "?") .. ". Nobody is told when you change it.")
    self:AddTitleBox()

    -- A job's model selection, if one is open
    if self.picking then
        for _, tab in ipairs(tabs) do
            if tab.id == self.picking.tab then
                for _, job in ipairs(tab.jobs or {}) do
                    if job.command == self.picking.command then
                        self:AddModelPicker(tab, job)
                        return
                    end
                end
            end
        end
        self.picking = nil   -- that job is gone: back to the list
    end

    if #tabs > 1 then self:AddTabBar(tabs) end

    if current.plain then
        self:AddText("Click a model to wear it. Your title doesn't change.")
        local cards = {}
        for _, model in ipairs(current.plain) do
            cards[#cards + 1] = {
                model = model,
                caption = string.match(model, "([^/]+)%.mdl$") or model,
                worn = worn(model),
                onClick = function()
                    self:Request("model", model)
                    timer.Simple(0.3, function() if IsValid(self) then self:Rebuild() end end)
                end,
            }
        end
        self:AddCardGrid(cards)
    else
        local title = lp:getDarkRPVar("job")
        self:AddText("Click a job to put on its clothes and take its title. Jobs with several outfits let you pick one. Your current cover is outlined.")
        local cards = {}
        for _, job in ipairs(current.jobs) do
            -- Show the outfit you're wearing if this job is your cover
            local shown, isCover = job.models[1], false
            for _, model in ipairs(job.models) do
                if job.name == title and worn(model) then shown, isCover = model, true end
            end
            cards[#cards + 1] = {
                model = shown,
                caption = job.name,
                worn = isCover,
                count = #job.models,
                onClick = function()
                    if #job.models == 1 then
                        self:WearPreset(current.id, job, 1)
                    else
                        self.picking = { tab = current.id, command = job.command }
                        self:Rebuild()
                    end
                end,
            }
        end
        self:AddCardGrid(cards)
    end

    self:AddButton("Standard issue (your job's normal clothes)", function()
        self:Request("model", "")
        timer.Simple(0.3, function() if IsValid(self) then self:Rebuild() end end)
    end)
end

vgui.Register("RP1942_WardrobeMenu", PANEL, "RP1942_MenuBase")
