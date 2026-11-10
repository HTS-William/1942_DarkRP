--[[---------------------------------------------------------------------------
42Bros - Inventory (server). Settings and the item format: sh_inventory.lua

    RP1942_Inv       client -> server   "sync" | "store" i | "storeall" | "take" s | "drop" s
    RP1942_InvSync   server -> client   the inventory, the pocket, and why it's locked

A stored item is a plain table, saved as JSON:
    { k = "good",   id = "bread", q = 1-3, n = count }
    { k = "weapon", c = class, clip = magazine, clip2 = ..., ammo = spare rounds, n = count }

Moving is done so nothing can be copied: the item leaves where it was (and
the inventory file is written) before it appears anywhere else. A crash in
between loses at most that one item, never makes two.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_Inv")
util.AddNetworkString("RP1942_InvSync")

local INV = RP1942.Inventory
local CFG = INV.config
local DIR = "rp1942/inventory"
file.CreateDir("rp1942")
file.CreateDir(DIR)

local function fileOf(ply) return DIR .. "/" .. ply:SteamID64() .. ".json" end

--[[---------------------------------------------------------------------------
Loading and saving
---------------------------------------------------------------------------]]
-- Anything odd in a file (edited by hand, a good that no longer exists) is left out
local function clean(item)
    if not istable(item) then return nil end
    local n = math.Clamp(math.floor(tonumber(item.n) or 1), 1, CFG.stack)
    if item.k == "good" and isstring(item.id) and RP1942.Goods and RP1942.Goods[item.id] then
        return { k = "good", id = item.id, q = math.Clamp(math.floor(tonumber(item.q) or 1), 1, 3), n = n }
    elseif item.k == "weapon" and isstring(item.c) and item.c ~= "" then
        return { k = "weapon", c = item.c, n = n,
            clip = tonumber(item.clip) and math.floor(item.clip) or nil,
            clip2 = tonumber(item.clip2) and math.floor(item.clip2) or nil,
            ammo = math.max(0, math.floor(tonumber(item.ammo) or 0)) }
    end
end

local function load(ply)
    local items = {}
    local raw = file.Read(fileOf(ply), "DATA")
    local data = raw and util.JSONToTable(raw)
    if istable(data) and istable(data.items) then
        for _, it in ipairs(data.items) do
            local c = clean(it)
            if c and #items < CFG.slots then items[#items + 1] = c end
        end
    end
    ply.RP1942_Inv = items
    return items
end

local function save(ply)
    if not ply.RP1942_Inv then return end
    file.Write(fileOf(ply), util.TableToJSON({ v = 1, items = ply.RP1942_Inv }))
end

function RP1942.inventoryOf(ply)
    if not IsValid(ply) or ply:IsBot() then return {} end
    return ply.RP1942_Inv or load(ply)
end

hook.Add("PlayerInitialSpawn", "RP1942_Inventory", function(ply) if not ply:IsBot() then load(ply) end end)

--[[---------------------------------------------------------------------------
Pocket items <-> stored items
---------------------------------------------------------------------------]]
-- A DarkRP pocket entry (its saved copy of the entity) as a stored item, or nil
local function fromPocket(entry)
    if not istable(entry) then return nil end
    local dt = entry.DT or {}
    if entry.Class == "rp1942_good" then
        local id = dt.Good
        if isstring(id) and RP1942.Goods[id] then
            return { k = "good", id = id, q = math.Clamp(tonumber(dt.Quality) or 1, 1, 3), n = 1 }
        end
    elseif entry.Class == "spawned_weapon" then
        local class = dt.WeaponClass
        if isstring(class) and class ~= "" then
            return { k = "weapon", c = class, n = math.Clamp(tonumber(dt.amount) or 1, 1, CFG.stack),
                clip = tonumber(entry.clip1), clip2 = tonumber(entry.clip2), ammo = math.max(0, tonumber(entry.ammoadd) or 0) }
        end
    end
end
INV.fromPocket = fromPocket

-- A stored item (one of it) made into a real entity at pos, owned by ply
local function makeEntity(ply, item, pos)
    if item.k == "good" then
        local ent = RP1942.spawnGood and RP1942.spawnGood(item.id, pos, nil, item.q)
        if not IsValid(ent) then return nil end
        ent.RP1942_Holder = ply
        if ent.SetOwnerPlayer then ent:SetOwnerPlayer(ply) end   -- food: theirs to eat or sell
        return ent
    elseif item.k == "weapon" then
        if not RP1942.weaponExists(item.c) then return nil end
        local ent = RP1942.makeSpawnedWeapon(item.c, pos, item.clip)
        if not IsValid(ent) then return nil end
        ent.clip2 = item.clip2
        ent.ammoadd = item.ammo or 0   -- exactly what it went in with, not a fresh load
        return ent
    end
end

-- Where `item` would go: a slot with the same thing and room, or a new slot
local function slotFor(items, item)
    for i, it in ipairs(items) do
        if INV.sameKind(it, item) and (it.n or 1) + (item.n or 1) <= CFG.stack then return i end
    end
    if #items < CFG.slots then return #items + 1 end
end

--[[---------------------------------------------------------------------------
When it's locked
---------------------------------------------------------------------------]]
function INV.lockedReason(ply)
    if not IsValid(ply) or not ply:Alive() then return "You can't use your inventory while you're dead." end
    if ply.isArrested and ply:isArrested() then return "You can't use your inventory while you're under arrest." end
    if RP1942.isBeingCuffed and RP1942.isBeingCuffed(ply) then return "You can't use your inventory while you're being handcuffed." end
    local since = CurTime() - (ply.RP1942_LastHurt or -1000)
    if since < CFG.hurtLock then
        return "You were just hurt: your inventory opens again in " .. math.ceil(CFG.hurtLock - since) .. " seconds."
    end
end

--[[---------------------------------------------------------------------------
Telling the client
---------------------------------------------------------------------------]]
local function pocketList(ply)
    local list = {}
    for idx, entry in pairs(ply.darkRPPocket or {}) do
        local item = fromPocket(entry)
        local label = item and INV.label(item) or (entry.Class == "spawned_shipment" and "A shipment") or (entry.Model and string.GetFileFromFilename(entry.Model):gsub("%.mdl$", "")) or entry.Class or "?"
        list[#list + 1] = { i = idx, label = label, ok = item ~= nil }
    end
    table.sort(list, function(a, b) return a.i < b.i end)
    return list
end

local function sync(ply)
    if not IsValid(ply) then return end
    local items = RP1942.inventoryOf(ply)
    net.Start("RP1942_InvSync")
    net.WriteTable({
        items = items,
        slots = CFG.slots,
        pocket = pocketList(ply),
        pocketRoom = RP1942.pocketRoom(ply),
        locked = INV.lockedReason(ply),
    })
    net.Send(ply)
end
INV.sync = sync

-- The pocket changed some other way: refresh an open tab
local function later(ply)
    if not IsValid(ply) or not ply.RP1942_InvOpen then return end
    timer.Create("RP1942_InvSync_" .. ply:EntIndex(), 0, 1, function() sync(ply) end)
end
hook.Add("onPocketItemAdded", "RP1942_Inventory", function(ply) later(ply) end)
hook.Add("onPocketItemRemoved", "RP1942_Inventory", function(ply) later(ply) end)
hook.Add("onPocketItemDropped", "RP1942_Inventory", function(ply) later(ply) end)

--[[---------------------------------------------------------------------------
The actions
---------------------------------------------------------------------------]]
local function log(ply, what, item, n)
    if RP1942.log then
        RP1942.log("INVENTORY", "%s %s %s", ply:Nick(), what, INV.label({ k = item.k, id = item.id, q = item.q, c = item.c, n = n or 1 }))
    end
end

-- Pocket -> inventory. Returns true if it went in.
local function store(ply, idx, quiet)
    local pocket = ply.darkRPPocket
    local entry = pocket and pocket[idx]
    if not entry then return false end
    local item = fromPocket(entry)
    if not item then
        if not quiet then DarkRP.notify(ply, 1, 4, "That can't go in your inventory: only goods and weapons can.") end
        return false
    end
    local items = RP1942.inventoryOf(ply)
    local slot = slotFor(items, item)
    if not slot then
        if not quiet then DarkRP.notify(ply, 1, 4, "Your inventory is full (" .. CFG.slots .. " slots).") end
        return false
    end
    -- out of the pocket first, then into the inventory
    ply:removePocketItem(idx)
    if items[slot] then
        items[slot].n = (items[slot].n or 1) + (item.n or 1)
    else
        items[slot] = item
    end
    save(ply)
    log(ply, "stored", item, item.n)
    return true
end

-- One of slot `s` out of the inventory: into the pocket (toPocket) or onto the ground in front
local function takeOut(ply, s, toPocket)
    local items = RP1942.inventoryOf(ply)
    local item = items[s]
    if not item then return end
    if toPocket and RP1942.pocketRoom(ply) <= 0 then
        return DarkRP.notify(ply, 1, 4, "Your pocket is full.")
    end
    if item.k == "weapon" and not RP1942.weaponExists(item.c) then
        return DarkRP.notify(ply, 1, 5, "That weapon isn't installed on the server any more, so it stays stored.")
    end
    -- out of the inventory (and saved) first...
    local one = table.Copy(item)
    one.n = 1
    if (item.n or 1) > 1 then item.n = item.n - 1 else table.remove(items, s) end
    save(ply)
    -- ...then made real
    local pos = toPocket and (ply:GetPos() + Vector(0, 0, 40)) or RP1942.spawnInFront(ply, 60)
    local ent = makeEntity(ply, one, pos)
    if not IsValid(ent) then
        -- couldn't be made (shouldn't happen): put it back
        local back = slotFor(items, one)
        if back then
            if items[back] then items[back].n = (items[back].n or 1) + 1 else items[back] = one end
            save(ply)
        end
        return DarkRP.notify(ply, 1, 4, "That couldn't be taken out right now.")
    end
    if toPocket and not RP1942.pocketOrLeave(ply, ent) then
        ent:SetPos(RP1942.spawnInFront(ply, 60))   -- pocket filled up meanwhile: in front of you
    end
    log(ply, toPocket and "took" or "dropped", one, 1)
end

net.Receive("RP1942_Inv", function(_, ply)
    if not IsValid(ply) then return end
    local action = net.ReadString()
    local n = net.ReadUInt(16)
    local now = CurTime()

    -- the tab asking for the lists (it does every 2 s while open) has its own limit
    if action == "sync" then
        if (ply.RP1942_NextInvSync or 0) > now then return end
        ply.RP1942_NextInvSync = now + 0.5
        ply.RP1942_InvOpen = true
        return sync(ply)
    elseif action == "close" then
        ply.RP1942_InvOpen = nil
        return
    end

    if (ply.RP1942_NextInv or 0) > now then return end
    ply.RP1942_NextInv = now + 0.2

    local why = INV.lockedReason(ply)
    if why then
        DarkRP.notify(ply, 1, 4, why)
        return sync(ply)
    end

    if action == "store" then
        store(ply, n)
    elseif action == "storeall" then
        local stored, skipped = 0, 0
        local keys = table.GetKeys(ply.darkRPPocket or {})
        table.sort(keys)
        for _, idx in ipairs(keys) do
            if store(ply, idx, true) then stored = stored + 1 else skipped = skipped + 1 end
        end
        if stored > 0 then DarkRP.notify(ply, 0, 4, "Stored " .. stored .. " item(s)" .. (skipped > 0 and (", " .. skipped .. " couldn't go in") or "") .. ".") end
        if stored == 0 and skipped > 0 then DarkRP.notify(ply, 1, 4, "Nothing in your pocket can go in (only goods and weapons can, and only while there's room).") end
    elseif action == "take" then
        takeOut(ply, n, true)
    elseif action == "drop" then
        takeOut(ply, n, false)
    end
    sync(ply)
end)

hook.Add("PlayerDisconnected", "RP1942_Inventory", function(ply) save(ply) end)
hook.Add("ShutDown", "RP1942_Inventory", function()
    for _, p in ipairs(player.GetAll()) do save(p) end
end)

-- For staff (!inventory) and other modules
function INV.describe(ply)
    local items = RP1942.inventoryOf(ply)
    if #items == 0 then return "nothing stored" end
    local parts = {}
    for _, it in ipairs(items) do parts[#parts + 1] = INV.label(it) end
    return #items .. "/" .. CFG.slots .. " slots: " .. table.concat(parts, ", ")
end

-- How many Radio Sets a player has stored (the one-radio limit, rp1942_radio)
function INV.radios(ply)
    local n = 0
    for _, it in ipairs(RP1942.inventoryOf(ply)) do
        local good = it.k == "good" and RP1942.Goods[it.id]
        if good and good.radio then n = n + (it.n or 1) end
    end
    return n
end
