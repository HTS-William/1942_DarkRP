--[[---------------------------------------------------------------------------
1942 DarkRP - Reichsbank robbery (server). How it plays and the settings:
sh_bank.lua. The HUD, pop-ups and settings menu: cl_bank.lua.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_BankSettings")     -- server -> client: the live settings
util.AddNetworkString("RP1942_BankEvent")        -- server -> client: "start" / "end"
util.AddNetworkString("RP1942_BankPrompt")       -- server -> client: confirm starting / joining
util.AddNetworkString("RP1942_BankPromptAnswer") -- client -> server: yes to the prompt
util.AddNetworkString("RP1942_BankJoinAsk")      -- server -> initiator: someone wants in
util.AddNetworkString("RP1942_BankJoinAnswer")   -- initiator -> server: accept / refuse
util.AddNetworkString("RP1942_BankMenu")         -- server -> staff: open the settings menu
util.AddNetworkString("RP1942_BankMenuSave")     -- staff -> server: new settings
util.AddNetworkString("RP1942_BankMenuAction")   -- staff -> server: debug buttons

local B = RP1942.Bank
local S = RP1942.bankSetting
local SAVE_DIR = "rp1942"

--[[---------------------------------------------------------------------------
Settings: defaults (sh_bank.lua) + data/rp1942/bank.json
---------------------------------------------------------------------------]]
local function settingsFile() return SAVE_DIR .. "/bank.json" end

--[[---------------------------------------------------------------------------
The cooldown after a robbery is kept across restarts (the treasury is too, so
a restart mustn't open the vault early): data/rp1942/bank_cooldown.json holds
the real time it ends.
---------------------------------------------------------------------------]]
local cooldownStore = RP1942.dataStore("bank_cooldown")

local function setCooldown(seconds)
    seconds = math.max(seconds or 0, 0)
    SetGlobal2Float("rp1942_bank_cd", seconds > 0 and CurTime() + seconds or 0)
    cooldownStore.save({ ends = seconds > 0 and os.time() + math.ceil(seconds) or 0 })
end

hook.Add("InitPostEntity", "RP1942_BankCooldown", function()
    local left = (tonumber(cooldownStore.load().ends) or 0) - os.time()
    if left > 0 then SetGlobal2Float("rp1942_bank_cd", CurTime() + left) end
end)

local function loadSettings()
    B.settings = table.Copy(B.defaults)
    local saved = util.JSONToTable(file.Read(settingsFile(), "DATA") or "") or {}
    for k, v in pairs(saved) do
        if B.defaults[k] ~= nil and type(v) == type(B.defaults[k]) then B.settings[k] = v end
    end
    -- The addon's sound folder moved from sounds/ to sound/: mend a saved path
    local alarm = B.settings.alarm
    if isstring(alarm) and string.find(alarm, "^sounds/") and not file.Exists(alarm, "GAME") then
        B.settings.alarm = "sound/" .. string.sub(alarm, 8)
    end
end

local function sendSettings(to)
    net.Start("RP1942_BankSettings")
    net.WriteString(util.TableToJSON(B.settings))
    if to then net.Send(to) else net.Broadcast() end
end

local function validModel(m)
    return isstring(m) and m ~= "" and util.IsValidModel(m)
end

-- Every vault takes the model in the settings
local function applyModel()
    for _, v in ipairs(ents.FindByClass("rp1942_bank_vault")) do
        if v.ApplyModel then v:ApplyModel() end
    end
end

-- Clean up what the settings menu sends, and save it
local LIMITS = {
    duration = { 10, 7200 }, cooldown = { 0, 86400 }, joinWindow = { 0, 600 }, crewMax = { 1, 16 },
    minReich = { 0, 64 }, holdRadius = { 50, 10000 }, leaveGrace = { 0, 120 }, useRange = { 50, 400 },
    killReward = { 0, 1000000 }, alarmVolume = { 0, 1 }, alarmRange = { 200, 20000 },
}
function RP1942.setBankSettings(t, byPly)
    for k, def in pairs(B.defaults) do
        local v = t[k]
        if v ~= nil then
            if isnumber(def) then
                v = tonumber(v)
                if v then
                    local lim = LIMITS[k]
                    if lim then v = math.Clamp(v, lim[1], lim[2]) end
                    if k ~= "alarmVolume" then v = math.floor(v) end
                    B.settings[k] = v
                end
            elseif isbool(def) then
                B.settings[k] = v == true
            elseif isstring(def) then
                v = string.Trim(tostring(v))
                if k == "model" and not validModel(v) then
                    if IsValid(byPly) then DarkRP.notify(byPly, 1, 6, "'" .. v .. "' isn't an installed model: the vault keeps its old one.") end
                elseif v ~= "" then
                    B.settings[k] = v
                end
            end
        end
    end
    file.CreateDir(SAVE_DIR)
    file.Write(settingsFile(), util.TableToJSON(B.settings, true))
    sendSettings()
    applyModel()
    if file.Exists(S("alarm"), "GAME") then resource.AddFile(S("alarm")) end
    ServerLog(string.format("[1942] Bank settings changed by %s\n", IsValid(byPly) and byPly:Nick() or "Console"))
end

loadSettings()
if file.Exists(S("alarm"), "GAME") then
    resource.AddFile(S("alarm"))
elseif string.find(S("alarm"), "^sounds?/") then
    MsgC(Color(255, 170, 0), "[1942] Bank alarm not found at '", S("alarm"), "' (rp1942_bank settings).\n")
end
hook.Add("PlayerInitialSpawn", "RP1942_BankSettings", function(ply)
    timer.Simple(3, function() if IsValid(ply) then sendSettings(ply) end end)
end)

--[[---------------------------------------------------------------------------
The vault: placed with !addvault, saved per map in data/rp1942/bankvault_<map>.json
---------------------------------------------------------------------------]]
local vaultStore = RP1942.mapStore("bankvault")   -- lua/autorun/rp1942_util.lua
local loadVaults, writeVaults = vaultStore.load, vaultStore.save

local function spawnVault(pos, yaw, id)
    local v = ents.Create("rp1942_bank_vault")
    if not IsValid(v) then return end
    v:SetPos(pos)
    v:SetAngles(Angle(0, yaw or 0, 0))
    v:Spawn()
    v.saveId = id
    return v
end

local function spawnSavedVaults()
    for id, v in pairs(loadVaults()) do spawnVault(Vector(v.x, v.y, v.z), v.yaw, id) end
end
hook.Add("InitPostEntity", "RP1942_BankVaults", spawnSavedVaults)
hook.Add("PostCleanupMap", "RP1942_BankVaults", spawnSavedVaults)

local function staff(ply, access)
    return RP1942.staffCan(ply, access or "ulx banksettings", function(p) return p:IsSuperAdmin() end)
end

RP1942.defineStaffCommand("addvault", function(ply)
    if not staff(ply, "ulx addvault") then DarkRP.notify(ply, 1, 4, "You aren't allowed to place the vault.") return "" end
    local tr = ply:GetEyeTrace()
    if not tr.Hit or tr.HitPos:Distance(ply:EyePos()) > 500 then
        DarkRP.notify(ply, 1, 4, "Look at the floor where the vault should go.")
        return ""
    end
    local yaw = ply:EyeAngles().y + 180
    local v = spawnVault(tr.HitPos + Vector(0, 0, 4), yaw)
    if not IsValid(v) then return "" end
    v:SetPos(tr.HitPos - Vector(0, 0, v:OBBMins().z) + Vector(0, 0, 1))
    local list = loadVaults()
    local id = tostring(os.time()) .. "_" .. math.random(1000, 9999)
    local pos = v:GetPos()
    list[id] = { x = pos.x, y = pos.y, z = pos.z, yaw = yaw }
    writeVaults(list)
    v.saveId = id
    DarkRP.notify(ply, 0, 5, "Reichsbank vault placed and saved for this map.")
    ServerLog(string.format("[1942] %s placed the bank vault at %s\n", ply:Nick(), tostring(pos)))
    return ""
end)

RP1942.defineStaffCommand("removevault", function(ply)
    if not staff(ply, "ulx removevault") then DarkRP.notify(ply, 1, 4, "You aren't allowed to remove the vault.") return "" end
    local tr = ply:GetEyeTrace()
    local v = tr.Entity
    if not IsValid(v) or v:GetClass() ~= "rp1942_bank_vault" then
        DarkRP.notify(ply, 1, 4, "Look at the vault to remove it.")
        return ""
    end
    if v.saveId then
        local list = loadVaults()
        list[v.saveId] = nil
        writeVaults(list)
    end
    v:Remove()
    DarkRP.notify(ply, 0, 5, "Vault removed.")
    return ""
end)

--[[---------------------------------------------------------------------------
The robbery
---------------------------------------------------------------------------]]
local R = { active = false, crew = {}, pending = {} }
RP1942.BankRobbery = R   -- for debugging from lua_run

local function reichCount()
    local n = 0
    for _, p in ipairs(player.GetAll()) do
        if RP1942.getFaction and RP1942.getFaction(p) == "reich" then n = n + 1 end
    end
    return n
end

local function fmtTime(sec)
    sec = math.max(0, math.ceil(sec))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function setCrew(ply, on)
    if not IsValid(ply) then return end
    ply:SetNW2Bool("RP1942_BankCrew", on)
    if on then
        R.crew[ply] = true
    else
        R.crew[ply] = nil
    end
end

local function makeWanted(ply)
    if not RP1942.makeWanted then return end
    if RP1942.Wanted and RP1942.Wanted.reasons then
        RP1942.Wanted.reasons.bank_robbery = { text = B.text.wanted, time = S("duration") + 300 }
    end
    RP1942.makeWanted(ply, "bank_robbery")
end

local function crewList()
    local list = {}
    for p in pairs(R.crew) do if IsValid(p) then list[#list + 1] = p end end
    return list
end

local function broadcastEvent(kind, a, b)
    net.Start("RP1942_BankEvent")
    net.WriteString(kind)
    net.WriteString(a or "")
    net.WriteString(b or "")
    net.Broadcast()
end

-- Why the bank can't be robbed right now (nil = it can)
function RP1942.bankBlocked(ply)
    if not S("enabled") then return "Bank robberies are switched off." end
    if R.active then return "The bank is already being robbed." end
    local cd = GetGlobal2Float("rp1942_bank_cd", 0) - CurTime()
    if cd > 0 then return "The Reichsbank is on alert. Try again in " .. fmtTime(cd) .. "." end
    local ok, why = RP1942.bankCanRob(ply)
    if not ok then return why end
    if not ply:Alive() then return "You're dead." end
    if ply.isArrested and ply:isArrested() then return "You're arrested." end
    if not S("ignoreReichMinimum") then
        local n, need = reichCount(), S("minReich")
        if n < need then return "Too few Reich officials in the city (" .. n .. " of " .. need .. " needed)." end
    end
end

local function finish(success, reason, opts)
    if not R.active then return end
    opts = opts or {}
    local initiator, vault = R.initiator, R.vault
    R.active = false
    timer.Remove("RP1942_BankTick")
    timer.Remove("RP1942_BankJoinEnd")

    local paid, total = {}, 0
    if success then
        total = RP1942.getTreasury and RP1942.getTreasury() or 0
        -- Paid: the initiator, and crew still alive, free and in the bank
        for _, p in ipairs(crewList()) do
            local inBank = IsValid(vault) and p:GetPos():Distance(vault:GetPos()) <= S("holdRadius")
            if p == initiator or (p:Alive() and not (p.isArrested and p:isArrested()) and inBank) then
                paid[#paid + 1] = p
            end
        end
        if total > 0 and #paid > 0 and RP1942.treasuryWithdraw(total, "bank robbery") then
            local each = math.floor(total / #paid)
            local rest = total - each * #paid
            for _, p in ipairs(paid) do
                local amount = each + (p == initiator and rest or 0)
                p:addMoney(amount)
                DarkRP.notify(p, 0, 10, "The robbery worked! Your share: " .. DarkRP.formatMoney(amount) .. ".")
            end
        elseif total <= 0 then
            for _, p in ipairs(paid) do DarkRP.notify(p, 1, 8, "The robbery worked... but the treasury was empty.") end
        end
    end

    for p in pairs(R.crew) do if IsValid(p) then p:SetNW2Bool("RP1942_BankCrew", false) p:SetNW2Float("RP1942_BankOutside", 0) end end
    R.crew, R.pending = {}, {}
    R.initiator, R.vault = nil, nil
    SetGlobal2Bool("rp1942_bank_active", false)
    if not opts.noCooldown then setCooldown(S("cooldown")) end

    if success then
        local text = string.format(B.text.won, DarkRP.formatMoney(total))
        broadcastEvent("won", text, #paid .. (#paid == 1 and " robber" or " robbers"))
        if RP1942.alert then RP1942.alert("The Reichsbank was robbed: " .. DarkRP.formatMoney(total) .. " taken!", "wanted") end
    else
        broadcastEvent("lost", reason or "", opts.silent and "silent" or "")
    end
    ServerLog(string.format("[1942] Bank robbery %s (%s)%s\n", success and "SUCCEEDED" or "failed", tostring(reason),
        success and (": " .. total .. " paid to " .. #paid) or ""))
end
RP1942.bankFinish = finish

local function tick()
    if not R.active then return end
    local p, v = R.initiator, R.vault
    if not IsValid(p) then return finish(false, "The robber fled.") end
    if not IsValid(v) then return finish(false, "The vault is gone.") end
    if not p:Alive() then return finish(false, p:Nick() .. " was killed.") end

    local now = CurTime()
    if p:GetPos():Distance(v:GetPos()) > S("holdRadius") then
        R.outsideSince = R.outsideSince or now
        p:SetNW2Float("RP1942_BankOutside", R.outsideSince)
        if now - R.outsideSince >= S("leaveGrace") then
            return finish(false, p:Nick() .. " left the bank.")
        end
    elseif R.outsideSince then
        R.outsideSince = nil
        p:SetNW2Float("RP1942_BankOutside", 0)
    end

    if now >= R.endsAt then finish(true) end
end

local function endJoinWindow()
    for p in pairs(R.pending) do
        if IsValid(p) then DarkRP.notify(p, 1, 5, "Nobody answered: you're not in the crew.") end
    end
    R.pending = {}
end

-- Start a robbery. forced = staff debug: no requirements checked.
function RP1942.bankStart(ply, vault, forced)
    if R.active then return false, "The bank is already being robbed." end
    if not forced then
        local why = RP1942.bankBlocked(ply)
        if why then return false, why end
    end
    if not IsValid(vault) then return false, "There's no vault. Place one with !addvault." end

    local now = CurTime()
    R.active, R.initiator, R.vault = true, ply, vault
    R.endsAt, R.joinEnds = now + S("duration"), now + S("joinWindow")
    R.crew, R.pending, R.outsideSince = {}, {}, nil
    setCrew(ply, true)
    ply:SetNW2Float("RP1942_BankOutside", 0)
    SetGlobal2Entity("rp1942_bank_init", ply)
    SetGlobal2Entity("rp1942_bank_vault", vault)
    SetGlobal2Float("rp1942_bank_ends", R.endsAt)
    SetGlobal2Float("rp1942_bank_join", R.joinEnds)
    SetGlobal2Bool("rp1942_bank_active", true)

    makeWanted(ply)
    broadcastEvent("start", ply:Nick())
    DarkRP.notify(ply, 0, 10, "Hold the bank for " .. fmtTime(S("duration")) .. ". Stay alive and stay near the vault!")
    timer.Create("RP1942_BankTick", 0.5, 0, tick)
    timer.Create("RP1942_BankJoinEnd", math.max(S("joinWindow"), 0.1), 1, endJoinWindow)
    ServerLog(string.format("[1942] %s started a bank robbery%s\n", ply:Nick(), forced and " (forced by staff)" or ""))
    return true
end

-- A robber in the crew was accepted / dropped out
local function dropCrew(p, why)
    if not R.crew[p] or p == R.initiator then return end
    setCrew(p, false)
    if IsValid(R.initiator) then DarkRP.notify(R.initiator, 1, 5, p:Nick() .. " is out of the crew (" .. why .. ").") end
end

-- E on the vault
function RP1942.bankUse(ply, vault)
    if not IsValid(ply) then return end
    if ply:GetPos():Distance(vault:GetPos()) > S("useRange") + 60 then return end
    local now = CurTime()

    if not R.active then
        local why = RP1942.bankBlocked(ply)
        if why then return DarkRP.notify(ply, 1, 5, why) end
        ply.RP1942_BankPrompt = { kind = "start", vault = vault, expires = now + 20 }
        net.Start("RP1942_BankPrompt")
        net.WriteString("start")
        net.WriteString(string.format("Rob the Reichsbank?\nYou must stay alive and near the vault for %s. Others get %d seconds to ask to join you. If you succeed, the whole treasury (%s right now) is split between your crew.",
            fmtTime(S("duration")), S("joinWindow"), DarkRP.formatMoney(RP1942.getTreasury and RP1942.getTreasury() or 0)))
        net.Send(ply)
        return
    end

    if R.crew[ply] then return DarkRP.notify(ply, 0, 4, "Hold the bank: " .. fmtTime(R.endsAt - now) .. " to go.") end
    if now > R.joinEnds then return DarkRP.notify(ply, 1, 4, "It's too late to join this robbery.") end
    local ok, why = RP1942.bankCanRob(ply)
    if not ok then return DarkRP.notify(ply, 1, 4, why) end
    if table.Count(R.crew) >= S("crewMax") then return DarkRP.notify(ply, 1, 4, "The crew is full.") end
    if R.pending[ply] then return DarkRP.notify(ply, 0, 4, "You've already asked. Wait for " .. R.initiator:Nick() .. ".") end
    ply.RP1942_BankPrompt = { kind = "join", vault = vault, expires = now + 15 }
    net.Start("RP1942_BankPrompt")
    net.WriteString("join")
    net.WriteString(string.format("Ask %s to join the robbery?\nYou'll be WANTED. You're paid a share only if you're alive and near the vault when the time is up.", R.initiator:Nick()))
    net.Send(ply)
end

net.Receive("RP1942_BankPromptAnswer", function(_, ply)
    local kind = net.ReadString()
    local p = ply.RP1942_BankPrompt
    ply.RP1942_BankPrompt = nil
    if not p or p.kind ~= kind or CurTime() > p.expires or not IsValid(p.vault) then return end
    if ply:GetPos():Distance(p.vault:GetPos()) > S("useRange") + 120 then
        return DarkRP.notify(ply, 1, 4, "You walked away from the vault.")
    end

    if kind == "start" then
        local ok, why = RP1942.bankStart(ply, p.vault)
        if not ok then DarkRP.notify(ply, 1, 5, why) end
    elseif kind == "join" then
        if not R.active or CurTime() > R.joinEnds or R.crew[ply] or R.pending[ply] then return end
        if table.Count(R.crew) >= S("crewMax") then return DarkRP.notify(ply, 1, 4, "The crew is full.") end
        R.pending[ply] = true
        net.Start("RP1942_BankJoinAsk")
        net.WriteEntity(ply)
        net.WriteFloat(R.joinEnds)
        net.Send(R.initiator)
        DarkRP.notify(ply, 0, 5, "You asked " .. R.initiator:Nick() .. " to let you in.")
    end
end)

net.Receive("RP1942_BankJoinAnswer", function(_, ply)
    local who, yes = net.ReadEntity(), net.ReadBool()
    if not R.active or ply ~= R.initiator or not IsValid(who) or not R.pending[who] then return end
    R.pending[who] = nil
    if not yes then
        DarkRP.notify(who, 1, 5, ply:Nick() .. " doesn't want you in the crew.")
        return
    end
    if CurTime() > R.joinEnds + 2 then return DarkRP.notify(ply, 1, 4, "Too late: the crew is closed.") end
    if table.Count(R.crew) >= S("crewMax") then return DarkRP.notify(ply, 1, 4, "The crew is full.") end
    local ok = RP1942.bankCanRob(who)
    if not ok or not who:Alive() then return end
    setCrew(who, true)
    makeWanted(who)
    DarkRP.notify(who, 0, 8, "You're in the crew. Keep " .. ply:Nick() .. " alive and stay near the vault.")
    DarkRP.notify(ply, 0, 5, who:Nick() .. " joined the crew.")
end)

-- Rewards the Reich member who stopped the initiator
local function reward(actor)
    local amount = S("killReward")
    if amount <= 0 or not IsValid(actor) or not actor:IsPlayer() then return end
    if not (RP1942.getFaction and RP1942.getFaction(actor) == "reich") then return end
    actor:addMoney(amount)
    DarkRP.notify(actor, 0, 8, "You stopped the bank robbery: " .. DarkRP.formatMoney(amount) .. " reward.")
end

hook.Add("PlayerDeath", "RP1942_Bank", function(victim, _, attacker)
    if not R.active then return end
    if victim == R.initiator then
        if attacker ~= victim then reward(attacker) end
        finish(false, victim:Nick() .. " was killed.")
    elseif R.crew[victim] then
        dropCrew(victim, "killed")
    end
    R.pending[victim] = nil
end)

hook.Add("playerArrested", "RP1942_Bank", function(criminal, _, actor)
    if not R.active then return end
    if criminal == R.initiator then
        reward(actor)
        finish(false, criminal:Nick() .. " was arrested.")
    elseif R.crew[criminal] then
        dropCrew(criminal, "arrested")
    end
end)

hook.Add("PlayerDisconnected", "RP1942_Bank", function(ply)
    if not R.active then return end
    if ply == R.initiator then
        finish(false, ply:Nick() .. " fled the city.")
    else
        R.crew[ply], R.pending[ply] = nil, nil
    end
end)

hook.Add("OnPlayerChangedTeam", "RP1942_Bank", function(ply)
    if not R.active then return end
    if ply == R.initiator then
        finish(false, ply:Nick() .. " gave up.")
    elseif R.crew[ply] then
        dropCrew(ply, "changed job")
    end
end)

hook.Add("EntityRemoved", "RP1942_Bank", function(ent)
    if R.active and ent == R.vault then
        timer.Simple(0, function() finish(false, "The vault is gone.") end)
    end
end)

--[[---------------------------------------------------------------------------
Staff: debug commands and the settings menu
---------------------------------------------------------------------------]]
local function firstVault(near)
    local best, bestD
    for _, v in ipairs(ents.FindByClass("rp1942_bank_vault")) do
        local d = IsValid(near) and v:GetPos():DistToSqr(near:GetPos()) or 0
        if not best or d < bestD then best, bestD = v, d end
    end
    return best
end

function RP1942.bankStatus()
    local st = RP1942.bankState()
    local lines = {}
    lines[#lines + 1] = "Bank robberies: " .. (S("enabled") and "on" or "OFF")
        .. "  ·  vaults: " .. #ents.FindByClass("rp1942_bank_vault")
        .. "  ·  Reich online: " .. reichCount() .. "/" .. S("minReich") .. (S("ignoreReichMinimum") and " (ignored)" or "")
    if R.active then
        local crew = {}
        for _, p in ipairs(crewList()) do crew[#crew + 1] = p:Nick() end
        lines[#lines + 1] = "ROBBERY: " .. (IsValid(R.initiator) and R.initiator:Nick() or "?") .. " holds the bank, "
            .. fmtTime(R.endsAt - CurTime()) .. " left. Crew: " .. table.concat(crew, ", ")
    else
        local cd = st.cooldown - CurTime()
        lines[#lines + 1] = cd > 0 and ("On cooldown for " .. fmtTime(cd) .. ".") or "Ready to be robbed."
    end
    lines[#lines + 1] = "Treasury: " .. DarkRP.formatMoney(RP1942.getTreasury and RP1942.getTreasury() or 0)
    return lines
end

-- !bankstart [name]
function RP1942.bankForceStart(admin, target)
    target = IsValid(target) and target or admin
    if not IsValid(target) then return false, "Nobody to start it with." end
    local v = firstVault(target)
    local ok, why = RP1942.bankStart(target, v, true)
    if ok then ServerLog(string.format("[1942] %s force-started a bank robbery for %s\n", IsValid(admin) and admin:Nick() or "Console", target:Nick())) end
    return ok, why
end

function RP1942.bankStop(admin)
    if not R.active then return false, "No robbery is running." end
    finish(false, "Called off by staff.", { noCooldown = true, silent = true })
    return true
end

function RP1942.bankFinishNow()
    if not R.active then return false, "No robbery is running." end
    finish(true)
    return true
end

function RP1942.bankResetCooldown()
    setCooldown(0)
    return true
end

local function say(ply, ok, why, okText)
    if IsValid(ply) then DarkRP.notify(ply, ok and 0 or 1, 5, ok and okText or tostring(why)) end
end


function RP1942.openBankMenu(ply)
    if not IsValid(ply) then return end
    if not staff(ply) then DarkRP.notify(ply, 1, 4, "You aren't allowed to change the bank settings.") return end
    local t = table.Copy(B.settings)
    t._status = RP1942.bankStatus()
    t._active = R.active
    net.Start("RP1942_BankMenu")
    net.WriteString(util.TableToJSON(t))
    net.Send(ply)
end

net.Receive("RP1942_BankMenuSave", function(_, ply)
    if not staff(ply) then return end
    local t = util.JSONToTable(net.ReadString() or "")
    if not istable(t) then return end
    RP1942.setBankSettings(t, ply)
    DarkRP.notify(ply, 0, 4, "Bank settings saved.")
    RP1942.openBankMenu(ply)
end)

net.Receive("RP1942_BankMenuAction", function(_, ply)
    if not staff(ply) then return end
    local a = net.ReadString()
    local ok, why, msg
    if a == "start" then ok, why = RP1942.bankForceStart(ply, ply) msg = "Robbery started with you as the robber."
    elseif a == "stop" then ok, why = RP1942.bankStop(ply) msg = "Robbery called off."
    elseif a == "finish" then ok, why = RP1942.bankFinishNow() msg = "Robbery ended: it succeeded."
    elseif a == "cooldown" then ok = RP1942.bankResetCooldown() msg = "Cooldown cleared."
    else return end
    say(ply, ok, why, msg)
    timer.Simple(0.2, function() if IsValid(ply) then RP1942.openBankMenu(ply) end end)
end)
