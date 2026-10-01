--[[---------------------------------------------------------------------------
1942 DarkRP - shortening text to fit (client)

    RP1942.fitText(text, font, maxW)  -> text, or text cut short with "..."

UTF-8 safe (Jörg, Führer). Used by the HUD, the F4 menu (UI.fit), the
scoreboard and the election banner. Measuring is the dear part (one
GetTextSize per character trimmed), so answers are remembered per
text / font / width; the memory is cleared when it gets big or the screen
size (and so every font) changes.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local cache, count = {}, 0

function RP1942.fitText(text, font, maxW)
    text = tostring(text or "")
    if maxW <= 0 then return "" end
    local key = font .. "\1" .. maxW .. "\1" .. text
    local hit = cache[key]
    if hit then return hit end

    surface.SetFont(font)
    local out = text
    if surface.GetTextSize(out) > maxW then
        while #out > 0 and surface.GetTextSize(out .. "...") > maxW do
            local last = utf8.offset(out, -1)
            out = string.sub(out, 1, (last or #out) - 1)
        end
        out = out .. "..."
    end

    if count >= 500 then cache, count = {}, 0 end   -- never grows without bound
    cache[key], count = out, count + 1
    return out
end

hook.Add("OnScreenSizeChanged", "RP1942_FitText", function() cache, count = {}, 0 end)
