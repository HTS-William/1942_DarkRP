--[[---------------------------------------------------------------------------
1942 DarkRP - economy status line (client)

Shows the current tier's text to every player, top centre of the screen.
---------------------------------------------------------------------------]]
local SHOW_HUD = true
local COLOR_TEXT = Color(230, 224, 208)
local COLOR_OUTLINE = Color(0, 0, 0, 200)

-- fonts sized from the screen: lua/autorun/client/rp1942_screenfonts.lua
RP1942.screenFont("RP1942_EconomyHUD", 0.019, 500, { min = 14 })

hook.Add("HUDPaint", "RP1942_EconomyHUD", function()
    if not SHOW_HUD then return end
    -- The 1942 HUD shows the economy as a bar at the bottom instead (rp1942_hud)
    local hud = RP1942.HUDConfig
    if hud and hud.enabled and hud.showEconomy then return end
    local tier = RP1942.getEconomyTier()
    draw.SimpleTextOutlined(tier.text, "RP1942_EconomyHUD", ScrW() / 2, 8,
        COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, COLOR_OUTLINE)
end)
