--[[---------------------------------------------------------------------------
42Bros - the weapon checker (server). See sh_search.lua.

    RP1942_SearchList   server -> checker   what the search found
    RP1942_SearchTake   checker -> server   confiscate: "carried" class |
                                            "pocket" index | "all"

Nothing the client says is trusted: a confiscation must match the list the
server made, be less than keepFor seconds old, and the player must still be
in range and alive. A pocket item is matched by the very entry that was
listed, so the pocket can't be shuffled in between.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_SearchList")
util.AddNetworkString("RP1942_SearchTake")

local CFG = RP1942.Search

local function log(fmt, ...)
    if RP1942.log then RP1942.log("SEARCH", fmt, ...) end
end

local function who(ply) return IsValid(ply) and (ply:Nick() .. " (" .. ply:SteamID() .. ")") or "(gone)" end

-- A pocket entry's name (the inventory's names when that module is there)
local function pocketName(entry)
    if RP1942.Inventory and RP1942.Inventory.pocketLabel then return RP1942.Inventory.pocketLabel(entry) end
    local dt = entry.DT or {}
    if entry.Class == "spawned_weapon" then return RP1942.weaponName(dt.WeaponClass) end
    return entry.Class or "?"
end

local function canTake(entry)
    return CFG.takeable[entry.Class] == true
end

--[[---------------------------------------------------------------------------
Making the list
---------------------------------------------------------------------------]]
local function buildList(checker, target, kind)
    local carried, pocket = {}, {}
    for _, w in ipairs(target:GetWeapons()) do
        local class = w:GetClass()
        if not RP1942.searchHidden(class) then
            carried[#carried + 1] = { class = class, name = RP1942.weaponName(class) }
        end
    end
    table.sort(carried, function(a, b) return a.name < b.name end)

    local refs = {}
    if kind == "pocket" then
        local keys = table.GetKeys(target.darkRPPocket or {})
        table.sort(keys)
        for _, idx in ipairs(keys) do
            local entry = target.darkRPPocket[idx]
            pocket[#pocket + 1] = { idx = idx, name = pocketName(entry), take = canTake(entry) }
            refs[idx] = entry
        end
    end

    checker.RP1942_Search = { target = target, kind = kind, at = CurTime(), refs = refs }
    return carried, pocket
end

local function sendList(checker)
    local s = checker.RP1942_Search
    if not s or not IsValid(s.target) then return end
    local carried, pocket = buildList(checker, s.target, s.kind)
    net.Start("RP1942_SearchList")
    net.WriteEntity(s.target)
    net.WriteString(s.kind)
    net.WriteTable({ carried = carried, pocket = pocket })
    net.Send(checker)
end

--[[---------------------------------------------------------------------------
Searching (the SWEP calls these)
---------------------------------------------------------------------------]]
function RP1942.searchValid(checker, target)
    return IsValid(checker) and IsValid(target) and target:IsPlayer() and checker:Alive() and target:Alive()
        and checker:GetPos():DistToSqr(target:GetPos()) <= CFG.range ^ 2
end

function RP1942.searchBegin(checker, target, kind)
    local secs = kind == "pocket" and CFG.searchTime or CFG.patTime
    target:SetNW2Entity("RP1942_SearchedBy", checker)
    target:SetNW2Float("RP1942_SearchEnd", CurTime() + secs)
    target:SetNW2Float("RP1942_SearchStart", CurTime())
    DarkRP.notify(target, 0, 4, checker:Nick() .. (kind == "pocket" and " is searching your pockets." or " is patting you down."))
    return secs
end

function RP1942.searchStop(checker, target, reason)
    if IsValid(target) and target:GetNW2Entity("RP1942_SearchedBy") == checker then
        target:SetNW2Entity("RP1942_SearchedBy", NULL)
    end
    if reason then
        if IsValid(checker) then DarkRP.notify(checker, 1, 3, reason) end
        if IsValid(target) then DarkRP.notify(target, 0, 3, "The search stopped.") end
    end
end

function RP1942.searchFinish(checker, target, kind)
    RP1942.searchStop(checker, target)
    local carried = #(select(1, buildList(checker, target, kind)))
    log("%s %s %s: %s", who(checker), kind == "pocket" and "searched the pockets of" or "patted down", who(target),
        carried == 0 and "no weapons" or (carried .. " weapon(s)"))
    DarkRP.notify(target, 0, 4, checker:Nick() .. " finished searching you.")
    sendList(checker)
end

--[[---------------------------------------------------------------------------
Confiscating: it goes into the checker's pocket (or at their feet if it's full)
---------------------------------------------------------------------------]]
local full = {}   -- [checker] = true when something had to be left at their feet this time

local function toChecker(checker, ent)
    if not IsValid(ent) then return end
    ent.RP1942_ShopOwner = nil   -- (a shop ammo box is the checker's now)
    if not RP1942.pocketOrLeave(checker, ent) then
        ent:SetPos(RP1942.spawnInFront and RP1942.spawnInFront(checker, 40) or (checker:GetPos() + Vector(0, 0, 40)))
        full[checker] = true
    end
end

local function takeCarried(checker, target, class)
    if RP1942.searchHidden(class) or not target:HasWeapon(class) then return nil end
    local w = target:GetWeapon(class)
    local clip = IsValid(w) and w:Clip1() or nil
    target:StripWeapon(class)
    if RP1942.weaponExists and not RP1942.weaponExists(class) then return RP1942.weaponName(class) end
    local ent = RP1942.makeSpawnedWeapon(class, checker:GetPos() + Vector(0, 0, 40), clip and math.max(clip, 0) or nil)
    if IsValid(ent) then
        ent.ammoadd = 0   -- just what was in the magazine, no fresh spare rounds
        toChecker(checker, ent)
    end
    return RP1942.weaponName(class)
end

local function takePocket(checker, target, idx, s)
    local entry = target.darkRPPocket and target.darkRPPocket[idx]
    if not entry or entry ~= s.refs[idx] or not canTake(entry) then return nil end
    local name = pocketName(entry)
    -- out of their pocket as the real thing, straight into the checker's
    local ok, ent = pcall(target.dropPocketItem, target, idx)
    if not ok or not IsValid(ent) then return nil end
    toChecker(checker, ent)
    return name
end

net.Receive("RP1942_SearchTake", function(_, checker)
    if not IsValid(checker) then return end
    local now = CurTime()
    if (checker.RP1942_NextTake or 0) > now then return end
    checker.RP1942_NextTake = now + 0.2

    local what = net.ReadString()
    local key = net.ReadString()
    local s = checker.RP1942_Search
    local w = checker:GetActiveWeapon()
    if not (s and IsValid(w) and w:GetClass() == "rp1942_weapon_checker") then return end
    local target = s.target
    if now - s.at > CFG.keepFor then return DarkRP.notify(checker, 1, 4, "That search is too old: search them again.") end
    if not RP1942.searchValid(checker, target) then return DarkRP.notify(checker, 1, 4, "They're too far away.") end

    local taken = {}
    if what == "carried" then
        taken[#taken + 1] = takeCarried(checker, target, key)
    elseif what == "pocket" and s.kind == "pocket" then
        taken[#taken + 1] = takePocket(checker, target, tonumber(key) or -1, s)
    elseif what == "all" then
        for _, wep in ipairs(target:GetWeapons()) do
            local name = takeCarried(checker, target, wep:GetClass())
            if name then taken[#taken + 1] = name end
        end
        if s.kind == "pocket" then
            for idx in pairs(s.refs) do
                local name = takePocket(checker, target, idx, s)
                if name then taken[#taken + 1] = name end
            end
        end
    end

    if #taken > 0 then
        local list = table.concat(taken, ", ")
        DarkRP.notify(checker, 0, 5, "Confiscated from " .. target:Nick() .. ": " .. list .. ". "
            .. (full[checker] and "Your pocket is full: what didn't fit is at your feet." or "It's in your pocket."))
        DarkRP.notify(target, 1, 6, checker:Nick() .. " confiscated: " .. list .. ".")
        log("%s confiscated from %s: %s", who(checker), who(target), list)
    end
    full[checker] = nil
    sendList(checker)   -- the list again, without what's gone
end)

hook.Add("PlayerDisconnected", "RP1942_Search", function(ply) full[ply] = nil end)
