--[[---------------------------------------------------------------------------
42Bros - server console logs (server). Settings and tags: sh_logs.lua

    RP1942.log(tag, format, ...)   one tagged line to the console and the day's file
    RP1942.logWho(ply)             "Name (STEAM_0:...) [Job, side]"
---------------------------------------------------------------------------]]
local CFG = RP1942.Logs
local DIR = "rp1942/logs"

local COLORS = {
    KILL   = Color(230, 110, 96),
    DEATH  = Color(170, 160, 142),
    MONEY  = Color(140, 200, 110),
    BIG    = Color(255, 70, 60),
    STATUS = Color(120, 170, 240),
    SETUP  = Color(201, 168, 92),
    WARN   = Color(255, 170, 0),
    LEAVE  = Color(170, 160, 142),
}
local TAG_COLOR = Color(201, 168, 92)

file.CreateDir(DIR)

function RP1942.log(tag, fmt, ...)
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or fmt
    msg = string.gsub(msg, "[\r\n]+", " ")
    if CFG.toConsole then
        MsgC(TAG_COLOR, "[42Bros]", COLORS[tag] or color_white, "[" .. tag .. "] ", color_white, msg, "\n")
    end
    if CFG.toFile then
        file.Append(DIR .. "/" .. os.date("%Y-%m-%d") .. ".txt", os.date("%H:%M:%S") .. " [42Bros][" .. tag .. "] " .. msg .. "\n")
    end
    if RP1942.LogCapture then table.insert(RP1942.LogCapture, "[" .. tag .. "] " .. msg) end   -- (!serverstatus, !setupcheck)
end

