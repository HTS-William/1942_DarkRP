--[[---------------------------------------------------------------------------
42Bros - reports (server). See sh_reports.lua.

    RP1942_ReportSend   player -> server   target SteamID64 ("" = nobody), text
    RP1942_ReportForm   server -> player   open the form
    RP1942_ReportList   server -> staff    the open reports (and open the list?)
    RP1942_ReportAct    staff -> server    action, report id, note

Every staff action is checked here against ULX permissions: the client only
asks.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_ReportSend")
util.AddNetworkString("RP1942_ReportForm")
util.AddNetworkString("RP1942_ReportList")
util.AddNetworkString("RP1942_ReportAct")

local CFG = RP1942.Reports
local FILE = "rp1942/reports.json"

local reports = {}   -- [id] = { id, at, by, byName, about, aboutName, text, where, claimed, claimedName }
local nextId = 1

local function log(fmt, ...) if RP1942.log then RP1942.log("REPORT", fmt, ...) end end

local function can(ply, access)
    if not IsValid(ply) then return false end
    if ULib and ULib.ucl and ULib.ucl.query then return ULib.ucl.query(ply, access) == true end
    return ply:IsAdmin()
end
local function isStaff(ply) return can(ply, "ulx reports") end
RP1942.reportStaff = isStaff

local function staffOnline()
    local list = {}
    for _, p in ipairs(player.GetAll()) do if isStaff(p) then list[#list + 1] = p end end
    return list
end

local function save()
    file.CreateDir("rp1942")
    local list = {}
    for _, r in pairs(reports) do list[#list + 1] = r end
    file.Write(FILE, util.TableToJSON({ next = nextId, reports = list }))
end

local function load()
    local raw = file.Read(FILE, "DATA")
    local data = raw and util.JSONToTable(raw)
    if not istable(data) then return end
    nextId = tonumber(data.next) or 1
    for _, r in ipairs(data.reports or {}) do
        if istable(r) and tonumber(r.id) then
            r.claimed, r.claimedName = nil, nil   -- (nobody's on it after a restart)
            reports[tonumber(r.id)] = r
        end
    end
end
hook.Add("Initialize", "RP1942_Reports", load)

-- The list, sorted oldest first, to every staff member online (open = also open their list)
local function listFor()
    local list = {}
    for _, r in pairs(reports) do
        local copy = table.Copy(r)
        copy.byOnline = IsValid(player.GetBySteamID64(r.by))
        copy.aboutOnline = r.about ~= "" and IsValid(player.GetBySteamID64(r.about))
        list[#list + 1] = copy
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function sendList(to, open)
    to = to or staffOnline()
    if istable(to) and #to == 0 then return end
    net.Start("RP1942_ReportList")
    net.WriteBool(open == true)
    net.WriteTable(listFor())
    net.Send(to)
end
RP1942.sendReports = sendList

--[[---------------------------------------------------------------------------
Making a report
---------------------------------------------------------------------------]]
local function clean(text)
    if RP1942.cleanChatText then text = RP1942.cleanChatText(text) end
    text = string.Trim(tostring(text or ""))
    if #text > CFG.maxLength then text = text:sub(1, CFG.maxLength) end
    return text
end

local function openCount(ply)
    local n, sid = 0, ply:SteamID64()
    for _, r in pairs(reports) do if r.by == sid then n = n + 1 end end
    return n
end

-- A target named in the text ("@ Hans is RDMing"): the first online player whose
-- name starts one of the words, if exactly one matches
local function guessTarget(ply, text)
    local found
    for word in text:gmatch("[%w_%-]+") do
        if #word >= 3 then
            for _, p in ipairs(player.GetAll()) do
                if p ~= ply and string.lower(p:Nick()):find(string.lower(word), 1, true) == 1 then
                    if found and found ~= p then return nil end
                    found = p
                end
            end
        end
    end
    return found
end

function RP1942.makeReport(ply, target, text)
    if not IsValid(ply) then return end
    local now = CurTime()
    if (ply.RP1942_NextReport or 0) > now then
        return DarkRP.notify(ply, 1, 4, "Wait " .. math.ceil(ply.RP1942_NextReport - now) .. " seconds before sending another report.")
    end
    text = clean(text)
    if #text < CFG.minLength then
        return DarkRP.notify(ply, 1, 4, "Say what happened: who, what, and where.")
    end
    if openCount(ply) >= CFG.maxOpen then
        return DarkRP.notify(ply, 1, 5, "You already have " .. CFG.maxOpen .. " open reports: wait for staff to get to them.")
    end
    ply.RP1942_NextReport = now + CFG.cooldown
    if not IsValid(target) then target = guessTarget(ply, text) end
    if target == ply then target = nil end

    local r = {
        id = nextId, at = os.time(),
        by = ply:SteamID64(), byName = ply:Nick(),
        about = IsValid(target) and target:SteamID64() or "", aboutName = IsValid(target) and target:Nick() or "",
        text = text,
        where = ply:GetPos():ToTable(),
    }
    nextId = nextId + 1
    reports[r.id] = r
    save()
    log("#%d from %s (%s)%s: %s", r.id, r.byName, ply:SteamID(), IsValid(target) and (" about " .. r.aboutName .. " (" .. target:SteamID() .. ")") or "", text)

    local staff = staffOnline()
    DarkRP.notify(ply, 0, 6, "Report #" .. r.id .. " sent. " .. (#staff > 0 and (#staff .. " staff online.") or "No staff online right now: it waits until someone joins."))
    for _, s in ipairs(staff) do
        DarkRP.notify(s, 1, 8, "Report #" .. r.id .. " from " .. r.byName .. (r.aboutName ~= "" and (" about " .. r.aboutName) or "") .. ". !reports to see it.")
        s:EmitSound("buttons/blip1.wav", 75, 120)
    end
    sendList(staff, false)
    return r
end

net.Receive("RP1942_ReportSend", function(_, ply)
    local about = net.ReadString()
    local text = net.ReadString()
    local target = about ~= "" and player.GetBySteamID64(about) or nil
    RP1942.makeReport(ply, target, text)
end)

DarkRP.defineChatCommand("report", function(ply, args)
    args = string.Trim(args or "")
    if args == "" then
        net.Start("RP1942_ReportForm")
        net.Send(ply)
    else
        RP1942.makeReport(ply, nil, args)
    end
    return ""
end)

-- "@ text" from a player is a report (staff's own @ stays ULX's admin chat).
-- Runs before ULX's chat commands so it isn't also sent as admin chat.
hook.Add("PlayerSay", "RP1942_Reports", function(ply, text)
    if not isstring(text) or text:sub(1, 1) ~= "@" or isStaff(ply) then return end
    local msg = string.Trim(text:sub(2))
    if msg == "" then
        net.Start("RP1942_ReportForm")
        net.Send(ply)
    else
        RP1942.makeReport(ply, nil, msg)
    end
    return ""
end, HOOK_HIGHEST)

--[[---------------------------------------------------------------------------
Staff actions
---------------------------------------------------------------------------]]
local function tellReporter(r, msg)
    local p = player.GetBySteamID64(r.by)
    if IsValid(p) then DarkRP.notify(p, 0, 7, msg) end
end

-- Somewhere free next to `to` for a player to stand
local function spotNear(ply, to)
    local base = to:GetPos()
    local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
    for _, off in ipairs({ Vector(40, 0, 0), Vector(-40, 0, 0), Vector(0, 40, 0), Vector(0, -40, 0), Vector(40, 40, 0), Vector(-40, -40, 0), Vector(0, 0, 80) }) do
        local pos = base + off
        local tr = util.TraceHull({ start = pos + Vector(0, 0, 4), endpos = pos + Vector(0, 0, 4), mins = mins, maxs = maxs, mask = MASK_PLAYERSOLID, filter = { ply, to } })
        if not tr.Hit then return pos end
    end
    return base + Vector(0, 0, 80)
end

local ACTIONS = {}

function ACTIONS.claim(staff, r)
    if r.claimed and r.claimed ~= staff:SteamID64() then
        return DarkRP.notify(staff, 1, 4, r.claimedName .. " already has #" .. r.id .. ".")
    end
    r.claimed, r.claimedName = staff:SteamID64(), staff:Nick()
    tellReporter(r, staff:Nick() .. " is looking at your report #" .. r.id .. ".")
    log("#%d claimed by %s", r.id, staff:Nick())
    return true
end

function ACTIONS.release(staff, r)
    if r.claimed ~= staff:SteamID64() and not can(staff, "ulx reportsall") then return end
    r.claimed, r.claimedName = nil, nil
    log("#%d released by %s", r.id, staff:Nick())
    return true
end

function ACTIONS.goto_(staff, r)
    if not can(staff, "ulx goto") then return DarkRP.notify(staff, 1, 4, "You don't have goto.") end
    local p = player.GetBySteamID64(r.by)
    if not IsValid(p) then return DarkRP.notify(staff, 1, 4, r.byName .. " isn't on the server.") end
    if staff:InVehicle() then staff:ExitVehicle() end
    staff:SetPos(spotNear(staff, p))
    staff:SetLocalVelocity(Vector(0, 0, 0))
    log("#%d: %s went to %s", r.id, staff:Nick(), r.byName)
end

function ACTIONS.bring(staff, r)
    if not can(staff, "ulx bring") then return DarkRP.notify(staff, 1, 4, "You don't have bring.") end
    local p = player.GetBySteamID64(r.by)
    if not IsValid(p) then return DarkRP.notify(staff, 1, 4, r.byName .. " isn't on the server.") end
    if p:InVehicle() then p:ExitVehicle() end
    p:SetPos(spotNear(p, staff))
    p:SetLocalVelocity(Vector(0, 0, 0))
    log("#%d: %s brought %s", r.id, staff:Nick(), r.byName)
end

function ACTIONS.cleanup(staff, r)
    if not can(staff, "ulx cleanplayer") then return DarkRP.notify(staff, 1, 4, "You don't have cleanplayer.") end
    local p = r.about ~= "" and player.GetBySteamID64(r.about)
    if not IsValid(p) then return DarkRP.notify(staff, 1, 4, "The reported player isn't on the server (their things went when they left).") end
    local n, what = RP1942.cleanupPlayer(p, staff)
    DarkRP.notify(staff, 0, 5, n > 0 and ("Removed " .. p:Nick() .. "'s things: " .. what .. ".") or (p:Nick() .. " owns nothing in the world."))
end

function ACTIONS.close(staff, r, note)
    note = clean(note or "")
    reports[r.id] = nil
    tellReporter(r, "Your report #" .. r.id .. " was closed by " .. staff:Nick() .. (note ~= "" and (": " .. note) or "."))
    log("#%d closed by %s%s", r.id, staff:Nick(), note ~= "" and (": " .. note) or "")
    return true
end

net.Receive("RP1942_ReportAct", function(_, staff)
    if not isStaff(staff) then return end
    local now = CurTime()
    if (staff.RP1942_NextReportAct or 0) > now then return end
    staff.RP1942_NextReportAct = now + 0.3
    local action = net.ReadString()
    local id = net.ReadUInt(32)
    local note = net.ReadString()
    local r = reports[id]
    if not r then return sendList({ staff }, false) end
    local fn = ACTIONS[action == "goto" and "goto_" or action]
    if not fn then return end
    if fn(staff, r, note) then save() end
    sendList(nil, false)
end)

-- Staff joining: if anything's waiting, say so
hook.Add("PlayerInitialSpawn", "RP1942_Reports", function(ply)
    timer.Simple(8, function()
        if not IsValid(ply) or not isStaff(ply) then return end
        local n = table.Count(reports)
        if n > 0 then
            DarkRP.notify(ply, 1, 8, n .. " open report" .. (n == 1 and "" or "s") .. " waiting. !reports to see them.")
            sendList({ ply }, false)
        end
    end)
end)

if ULib and ULib.ucl and ULib.ucl.registerAccess then
    ULib.ucl.registerAccess("ulx reportsall", ULib.ACCESS_ADMIN, "Release reports other staff have claimed", "42Bros")
end
