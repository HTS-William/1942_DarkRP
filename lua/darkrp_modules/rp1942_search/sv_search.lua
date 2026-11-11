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
Confiscating
---------------------------------------------------------------------------]]
local function keep(target, item)
    target.RP1942_Confiscated = target.RP1942_Confiscated or {}
    table.insert(target.RP1942_Confiscated, item)
end

local function takeCarried(checker, target, class)
    if RP1942.searchHidden(class) or not target:HasWeapon(class) then return nil end
    local w = target:GetWeapon(class)
    keep(target, { kind = "weapon", class = class, clip = IsValid(w) and w:Clip1() or nil })
    target:StripWeapon(class)
    return RP1942.weaponName(class)
end

local function takePocket(checker, target, idx, s)
    local entry = target.darkRPPocket and target.darkRPPocket[idx]
    if not entry or entry ~= s.refs[idx] or not canTake(entry) then return nil end
    local name = pocketName(entry)
    target:removePocketItem(idx)
    keep(target, { kind = "pocket", entry = entry })
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
        DarkRP.notify(checker, 0, 5, "Confiscated from " .. target:Nick() .. ": " .. list .. ".")
        DarkRP.notify(target, 1, 6, checker:Nick() .. " confiscated: " .. list .. ".")
        log("%s confiscated from %s: %s", who(checker), who(target), list)
    end
    sendList(checker)   -- the list again, without what's gone
end)

--[[---------------------------------------------------------------------------
Giving it back (Reload on them)
---------------------------------------------------------------------------]]
function RP1942.searchGiveBack(checker, target)
    local items = target.RP1942_Confiscated
    if not items or #items == 0 then
        return DarkRP.notify(checker, 1, 3, target:Nick() .. " has nothing confiscated.")
    end
    target.RP1942_Confiscated = nil
    local names = {}
    for _, it in ipairs(items) do
        if it.kind == "weapon" then
            local w = target:Give(it.class, true)   -- (no extra ammo with it)
            if IsValid(w) and it.clip and it.clip >= 0 then w:SetClip1(it.clip) end
            names[#names + 1] = RP1942.weaponName(it.class)
        elseif it.kind == "pocket" then
            -- back through their pocket, put down at their feet
            target.darkRPPocket = target.darkRPPocket or {}
            local idx = table.insert(target.darkRPPocket, it.entry) or #target.darkRPPocket
            local ok = pcall(target.dropPocketItem, target, idx)
            if ok then names[#names + 1] = pocketName(it.entry) end
        end
    end
    local list = table.concat(names, ", ")
    DarkRP.notify(checker, 0, 5, "Gave back to " .. target:Nick() .. ": " .. list .. ".")
    DarkRP.notify(target, 0, 6, checker:Nick() .. " gave back: " .. list .. " (pocket items are at your feet).")
    log("%s gave back to %s: %s", who(checker), who(target), list)
end

hook.Add("PlayerDisconnected", "RP1942_Search", function(ply) ply.RP1942_Confiscated = nil end)
