--[[---------------------------------------------------------------------------
The Führer's menu. jobs.lua (Führer):  menu = "RP1942_FuhrerMenu",
Server side of the buttons: sv_menu_fuhrer.lua
---------------------------------------------------------------------------]]
local PANEL = {}

function PANEL:GetSubtitle()
    return "Reichskanzlei"
end

function PANEL:Populate()
    self:AddSection("Economy")

    -- Live status line: updates while the menu is open
    local status = self:AddText("")
    local baseThink = status.Think
    status.Think = function(s)
        if baseThink then baseThink(s) end
        local value = RP1942.getEconomy and RP1942.getEconomy()
        local text = value
            and string.format("%s  (%d / %d)", RP1942.getEconomyTier(value).text, value, RP1942.Economy.MAX)
            or "Economy module not loaded."
        if s:GetText() ~= text then s:SetText(text) end
    end

    self:AddSection("Debug")
    self:AddButton("Make economy gooder (+10)", function() self:Request("economy_up") end)
    self:AddButton("Make economy worser (-10)", function() self:Request("economy_down") end)
end

vgui.Register("RP1942_FuhrerMenu", PANEL, "RP1942_MenuBase")
