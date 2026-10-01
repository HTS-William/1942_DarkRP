--[[---------------------------------------------------------------------------
1942 DarkRP - markers (client): labels on the screen over places in the
world, for a while. The server sends them with RP1942.showMarkers
(lua/autorun/rp1942_util.lua): your new oil derrick, every oil site, saved
machines (!prodsaves), every padlock (!doorlocks)...

Each label shows its text and how far away it is, stays on the screen's
edge when the place is off to the side, and fades out at the end. Several
sets can be up at once (each with its own time); a set sent again with the
same tag (running !doorlocks twice) replaces the old one.
---------------------------------------------------------------------------]]
RP1942.screenFont("RP1942_Marker", 0.016, 600, { min = 13 })

local sets = {}   -- { tag, markers = { { pos, text } }, untilT }

net.Receive("RP1942_Markers", function()
    local tag = net.ReadString()
    local seconds = net.ReadFloat()
    local list = {}
    for i = 1, net.ReadUInt(8) do list[i] = { pos = net.ReadVector(), text = net.ReadString() } end
    if tag ~= "" then
        for i = #sets, 1, -1 do
            if sets[i].tag == tag then table.remove(sets, i) end
        end
    end
    sets[#sets + 1] = { tag = tag, markers = list, untilT = CurTime() + seconds }
end)

hook.Add("HUDPaint", "RP1942_Markers", function()
    if #sets == 0 then return end
    local now = CurTime()
    local eye = LocalPlayer():EyePos()
    local sw, sh = ScrW(), ScrH()
    local bg, ink = RP1942.col("labelBg"), RP1942.col("gold")
    surface.SetFont("RP1942_Marker")
    for i = #sets, 1, -1 do
        local set = sets[i]
        if now > set.untilT then
            table.remove(sets, i)
        else
            local fade = math.Clamp((set.untilT - now) / 5, 0, 1)
            for _, m in ipairs(set.markers) do
                local s = m.pos:ToScreen()
                if s.visible then
                    local text = (m.text ~= "" and (m.text .. "  ·  ") or "") .. RP1942.metres(eye:Distance(m.pos)) .. " m"
                    local tw, th = surface.GetTextSize(text)
                    local x, y = math.Clamp(s.x, tw / 2 + 8, sw - tw / 2 - 8), math.Clamp(s.y, 40, sh - 40)
                    draw.RoundedBox(4, x - tw / 2 - 8, y - th - 14, tw + 16, th + 8, Color(bg.r, bg.g, bg.b, bg.a * fade))
                    draw.SimpleText(text, "RP1942_Marker", x, y - th - 10, Color(ink.r, ink.g, ink.b, 255 * fade), TEXT_ALIGN_CENTER)
                    surface.SetDrawColor(ink.r, ink.g, ink.b, 255 * fade)
                    surface.DrawRect(x - 1, y - 6, 2, 6)
                end
            end
        end
    end
end)
