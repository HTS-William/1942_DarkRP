--[[---------------------------------------------------------------------------
1942 DarkRP - where the "who's talking" panels sit

Both voice HUDs (Garry's Mod's own g_VoicePanelList and EasyChat's
EasyChat.GUI.VoiceList) sit 300 pixels in from the right edge, which leaves
them floating in the middle of the screen on wide displays. They're moved
flush with the right edge, RIGHT_MARGIN from it, whenever someone starts
talking (the lists are only created then) and when the screen size changes.
---------------------------------------------------------------------------]]
local RIGHT_MARGIN = 16   -- pixels between the panels and the right edge of the screen
local WIDTH = 250         -- the panels' width (both HUDs use 250)

local function place()
    local x = ScrW() - WIDTH - RIGHT_MARGIN
    for _, list in ipairs({ g_VoicePanelList, EasyChat and EasyChat.GUI and EasyChat.GUI.VoiceList }) do
        if IsValid(list) then
            local _, y = list:GetPos()
            list:SetPos(x, y)
            list:SetWide(WIDTH)
        end
    end
end

-- the lists are made on the first PlayerStartVoice, after the hooks run
hook.Add("PlayerStartVoice", "RP1942_VoicePanelPos", function()
    timer.Simple(0, place)
end)
hook.Add("OnScreenSizeChanged", "RP1942_VoicePanelPos", function()
    timer.Simple(0, place)
end)
