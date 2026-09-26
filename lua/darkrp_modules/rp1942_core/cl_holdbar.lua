--[[---------------------------------------------------------------------------
1942 DarkRP - the "hold E" progress bar (client)
Shown under the crosshair while holding E on something that takes time:
searching a dumpster, robbing the supply train, and anything later. Lives in
core so it works no matter which of those are installed. From the server:
    ply:SetNW2Float("RP1942_HoldStart", CurTime())
    ply:SetNW2Float("RP1942_HoldEnd",   CurTime() + seconds)
    ply:SetNW2String("RP1942_HoldText", "Doing something...")
and set HoldEnd back to 0 to hide it.
---------------------------------------------------------------------------]]
local fontH = 0
local function makeFont()
    local h = math.max(14, math.floor(ScrH() * 0.019))
    if h == fontH then return end
    fontH = h
    surface.CreateFont("RP1942_HoldText", { font = "Roboto", size = h, weight = 600, extended = true })
end

hook.Add("HUDPaint", "RP1942_HoldBar", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local finish = ply:GetNW2Float("RP1942_HoldEnd", 0)
    if finish <= 0 then return end
    local start = ply:GetNW2Float("RP1942_HoldStart", 0)
    local frac = math.Clamp((CurTime() - start) / math.max(finish - start, 0.01), 0, 1)

    makeFont()
    local f4 = RP1942.F4Config and RP1942.F4Config.colors or {}
    local s = math.max(ScrH() / 1080, 0.6)
    local w, h = math.floor(320 * s), math.floor(12 * s)
    local x, y = math.floor(ScrW() / 2 - w / 2), math.floor(ScrH() / 2 + 60 * s)

    draw.SimpleText(ply:GetNW2String("RP1942_HoldText", ""), "RP1942_HoldText", ScrW() / 2, y - 6 * s,
        f4.text or Color(236, 228, 212), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

    local pad = math.max(2, math.floor(2 * s))
    surface.SetDrawColor(14, 13, 12, 220)
    surface.DrawRect(x - pad, y - pad, w + pad * 2, h + pad * 2)
    surface.SetDrawColor(f4.tabActive or Color(112, 22, 22))
    surface.DrawRect(x, y, math.floor(w * frac), h)
end)
