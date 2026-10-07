--[[---------------------------------------------------------------------------
1942 DarkRP - the respawn countdown (client). Server: sv_respawn.lua

    Dead:            the screen darkens, RESPAWNING IN 5
    Changing sides:  the screen fades out, REPORTING FOR DUTY IN 5
---------------------------------------------------------------------------]]
RP1942.screenFont("RP1942_RespawnBig", 0.034, 800, { min = 22 })
RP1942.screenFont("RP1942_RespawnSmall", 0.018, 500, { min = 13 })

hook.Add("HUDPaint", "RP1942_RespawnCountdown", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local at = ply:GetNW2Float("RP1942_RespawnAt", 0)
    local left = at - CurTime()
    if at <= 0 or left <= -0.5 then return end

    local delay = RP1942.RespawnDelay or 6
    local alive = ply:Alive()
    -- Dead: a steady dark veil. Changing sides: fading to black.
    local a = alive and math.Clamp(1 - left / delay, 0, 1) * 235 or 170
    surface.SetDrawColor(0, 0, 0, a)
    surface.DrawRect(0, 0, ScrW(), ScrH())

    local text = ply:GetNW2String("RP1942_RespawnText", "RESPAWNING")
    if text == "" then text = "RESPAWNING" end
    local secs = math.max(0, math.ceil(left))
    local y = ScrH() * 0.42
    draw.SimpleText(secs > 0 and (text .. " IN " .. secs) or (text .. "..."), "RP1942_RespawnBig", ScrW() / 2, y,
        RP1942.col("text"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- A thin bar running down
    local s = math.max(ScrH() / 1080, 0.6)
    local w, h = math.floor(360 * s), math.max(3, math.floor(5 * s))
    local x, by = math.floor(ScrW() / 2 - w / 2), math.floor(y + 34 * s)
    surface.SetDrawColor(46, 43, 39, 230)
    surface.DrawRect(x, by, w, h)
    surface.SetDrawColor(RP1942.col("tabActive"))
    surface.DrawRect(x, by, math.floor(w * math.Clamp(left / delay, 0, 1)), h)
end)
