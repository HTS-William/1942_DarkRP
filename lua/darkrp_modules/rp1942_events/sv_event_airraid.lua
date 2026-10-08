--[[---------------------------------------------------------------------------
1942 DarkRP - air raid event (server). Settings: RP1942.Events.airraid (sh_events.lua)

Finding "outside": a spot counts as outdoors when a trace straight up from it
reaches the sky (the skybox). Each bomb picks a spot near an outdoor player
(or anywhere around a random player), checks it really is under open sky,
drops onto the ground there, and stays clear of spawn points. Spots that
fail are skipped, so indoors, tunnels and the spawn are never hit.
---------------------------------------------------------------------------]]
local CFG = RP1942.Events.airraid
util.AddNetworkString("RP1942_AirRaid")
resource.AddFile("sound/" .. CFG.sound)

local raid   -- { endsAt =, bombsFrom =, bombsUntil = } while it runs

local function duration()
    local d = SoundDuration and SoundDuration(CFG.sound) or 0
    if not d or d < 5 then d = CFG.duration end
    return d
end

local spawns
local function spawnPoints()
    if spawns then return spawns end
    spawns = {}
    for _, class in ipairs({ "info_player_start", "info_player_deathmatch", "info_player_combine", "info_player_rebel",
                             "info_player_terrorist", "info_player_counterterrorist", "info_player_teamspawn" }) do
        for _, e in ipairs(ents.FindByClass(class)) do spawns[#spawns + 1] = e:GetPos() end
    end
    return spawns
end

local function nearSpawn(pos)
    local r2 = (CFG.safeFromSpawn or 0) ^ 2
    if r2 <= 0 then return false end
    for _, s in ipairs(spawnPoints()) do
        if s:DistToSqr(pos) < r2 then return true end
    end
    return false
end

-- Is there open sky straight above pos? Returns the point just under the sky.
local function skyAbove(pos)
    local tr = util.TraceLine({ start = pos, endpos = pos + Vector(0, 0, 32768), mask = MASK_SOLID_BRUSHONLY })
    if tr.HitSky then return tr.HitPos end
end
RP1942.airRaidSkyAbove = skyAbove

local function outdoorPlayers()
    local list = {}
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() and skyAbove(p:EyePos()) then list[#list + 1] = p end
    end
    return list
end

-- One landing spot outdoors, or nil
local function pickSpot()
    local players = player.GetAll()
    if #players == 0 then return end
    local outside = outdoorPlayers()
    local anchor, spread
    if #outside > 0 and math.random(100) <= (CFG.nearPlayers or 70) then
        anchor, spread = outside[math.random(#outside)], CFG.spread or 900
    else
        anchor, spread = players[math.random(#players)], CFG.roam or 3500
    end
    local base = anchor:GetPos() + Vector(0, 0, 48)
    for _ = 1, 12 do
        local a, r = math.random() * math.pi * 2, math.sqrt(math.random()) * spread
        local p = base + Vector(math.cos(a) * r, math.sin(a) * r, 0)
        if util.IsInWorld(p) then
            local sky = skyAbove(p)
            if sky then
                local down = util.TraceLine({ start = sky - Vector(0, 0, 8), endpos = sky - Vector(0, 0, 32768), mask = MASK_SOLID_BRUSHONLY })
                local ground = down.HitPos
                if down.Hit and not down.HitSky and not nearSpawn(ground) then
                    return ground, sky
                end
            end
        end
    end
end

-- A bomb: unseen; its whistle plays where it will land, then it explodes there
local function dropBomb()
    local ground = pickSpot()
    if not ground then return end
    local b = ents.Create("rp1942_airbomb")
    if not IsValid(b) then return end
    b:SetDrop(ground, CFG)
    b:SetPos(ground + Vector(0, 0, 48))
    b:Spawn()
end

local function broadcast(on)
    SetGlobal2Bool("RP1942_AirRaid", on)
    net.Start("RP1942_AirRaid")
    net.WriteBool(on)
    net.WriteString(on and CFG.msgStart or CFG.msgEnd or "")
    net.WriteFloat(0)
    net.Broadcast()
end

local function finish(cancelled)
    if not raid then return end
    raid = nil
    timer.Remove("RP1942_AirRaid")
    -- Bombs already whistling down still land unless staff called it off
    if cancelled then for _, b in ipairs(ents.FindByClass("rp1942_airbomb")) do b:Remove() end end
    broadcast(false)
end

local function nextBomb()
    if not raid then return end
    local now = CurTime()
    if now >= raid.endsAt then return finish(false) end
    if now >= raid.bombsFrom and now < raid.bombsUntil then dropBomb() end
    local e = CFG.bombEvery or { min = 0.5, max = 1.4 }
    timer.Create("RP1942_AirRaid", math.Rand(e.min, math.max(e.min, e.max)), 1, nextBomb)
end

RP1942.registerEvent("airraid", {
    name   = "Air raid",
    config = CFG,

    start = function()
        local now, d = CurTime(), duration()
        raid = { endsAt = now + d, bombsFrom = now + (CFG.warning or 8), bombsUntil = now + d - (CFG.endQuiet or 4) }
        broadcast(true)
        nextBomb()
    end,

    isActive = function() return raid ~= nil end,

    stop = function() finish(true) end,
})

-- Someone joining mid-raid hears the siren too (from where it is now)
hook.Add("PlayerInitialSpawn", "RP1942_AirRaid", function(ply)
    timer.Simple(5, function()
        if raid and IsValid(ply) then
            net.Start("RP1942_AirRaid")
            net.WriteBool(true)
            net.WriteString("")
            net.WriteFloat(duration() - (raid.endsAt - CurTime()))
            net.Send(ply)
        end
    end)
end)
