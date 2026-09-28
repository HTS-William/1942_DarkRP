--[[---------------------------------------------------------------------------
1942 DarkRP - admin ESP (client)

Every player, through walls: their name, REAL job (with their cover if
they're undercover), rank, health and distance, in their job's colour.
Players the server hasn't sent to your game (far away) are drawn from the
positions it sends while ESP is on.
---------------------------------------------------------------------------]]
local on = false
local far = {}   -- userid -> { pos, hp, alive, t }

net.Receive("RP1942_ESP", function() on = net.ReadBool() end)

net.Receive("RP1942_ESPData", function()
    local n = net.ReadUInt(8)
    local now = RealTime()
    for _ = 1, n do
        local id = net.ReadUInt(16)
        far[id] = { pos = net.ReadVector(), hp = net.ReadUInt(8), alive = net.ReadBool(), t = now }
    end
end)

local function fonts()
    local h = ScrH()
    surface.CreateFont("RP1942_ESPName", { font = "Roboto", size = math.max(14, math.floor(h * 0.016)), weight = 800, extended = true, outline = true })
    surface.CreateFont("RP1942_ESPInfo", { font = "Roboto", size = math.max(12, math.floor(h * 0.013)), weight = 600, extended = true, outline = true })
end
fonts()
hook.Add("OnScreenSizeChanged", "RP1942_ESPFonts", fonts)

local function lifted(col)
    local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
    if lum >= 110 then return col end
    return Color(Lerp(0.5, col.r, 230), Lerp(0.5, col.g, 225), Lerp(0.5, col.b, 215))
end

-- One player's box and labels. (Returns early instead of using goto:
-- "continue" is a keyword in Garry's Mod Lua, so it can't be a label.)
local function drawPlayer(p, eye, cfg, maxD, dis)
    -- Where: from the game if it has them, else from the server's list
    local pos, hp, alive = p:GetPos(), p:Health(), p:Alive()
    local dormant = p:IsDormant()
    if dormant then
        local f = far[p:UserID()]
        if not f or RealTime() - f.t > 3 then return end
        pos, hp, alive = f.pos, f.hp, f.alive
    end
    local dist = eye:Distance(pos)
    if maxD and dist > maxD then return end

    local head = (pos + Vector(0, 0, 76)):ToScreen()
    local feet = pos:ToScreen()
    if not head.visible then return end

    local job = RPExtraTeams[p:Team()]
    local col = lifted(job and job.color or team.GetColor(p:Team()))
    if not alive then col = Color(140, 140, 140) end

    -- Box (players on screen)
    local h = math.max(feet.y - head.y, 8)
    local w = h * 0.45
    if cfg.boxes ~= false and feet.visible then
        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawOutlinedRect(head.x - w / 2 - 1, head.y - 1, w + 2, h + 2, 1)
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(head.x - w / 2, head.y, w, h, 1)
        -- health bar on the left
        local frac = math.Clamp(hp / math.max(p:GetMaxHealth(), 1), 0, 1)
        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(head.x - w / 2 - 6, head.y, 3, h)
        surface.SetDrawColor(Lerp(frac, 220, 90), Lerp(frac, 70, 200), 70)
        surface.DrawRect(head.x - w / 2 - 6, head.y + h * (1 - frac), 3, h * frac)
    end

    -- Text above
    local title = p:getDarkRPVar("job") or (job and job.name) or ""
    local jobText = job and job.name or title
    if job and dis and dis.jobs and dis.jobs[job.command] and title ~= job.name then
        jobText = job.name .. "  (cover: " .. title .. ")"
    end
    local rank = p:GetUserGroup()
    local lines = {
        { p:Nick() .. ((rank ~= "user" and rank ~= "") and ("  [" .. string.upper(rank) .. "]") or ""), "RP1942_ESPName", col },
        { jobText, "RP1942_ESPInfo", Color(230, 225, 215) },
        { (alive and (hp .. " HP") or "DEAD") .. "   ·   " .. math.floor(dist / 52.5) .. " m"
            .. (p:getDarkRPVar("wanted") and "   ·   WANTED" or "") .. (dormant and "   ·   far" or ""), "RP1942_ESPInfo", Color(190, 185, 170) },
    }
    local y = head.y - 4
    for i = #lines, 1, -1 do
        local l = lines[i]
        surface.SetFont(l[2])
        local _, th = surface.GetTextSize(l[1])
        y = y - th
        draw.SimpleText(l[1], l[2], head.x, y, l[3], TEXT_ALIGN_CENTER)
    end
end

hook.Add("HUDPaint", "RP1942_ESP", function()
    if not on then return end
    local lp = LocalPlayer()
    local cfg = RP1942.ESP or {}
    local maxD = (cfg.maxDistance or 0) > 0 and cfg.maxDistance or nil
    local dis = RP1942.Config and RP1942.Config.Disguise
    local eye = lp:EyePos()
    for _, p in ipairs(player.GetAll()) do
        if p ~= lp then drawPlayer(p, eye, cfg, maxD, dis) end
    end
    draw.SimpleText("ESP", "RP1942_ESPName", ScrW() - 12, 12, Color(220, 80, 60), TEXT_ALIGN_RIGHT)
end)
