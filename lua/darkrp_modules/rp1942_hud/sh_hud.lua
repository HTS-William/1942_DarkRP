--[[---------------------------------------------------------------------------
1942 DarkRP - HUD (shared config)

Replaces DarkRP's bottom-left player panel and the HL2 ammo counter, in the
F4 menu's style. DarkRP's other HUD parts stay: names above heads, the
arrested timer, the lockdown notice, agendas, voice chat.

    bottom-left    job colour strip, name, job / money / salary,
                   health and armour bars, status tags:
                       LEG INJURED   (pain system: can't sprint or jump)
                       WANTED        (with the reason)
                       UNDERCOVER    (your real job, when your title is a cover)
                       LICENSED      (DarkRP gun licence)
    bottom-centre  the economy: tier, a meter (tier boundaries marked), the
                   wage multiplier, and your tax rate when there is one
    bottom-right   weapon name and ammo (only for weapons that use ammo)

Any screen: everything scales with the screen height; on very wide screens
(ultrawide, triple monitors) the HUD stays inside a central maxAspect area;
if the economy bar would touch a side panel it moves up above it.

While this HUD is on, the wanted system's small corner tag is left out (the
WANTED status tag replaces it), and so is the economy line at the top of the
screen (the economy bar replaces it).

Files: sh_hud.lua (this), cl_hud.lua (the drawing).
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.HUDConfig = {
    enabled     = true,        -- false = DarkRP's own HUD comes back
    showAmmo    = true,
    showSalary  = true,
    showEconomy = true,
    lowHealth   = 25,          -- at or below this, the health bar pulses
    width       = 380,         -- player panel width at 1080p (scales with the screen)
    economyWidth = 440,        -- economy bar width at 1080p
    maxAspect   = 21 / 9,      -- wider screens keep the HUD in a central area this shape

    --[[-----------------------------------------------------------------------
    Colours. Background, text and accents follow the F4 menu's colours
    (RP1942.F4Config.colors) when that's installed; these are the extras.
    -----------------------------------------------------------------------]]
    colors = {
        health      = Color(176, 42, 36),
        healthLow   = Color(230, 70, 55),
        armour      = Color(104, 128, 150),
        barBg       = Color(46, 43, 39),
        injury      = Color(206, 146, 48),    -- LEG INJURED tag
        wanted      = Color(200, 30, 30),     -- WANTED tag
        undercover  = Color(70, 70, 66),      -- UNDERCOVER tag
        licence     = Color(64, 92, 60),      -- LICENSED tag

        -- Economy meter, by tier (tier ids from rp1942_economy/sh_economy.lua)
        economy = {
            poor        = Color(170, 50, 40),
            downturn    = Color(200, 132, 52),
            average     = Color(190, 170, 110),
            good        = Color(112, 170, 82),
            flourishing = Color(82, 200, 112),
        },
    },
}
