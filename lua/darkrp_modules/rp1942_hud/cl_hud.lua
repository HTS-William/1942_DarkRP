--[[---------------------------------------------------------------------------
1942 DarkRP - HUD (client). Settings: RP1942.HUDConfig in sh_hud.lua.

    ┌▌ player panel ────────┐      ┌ economy ─────────────┐      ┌ ammo ┐
    │▌ name                 │      │ ECONOMY · AVERAGE ×… │      │ KAR  │
    │▌ job · money · salary │      │ [===|====|===|===]   │      │ 5/90 │
    │▌ HEALTH / ARMOUR bars │      └──────────────────────┘      └──────┘
    │▌ status tags          │
    └───────────────────────┘

Screen handling (any resolution or shape):
    - one scale for everything: screen height / 1080, no upper limit, so
      text and panels always grow together (4K = twice 1080p)
    - label and value columns are measured from the text, never assumed
    - wider than maxAspect (ultrawide, triple monitors): the HUD stays in a
      central area of that shape instead of the far corners
    - the economy bar moves up if it would touch either side panel
Each frame the panels' rectangles are left in RP1942.HUDRects.
---------------------------------------------------------------------------]]
local CFG = RP1942.HUDConfig
if not CFG then return end
local HC = CFG.colors

-- Base colours follow the F4 menu so the two always match
local FALLBACK = {
    bg = Color(20, 19, 17), titleBar = Color(14, 13, 12), tabActive = Color(112, 22, 22),
    gold = Color(201, 168, 92), text = Color(236, 228, 212), sub = Color(160, 152, 136),
}
local function C(key)
    local f4 = RP1942.F4Config and RP1942.F4Config.colors
    return (f4 and f4[key]) or FALLBACK[key]
end
local function alpha(c, a) return Color(c.r, c.g, c.b, a) end

local function buildFonts()
    local h = ScrH()
    local function font(name, scale, weight)
        surface.CreateFont(name, { font = "Roboto", size = math.max(12, math.floor(h * scale)), weight = weight, extended = true })
    end
    font("RP1942_HudName",    0.021, 800)
    font("RP1942_HudBody",    0.015, 500)
    font("RP1942_HudSmall",   0.0125, 700)
    font("RP1942_HudAmmo",    0.040, 800)
    font("RP1942_HudAmmoSub", 0.018, 600)
end
buildFonts()
hook.Add("OnScreenSizeChanged", "RP1942_HudFonts", buildFonts)

local function textSize(font, text)
    surface.SetFont(font)
    return surface.GetTextSize(text)
end
local function fontH(font) local _, h = textSize(font, "Ag") return h end

