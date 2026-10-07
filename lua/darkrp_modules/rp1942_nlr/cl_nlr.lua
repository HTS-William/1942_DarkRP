--[[---------------------------------------------------------------------------
1942 DarkRP - the NLR zone (client). Settings: sh_nlr.lua

While your NLR runs:
    - a small tag at the top of the screen:  NEW LIFE RULE  2:31
    - the zone where you died, drawn on the ground as a red ring (only you
      see it), once you're anywhere near it
    - back inside it: a warning in the middle of the screen counting down
      until you're sent to spawn
    - sent to spawn: "held at spawn" with the time left
---------------------------------------------------------------------------]]
local CFG = RP1942.NLR

RP1942.screenFont("RP1942_NLRTag", 0.016, 700, { min = 13 })
RP1942.screenFont("RP1942_NLRBig", 0.026, 800, { min = 18 })
RP1942.screenFont("RP1942_NLRSmall", 0.017, 500, { min = 13 })

local function C(k) return RP1942.col(k) end
local RED = Color(214, 64, 52)

local function clock(s)
    s = math.max(0, math.ceil(s))
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

hook.Add("HUDPaint", "RP1942_NLR", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local st = RP1942.nlrState(ply)
    if not st then return end
    local now = CurTime()
    local s = math.max(ScrH() / 1080, 0.6)

    -- The tag at the top
    local tag = "NEW LIFE RULE  ·  " .. clock(st.ends - now)
    surface.SetFont("RP1942_NLRTag")
    local tw, th = surface.GetTextSize(tag)
    local pw, ph = tw + math.floor(28 * s), th + math.floor(10 * s)
    local px, py = math.floor(ScrW() / 2 - pw / 2), math.floor(14 * s)
    draw.RoundedBox(4, px, py, pw, ph, Color(14, 13, 12, 220))
    surface.SetDrawColor(st.held and RED or C("gold"))
    surface.DrawRect(px, py, math.max(3, math.floor(4 * s)), ph)
    draw.SimpleText(tag, "RP1942_NLRTag", ScrW() / 2 + 2 * s, py + ph / 2, C("text"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- The warning, or being held
    local title, line
    if st.held then
        title = "HELD AT SPAWN  ·  " .. clock(st.ends - now)
        line = "You went back where you died. You can move again when your NLR is over."
    elseif st.warnBy > now then
        title = "LEAVE THE NLR ZONE  ·  " .. math.ceil(st.warnBy - now)
        line = "You're back where you died. Get out of the red ring or you'll be sent to spawn."
    end
    if not title then return end
    local flash = st.held or math.floor(RealTime() * 3) % 2 == 0
    surface.SetFont("RP1942_NLRBig")
    local bw1 = surface.GetTextSize(title)
    surface.SetFont("RP1942_NLRSmall")
    local bw2 = surface.GetTextSize(line)
    local bw, bh = math.max(bw1, bw2) + math.floor(56 * s), math.floor(86 * s)
    local bx, by = math.floor(ScrW() / 2 - bw / 2), math.floor(ScrH() * 0.22)
    draw.RoundedBox(4, bx, by, bw, bh, Color(28, 14, 12, 235))
    surface.SetDrawColor(flash and RED or Color(120, 40, 32))
    surface.DrawRect(bx, by, bw, math.max(3, math.floor(4 * s)))
    draw.SimpleText(title, "RP1942_NLRBig", ScrW() / 2, by + bh * 0.38, flash and RED or C("text"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(line, "RP1942_NLRSmall", ScrW() / 2, by + bh * 0.74, C("text"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-- The zone on the ground: a red ring with a low glowing wall round where you died
local SEGMENTS = 64
hook.Add("PostDrawTranslucentRenderables", "RP1942_NLR", function(depth, sky)
    if depth or sky then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local st = RP1942.nlrState(ply)
    if not st or st.held then return end
    local r = CFG.radius
    if ply:GetPos():DistToSqr(st.pos) > (r * 2.5) ^ 2 then return end

    local inside = ply:GetPos():DistToSqr(st.pos) < r * r
    local pulse = 0.6 + 0.4 * math.abs(math.sin(RealTime() * (inside and 6 or 2)))
    render.SetColorMaterial()
    local prev
    local base = st.pos + Vector(0, 0, 4)
    for i = 0, SEGMENTS do
        local a = i / SEGMENTS * math.pi * 2
        local p = base + Vector(math.cos(a) * r, math.sin(a) * r, 0)
        if prev then
            -- a low wall along the ring, so it reads from any angle
            render.DrawQuad(prev, p, p + Vector(0, 0, 48), prev + Vector(0, 0, 48), Color(214, 64, 52, 70 * pulse))
            render.DrawQuad(prev + Vector(0, 0, 48), p + Vector(0, 0, 48), p, prev, Color(214, 64, 52, 70 * pulse))
            render.DrawLine(prev, p, Color(240, 80, 60, 255 * pulse), true)
        end
        prev = p
    end
end)
