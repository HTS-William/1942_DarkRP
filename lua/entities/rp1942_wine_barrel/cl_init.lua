include("shared.lua")

ENT.PanelSize  = { w = 560, h = 560 }
ENT.PanelScale = 0.045

local ACCENT = Color(140, 40, 62)
local ALERT = Color(230, 110, 96)

-- A line of tasting notes, picked once per barrel by its vintage
local NOTES = {
    [1] = { "Thin and sour. Fine for cooking, if you must.", "Vinegar with ambitions.", "Best drunk quickly, and by someone else." },
    [2] = { "A sturdy red. Hints of oak and ration-card optimism.", "Honest, dry and warming on a cold night.", "Plums, smoke and a little patience." },
    [3] = { "Deep and velvety. Worth hiding from the quartermaster.", "Dark cherry and old leather: a cellar-worthy vintage.", "Smooth as a Sunday. Officers would pay double." },
}

function ENT:PaintPanel(P, w, h)
    local C = RP1942.PanelColors
    local c = self:Config()
    local x, y, iw = 28, 76, w - 56
    P:Title("WINE BARREL", ACCENT)

    local fermenting, done = self:IsFermenting(), self:IsDone()
    local stirs, calls = self:GetStirs(), self:GetCalls()

    if not fermenting and not done then
        P:Text("Ready to ferment  ·  " .. c.bottles .. " bottles in " .. RP1942.clock(c.time), "RP1942_PanelBody", x, y, C.dim)
        P:Bar(x, y + 32, iw, 14, 0, ACCENT)
        y = y + 70
        P:Text("HOW IT WORKS", "RP1942_PanelHead", x, y, C.dim)
        P:Text("While it ferments, the must calls for stirring", "RP1942_PanelBody", x, y + 30, C.dim)
        P:Text("now and then. Stir before the timer runs out:", "RP1942_PanelBody", x, y + 58, C.dim)
        P:Text("every call you miss lowers the vintage.", "RP1942_PanelBody", x, y + 86, C.dim)
        y = y + 150
        P:Button("start", x, y, iw, 64, "START FERMENTING", { color = ACCENT })
    else
        -- Progress
        if fermenting then
            local left = self:GetDoneAt() - CurTime()
            P:Text("Fermenting  ·  " .. RP1942.clock(left) .. " left", "RP1942_PanelBody", x, y, C.dim)
            P:Bar(x, y + 32, iw, 14, 1 - left / c.time, ACCENT)
        else
            P:Text("Done!  Bottle it while it's fresh.", "RP1942_PanelBody", x, y, C.gold)
            P:Bar(x, y + 32, iw, 14, 1, ACCENT)
        end
        y = y + 70

        -- Stirring
        if self:NeedsStir() then
            local left = self:GetStirBy() - CurTime()
            P:Text("THE MUST NEEDS STIRRING", "RP1942_PanelHead", x, y, ALERT)
            P:Text("Stir within " .. RP1942.clock(left) .. " or the vintage suffers.", "RP1942_PanelBody", x, y + 28, C.dim)
            P:Bar(x, y + 62, iw, 12, left / c.stirWindow, ALERT)
        elseif fermenting then
            P:Text("RESTING", "RP1942_PanelHead", x, y, C.dim)
            P:Text("Stay close: it may call for stirring again.", "RP1942_PanelBody", x, y + 28, C.faint)
        end
        y = y + 96

        -- Vintage: final once done, otherwise the best it can still reach
        local missed = done and (calls - stirs) or self:Missed()
        local stars = done and self:GetQuality() or self:Vintage(missed)
        P:Text(done and "VINTAGE" or "VINTAGE (SO FAR)", "RP1942_PanelHead", x, y, C.dim)
        local sw = P:Stars(x, y + 30, stars, 26)
        P:Text(RP1942.qualityName(stars) .. "  ·  stirred " .. stirs .. (stirs == 1 and " time" or " times")
            .. (missed > 0 and ("  ·  missed " .. missed) or ""), "RP1942_PanelBody", x + sw + 8, y + 30, C.text)
        y = y + 80

        if done then
            local notes = NOTES[self:GetQuality()] or NOTES[2]
            P:Text("TASTING NOTES", "RP1942_PanelHead", x, y, C.dim)
            P:Text("\"" .. notes[(self:EntIndex() % #notes) + 1] .. "\"", "RP1942_PanelSmall", x, y + 30, C.dim)
        end
        y = y + 70

        local bw = (iw - 20) / 2
        P:Button("stir", x, y, bw, 58, "STIR", { enabled = self:NeedsStir(), color = ACCENT })
        P:Button("bottle", x + bw + 20, y, bw, 58, "BOTTLE (" .. c.bottles .. ")", { enabled = done, color = Color(90, 110, 60) })
    end

    y = h - 44
    if P.hover then
        local names = { start = "START FERMENTING", stir = "STIR", bottle = "BOTTLE" }
        P:Text("Looking at: " .. (names[P.hover] or P.hover) .. "  —  press E", "RP1942_PanelBody", x, y, C.gold)
    else
        P:Text("Look at a button and press E.", "RP1942_PanelBody", x, y, C.faint)
    end
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
