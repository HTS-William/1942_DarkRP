--[[---------------------------------------------------------------------------
The Führer's menu. jobs.lua (Führer):  menu = "RP1942_FuhrerMenu",
Server side of the buttons: sv_menu_fuhrer.lua
---------------------------------------------------------------------------]]
local PANEL = {}

local TAX_STEP = 5
local FACTION_NAMES = { civilian = "Civilians", resistance = "Resistance", reich = "Reich" }

function PANEL:GetSubtitle()
    return "Reichskanzlei"
end

function PANEL:GetMenuSize()
    return math.Clamp(ScrW() * 0.45, 460, 780), math.Clamp(ScrH() * 0.75, 420, 900)
end

-- A small themed button inside a row
function PANEL:RowButton(parent, text, onClick)
    local theme = self.theme
    local btn = parent:Add("DButton")
    btn:Dock(RIGHT)
    btn:DockMargin(4, 4, 0, 4)
    btn:SetWide(52)
    btn:SetFont("RP1942_MenuBody")
    btn:SetTextColor(theme.text)
    btn:SetText(text)
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

-- One tax row: live label on the left, buttons on the right
function PANEL:TaxRow(getText, buttons)
    local row = self.content:Add("DPanel")
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 3)
    row:SetTall(32)
    row.Paint = nil

    -- Added right-to-left, so the last button listed ends up rightmost
    for i = #buttons, 1, -1 do
        self:RowButton(row, buttons[i][1], buttons[i][2])
    end

    local label = row:Add("DLabel")
    label:Dock(FILL)
    label:SetFont("RP1942_MenuBody")
    label:SetTextColor(self.theme.text)
    label.Think = function(s)
        local text = getText()
        if s:GetText() ~= text then s:SetText(text) end
    end
    return row
end

function PANEL:Populate()
    -- Economy ------------------------------------------------------------------
    self:AddSection("Economy")

    local status = self:AddText("")
    local baseThink = status.Think
    status.Think = function(s)
        if baseThink then baseThink(s) end
        local value = RP1942.getEconomy and RP1942.getEconomy()
        local text = value
            and string.format("%s  (%d / %d, wages x%.2f)", RP1942.getEconomyTier(value).text,
                value, RP1942.Economy.MAX, RP1942.getEconomyMultiplier(value))
            or "Economy module not loaded."
        if s:GetText() ~= text then s:SetText(text) end
    end

    self:AddButton("Make economy gooder (+10)", function() self:Request("economy_up") end)
    self:AddButton("Make economy worser (-10)", function() self:Request("economy_down") end)

    -- Treasury -----------------------------------------------------------------
    self:AddSection("Reich treasury")
    local treasury = self:AddText("")
    local baseTreasuryThink = treasury.Think
    treasury.Think = function(s)
        if baseTreasuryThink then baseTreasuryThink(s) end
        local text = RP1942.getTreasury
            and ("Balance:  " .. DarkRP.formatMoney(RP1942.getTreasury()) .. "   (all income tax is paid in here)")
            or "Treasury module not loaded."
        if s:GetText() ~= text then s:SetText(text) end
    end

    self:AddPayout()

    if not RP1942.getTaxRate then
        self:AddText("Tax module not loaded.")
        return
    end

    -- Taxes by faction --------------------------------------------------------------
    self:AddSection("Income tax by faction")
    self:AddText("Taken from wages after the economy multiplier. Applies to every job in the faction unless the job has its own rate below.")

    for _, faction in ipairs(RP1942.TaxConfig.FACTIONS) do
        self:TaxRow(
            function()
                return string.format("%s:  %d%%", FACTION_NAMES[faction] or faction, RP1942.TaxRates.factions[faction] or 0)
            end,
            {
                { "-" .. TAX_STEP, function() self:Request("tax_faction", faction .. ":" .. -TAX_STEP) end },
                { "+" .. TAX_STEP, function() self:Request("tax_faction", faction .. ":" .. TAX_STEP) end },
            }
        )
    end

    -- Taxes by job, grouped by faction -------------------------------------------------
    for _, faction in ipairs(RP1942.TaxConfig.FACTIONS) do
        self:AddSection("Job rates: " .. (FACTION_NAMES[faction] or faction))

        for _, job in ipairs(RPExtraTeams) do
            if (job.faction or "civilian") == faction then
                local cmd = job.command
                self:TaxRow(
                    function()
                        local rate, from = RP1942.getTaxRate(job)
                        return string.format("%s:  %d%%%s", job.name, rate, from == "faction" and "  (faction rate)" or "")
                    end,
                    {
                        { "-" .. TAX_STEP, function() self:Request("tax_job", cmd .. ":" .. -TAX_STEP) end },
                        { "+" .. TAX_STEP, function() self:Request("tax_job", cmd .. ":" .. TAX_STEP) end },
                        { "Reset",         function() self:Request("tax_job_reset", cmd) end },
                    }
                )
            end
        end
    end
end

--[[---------------------------------------------------------------------------
Reich payout: pay every player in the chosen factions from the treasury.
A chosen faction with nobody online is skipped (and says so). The Führer
isn't paid. Server side: "payout" in sv_menu_fuhrer.lua.
---------------------------------------------------------------------------]]
local PAYOUT_FACTIONS = { "reich", "civilian", "resistance" }

