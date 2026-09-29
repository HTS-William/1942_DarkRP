--[[---------------------------------------------------------------------------
1942 DarkRP - staff commands for ULX, in the "42Bros" category

ULX loads this file by itself (it loads every lua/ulx/modules/sh/*.lua). Find
them in the ULX menu (!menu) under Cmds > 42Bros, each with its description,
or type them: in chat with ! (!train), in console with ulx (ulx train).
These are the ONLY staff commands: there are no /chat versions.

Who may use each one is set per rank in the ULX menu (Groups tab, 42Bros).
The code behind the "look at" commands is registered with
RP1942.defineStaffCommand (rp1942_admin/sh_staffcommands.lua) and checks the
same ULX permission again (RP1942.staffCan, rp1942_core/sh_staff.lua).

"Look at" commands act on what you're aiming at, so aim first, then open
the menu or type the command.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.ULX42 = true   -- tells RP1942.staffCan to ask ULX

local CATEGORY = "42Bros"

-- Run one of our staff commands for ply (it does its own work and messages).
-- Their code lives with what they work on (RP1942.defineStaffCommand,
-- rp1942_admin/sh_staffcommands.lua).
local function darkrpCommand(ply, name, args)
    if RP1942.runStaffCommand and RP1942.runStaffCommand(ply, name, args) then return true end
    ULib.tsayError(ply, "The " .. name .. " command isn't loaded on this server.", true)
    return false
end

local function inGameOnly(ply)
    if IsValid(ply) then return true end
    ULib.tsayError(ply, "This one works on what you're looking at: use it in game.", true)
    return false
end

local function register(name, fn, say, access, help)
    local cmd = ulx.command(CATEGORY, "ulx " .. name, fn, say)
    cmd:defaultAccess(access)
    cmd:help(help)
    return cmd
end

--[[---------------------------------------------------------------------------
World events
---------------------------------------------------------------------------]]
function ulx.rp1942train(ply)
    if not RP1942.startEvent then return ULib.tsayError(ply, "World events aren't loaded.", true) end
    local ok, why = RP1942.startEvent("train", true)
    if not ok then return ULib.tsayError(ply, "Can't start the train: " .. tostring(why), true) end
    ulx.fancyLogAdmin(ply, true, "#A started the supply train")
end
register("train", ulx.rp1942train, "!train", ULib.ACCESS_ADMIN,
    "Start the Reich supply train now. It rolls into the station, waits, then carries on. Doesn't change the automatic timer.")

function ulx.rp1942event(ply, id)
    if not RP1942.startEvent then return ULib.tsayError(ply, "World events aren't loaded.", true) end
    local ok, why = RP1942.startEvent(string.lower(id), true)
    if not ok then return ULib.tsayError(ply, "Can't start '" .. id .. "': " .. tostring(why), true) end
    ulx.fancyLogAdmin(ply, true, "#A started the world event #s", id)
end
local ev = register("event", ulx.rp1942event, "!event", ULib.ACCESS_ADMIN,
    "Start a world event by its id (train is the only one so far). Ignores the player minimum.")
ev:addParam{ type = ULib.cmds.StringArg, hint = "event id", completes = { "train" } }

function ulx.rp1942stopevent(ply)
    local active = RP1942.activeEvent and RP1942.activeEvent()
    if not active then return ULib.tsayError(ply, "No world event is running.", true) end
    if active.stop then active.stop() end
    ulx.fancyLogAdmin(ply, true, "#A stopped the world event #s", active.id or "?")
end
register("stopevent", ulx.rp1942stopevent, "!stopevent", ULib.ACCESS_ADMIN,
    "End the world event that's running now (e.g. send the train away).")

function ulx.rp1942eventsettings(ply)
    if not IsValid(ply) then return ULib.tsayError(ply, "Use this in game.", true) end
    if not RP1942.openEventMenu then return ULib.tsayError(ply, "World events aren't loaded.", true) end
    RP1942.openEventMenu(ply)
end
register("eventsettings", ulx.rp1942eventsettings, "!eventsettings", ULib.ACCESS_SUPERADMIN,
    "Opens the world event settings: minutes between events, the player minimum, retrying when too few are on, each event on/off, and start/stop buttons. Saved for the server.")

--[[---------------------------------------------------------------------------
The Führer
---------------------------------------------------------------------------]]
function ulx.rp1942setfuhrer(ply, target)
    if not RP1942.appointFuhrer then return ULib.tsayError(ply, "The election isn't loaded.", true) end
    local ok, why = RP1942.appointFuhrer(target, ply)
    if not ok then return ULib.tsayError(ply, "Can't: " .. tostring(why), true) end
    ulx.fancyLogAdmin(ply, "#A appointed #T Führer", target)
end
local sf = register("setfuhrer", ulx.rp1942setfuhrer, "!setfuhrer", ULib.ACCESS_SUPERADMIN,
    "Makes a player the Führer right now, without an election. A running election is cancelled (fees refunded) and the sitting Führer is moved to the default job.")
sf:addParam{ type = ULib.cmds.PlayerArg }

function ulx.rp1942removefuhrer(ply)
    if not RP1942.removeFuhrer then return ULib.tsayError(ply, "The election isn't loaded.", true) end
    local ok, why = RP1942.removeFuhrer(ply)
    if not ok then return ULib.tsayError(ply, "Can't: " .. tostring(why), true) end
    ulx.fancyLogAdmin(ply, "#A removed the Führer from office")
end
register("removefuhrer", ulx.rp1942removefuhrer, "!removefuhrer", ULib.ACCESS_SUPERADMIN,
    "Removes the sitting Führer from office (moved to the default job), so a new election can be held.")

--[[---------------------------------------------------------------------------
ESP
---------------------------------------------------------------------------]]
function ulx.rp1942esp(ply)
    if not IsValid(ply) then return ULib.tsayError(ply, "Use this in game.", true) end
    if not RP1942.toggleESP then return ULib.tsayError(ply, "ESP isn't loaded.", true) end
    RP1942.toggleESP(ply)
end
register("esp", ulx.rp1942esp, "!esp", ULib.ACCESS_ADMIN,
    "Toggles admin ESP for you: every player through walls, anywhere on the map, with their name, real job (and cover if undercover), rank, health and distance.")

--[[---------------------------------------------------------------------------
Economy and treasury
---------------------------------------------------------------------------]]
function ulx.rp1942seteconomy(ply, value)
    if not RP1942.setEconomy then return ULib.tsayError(ply, "The economy isn't loaded.", true) end
    local old = RP1942.getEconomy()
    local new = RP1942.setEconomy(value, "set by staff (" .. (IsValid(ply) and ply:Nick() or "Console") .. ")")
    ulx.fancyLogAdmin(ply, true, "#A set the economy from #i to #i", old, new)
end
local se = register("seteconomy", ulx.rp1942seteconomy, "!seteconomy", ULib.ACCESS_SUPERADMIN,
    "Set the economy bar (1-110; 50 is where it starts). It changes everyone's wages and market prices.")
se:addParam{ type = ULib.cmds.NumArg, min = 1, max = 110, hint = "economy", ULib.cmds.round }

function ulx.rp1942treasury(ply, amount)
    if not RP1942.treasuryDeposit then return ULib.tsayError(ply, "The treasury isn't loaded.", true) end
    local reason = "staff (" .. (IsValid(ply) and ply:Nick() or "Console") .. ")"
    if amount >= 0 then
        RP1942.treasuryDeposit(amount, reason)
    elseif not RP1942.treasuryWithdraw(-amount, reason) then
        return ULib.tsayError(ply, "The treasury only holds " .. DarkRP.formatMoney(RP1942.getTreasury()) .. ".", true)
    end
    ulx.fancyLogAdmin(ply, true, "#A changed the Reich treasury by #s (now #s)", DarkRP.formatMoney(amount), DarkRP.formatMoney(RP1942.getTreasury()))
end
local tr = register("treasury", ulx.rp1942treasury, "!treasury", ULib.ACCESS_SUPERADMIN,
    "Add money to the Reich treasury, or take it away with a negative amount (it can't go below zero).")
tr:addParam{ type = ULib.cmds.NumArg, min = -10000000, max = 10000000, hint = "amount", ULib.cmds.round }

--[[---------------------------------------------------------------------------
Wanted
---------------------------------------------------------------------------]]
function ulx.rp1942makewanted(ply, target, reason)
    if not RP1942.makeWanted then return ULib.tsayError(ply, "The wanted system isn't loaded.", true) end
    if reason == "" then reason = "By order of the Reich" end
    RP1942.makeWanted(target, reason, nil)
    ulx.fancyLogAdmin(ply, true, "#A made #T wanted (#s)", target, reason)
end
local mw = register("makewanted", ulx.rp1942makewanted, "!makewanted", ULib.ACCESS_ADMIN,
    "Make a player wanted by the Reich, with a reason (shown under WANTED). Everyone gets the Reich Alert.")
mw:addParam{ type = ULib.cmds.PlayerArg }
mw:addParam{ type = ULib.cmds.StringArg, hint = "reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, default = "" }

function ulx.rp1942clearwanted(ply, targets)
    local cleared = {}
    for _, t in ipairs(targets) do
        if t:getDarkRPVar("wanted") then
            t:unWanted(IsValid(ply) and ply or nil)
            cleared[#cleared + 1] = t
        end
    end
    if #cleared == 0 then return ULib.tsayError(ply, "Nobody there is wanted.", true) end
    ulx.fancyLogAdmin(ply, true, "#A cleared the wanted status of #T", cleared)
end
local cw = register("clearwanted", ulx.rp1942clearwanted, "!clearwanted", ULib.ACCESS_ADMIN,
    "Clear the wanted status of one or more players.")
cw:addParam{ type = ULib.cmds.PlayersArg }

--[[---------------------------------------------------------------------------
Map setup (saved per map). Aim first.
---------------------------------------------------------------------------]]
local FACTIONS = { "reich", "resistance", "civilian", "wehrmacht", "waffen_ss", "leibstandarte", "none" }

function ulx.rp1942factiondoor(ply, faction)
    if not inGameOnly(ply) then return end
    if not RP1942.setFactionDoor then return ULib.tsayError(ply, "Faction doors aren't loaded.", true) end
    RP1942.setFactionDoor(ply, faction)
    ulx.fancyLogAdmin(ply, true, "#A set a door's faction to #s", faction)
end
local fd = register("factiondoor", ulx.rp1942factiondoor, "!factiondoor", ULib.ACCESS_SUPERADMIN,
    "Look at a door: only that faction can lock and unlock it, and nobody can buy it. 'none' makes it a normal door. Saved for this map.")
fd:addParam{ type = ULib.cmds.StringArg, hint = "faction", completes = FACTIONS }

local function lookAt(name, access, help)
    local fnName = "rp1942" .. name
    ulx[fnName] = function(ply)
        if not inGameOnly(ply) then return end
        if darkrpCommand(ply, name) then
            ulx.fancyLogAdmin(ply, true, "#A used #s", name)
        end
    end
    register(name, ulx[fnName], "!" .. name, access, help)
end

lookAt("adddumpster", ULib.ACCESS_SUPERADMIN, "Look at the floor: places a dumpster there, facing you. Saved for this map.")
lookAt("removedumpster", ULib.ACCESS_SUPERADMIN, "Look at a dumpster: removes it, and from this map's save.")
lookAt("addmarket", ULib.ACCESS_SUPERADMIN, "Look at the floor: places a market there, facing you, where players sell goods. Saved for this map.")
lookAt("removemarket", ULib.ACCESS_SUPERADMIN, "Look at a market: removes it, and from this map's save.")
function ulx.rp1942getdumpsterpos(ply)
    if not IsValid(ply) then
        if rp1942_dumpsters_positionsCode then print((rp1942_dumpsters_positionsCode())) end
        return
    end
    if darkrpCommand(ply, "getdumpsterpos") then ulx.fancyLogAdmin(ply, true, "#A copied the dumpster positions") end
end
register("getdumpsterpos", ulx.rp1942getdumpsterpos, "!getdumpsterpos", ULib.ACCESS_SUPERADMIN,
    "Copies every dumpster on this map to your clipboard as code for rp1942_dumpster/config.lua (AddSpawnPos), to hardcode them. Also printed in your console (or the server console).")

lookAt("saveprod", ULib.ACCESS_SUPERADMIN, "Look at a production machine (oven, flour, barrel, factory line, derrick, market or printer): saves it for this map. It comes back after every restart and cleanup, frozen in place and owned by nobody.")
lookAt("saveprodall", ULib.ACCESS_SUPERADMIN, "Saves every machine you placed from !prodspawn that isn't saved yet, for this map.")
lookAt("unsaveprod", ULib.ACCESS_SUPERADMIN, "Look at a saved machine: removes it, and from this map's save.")
lookAt("prodsaves", ULib.ACCESS_SUPERADMIN, "Counts the saved machines on this map and highlights them on your screen for a minute.")

lookAt("addoilsite", ULib.ACCESS_SUPERADMIN, "Look at the ground or a platform: marks an oil site. Bought oil derricks are built on the nearest free one, facing where you stood. Saved for this map.")
lookAt("removeoilsite", ULib.ACCESS_SUPERADMIN, "Look near an oil site: removes it (and the derrick on it), and from this map's save.")
lookAt("oilsites", ULib.ACCESS_SUPERADMIN, "Shows every oil site on this map on your screen for a minute, and whether each is free or taken.")

--[[---------------------------------------------------------------------------
Bank robbery (rp1942_bank)
---------------------------------------------------------------------------]]
lookAt("addvault", ULib.ACCESS_SUPERADMIN, "Look at the floor: places the Reichsbank vault there, facing you. Robbers press E on it. Saved for this map.")
lookAt("removevault", ULib.ACCESS_SUPERADMIN, "Look at the Reichsbank vault: removes it, and from this map's save.")

function ulx.rp1942banksettings(ply)
    if not IsValid(ply) then return ULib.tsayError(ply, "Use this in game.", true) end
    if not RP1942.openBankMenu then return ULib.tsayError(ply, "The bank isn't loaded.", true) end
    RP1942.openBankMenu(ply)
end
register("banksettings", ulx.rp1942banksettings, "!banksettings", ULib.ACCESS_SUPERADMIN,
    "Bank robbery settings: length, cooldown, join window, Reich needed, crew size, bank radius, reward, vault model, alarm. Also shows the status and has debug buttons (start / stop / finish / clear cooldown). Saved in data/rp1942/bank.json. This permission also covers every bank debug command.")

function ulx.rp1942bankstart(ply, target)
    if not RP1942.bankForceStart then return ULib.tsayError(ply, "The bank isn't loaded.", true) end
    local ok, why = RP1942.bankForceStart(ply, target)
    if not ok then return ULib.tsayError(ply, "Can't start: " .. tostring(why), true) end
    ulx.fancyLogAdmin(ply, true, "#A started a bank robbery with #T as the robber", target)
end
local bs = register("bankstart", ulx.rp1942bankstart, "!bankstart", ULib.ACCESS_SUPERADMIN,
    "Debug: start a bank robbery now with that player as the robber (yourself if left empty), at the vault nearest them. Ignores every requirement (Reich online, cooldown, job).")
bs:addParam{ type = ULib.cmds.PlayerArg, ULib.cmds.optional }

local function bankSimple(name, fnName, okText, help)
    ulx["rp1942" .. name] = function(ply)
        local fn = RP1942[fnName]
        if not fn then return ULib.tsayError(ply, "The bank isn't loaded.", true) end
        local ok, why = fn(ply)
        if not ok then return ULib.tsayError(ply, tostring(why), true) end
        ulx.fancyLogAdmin(ply, true, "#A " .. okText)
    end
    register(name, ulx["rp1942" .. name], "!" .. name, ULib.ACCESS_SUPERADMIN, help)
end
bankSimple("bankstop", "bankStop", "called off the bank robbery", "Debug: call off the running bank robbery. Nobody is paid and there's no cooldown.")
bankSimple("bankfinish", "bankFinishNow", "ended the bank robbery (it succeeded)", "Debug: end the bank robbery timer now. It succeeds: the treasury is split between the crew.")
bankSimple("bankcooldown", "bankResetCooldown", "cleared the bank cooldown", "Debug: clear the bank's cooldown so it can be robbed again right away.")

function ulx.rp1942bankstatus(ply)
    if not RP1942.bankStatus then return ULib.tsayError(ply, "The bank isn't loaded.", true) end
    for _, l in ipairs(RP1942.bankStatus()) do ULib.tsay(ply, "[Bank] " .. l, true) end
end
register("bankstatus", ulx.rp1942bankstatus, "!bankstatus", ULib.ACCESS_ADMIN,
    "Shows what the bank robbery system is doing: on/off, vaults, Reich online, the running robbery and its crew, the cooldown and the treasury.")

--[[---------------------------------------------------------------------------
Testing
---------------------------------------------------------------------------]]
function ulx.rp1942prodspawn(ply)
    if not IsValid(ply) then return ULib.tsayError(ply, "Use this in game.", true) end
    if not RP1942.openProdSpawn then return ULib.tsayError(ply, "Production isn't loaded.", true) end
    RP1942.openProdSpawn(ply)
end
register("prodspawn", ulx.rp1942prodspawn, "!prodspawn", ULib.ACCESS_SUPERADMIN,
    "Opens the production spawner: ovens, flour, wine barrels, factory lines, derricks, markets and every good at any quality (into your pocket or at your crosshair), plus 'finish its timer' and 'remove it' for the machine you're looking at.")

function ulx.rp1942testexplosion(ply, damage, radius)
    if not inGameOnly(ply) then return end
    if not RP1942.explode then return ULib.tsayError(ply, "Explosions aren't loaded.", true) end
    RP1942.explode(ply:GetEyeTrace().HitPos, { damage = damage, radius = radius, attacker = ply })
    ulx.fancyLogAdmin(ply, true, "#A set off a test explosion (#i damage, #i radius)", damage, radius)
end
local te = register("testexplosion", ulx.rp1942testexplosion, "!testexplosion", ULib.ACCESS_SUPERADMIN,
    "Sets off an explosion where you're aiming, to test the effects. It really does damage: 0 damage = effect only.")
te:addParam{ type = ULib.cmds.NumArg, min = 0, max = 1000, default = 120, hint = "damage", ULib.cmds.optional, ULib.cmds.round }
te:addParam{ type = ULib.cmds.NumArg, min = 50, max = 2000, default = 250, hint = "radius", ULib.cmds.optional, ULib.cmds.round }
