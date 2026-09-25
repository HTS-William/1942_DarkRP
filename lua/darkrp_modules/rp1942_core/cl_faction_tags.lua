--[[---------------------------------------------------------------------------
1942 DarkRP - faction tags (client)

A small label above undercover jobs' heads that only their own side sees:
the Reich sees "GESTAPO" over Gestapo agents, the Resistance sees
"RESISTANCE" over Resistance Operatives. Everyone else sees nothing.
Settings: RP1942.Config.FactionTags (sh_config.lua).

Where it goes: DarkRP draws the name 50px above the head when you look at
someone; a wanted player instead has WANTED (and its reason) above the head
with the name below. The label sits above whichever of those is there.
---------------------------------------------------------------------------]]
local function buildFont()
    surface.CreateFont("RP1942_ReichTag", {
        font = "Roboto", size = math.max(12, math.floor(ScrH() * 0.016)), weight = 800, extended = true,
    })
end
buildFont()
hook.Add("OnScreenSizeChanged", "RP1942_FactionTagFont", buildFont)

local function fontHeight(font)
    surface.SetFont(font)
    local _, h = surface.GetTextSize("Ag")
    return h
end

-- Height taken up above the head by the wanted tag (0 if not wanted)
local function wantedStackHeight(ply)
    if not ply:getDarkRPVar("wanted") or not RP1942.Wanted then return 0 end
    local h = 2 + fontHeight("RP1942_WantedTag")
    local reason = ply:getDarkRPVar("wantedReason")
    if RP1942.Wanted.showReason and reason and reason ~= "" then h = h + fontHeight("RP1942_WantedReason") + 1 end
    return h
end

-- Draws one player's label, if they have one and are in view
local function drawTag(cfg, lp, shootPos, ply)
    if ply == lp or not ply:Alive() or ply:IsDormant() or ply:GetNoDraw() then return end
    local job = RPExtraTeams[ply:Team()]
    local tag = job and cfg.jobs[job.command]
    -- Only the tag's own side sees it
    if not (tag and RP1942.isFaction(lp, tag.seenBy)) then return end
    local text = tag.text

    local maxDist = cfg.distance or 600
    local head = ply:EyePos()
    local dist = shootPos:Distance(head)
    if dist > maxDist then return end
    if head.isInSight and not head:isInSight({ lp, ply }) then return end

    head.z = head.z + 10   -- same anchor DarkRP uses for names
    local pos = head:ToScreen()
    if not pos.visible then return end

    -- Bottom of the label: above the name, or above the WANTED tag
    local bottom
    if ply:getDarkRPVar("wanted") then
        bottom = pos.y - wantedStackHeight(ply) - 4
    else
        bottom = pos.y - 50 - 3
    end

    local alpha = math.Clamp((maxDist - dist) / (maxDist * 0.25), 0, 1)
    surface.SetFont("RP1942_ReichTag")
    local tw, th = surface.GetTextSize(text)
    local padX, padY, bar = 6, 2, 3
    local w, h = tw + padX * 2 + bar, th + padY * 2
    local x, y = math.floor(pos.x - w / 2), math.floor(bottom - h)

    draw.RoundedBox(3, x, y, w, h, Color(cfg.bg.r, cfg.bg.g, cfg.bg.b, (cfg.bg.a or 255) * alpha))
    local accent = tag.accent or Color(112, 22, 22)
    surface.SetDrawColor(accent.r, accent.g, accent.b, 255 * alpha)
    surface.DrawRect(x, y, bar, h)
    draw.SimpleText(text, "RP1942_ReichTag", x + bar + padX, y + padY,
        Color(cfg.color.r, cfg.color.g, cfg.color.b, 255 * alpha))
end

hook.Add("HUDPaint", "RP1942_FactionTags", function()
    local cfg = RP1942.Config and RP1942.Config.FactionTags
    if not (cfg and cfg.enabled) then return end
    local lp = LocalPlayer()
    if not (IsValid(lp) and RP1942.isFaction) then return end

    local shootPos = lp:GetShootPos()
    for _, ply in ipairs(player.GetAll()) do
        drawTag(cfg, lp, shootPos, ply)
    end
end)