-- Run fn and return the lines it logged (for showing them to staff in game)
function RP1942.captureLog(fn)
    local prev = RP1942.LogCapture
    RP1942.LogCapture = {}
    local ok, err = pcall(fn)
    local lines = RP1942.LogCapture
    RP1942.LogCapture = prev
    if not ok then lines[#lines + 1] = "[ERROR] " .. tostring(err) end
    return lines
end
local log = RP1942.log

local function money(n) return DarkRP and DarkRP.formatMoney(n or 0) or ("$" .. tostring(n)) end

local function jobOf(ply)
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    return job and job.name or team.GetName(ply:Team()) or "?"
end
local function sideOf(ply)
    return RP1942.getFaction and RP1942.getFaction(ply) or "?"
end

function RP1942.logWho(ply)
    if not IsValid(ply) then return "(gone)" end
    if not ply:IsPlayer() then return ply:GetClass() end
    return string.format("%s (%s) [%s, %s]", ply:Nick(), ply:SteamID(), jobOf(ply), sideOf(ply))
end
local who = RP1942.logWho
local function name(ply) return IsValid(ply) and (ply:Nick() .. " (" .. ply:SteamID() .. ")") or "(gone)" end

--[[---------------------------------------------------------------------------
KILL / DEATH
---------------------------------------------------------------------------]]
local function harmless(class)
    if not class or class == "" then return true end
    if CFG.harmless[class] then return true end
    for _, w in ipairs(GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.DefaultWeapons or {}) do
        if w == class then return true end
    end
    return false
end

-- What the victim was holding, captured before DarkRP drops their weapons on death
hook.Add("DoPlayerDeath", "RP1942_Logs", function(victim)
    local w = IsValid(victim) and victim:GetActiveWeapon()
    victim.RP1942_DiedHolding = IsValid(w) and w:GetClass() or ""
end)

local function onNLR(ply) return ply:GetNW2Float("RP1942_NLREnd", 0) > CurTime() end
local function isStaffDuty(ply)
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    return job and job.command == "staffduty"
end

-- Who's really behind an attacker that isn't a player (a grenade, a car, a prop)
local function playerBehind(ent)
    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then return ent end
    if ent:IsVehicle() and IsValid(ent:GetDriver()) then return ent:GetDriver() end
    local o = ent.GetOwner and ent:GetOwner()
    if IsValid(o) and o:IsPlayer() then return o end
    if ent.CPPIGetOwner then
        local c = ent:CPPIGetOwner()
        if IsValid(c) and c:IsPlayer() then return c, true end   -- true: through a prop
    end
end

local CAUSES = {
    worldspawn = "the world (a fall or crush)", trigger_hurt = "the map (a hurt zone)",
    rp1942_airbomb = "an air raid bomb", rp1942_fire = "fire", entityflame = "fire",
    rp1942_supply_train = "the supply train", env_explosion = "an explosion",
}

hook.Add("PlayerDeath", "RP1942_Logs", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end
    local killer, viaProp = playerBehind(attacker)
    if not killer and IsValid(inflictor) then killer, viaProp = playerBehind(inflictor) end

    if killer == victim then
        log("DEATH", "%s killed themselves", who(victim))
        return
    end

    if not IsValid(killer) then
        local class = IsValid(attacker) and attacker:GetClass() or "?"
        log("DEATH", "%s died: %s", who(victim), CAUSES[class] or class)
        return
    end

    -- The weapon
    local weapon
    if viaProp then
        weapon = "a prop (" .. (IsValid(attacker) and attacker:GetClass() or "?") .. ")"
    elseif IsValid(inflictor) and inflictor ~= killer and not inflictor:IsPlayer() then
        weapon = inflictor:GetClass()
    else
        local w = killer:GetActiveWeapon()
        weapon = IsValid(w) and w:GetClass() or "?"
    end
    local metres = math.Round(victim:GetPos():Distance(killer:GetPos()) * 0.01905)

    local flags = {}
    local vSide, kSide = sideOf(victim), sideOf(killer)
    if vSide == kSide and vSide ~= "staff" then flags[#flags + 1] = "SAME SIDE" end
    if harmless(victim.RP1942_DiedHolding) then flags[#flags + 1] = "UNARMED" end
    if onNLR(killer) then flags[#flags + 1] = "KILLER ON NLR" end
    if isStaffDuty(killer) then flags[#flags + 1] = "STAFF ON DUTY" end
    if victim.isArrested and victim:isArrested() then flags[#flags + 1] = "VICTIM ARRESTED" end
    if viaProp then flags[#flags + 1] = "PROP KILL" end

    log("KILL", "%s killed %s with %s at %dm%s", who(killer), who(victim), weapon, metres,
        #flags > 0 and ("  <" .. table.concat(flags, ", ") .. ">") or "")
end)

--[[---------------------------------------------------------------------------
MONEY between players, and to / from the game
---------------------------------------------------------------------------]]
hook.Add("playerGaveMoney", "RP1942_Logs", function(ply, target, amount)
    log("MONEY", "%s gave %s to %s", name(ply), money(amount), name(target))
end)
hook.Add("playerDroppedMoney", "RP1942_Logs", function(ply, amount)
    log("MONEY", "%s dropped %s", name(ply), money(amount))
end)
hook.Add("playerPickedUpMoney", "RP1942_Logs", function(ply, amount)
    log("MONEY", "%s picked up %s", name(ply), money(amount))
end)
hook.Add("playerDroppedCheque", "RP1942_Logs", function(ply, recipient, amount)
    log("MONEY", "%s wrote a cheque for %s to %s", name(ply), money(amount), name(recipient))
end)
hook.Add("playerPickedUpCheque", "RP1942_Logs", function(ply, recipient, amount, success)
    if success then log("MONEY", "%s cashed a cheque for %s", name(ply), money(amount)) end
end)

-- Food bought with E (rp1942_good)
hook.Add("RP1942_GoodBought", "RP1942_Logs", function(ply, seller, good, q, price)
    local g = RP1942.Goods and RP1942.Goods[good]
    log("MONEY", "%s bought %s %s from %s for %s", name(ply), RP1942.qualityName and RP1942.qualityName(q) or q,
        g and g.name or good, name(seller), money(price))
end)

-- Market sales
hook.Add("RP1942_GoodsSold", "RP1942_Logs", function(ply, items, net, tax)
    log("MONEY", "%s sold %d good(s) at the market for %s (%s tax)", name(ply), #items, money(net), money(tax))
end)

-- Dealer shops and the F4 shop
hook.Add("RP1942_ShopPurchase", "RP1942_Logs", function(ply, item, ent, price, amount)
    log("MONEY", "%s bought %s%s%s", name(ply), (amount and amount > 1) and (amount .. "x ") or "",
        item and item.name or "?", price and (" for " .. money(price)) or "")
end)
hook.Add("RP1942_F4ShopPurchase", "RP1942_Logs", function(ply, item, price)
    log("MONEY", "%s bought %s (F4)%s", name(ply), item and item.name or "?", price and (" for " .. money(price)) or "")
end)

-- Printers
hook.Add("RP1942_PrinterCollected", "RP1942_Logs", function(ply, printer, amount, owner)
    if IsValid(owner) and owner ~= ply then
        log("MONEY", "%s emptied %s's %s: %s", name(ply), name(owner), printer.PrintName or "printer", money(amount))
    else
        log("MONEY", "%s collected %s from their %s", name(ply), money(amount), printer.PrintName or "printer")
    end
end)

-- Dead drops (dumpsters)
hook.Add("RP1942_DeadDrop", "RP1942_Logs", function(ply, amount, weapon)
    if weapon then
        log("MONEY", "%s hid a %s in a dumpster (dead drop)", name(ply), weapon)
    else
        log("MONEY", "%s hid %s in a dumpster (dead drop)", name(ply), money(amount))
    end
end)
hook.Add("RP1942_DeadDropTaken", "RP1942_Logs", function(ply, amount, weapons)
    log("MONEY", "%s took a dead drop: %s and %d weapon(s)", name(ply), money(amount), weapons or 0)
end)

--[[---------------------------------------------------------------------------
BIG: every change to a wallet goes through DarkRP's playerWalletChanged.
A big payment is logged with the file and line that paid it, so an exploit
points straight at its source.
---------------------------------------------------------------------------]]
local SKIP_SRC = { "money/sv_money", "rp1942_logs", "/hook.lua", "includes/modules/hook" }
local function payer()
    for level = 3, 16 do
        local info = debug.getinfo(level, "Sl")
        if not info then break end
        local src = info.short_src or ""
        local skip = src == "[C]"
        for _, s in ipairs(SKIP_SRC) do if string.find(src, s, 1, true) then skip = true break end end
        if not skip then
            src = string.gsub(src, "^addons/[^/]+/", "")
            return src .. ":" .. (info.currentline or 0)
        end
    end
    return "unknown (console or an admin command)"
end

hook.Add("playerWalletChanged", "RP1942_Logs", function(ply, amount)
    if not IsValid(ply) or not isnumber(amount) or amount <= 0 then return end
    if amount >= CFG.bigPayment then
        log("BIG", "%s received %s in one payment (from %s)", who(ply), money(amount), payer())
    end
    local now = CurTime()
    if not ply.RP1942_EarnFrom or now - ply.RP1942_EarnFrom > CFG.fastWindow then
        ply.RP1942_EarnFrom, ply.RP1942_Earned, ply.RP1942_EarnFlagged = now, 0, false
    end
    ply.RP1942_Earned = ply.RP1942_Earned + amount
    if not ply.RP1942_EarnFlagged and ply.RP1942_Earned >= CFG.fastEarnings then
        ply.RP1942_EarnFlagged = true
        log("BIG", "%s earned %s in %d minute(s) (latest from %s)", who(ply), money(ply.RP1942_Earned),
            math.max(1, math.ceil((now - ply.RP1942_EarnFrom) / 60)), payer())
    end
    -- nothing returned: the wallet change goes ahead untouched
end)

--[[---------------------------------------------------------------------------
STATUS every few minutes
---------------------------------------------------------------------------]]
local SIDE_NAMES = { reich = "Reich", resistance = "Resistance", civilian = "Civilian", staff = "Staff" }

function RP1942.logStatus()
    local players = player.GetAll()
    local sides, order = {}, { "reich", "resistance", "civilian", "staff" }
    local total, rich = 0, {}
    for _, p in ipairs(players) do
        local s = sideOf(p)
        sides[s] = (sides[s] or 0) + 1
        local m = p.getDarkRPVar and p:getDarkRPVar("money") or 0
        total = total + m
        rich[#rich + 1] = { p = p, m = m }
    end
    local parts = {}
    for _, s in ipairs(order) do
        if sides[s] then parts[#parts + 1] = (SIDE_NAMES[s] or s) .. " " .. sides[s] end
    end
    for s, n in pairs(sides) do
        if not SIDE_NAMES[s] then parts[#parts + 1] = s .. " " .. n end
    end
    table.sort(rich, function(a, b) return a.m > b.m end)
    local top = {}
    for i = 1, math.min(CFG.statusRichest, #rich) do top[#top + 1] = rich[i].p:Nick() .. " " .. money(rich[i].m) end

    log("STATUS", "%d online (%s) | Treasury %s | Economy %s%% | Wallets %s (avg %s)%s",
        #players, #parts > 0 and table.concat(parts, ", ") or "nobody",
        money(RP1942.getTreasury and RP1942.getTreasury() or 0),
        tostring(RP1942.getEconomy and RP1942.getEconomy() or "?"),
        money(total), money(#players > 0 and math.floor(total / #players) or 0),
        #top > 0 and (" | Richest: " .. table.concat(top, ", ")) or "")
end

if CFG.statusEvery > 0 then
    timer.Create("RP1942_LogStatus", CFG.statusEvery, 0, function()
        if #player.GetAll() > 0 then RP1942.logStatus() end
    end)
end

--[[---------------------------------------------------------------------------
SETUP: once the map's saved things have spawned, what's here and what's missing
---------------------------------------------------------------------------]]
local function count(class) return #ents.FindByClass(class) end

local function warn(fmt, ...) log("WARN", fmt, ...) end

function RP1942.logSetup()
    local map = game.GetMap()
    log("SETUP", "Map %s | gamemode %s | DarkRP %s", map, engine.ActiveGamemode(), DarkRP and "loaded" or "MISSING")
    if not DarkRP then warn("DarkRP isn't loaded: the server is not running the 42Bros gamemode properly.") end
    if engine.ActiveGamemode() ~= "occupationrp" then
        warn("The gamemode is '%s', not 'occupationrp'. Check the Gamemode setting / +gamemode in the start line.", engine.ActiveGamemode())
    end

    local ws = 0
    for _, a in ipairs(engine.GetAddons()) do if a.mounted and a.wsid and tostring(a.wsid) ~= "0" then ws = ws + 1 end end
    log("SETUP", "Workshop items mounted: %d", ws)
    if ws == 0 then warn("No Workshop items are mounted: is the collection set (+host_workshop_collection) and Public or Unlisted?") end

    local saved = 0
    for _, e in ipairs(ents.GetAll()) do if e.RP1942_SaveId then saved = saved + 1 end end
    local placed = {
        { "Markets", count("rp1942_market"), "place one with !addmarket" },
        { "Bank vault", count("rp1942_bank_vault"), "place it with !addvault" },
        { "Dumpsters", count("rp1942_dumpster"), "place them with !adddumpster" },
        { "Law boards", count("darkrp_laws"), nil },
        { "Saved machines and props", saved, nil },
        { "Staff radios", count("rp1942_radio"), nil },
    }
    local line = {}
    for _, p in ipairs(placed) do line[#line + 1] = p[1] .. " " .. p[2] end
    log("SETUP", "Placed on this map: %s", table.concat(line, ", "))
    for _, p in ipairs(placed) do
        if p[2] == 0 and p[3] then warn("No %s on this map: %s.", string.lower(p[1]), p[3]) end
    end

    if RP1942.mapStore then
        local apc = RP1942.mapStore("apc_spot").load()
        if not tonumber(apc.x) then warn("No APC garage set on this map: the Führer's armoured car has nowhere to appear.") end
        local oil = 0
        for _ in pairs(RP1942.mapStore("oilsites").load()) do oil = oil + 1 end
        if oil == 0 then warn("No oil sites marked on this map: Petroleum Producers can't build rigs (!addoilsite).") end
    end

    local train = RP1942.Events and RP1942.Events.train
    if train then
        if train.map and train.map ~= map then
            log("SETUP", "Supply train: its route is set for %s, so it won't run on this map.", train.map)
        elseif train.start and train.finish and not (util.IsInWorld(train.start) and util.IsInWorld(train.finish)) then
            warn("The supply train's route is outside this map: fix RP1942.Events.train.start / finish in sh_events.lua.")
        else
            log("SETUP", "Supply train route: OK")
        end
    end

    if GetConVar("sv_allowcslua"):GetBool() then warn("sv_allowcslua is 1: players can run their own Lua. Set it to 0 in server.cfg.") end
    local host = GetConVar("hostname"):GetString()
    if string.find(string.lower(host), "1942rp", 1, true) then warn("The server name contains '1942RP' (%s).", host) end
    if file.Exists("mcv_harness/enable.txt", "DATA") then
        warn("data/mcv_harness/enable.txt exists: the MCV test harness is ON. Delete that file on a live server.")
    end
    log("SETUP", "Logs are also saved to garrysmod/data/%s/%s.txt", DIR, os.date("%Y-%m-%d"))
end

hook.Add("InitPostEntity", "RP1942_LogSetup", function()
    timer.Simple(CFG.startupDelay, RP1942.logSetup)
end)

-- Staff run both again with !serverstatus and !setupcheck (lua/ulx/modules/sh/42bros.lua)