function PANEL:AddPayout()
    local theme = self.theme
    self:AddSection("Reich payout")
    self:AddText("Pay the players in the chosen factions from the treasury: everyone gets the same share. Factions with nobody online are skipped. You aren't paid yourself.")

    self.payoutPicked = self.payoutPicked or { reich = true }
    self.payoutMode = self.payoutMode or "split"

    -- Split a total evenly, or the same amount each
    local modes = self.content:Add("DPanel")
    modes:Dock(TOP)
    modes:DockMargin(0, 2, 0, 4)
    modes:SetTall(32)
    modes.Paint = nil
    for _, m in ipairs({ { "split", "Split a total evenly" }, { "each", "Same amount each" } }) do
        local b = modes:Add("DButton")
        b:Dock(LEFT)
        b:DockMargin(0, 0, 4, 0)
        b:SetFont("RP1942_MenuBody")
        b:SetTextColor(theme.text)
        b:SetText(m[2])
        b.Paint = function(s, w, h)
            local on = self.payoutMode == m[1]
            surface.SetDrawColor(on and theme.accentHover or (s:IsHovered() and theme.accent or Color(0, 0, 0, 90)))
            surface.DrawRect(0, 0, w, h)
            if on then
                surface.SetDrawColor(theme.text)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
        end
        b.DoClick = function() surface.PlaySound("ui/buttonclick.wav") self.payoutMode = m[1] end
    end
    modes.PerformLayout = function(s, w)
        local each = math.floor((w - 4) / 2)
        for _, c in ipairs(s:GetChildren()) do c:SetWide(each) end
    end

    -- Amount per player
    local row = self.content:Add("DPanel")
    row:Dock(TOP)
    row:DockMargin(0, 2, 0, 4)
    row:SetTall(32)
    row.Paint = nil
    local label = row:Add("DLabel")
    label:Dock(LEFT)
    label:SetFont("RP1942_MenuBody")
    label:SetTextColor(theme.text)
    label:SetText("Total to share out:  R.M.")
    label:SetWide(220)
    label.Think = function(s)
        local text = self.payoutMode == "each" and "Amount per player:  R.M." or "Total to share out:  R.M."
        if s:GetText() ~= text then s:SetText(text) end
    end
    local entry = row:Add("DTextEntry")
    entry:Dock(LEFT)
    entry:SetWide(110)
    entry:SetNumeric(true)
    entry:SetFont("RP1942_MenuBody")
    entry:SetValue(self.payoutAmount or "5000")
    entry:SetTextColor(theme.text)
    entry:SetCursorColor(theme.text)
    entry:SetPaintBackground(false)
    entry.Paint = function(s, w, h)
        surface.SetDrawColor(0, 0, 0, 90)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(s:HasFocus() and theme.accentHover or theme.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(theme.text, theme.accentHover, theme.text)
    end
    entry.OnChange = function(s) self.payoutAmount = s:GetValue() end

    -- Faction toggles
    local toggles = self.content:Add("DPanel")
    toggles:Dock(TOP)
    toggles:DockMargin(0, 0, 0, 4)
    toggles:SetTall(32)
    toggles.Paint = nil
    for i, faction in ipairs(PAYOUT_FACTIONS) do
        local b = toggles:Add("DButton")
        b:Dock(LEFT)
        b:DockMargin(0, 0, 4, 0)
        b:SetFont("RP1942_MenuBody")
        b:SetTextColor(theme.text)
        b.Think = function(s)
            local n = RP1942.countFaction and RP1942.countFaction(faction, LocalPlayer()) or 0
            local text = (self.payoutPicked[faction] and "[x] " or "[  ] ") .. (FACTION_NAMES[faction] or faction) .. "  (" .. n .. ")"
            if s:GetText() ~= text then s:SetText(text) end
        end
        b.Paint = function(s, w, h)
            local on = self.payoutPicked[faction]
            surface.SetDrawColor(on and theme.accentHover or (s:IsHovered() and theme.accent or Color(0, 0, 0, 90)))
            surface.DrawRect(0, 0, w, h)
            if on then
                surface.SetDrawColor(theme.text)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
        end
        b.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            self.payoutPicked[faction] = not self.payoutPicked[faction] or nil
        end
    end
    toggles.PerformLayout = function(s, w)
        local each = math.floor((w - 8) / #PAYOUT_FACTIONS)
        for _, c in ipairs(s:GetChildren()) do c:SetWide(each) end
    end

    -- Who it goes to, and the cost
    local preview = self:AddText("")
    local baseThink = preview.Think
    preview.Think = function(s)
        if baseThink then baseThink(s) end
        local amount = math.floor(tonumber(self.payoutAmount or entry:GetValue()) or 0)
        local lp, count = LocalPlayer(), 0
        for _, p in ipairs(player.GetAll()) do
            if p ~= lp and self.payoutPicked[RP1942.getFaction(p)] then count = count + 1 end
        end
        local each, total = amount, amount * count
        if self.payoutMode ~= "each" then
            each = count > 0 and math.floor(amount / count) or 0
            total = each * count
        end
        local text = string.format("%d %s  ·  %s each  ·  costs %s of the treasury", count, count == 1 and "player" or "players",
            DarkRP.formatMoney(each), DarkRP.formatMoney(total))
        if s:GetText() ~= text then s:SetText(text) end
    end

    self:AddButton("Pay out from the treasury", function()
        local picked = {}
        for _, f in ipairs(PAYOUT_FACTIONS) do if self.payoutPicked[f] then picked[#picked + 1] = f end end
        self:Request("payout", self.payoutMode .. ":" .. tostring(math.floor(tonumber(entry:GetValue()) or 0)) .. "|" .. table.concat(picked, ","))
    end)
end

vgui.Register("RP1942_FuhrerMenu", PANEL, "RP1942_MenuBase")
