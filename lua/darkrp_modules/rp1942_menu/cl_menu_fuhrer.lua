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

vgui.Register("RP1942_FuhrerMenu", PANEL, "RP1942_MenuBase")
