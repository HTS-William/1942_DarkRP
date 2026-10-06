include("shared.lua")

--[[---------------------------------------------------------------------------
The oven's panel, in the Wine Barrel's style. It sits on the front of the
oven (RP1942.PanelSpots.rp1942_oven in sh_production.lua; fine-tune it in
game with the rp1942_panel_* console commands).

    BREAD OVEN
    Baking · 1:42 left                  [progress]
    THE FIRE IS DYING - STOKE IT        [cold | just right | too hot]
    BATCH (SO FAR)   ★★☆ 2 loaves · in the green 64% of the time
    FLOUR            [sacks waiting]
    [ STOKE FIRE ] [ COLLECT ] [ OFF ]
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 560, h = 600 }
ENT.PanelScale = 0.045   -- only used if the panel floats (no spot)

local ACCENT = Color(196, 98, 40)
local COLD, RIGHT, HOT = Color(70, 90, 150), Color(60, 140, 70), Color(190, 50, 40)
local BLUE_TEXT, RED_TEXT, GREEN_TEXT = Color(120, 160, 240), Color(230, 110, 96), Color(140, 220, 140)
local SACK = Color(150, 128, 90)
local COLLECT_BTN, POWER_BTN = Color(90, 110, 60), Color(52, 48, 42)

-- A line from the baker's book, picked once per oven by the batch's stars
local NOTES = {
    [1] = { "Heavy as a brick. Soldiers have eaten worse.", "Burnt at the edges, raw in the middle.", "It's bread. Technically." },
    [2] = { "A fair loaf: good with soup, better with butter.", "Honest rye, a little dense. Nobody complains.", "Plain and filling, like Sunday at Grandmother's." },
    [3] = { "Golden crust, soft crumb: worth every ration coupon.", "The whole street can smell it. Expect visitors.", "Fit for the Kommandant's table." },
}

-- "Excellent", "Fine", "Poor"
local function qualityName(q)
    local n = RP1942.qualityName(q)
    return string.upper(string.sub(n, 1, 1)) .. string.sub(n, 2)
end

function ENT:PaintPanel(P, w, h)
    local C = RP1942.PanelColors
    local c = self:Config()
    local x, y, iw = 28, 76, w - 56
    local baking, ready, flour, off = self:IsBaking(), self:GetReady(), self:GetFlour(), self:GetOff()
    P:Title("BREAD OVEN", ACCENT)

    ------------------------------------------------------------ status and progress
    if ready > 0 then
        P:Text("Done!  Collect the bread while it's warm.", "RP1942_PanelBody", x, y, C.gold)
        P:Bar(x, y + 32, iw, 14, 1, ACCENT)
    elseif baking then
        local left = math.max(self:GetDoneAt() - self:Now(), 0)
        P:Text(off and ("Switched off  ·  bake paused, " .. RP1942.clock(left) .. " left") or ("Baking  ·  " .. RP1942.clock(left) .. " left"),
            "RP1942_PanelBody", x, y, C.dim)
        P:Bar(x, y + 32, iw, 14, 1 - left / c.bakeTime, ACCENT)
    else
        local maxLoaves = c.grades[1] and c.grades[1].loaves or 3
        P:Text(off and "Switched off" or (flour > 0 and "Starting..." or ("Ready to bake  ·  up to " .. maxLoaves .. " loaves in " .. RP1942.clock(c.bakeTime))),
            "RP1942_PanelBody", x, y, C.dim)
        P:Bar(x, y + 32, iw, 14, 0, ACCENT)
    end
    y = y + 70

    local zones = { { 0, c.heat.cold, COLD, "COLD" }, { c.heat.cold, c.heat.hot, RIGHT, "JUST RIGHT" }, { c.heat.hot, 100, HOT, "TOO HOT" } }

    if baking or ready > 0 then
        ------------------------------------------------------------ the fire
        local zone = baking and self:HeatZone() or nil
        if ready > 0 then
            P:Text("THE FIRE", "RP1942_PanelHead", x, y, C.dim)
            P:Text("BANKED", "RP1942_PanelHead", x + iw, y, C.faint, TEXT_ALIGN_RIGHT)
        elseif off then
            P:Text("THE FIRE", "RP1942_PanelHead", x, y, C.dim)
            P:Text("SWITCHED OFF", "RP1942_PanelHead", x + iw, y, C.faint, TEXT_ALIGN_RIGHT)
        elseif zone == "cold" then
            P:Text("THE FIRE IS DYING  -  STOKE IT", "RP1942_PanelHead", x, y, BLUE_TEXT)
        elseif zone == "hot" then
            P:Text("TOO HOT  -  LET IT COOL", "RP1942_PanelHead", x, y, RED_TEXT)
        else
            P:Text("THE FIRE  ·  JUST RIGHT", "RP1942_PanelHead", x, y, GREEN_TEXT)
        end
        P:Zones(x, y + 52, iw, 22, baking and self:Heat() or 50, zones, { live = baking and not off })
        y = y + 126

        ------------------------------------------------------------ the batch
        if ready > 0 then
            local q = self:GetReadyQuality()
            P:Text("IN THE TRAY", "RP1942_PanelHead", x, y, C.dim)
            local sw = P:Stars(x, y + 30, q, 26)
            P:Text(qualityName(q) .. "  ·  " .. ready .. (ready == 1 and " loaf" or " loaves"), "RP1942_PanelBody", x + sw + 8, y + 31, C.text)
            y = y + 80
            local notes = NOTES[q] or NOTES[2]
            P:Text("FROM THE BAKER'S BOOK", "RP1942_PanelHead", x, y, C.dim)
            P:Text("\"" .. notes[(self:EntIndex() % #notes) + 1] .. "\"", "RP1942_PanelSmall", x, y + 30, C.dim)
        else
            local share = self:GetGreen() / math.max(self:Now() - self:GetBakeStart(), 1)
            local loaves = self:Grade(share)
            P:Text("BATCH (SO FAR)", "RP1942_PanelHead", x, y, C.dim)
            local sw = P:Stars(x, y + 30, loaves, 26)
            P:Text(loaves .. (loaves == 1 and " loaf" or " loaves") .. "  ·  in the green " .. math.Round(math.Clamp(share, 0, 1) * 100) .. "% of the time",
                "RP1942_PanelBody", x + sw + 8, y + 31, C.text)
            y = y + 80
            P:Text("FLOUR", "RP1942_PanelHead", x, y, C.dim)
            local fw = P:Slots(x, y + 30, flour, c.queue, SACK)
            P:Text(flour == 0 and "No more sacks waiting" or (flour .. (flour == 1 and " more sack waiting" or " more sacks waiting")),
                "RP1942_PanelBody", x + fw + 8, y + 36, C.text)
        end
    else
        ------------------------------------------------------------ waiting for flour
        P:Text("FLOUR", "RP1942_PanelHead", x, y, C.dim)
        local fw = P:Slots(x, y + 30, flour, c.queue, SACK)
        P:Text(flour == 0 and "No sacks waiting" or (flour .. (flour == 1 and " sack waiting" or " sacks waiting")),
            "RP1942_PanelBody", x + fw + 8, y + 36, C.text)
        y = y + 90
        P:Text("HOW IT WORKS", "RP1942_PanelHead", x, y, C.dim)
        P:Text("Push a sack of flour in to start a bake. While it", "RP1942_PanelBody", x, y + 30, C.dim)
        P:Text("bakes the fire cools: stoke it to keep the needle", "RP1942_PanelBody", x, y + 58, C.dim)
        P:Text("in the green. More time in the green, more loaves.", "RP1942_PanelBody", x, y + 86, C.dim)
        y = y + 150
        if not off and flour == 0 then P:Text("PUSH IN A SACK OF FLOUR", "RP1942_PanelHead", x, y, C.gold) end
    end

    ------------------------------------------------------------ buttons
    local by, pw = h - 140, 110
    local bw = (iw - 40 - pw) / 2
    P:Button("stoke", x, by, bw, 58, "STOKE FIRE", { enabled = baking and not off, color = ACCENT })
    P:Button("collect", x + bw + 20, by, bw, 58, ready > 0 and ("COLLECT (" .. ready .. ")") or "COLLECT", { enabled = ready > 0, color = COLLECT_BTN })
    P:Button("power", x + 2 * bw + 40, by, pw, 58, off and "ON" or "OFF", { color = POWER_BTN })

    P:Hint(x, h, { stoke = "STOKE FIRE", collect = "COLLECT BREAD", power = off and "SWITCH ON" or "SWITCH OFF (PAUSES THE BAKE)" })
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
