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
    self:AddText("Buy ovens and sacks of flour in the F4 Shop and push sacks into an oven (it queues three).")
    self:AddText("While it bakes, keep the fire in the green with STOKE FIRE on the oven's panel. Every second in the green counts: mostly green gives three excellent loaves, neglect gives one poor one.")
    self:AddText("Collect the bread from the panel, then sell it at a market or to other players. Better bread sells for more, and market sales help the economy.")
end

vgui.Register("RP1942_BakerMenu", PANEL, "RP1942_MenuBase")