local function fit(text, font, maxW)
    if maxW <= 0 then return "" end
    if textSize(font, text) <= maxW then return text end
    while #text > 0 and textSize(font, text .. "...") > maxW do
        local last = utf8.offset(text, -1)
        text = string.sub(text, 1, (last or #text) - 1)
    end
    return text .. "..."
end

--[[---------------------------------------------------------------------------
The screen: scale and the area the HUD lives in
---------------------------------------------------------------------------]]
local function metrics()
    local sw, sh = ScrW(), ScrH()
    local s = math.max(sh / 1080, 0.6)
    local areaW = math.min(sw, sh * (CFG.maxAspect or 21 / 9))
    local m = {
        s = s, sw = sw, sh = sh,
        left = math.floor((sw - areaW) / 2), right = math.floor((sw + areaW) / 2), areaW = areaW,
        margin = math.floor(16 * s), pad = math.floor(12 * s), gap = math.floor(8 * s),
    }
    return m
end

local function overlapsX(a, b, gap)
    return a and b and a.x < b.x + b.w + gap and b.x < a.x + a.w + gap
end

--[[---------------------------------------------------------------------------
Hide only what this replaces
---------------------------------------------------------------------------]]
hook.Add("HUDShouldDraw", "RP1942_HUD", function(name)
    if not CFG.enabled then return end
    if name == "DarkRP_LocalPlayerHUD" then return false end
    if CFG.showAmmo and (name == "CHudAmmo" or name == "CHudSecondaryAmmo") then return false end
end)

local function hidden(lp)
    if not IsValid(lp) or not lp:Alive() then return true end
    local wep = lp:GetActiveWeapon()
    return IsValid(wep) and wep:GetClass() == "gmod_camera"   -- clean screenshots
end

--[[---------------------------------------------------------------------------
Status tags: { text, colour } for whatever applies right now
---------------------------------------------------------------------------]]
local function statusTags(lp)
    local tags = {}

    -- Pain system: a leg shot stops sprinting and jumping for a while
    if PainSystem and PainSystem.HasLegInjury and PainSystem.HasLegInjury(lp) then
        local untilT = lp:GetNW2Float("PainSys_LegsUntil", 0)
        local text = "LEG INJURED  ·  NO SPRINT OR JUMP"
        if untilT < 1e8 then
            text = text .. "  ·  " .. string.FormattedTime(math.max(0, math.ceil(untilT - CurTime())), "%01i:%02i")
        end
        local pulse = 0.75 + 0.25 * math.sin(CurTime() * 4)
        tags[#tags + 1] = { text, alpha(HC.injury, 255 * pulse) }
    end

    if lp:getDarkRPVar("wanted") then
        local reason = lp:getDarkRPVar("wantedReason")
        tags[#tags + 1] = { "WANTED" .. ((reason and reason ~= "") and ("  ·  " .. reason) or ""), HC.wanted }
    end

    -- Your shown title is a cover (Gestapo, Resistance Operative): remind you who you really are
    local job = RPExtraTeams[lp:Team()]
    local title = lp:getDarkRPVar("job")
    if job and title and title ~= job.name and (job.quietJoin or (RP1942.canDisguise and RP1942.canDisguise(lp))) then
        tags[#tags + 1] = { "UNDERCOVER  ·  " .. job.name, HC.undercover }
    end

    if lp:getDarkRPVar("HasGunlicense") then
        tags[#tags + 1] = { "LICENSED", HC.licence }
    end
    return tags
end

--[[---------------------------------------------------------------------------
Bottom-left: the player panel. Returns its rectangle.
---------------------------------------------------------------------------]]
local shownHealth, shownArmour = 100, 0

local function drawBar(x, y, w, m, label, value, maxValue, color, shown)
    local s = m.s
    -- Columns measured from the text, so they never collide at any size
    local labelW = math.max(math.floor(66 * s), textSize("RP1942_HudSmall", "ARMOUR") + math.floor(8 * s))
    local valueW = math.max(math.floor(40 * s), textSize("RP1942_HudBody", "000") + math.floor(6 * s))
    local barH = math.max(6, math.floor(9 * s))
    local rowH = math.max(fontH("RP1942_HudSmall"), fontH("RP1942_HudBody"), barH)

    draw.SimpleText(label, "RP1942_HudSmall", x, y + rowH / 2, C("sub"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local bx, bw = x + labelW, math.max(10, w - labelW - valueW)
    local by = y + (rowH - barH) / 2
    draw.RoundedBox(3, bx, by, bw, barH, HC.barBg)
    local frac = math.Clamp(shown / math.max(maxValue, 1), 0, 1)
    if frac > 0 then draw.RoundedBox(3, bx, by, math.max(barH, bw * frac), barH, color) end
    draw.SimpleText(tostring(math.max(0, math.Round(value))), "RP1942_HudBody", x + w, y + rowH / 2, C("text"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    return rowH
end

local function drawPlayerPanel(lp, m)
    local s, pad, gap = m.s, m.pad, m.gap
    local w = math.floor(math.min(CFG.width * s, m.areaW * 0.34))
    local strip = math.max(3, math.floor(4 * s))
    local innerX, innerW = pad + strip, w - pad * 2 - strip

    local hp, maxHp = lp:Health(), math.max(lp:GetMaxHealth(), 1)
    local armour = lp:Armor()
    shownHealth = Lerp(math.min(FrameTime() * 8, 1), shownHealth, hp)
    shownArmour = Lerp(math.min(FrameTime() * 8, 1), shownArmour, armour)
    local showArmour = armour > 0 or shownArmour > 0.5

    local job = RPExtraTeams[lp:Team()]
    local title = lp:getDarkRPVar("job") or (job and job.name) or ""
    local line2 = title .. "  ·  " .. DarkRP.formatMoney(lp:getDarkRPVar("money") or 0)
    local salary = lp:getDarkRPVar("salary")
    if CFG.showSalary and salary and salary > 0 then line2 = line2 .. "  ·  +" .. DarkRP.formatMoney(salary) end

    -- Status tags, wrapped onto as many rows as they need
    local tags = statusTags(lp)
    local tagH, tagPadX = fontH("RP1942_HudSmall") + math.floor(6 * s), math.floor(8 * s)
    local placed, tx, ty = {}, 0, 0
    for _, tag in ipairs(tags) do
        local text = fit(tag[1], "RP1942_HudSmall", innerW - tagPadX * 2)
        local tw = textSize("RP1942_HudSmall", text) + tagPadX * 2
        if tx > 0 and tx + tw > innerW then tx, ty = 0, ty + tagH + math.floor(4 * s) end
        placed[#placed + 1] = { text = text, color = tag[2], x = tx, y = ty, w = tw }
        tx = tx + tw + math.floor(4 * s)
    end
    local tagsH = #placed > 0 and (ty + tagH) or 0

    local nameH, bodyH = fontH("RP1942_HudName"), fontH("RP1942_HudBody")
    local rowH = math.max(fontH("RP1942_HudSmall"), bodyH, math.floor(9 * s))
    local h = pad + nameH + 2 + bodyH + gap + 2 + gap + rowH + (showArmour and (gap + rowH) or 0)
        + (tagsH > 0 and (gap + tagsH) or 0) + pad

    local x, y = m.left + m.margin, m.sh - m.margin - h
    draw.RoundedBox(6, x, y, w, h, alpha(C("bg"), 235))
    local jobColor = job and job.color or team.GetColor(lp:Team())
    draw.RoundedBoxEx(6, x, y, strip, h, jobColor, true, false, true, false)

    local cy = y + pad
    draw.SimpleText(fit(lp:Nick(), "RP1942_HudName", innerW), "RP1942_HudName", x + innerX, cy, C("text"))
    cy = cy + nameH + 2
    draw.SimpleText(fit(line2, "RP1942_HudBody", innerW), "RP1942_HudBody", x + innerX, cy, C("sub"))
    cy = cy + bodyH + gap

    surface.SetDrawColor(C("tabActive"))
    surface.DrawRect(x + strip, cy, w - strip, 2)
    cy = cy + 2 + gap

    local healthColor = HC.health
    if hp <= CFG.lowHealth then
        local pulse = 0.5 + 0.5 * math.sin(CurTime() * 6)
        healthColor = Color(Lerp(pulse, HC.health.r, HC.healthLow.r), Lerp(pulse, HC.health.g, HC.healthLow.g), Lerp(pulse, HC.health.b, HC.healthLow.b))
    end
    cy = cy + drawBar(x + innerX, cy, innerW, m, "HEALTH", hp, maxHp, healthColor, shownHealth)
    if showArmour then
        cy = cy + gap
        cy = cy + drawBar(x + innerX, cy, innerW, m, "ARMOUR", armour, 100, HC.armour, shownArmour)
    end

    if tagsH > 0 then
        cy = cy + gap
        for _, t in ipairs(placed) do
            draw.RoundedBox(3, x + innerX + t.x, cy + t.y, t.w, tagH, t.color)
            draw.SimpleText(t.text, "RP1942_HudSmall", x + innerX + t.x + tagPadX, cy + t.y + tagH / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    return { x = x, y = y, w = w, h = h }
end

--[[---------------------------------------------------------------------------
Bottom-right: weapon and ammo. Returns its rectangle, or nil if not shown.
---------------------------------------------------------------------------]]
local function drawAmmo(lp, m)
    local wep = lp:GetActiveWeapon()
    if not IsValid(wep) then return nil end
    local ammoType = wep:GetPrimaryAmmoType()
    local clip = wep:Clip1()
    if ammoType == -1 and clip < 0 then return nil end   -- melee, tools, hands

    local s, pad = m.s, m.pad
    local reserve = ammoType ~= -1 and lp:GetAmmoCount(ammoType) or 0
    local big = tostring(clip >= 0 and clip or reserve)
    local small = clip >= 0 and ("/ " .. reserve) or ""
    local secType = wep:GetSecondaryAmmoType()
    local alt = (secType and secType ~= -1) and ("ALT  " .. lp:GetAmmoCount(secType)) or nil

    local bigW, bigH = textSize("RP1942_HudAmmo", big)
    local smallW = small ~= "" and textSize("RP1942_HudAmmoSub", small) or 0
    local nameH = fontH("RP1942_HudSmall")
    local maxW = math.floor(m.areaW * 0.22)
    local name = fit(string.upper(language.GetPhrase(wep:GetPrintName() or "")), "RP1942_HudSmall", maxW - pad * 2)
    local nameW = textSize("RP1942_HudSmall", name)
    local altW = alt and textSize("RP1942_HudSmall", alt) or 0
    local w = math.max(bigW + (smallW > 0 and (smallW + math.floor(6 * s)) or 0), nameW, altW, math.floor(130 * s)) + pad * 2
    local h = pad + nameH + math.floor(4 * s) + 2 + math.floor(4 * s) + bigH + (alt and (nameH + 2) or 0) + pad
    local x, y = m.right - m.margin - w, m.sh - m.margin - h

    draw.RoundedBox(6, x, y, w, h, alpha(C("bg"), 235))
    draw.SimpleText(name, "RP1942_HudSmall", x + w - pad, y + pad, C("sub"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    local ry = y + pad + nameH + math.floor(4 * s)
    surface.SetDrawColor(C("tabActive"))
    surface.DrawRect(x, ry, w, 2)
    local by = ry + 2 + math.floor(4 * s)

    local empty = clip == 0 or (clip < 0 and reserve == 0)
    local right = x + w - pad
    if smallW > 0 then
        draw.SimpleText(small, "RP1942_HudAmmoSub", right, by + bigH * 0.78, C("sub"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        right = right - smallW - math.floor(6 * s)
    end
    draw.SimpleText(big, "RP1942_HudAmmo", right, by, empty and HC.healthLow or C("text"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    if alt then
        draw.SimpleText(alt, "RP1942_HudSmall", x + w - pad, by + bigH + 2, C("gold"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end
    return { x = x, y = y, w = w, h = h }
end

--[[---------------------------------------------------------------------------
Bottom-centre: the economy.
    ECONOMY · AVERAGE                          WAGES ×0.91 · TAX 10%
    [███████████████████|█████····|·········|·········]
The meter fills to the economy value (1-110) in the tier's colour, with a
tick at each tier boundary. Moves up above a side panel it would touch.
---------------------------------------------------------------------------]]
local function drawEconomy(lp, m, avoid)
    if not (RP1942.getEconomy and RP1942.getEconomyTier and RP1942.Economy) then return nil end
    local s, pad, gap = m.s, m.pad, m.gap
    local E = RP1942.Economy
    local value = RP1942.getEconomy()
    local tier = RP1942.getEconomyTier(value)
    local tierColor = (HC.economy and HC.economy[tier.id]) or C("gold")

    local mult = RP1942.getEconomyMultiplier and RP1942.getEconomyMultiplier(value) or 1
    local right = string.format("WAGES ×%.2f", mult)
    local rate = RP1942.getTaxRate and RP1942.getTaxRate(RPExtraTeams[lp:Team()]) or 0
    if rate and rate > 0 then right = right .. "  ·  TAX " .. rate .. "%" end

    local w = math.floor(math.min(CFG.economyWidth * s, m.areaW * 0.36))
    local innerW = w - pad * 2
    local rightW = textSize("RP1942_HudSmall", right)
    local left = "ECONOMY  ·  " .. string.upper(tier.id)
    if textSize("RP1942_HudSmall", left) + rightW + gap > innerW then left = string.upper(tier.id) end
    left = fit(left, "RP1942_HudSmall", innerW - rightW - gap)

    local textH = fontH("RP1942_HudSmall")
    local barH = math.max(6, math.floor(9 * s))
    local h = pad + textH + math.floor(6 * s) + barH + pad

    local x = math.floor(m.sw / 2 - w / 2)
    local y = m.sh - m.margin - h
    -- Touching a side panel? Sit above the tallest one it touches.
    local rect = { x = x, y = y, w = w, h = h }
    for _, other in ipairs(avoid) do
        if overlapsX(rect, other, gap) then y = math.min(y, other.y - gap - h) end
    end
    rect.y = y

    draw.RoundedBox(6, x, y, w, h, alpha(C("bg"), 235))
    draw.SimpleText(left, "RP1942_HudSmall", x + pad, y + pad, tierColor)
    draw.SimpleText(right, "RP1942_HudSmall", x + w - pad, y + pad, C("sub"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    local bx, by, bw = x + pad, y + pad + textH + math.floor(6 * s), innerW
    draw.RoundedBox(3, bx, by, bw, barH, HC.barBg)
    local span = math.max(E.MAX - E.MIN, 1)
    local frac = math.Clamp((value - E.MIN) / span, 0, 1)
    if frac > 0 then draw.RoundedBox(3, bx, by, math.max(barH, bw * frac), barH, tierColor) end
    surface.SetDrawColor(alpha(C("bg"), 200))
    for i = 2, #E.Tiers do
        local tx = bx + math.floor(bw * (E.Tiers[i].min - E.MIN) / span)
        surface.DrawRect(tx, by, math.max(1, math.floor(2 * s)), barH)
    end
    return rect
end

RP1942.HUDRects = {}

hook.Add("HUDPaint", "RP1942_HUD", function()
    if not CFG.enabled then return end
    local lp = LocalPlayer()
    if hidden(lp) then RP1942.HUDRects = {} return end
    local m = metrics()
    local rects = {}
    rects.player = drawPlayerPanel(lp, m)
    if CFG.showAmmo then rects.ammo = drawAmmo(lp, m) end
    if CFG.showEconomy then rects.economy = drawEconomy(lp, m, { rects.player, rects.ammo }) end
    RP1942.HUDRects = rects
end)
