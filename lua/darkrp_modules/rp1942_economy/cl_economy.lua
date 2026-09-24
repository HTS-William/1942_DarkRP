--[[---------------------------------------------------------------------------
1942 DarkRP - economy status line (client)

Shows the current tier's text to every player, top centre of the screen.
---------------------------------------------------------------------------]]
local SHOW_HUD = true
local COLOR_TEXT = Color(230, 224, 208)
local COLOR_OUTLINE = Color(0, 0, 0, 200)

local function buildFont()
    surface.CreateFont("RP1942_EconomyHUD", {
        font = "Roboto",
        size = math.max(14, math.floor(ScrH() * 0.019)),
        weight = 500,
    })
end
buildFont()
hook.Add("OnScreenSizeChanged", "RP1942_EconomyFont", buildFont)

hook.Add("HUDPaint", "RP1942_EconomyHUD", function()
    if not SHOW_HUD then return end
    local tier = RP1942.getEconomyTier()
    draw.SimpleTextOutlined(tier.text, "RP1942_EconomyHUD", ScrW() / 2, 8,
        COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, COLOR_OUTLINE)
end)
