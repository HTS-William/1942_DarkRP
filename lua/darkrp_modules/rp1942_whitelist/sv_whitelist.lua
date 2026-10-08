--[[---------------------------------------------------------------------------
1942 DarkRP - job whitelists (server). Settings: sh_whitelist.lua

data/rp1942/whitelist.json:
    { players = { ["STEAM_0:0:1"] = { name = "Hans", jobs = { eliteguard = true } } },
      seeded  = { ["eliteguard|STEAM_0:0:1"] = true } }
---------------------------------------------------------------------------]]
local CFG = RP1942.Whitelist
local store = RP1942.dataStore("whitelist")
local data = store.load()
data.players = data.players or {}
data.seeded = data.seeded or {}

local function save() store.save(data) end

local function entry(sid)
    data.players[sid] = data.players[sid] or { jobs = {} }
    data.players[sid].jobs = data.players[sid].jobs or {}
    return data.players[sid]
end

-- The seed list from the settings: each one added once
do
    local changed = false
    for command, ids in pairs(CFG.seed or {}) do
        for _, sid in ipairs(ids) do
            local key = command .. "|" .. sid
            if not data.seeded[key] then
                entry(sid).jobs[command] = true
                data.seeded[key] = true
                changed = true
            end
        end
    end
    if changed then save() end
end

local function sync(ply)
    if not IsValid(ply) then return end
    local e = data.players[ply:SteamID()]
    local list = {}
    if e then for command in pairs(e.jobs or {}) do list[#list + 1] = command end end
    table.sort(list)
    ply:SetNW2String("RP1942_Whitelist", table.concat(list, ","))
    if e and e.name ~= ply:Nick() then e.name = ply:Nick() save() end
end

hook.Add("PlayerInitialSpawn", "RP1942_Whitelist", function(ply) timer.Simple(1, function() sync(ply) end) end)

local function playerBySteamID(sid)
    for _, p in ipairs(player.GetAll()) do if p:SteamID() == sid then return p end end
end

function RP1942.isWhitelistJob(command) return CFG.jobs[command] ~= nil end

function RP1942.whitelistAdd(sid, command, name)
    if not RP1942.isWhitelistJob(command) then return false, "'" .. command .. "' isn't a whitelisted job." end
    local e = entry(sid)
    if e.jobs[command] then return false, "already whitelisted" end
    e.jobs[command] = true
    if name then e.name = name end
    save()
    sync(playerBySteamID(sid))
    return true
end

function RP1942.whitelistRemove(sid, command)
    local e = data.players[sid]
    if not (e and e.jobs and e.jobs[command]) then return false, "not whitelisted for it" end
    e.jobs[command] = nil
    if next(e.jobs) == nil then data.players[sid] = nil end
    save()
    local ply = playerBySteamID(sid)
    if IsValid(ply) then
        sync(ply)
        -- On the job right now: off it
        local job = RPExtraTeams[ply:Team()]
        if job and job.command == command and not RP1942.isWhitelistedFor(ply, command) then
            ply:changeTeam(GAMEMODE.DefaultTeam, true, true)
            DarkRP.notify(ply, 1, 6, "Your whitelist for " .. job.name .. " was removed.")
        end
    end
    return true
end

-- { { sid, name, jobs = { ... } } } sorted by name; only `sid` if given
function RP1942.whitelistList(sid)
    local out = {}
    for id, e in pairs(data.players) do
        if not sid or id == sid then
            local jobs = {}
            for command in pairs(e.jobs or {}) do jobs[#jobs + 1] = command end
            table.sort(jobs)
            if #jobs > 0 then out[#out + 1] = { sid = id, name = e.name or "?", jobs = jobs } end
        end
    end
    table.sort(out, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    return out
end
