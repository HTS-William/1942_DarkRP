--[[---------------------------------------------------------------------------
1942 DarkRP - fonts sized from the screen (client)

    RP1942.screenFont(name, scale, weight, opts)

Makes the font now (size = scale x screen height, never below opts.min) and
remakes it whenever the resolution changes, so one hook does it for every
menu and HUD. opts (all optional):
    min    smallest size in pixels (default 12)
    font   the typeface (default "Roboto")
    any other surface.CreateFont field: outline, antialias, italic...
Fonts are "extended" by default, so ü and ß (Führer, Straße) draw.

In lua/autorun so it's ready before any DarkRP module loads (modules load in
an order we don't control).
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local fonts = {}   -- name -> { scale, weight, opts }

local function make(name, f)
    local data = { font = "Roboto", extended = true, weight = f.weight }
    for k, v in pairs(f.opts) do
        if k ~= "min" then data[k] = v end
    end
    data.size = math.max(f.opts.min or 12, math.floor(ScrH() * f.scale))
    surface.CreateFont(name, data)
end

function RP1942.screenFont(name, scale, weight, opts)
    local f = { scale = scale, weight = weight, opts = opts or {} }
    fonts[name] = f
    make(name, f)
end

hook.Add("OnScreenSizeChanged", "RP1942_ScreenFonts", function()
    for name, f in pairs(fonts) do make(name, f) end
end)
