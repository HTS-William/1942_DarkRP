--[[---------------------------------------------------------------------------
1942 DarkRP - Spreading fire (server)

    RP1942.startFire(pos, opts)      light a patch of fire around pos
        opts.spots      how many fires (default 3)
        opts.radius     units around pos they're placed in (default 100)
        opts.attacker   player who gets the kills
        opts.inflictor  what did it (weapon, grenade)
        opts.life       seconds each fire burns (default: lifeMin-lifeMax)
        -> number of fires lit (0 when the system is off or the cap is hit)
    RP1942.extinguishAll()           -> number put out
    RP1942.extinguishNear(pos, r)    -> number put out
    RP1942.fireCount()

What lights fires by itself:
    * mcv_firepool (molotov, WP grenade): a patch inside the pool's radius
    * util.BlastDamage / util.BlastDamageInfo: every explosion in the game
      goes through these, so they're wrapped once here. Above
      blastMinDamage, blastChance of a patch. (The molotov's own tiny blast
      is skipped: its pool does the job.)

Hooks for other systems:
    RP1942_FireStarted(pos, opts)    return false to stop a patch being lit
    RP1942_FireNode(node)            a single fire has been lit
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Fire = RP1942.Fire or {}
local F = RP1942.Fire
local S = RP1942.fireSetting

local SAVE_DIR = "rp1942"
local SAVE_FILE = SAVE_DIR .. "/fire.json"

--[[ Settings: fire.json over the defaults ----------------------------------]]
local syncConvars   -- defined below (the convars)

local function loadSettings()
    local saved = util.JSONToTable(file.Read(SAVE_FILE, "DATA") or "") or {}
    F.settings = table.Copy(F.defaults)
    for k, v in pairs(saved) do
        if F.defaults[k] ~= nil then F.settings[k] = v end
    end
end
loadSettings()

local function saveSettings()
    file.CreateDir(SAVE_DIR)
    local diff = {}
    for k, v in pairs(F.settings) do
        if v ~= F.defaults[k] then diff[k] = v end
    end
    file.Write(SAVE_FILE, util.TableToJSON(diff, true))
end

-- Set a setting from text. -> ok, message
function RP1942.setFireSetting(key, value)
    local def = F.defaults[key]
    if def == nil then return false, "No such setting: " .. tostring(key) .. ". They are: " .. table.concat(F.keys, ", ") end
    local v
    if isbool(def) then
        value = string.lower(tostring(value))
        if value == "1" or value == "true" or value == "on" or value == "yes" then v = true
        elseif value == "0" or value == "false" or value == "off" or value == "no" then v = false
        else return false, key .. " is on or off (1 / 0)." end
    elseif isnumber(def) then
        v = tonumber(value)
        if not v then return false, key .. " needs a number." end
        if v < 0 then v = 0 end
    else
        v = tostring(value)
    end
    F.settings[key] = v
    saveSettings()
    if syncConvars then syncConvars() end
    return true, key .. " = " .. tostring(v)
end

--[[ Server convars: rp1942_fire, rp1942_fire_spreading (mirror two settings)]]
local CVARS = {
    rp1942_fire           = { key = "enabled",   help = "1942 spreading fire: 1 = on, 0 = no fires at all (saved)" },
    rp1942_fire_spreading = { key = "spreading", help = "1942 fire spreads along the ground (1) or only burns where it was lit (0) (saved)" },
}
local syncing = false
for name, c in pairs(CVARS) do
    local cv = CreateConVar(name, S(c.key) and "1" or "0", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY), c.help, 0, 1)
    cvars.AddChangeCallback(name, function(_, _, new)
        if syncing then return end
        local on = tonumber(new) == 1
        if F.settings[c.key] ~= on then
            F.settings[c.key] = on
            saveSettings()
        end
    end, "RP1942_Fire")
    F["cvar_" .. c.key] = cv
end

-- keep the convars showing the live values (after !firesetting too)
syncConvars = function()
    syncing = true
    for name, c in pairs(CVARS) do
        local want = S(c.key) and "1" or "0"
        if GetConVar(name):GetString() ~= want then RunConsoleCommand(name, want) end
    end
    syncing = false
end
syncConvars()
hook.Add("InitPostEntity", "RP1942_FireCvars", syncConvars)

--[[ The nodes ---------------------------------------------------------------]]
local nodes = {}          -- node entity -> true
local clusters = {}       -- cluster id -> count
local nextCluster = 1

function F.register(node)
    nodes[node] = true
    clusters[node.Cluster] = (clusters[node.Cluster] or 0) + 1
end

function F.unregister(node)
    if not nodes[node] then return end
    nodes[node] = nil
    if clusters[node.Cluster] then
        clusters[node.Cluster] = clusters[node.Cluster] - 1
        if clusters[node.Cluster] <= 0 then clusters[node.Cluster] = nil end
    end
end

function RP1942.fireCount()
    local n = 0
    for node in pairs(nodes) do
        if IsValid(node) then n = n + 1 else nodes[node] = nil end
    end
    return n
end

function F.canSpawn(cluster)
    if not S("enabled") then return false end
    if RP1942.fireCount() >= S("maxFires") then return false end
    if cluster and (clusters[cluster] or 0) >= S("maxPerCluster") then return false end
    return true
end

-- Walkable ground near `at` a fire can sit on, or nil: not water, not a
-- steep slope, not on a player, not on top of another fire
local GROUND_UP, GROUND_DOWN = Vector(0, 0, 48), Vector(0, 0, 96)
function F.findGround(at, ignore)
    local tr = util.TraceLine({
        start = at + GROUND_UP,
        endpos = at - GROUND_DOWN,
        mask = MASK_SOLID_BRUSHONLY + CONTENTS_WATER,
        filter = ignore,
    })
    if not tr.Hit or tr.StartSolid then return nil end
    if bit.band(util.PointContents(tr.HitPos + Vector(0, 0, 4)), CONTENTS_WATER) ~= 0 then return nil end
    if tr.HitNormal.z < 0.7 then return nil end
    if tr.MatType == MAT_SLOSH then return nil end
    local pos = tr.HitPos + Vector(0, 0, 2)
    local spacing = S("minSpacing")
    for _, e in ipairs(ents.FindInSphere(pos, spacing)) do
        if e:GetClass() == "rp1942_fire" then return nil end
    end
    return pos
end

-- One fire. opts: generation, cluster, attacker, inflictor, life
function F.spawnNode(pos, opts)
    opts = opts or {}
    local node = ents.Create("rp1942_fire")
    if not IsValid(node) then return nil end
    node.Generation = opts.generation or 0
    node.Cluster    = opts.cluster or 0
    node.Arsonist   = IsValid(opts.attacker) and opts.attacker or nil
    node.Inflictor  = IsValid(opts.inflictor) and opts.inflictor or nil
    node.Life       = opts.life
    node.StaffLit   = opts.staff or nil
    node:SetPos(pos)
    node:Spawn()
    hook.Run("RP1942_FireNode", node)
    return node
end

function RP1942.startFire(pos, opts)
    if not isvector(pos) then return 0 end
    opts = opts or {}
    if not S("enabled") then return 0 end
    if hook.Run("RP1942_FireStarted", pos, opts) == false then return 0 end

    local spots = math.max(1, math.floor(opts.spots or 3))
    local radius = opts.radius or 100
    local cluster = nextCluster
    nextCluster = nextCluster + 1
    local lit = 0
    local tries = spots * 4
    while lit < spots and tries > 0 do
        tries = tries - 1
        if not F.canSpawn(cluster) then break end
        local at = pos
        if lit > 0 or spots > 1 then
            local a, d = math.Rand(0, 360), math.Rand(0, radius)
            at = pos + Vector(math.cos(math.rad(a)) * d, math.sin(math.rad(a)) * d, 0)
        end
        local ground = F.findGround(at)
        if ground and F.spawnNode(ground, {
            generation = 0, cluster = cluster, staff = opts.staff,
            attacker = opts.attacker, inflictor = opts.inflictor, life = opts.life,
        }) then
            lit = lit + 1
        end
    end
    return lit
end

function RP1942.extinguishAll()
    local n = 0
    for node in pairs(nodes) do
        if IsValid(node) then node:PutOut() n = n + 1 end
    end
    nodes = {}
    clusters = {}
    return n
end

function RP1942.extinguishNear(pos, radius)
    local n = 0
    local r2 = radius * radius
    for node in pairs(nodes) do
        if IsValid(node) and node:GetPos():DistToSqr(pos) <= r2 then
            node:PutOut()
            n = n + 1
        end
    end
    return n
end

--[[ What lights fires --------------------------------------------------------]]
-- Molotov and WP pools
hook.Add("OnEntityCreated", "RP1942_FirePool", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "mcv_firepool" then return end
    timer.Simple(0.1, function()
        if not IsValid(ent) or not S("enabled") then return end
        RP1942.startFire(ent:GetPos(), {
            spots = S("molotovSpots"),
            radius = (ent.Radius or 200) * 0.7,
            attacker = ent.Attacker,
            inflictor = ent.Inflictor,
        })
    end)
end)

-- Explosions: every one in the game goes through util.BlastDamage(Info)
local function nearFirePool(pos)
    for _, e in ipairs(ents.FindInSphere(pos, 60)) do
        if e:GetClass() == "mcv_firepool" then return true end
    end
    return false
end

local function onBlast(pos, radius, damage, attacker, inflictor)
    if not S("enabled") or not isvector(pos) then return end
    damage = tonumber(damage) or 0
    if damage < S("blastMinDamage") then return end
    if math.random() > S("blastChance") then return end
    radius = tonumber(radius) or 200
    local spots = math.Clamp(math.Round(radius / 100), 1, S("blastMaxSpots"))
    -- a moment later: a molotov / WP blast is followed by its pool, which
    -- lights its own fires, so those blasts are left alone
    timer.Simple(0.05, function()
        if nearFirePool(pos) then return end
        RP1942.startFire(pos, {
            spots = spots,
            radius = radius * 0.5,
            attacker = IsValid(attacker) and attacker:IsPlayer() and attacker or nil,
            inflictor = IsValid(inflictor) and inflictor or nil,
        })
    end)
end

F.origBlastDamage = F.origBlastDamage or util.BlastDamage
F.origBlastDamageInfo = F.origBlastDamageInfo or util.BlastDamageInfo
util.BlastDamage = function(inflictor, attacker, pos, radius, damage)
    F.origBlastDamage(inflictor, attacker, pos, radius, damage)
    pcall(onBlast, pos, radius, damage, attacker, inflictor)
end
util.BlastDamageInfo = function(dmginfo, pos, radius)
    F.origBlastDamageInfo(dmginfo, pos, radius)
    if dmginfo and dmginfo.GetDamage then
        pcall(onBlast, pos, radius, dmginfo:GetDamage(), dmginfo:GetAttacker(), dmginfo:GetInflictor())
    end
end

--[[ Fire extinguishers ------------------------------------------------------
Whatever an extinguisher SWEP does inside, while it's being fired we put out
the fires in front of the player. A weapon counts if its class contains
"extinguish" or is in the extinguishClasses setting. Burning players in the
spray are put out too.
---------------------------------------------------------------------------]]
local function isExtinguisher(wep)
    if not IsValid(wep) then return false end
    local class = string.lower(wep:GetClass())
    if string.find(class, "extinguish", 1, true) then return true end
    for c in string.gmatch(string.lower(S("extinguishClasses") or ""), "[^,%s]+") do
        if c == class then return true end
    end
    return false
end

-- The reward for putting a fire out: extinguishReward RM per fire, never
-- for a fire you lit yourself (so nobody farms their own molotovs)
function F.reward(ply, node)
    local amount = S("extinguishReward") or 0
    if amount <= 0 or not IsValid(ply) or not ply.addMoney then return end
    if node.Arsonist == ply and not node.StaffLit then
        if (ply.RP1942_FireOwnWarned or 0) < CurTime() then
            ply.RP1942_FireOwnWarned = CurTime() + 10
            DarkRP.notify(ply, 1, 5, "No reward: you started this fire yourself.")
        end
        return
    end
    ply:addMoney(amount)
    ServerLog(string.format("[1942] %s put out a fire: +%d\n", ply:Nick(), amount))
    ply.RP1942_FireRewarded = (ply.RP1942_FireRewarded or 0) + amount
    -- one message for a burst of fires, not one per fire
    if not timer.Exists("RP1942_FireReward_" .. ply:EntIndex()) then
        timer.Create("RP1942_FireReward_" .. ply:EntIndex(), 1.5, 1, function()
            if not IsValid(ply) then return end
            local total = ply.RP1942_FireRewarded or 0
            ply.RP1942_FireRewarded = 0
            if total > 0 then DarkRP.notify(ply, 0, 4, "You put out a fire: +" .. DarkRP.formatMoney(total)) end
        end)
    end
end

-- The player spraying at a fire (the nearest one firing an extinguisher)
local function sprayer(pos)
    local best, bestDist = nil, 400 * 400
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:KeyDown(IN_ATTACK) and isExtinguisher(ply:GetActiveWeapon()) then
            local d = ply:EyePos():DistToSqr(pos)
            if d < bestDist then best, bestDist = ply, d end
        end
    end
    return best
end

-- Rubat's Fire Extinguisher (Workshop 104607228, class weapon_extinguisher)
-- asks this hook before it puts something out: our fires go out for it
-- outright (no coin toss), and it leaves them to us.
-- (It finds both the node and its env_fire, so the env_fire is routed to
-- its node: otherwise the flames would vanish without the reward.)
hook.Add("ExtinguisherDoExtinguish", "RP1942_Fire", function(ent)
    if not IsValid(ent) then return end
    local node
    if ent:GetClass() == "rp1942_fire" then
        node = ent
    elseif ent:GetClass() == "env_fire" and IsValid(ent:GetParent()) and ent:GetParent():GetClass() == "rp1942_fire" then
        node = ent:GetParent()
    end
    if not node then return end
    node:PutOut(sprayer(node:GetPos()))
    return true
end)

local nextSpray = 0
hook.Add("Think", "RP1942_FireExtinguisher", function()
    local now = CurTime()
    if now < nextSpray then return end
    nextSpray = now + 0.15
    if not next(nodes) then return end

    local range = S("extinguishRange")
    local cosA = math.cos(math.rad(S("extinguishAngle")))
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() or not ply:KeyDown(IN_ATTACK) then continue end
        if not isExtinguisher(ply:GetActiveWeapon()) then continue end
        local eye, dir = ply:EyePos(), ply:GetAimVector()
        for _, ent in ipairs(ents.FindInSphere(eye, range)) do
            local isNode = ent:GetClass() == "rp1942_fire"
            local burningPly = ent:IsPlayer() and ent ~= ply and (ent:IsOnFire() or (ent.MCV_BurnEnd or 0) > now)
            if not isNode and not burningPly then continue end
            local to = ent:GetPos() + Vector(0, 0, isNode and 20 or 40) - eye
            local d = to:Length()
            if d > 1 and to:GetNormalized():Dot(dir) < cosA then continue end
            local tr = util.TraceLine({ start = eye, endpos = eye + to, filter = { ply, ent }, mask = MASK_SOLID_BRUSHONLY })
            if tr.Hit and tr.Fraction < 0.95 then continue end
            if isNode then
                ent:PutOut(ply)
            else
                ent:Extinguish()
                if MCV and MCV.Extinguish then MCV.Extinguish(ent) end
            end
        end
    end
end)

--[[ Status and staff commands -----------------------------------------------]]
function RP1942.fireStatus()
    local lines = {
        (S("enabled") and (S("spreading") and "On" or "On, not spreading") or "OFF") .. ": " .. RP1942.fireCount() .. " fire(s) burning in " .. table.Count(clusters) .. " patch(es); cap " .. S("maxFires") .. " (" .. S("maxPerCluster") .. " per patch)",
    }
    for _, k in ipairs(F.keys) do
        if k ~= "enabled" then lines[#lines + 1] = k .. " = " .. tostring(S(k)) end
    end
    return lines
end

local function allowed(ply, access)
    if RP1942.staffCan(ply, access, function(p) return p:IsSuperAdmin() end) then return true end
    if IsValid(ply) then DarkRP.notify(ply, 1, 4, "You aren't allowed to do that.") end
    return false
end

local function say(ply, msg)
    if IsValid(ply) then DarkRP.notify(ply, 0, 5, msg) else print("[1942 fire] " .. msg) end
end

RP1942.defineStaffCommand("fire", function(ply, args)
    if not allowed(ply, "ulx fire") then return "" end
    local tr = ply:GetEyeTrace()
    if not tr.Hit or tr.HitPos:Distance(ply:EyePos()) > 1500 then
        return say(ply, "Look at the ground where the fire should start.")
    end
    local spots = tonumber(args) or 3
    local was = S("enabled")
    F.settings.enabled = true   -- staff may light one even while the system is off
    local n = RP1942.startFire(tr.HitPos, { spots = spots, radius = 60 + spots * 15, attacker = ply, staff = true })
    F.settings.enabled = was
    say(ply, n > 0 and (n .. " fire(s) lit.") or "No fire would take there (water, a slope, or the cap is reached).")
    ServerLog(string.format("[1942] %s lit %d fire(s) at %s\n", ply:Nick(), n, tostring(tr.HitPos)))
    return ""
end)

RP1942.defineStaffCommand("extinguish", function(ply)
    if not allowed(ply, "ulx extinguish") then return "" end
    local n = RP1942.extinguishNear(ply:GetEyeTrace().HitPos, 400)
    say(ply, n .. " fire(s) put out.")
    return ""
end)

RP1942.defineStaffCommand("extinguishall", function(ply)
    if not allowed(ply, "ulx extinguishall") then return "" end
    local n = RP1942.extinguishAll()
    say(ply, n .. " fire(s) put out.")
    return ""
end)

RP1942.defineStaffCommand("firestatus", function(ply)
    if not allowed(ply, "ulx firestatus") then return "" end
    for _, l in ipairs(RP1942.fireStatus()) do
        if IsValid(ply) then ply:ChatPrint("[Fire] " .. l) else print("[Fire] " .. l) end
    end
    return ""
end)

RP1942.defineStaffCommand("firesetting", function(ply, args)
    if not allowed(ply, "ulx firesetting") then return "" end
    local key, value = string.match(tostring(args or ""), "^%s*(%S+)%s*(.-)%s*$")
    if not key or key == "" then
        return say(ply, "Settings: " .. table.concat(F.keys, ", "))
    end
    if value == "" then
        if F.defaults[key] == nil then return say(ply, "No such setting: " .. key) end
        return say(ply, key .. " = " .. tostring(S(key)) .. " (default " .. tostring(F.defaults[key]) .. ")")
    end
    local ok, msg = RP1942.setFireSetting(key, value)
    say(ply, msg)
    if ok then ServerLog(string.format("[1942] %s set fire setting %s\n", IsValid(ply) and ply:Nick() or "console", msg)) end
    return ""
end)

-- Console (server or superadmin): rp1942_fire_test [spots]
concommand.Add("rp1942_fire_test", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if not IsValid(ply) then return print("Use this in game.") end
    RP1942.runStaffCommand(ply, "fire", args[1])
end)
