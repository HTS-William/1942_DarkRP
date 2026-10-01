--[[---------------------------------------------------------------------------
1942 DarkRP - the colours (client)

    RP1942.col(key)   -> a Color

The palette is the F4 menu's (RP1942.F4Config.colors in rp1942_f4/sh_f4.lua):
change a colour there and the HUD, notifications, the hold bar, the staff
spawner, the bank, machine labels and panels all follow. The few colours
below aren't in the F4 menu, so they live here; the rest of the table is
only used if the F4 module isn't installed.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local EXTRA = {
    labelBg = Color(14, 13, 12, 215),   -- behind floating labels in the world
    dim     = Color(170, 160, 142),     -- second lines on those labels
    well    = Color(46, 43, 39),        -- empty part of a progress bar
    good    = Color(90, 170, 90),       -- running, ready, success
    bad     = Color(200, 60, 50),       -- stopped, broken, failure
    warn    = Color(230, 170, 60),      -- getting hot, nearly done
    neutral = Color(60, 56, 50),
}

-- Only if rp1942_f4 is missing (the same values as sh_f4.lua)
local FALLBACK = {
    bg = Color(20, 19, 17, 248), titleBar = Color(14, 13, 12), panel = Color(28, 26, 23),
    card = Color(38, 35, 31), cardHover = Color(52, 48, 42), cardSelected = Color(64, 52, 36),
    category = Color(84, 18, 18), categoryAlt = Color(38, 72, 30), entry = Color(14, 13, 12),
    tab = Color(34, 32, 29), tabHover = Color(48, 45, 40), tabActive = Color(112, 22, 22),
    gold = Color(201, 168, 92), text = Color(236, 228, 212), sub = Color(160, 152, 136),
    available = Color(140, 200, 110), unavailable = Color(215, 85, 70),
    button = Color(128, 26, 24), buttonHover = Color(156, 36, 32), disabled = Color(52, 49, 45),
}

local MISSING = Color(255, 0, 255)

function RP1942.col(key)
    local f4 = RP1942.F4Config and RP1942.F4Config.colors
    return (f4 and f4[key]) or EXTRA[key] or FALLBACK[key] or MISSING
end
