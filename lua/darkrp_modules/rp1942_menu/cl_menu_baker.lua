--[[---------------------------------------------------------------------------
EXAMPLE: the simplest job menu. Only overrides what it needs.
jobs.lua (Baker):  menu = "RP1942_BakerMenu",
Server side of the button: sv_menu_baker.lua
---------------------------------------------------------------------------]]
local PANEL = {}

function PANEL:GetSubtitle()
    return "Bakery ledger"
end

function PANEL:Populate()
    self:AddSection("Shop")
    self:AddButton("Announce fresh bread", function()
        self:Request("announce_bread")
    end)

    self:AddSection("Notes")
    self:AddText("Ovens take 3 minutes and yield between one and three loaves.")
end

vgui.Register("RP1942_BakerMenu", PANEL, "RP1942_MenuBase")
