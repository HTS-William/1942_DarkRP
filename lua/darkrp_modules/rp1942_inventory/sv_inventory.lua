--[[---------------------------------------------------------------------------
42Bros - Inventory (server). Settings and the item format: sh_inventory.lua

    RP1942_Inv       client -> server   "sync" | "store" i | "storeall" | "take" s | "drop" s
    RP1942_InvSync   server -> client   the inventory, the pocket, and why it's locked

A stored item is a plain table, saved as JSON (file version 2):
    { k = "good",   id = "bread", q = 1-3, n = count }
    { k = "weapon", c = class, n = 1, clip = .., clip2 = .., ammo = .. }
                    one gun per slot; a version 1 file's stacked guns are
                    split into a slot each, their ammo shared out evenly
    { k = "ammo",   a = ammo type, n = rounds }

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
-- A gun's magazine when nothing says otherwise: full (melee and the like: 0)
local function fullClip(class, secondary)
    local stored = weapons.GetStored(class or "")
    local t = stored and (secondary and stored.Secondary or stored.Primary)
    local size = t and tonumber(t.ClipSize) or 0
    return size > 0 and size or 0
end

-- Anything odd in a file (edited by hand, a good that no longer exists) is left out.
-- perGun: a version 1 file, whose weapon ammo was per gun rather than per slot.
local function clean(item, perGun)
    if not istable(item) then return nil end
    local n = math.max(1, math.floor(tonumber(item.n) or 1))
    if item.k == "good" and isstring(item.id) and RP1942.Goods and RP1942.Goods[item.id] then
        return { k = "good", id = item.id, q = math.Clamp(math.floor(tonumber(item.q) or 1), 1, 3), n = math.min(n, CFG.stack) }
    elseif item.k == "weapon" and isstring(item.c) and item.c ~= "" then
        n = math.min(n, CFG.stack)
        local mult = perGun and n or 1
        local clip = tonumber(item.clip) and math.floor(item.clip) * mult or fullClip(item.c) * n
        return { k = "weapon", c = item.c, n = n,
            clip = fullClip(item.c) > 0 and math.Clamp(clip, 0, fullClip(item.c) * n) or math.max(0, clip),
            clip2 = tonumber(item.clip2) and math.max(0, math.floor(item.clip2) * mult) or nil,
            ammo = math.max(0, math.floor(tonumber(item.ammo) or 0) * mult) }
    elseif item.k == "ammo" and isstring(item.a) and item.a ~= "" and #item.a <= 64 then
        return { k = "ammo", a = item.a, n = math.min(n, CFG.ammoStack) }
    end
end

local compact   -- (below)

local function load(ply)
    local items = {}
    local raw = file.Read(fileOf(ply), "DATA")
    local data = raw and util.JSONToTable(raw)
    if istable(data) and istable(data.items) then
        local perGun = (tonumber(data.v) or 1) < 2
        for _, it in ipairs(data.items) do
            local c = clean(it, perGun)
            if c and #items < CFG.slots then items[#items + 1] = c end
        end
    end
    ply.RP1942_Inv = compact(items)
    return ply.RP1942_Inv
end

local function save(ply)
    if not ply.RP1942_Inv then return end
    file.Write(fileOf(ply), util.TableToJSON({ v = 2, items = ply.RP1942_Inv }))
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
    if entry.Class == "rp1942_good" or entry.Class == "rp1942_goods_crate" then
        local id = dt.Good
        if isstring(id) and RP1942.Goods[id] then
            local n = entry.Class == "rp1942_goods_crate" and math.max(1, math.floor(tonumber(dt.Count) or 1)) or 1
            return { k = "good", id = id, q = math.Clamp(tonumber(dt.Quality) or 1, 1, 3), n = n }
        end
    elseif entry.Class == "spawned_weapon" then
        local class = dt.WeaponClass
        if isstring(class) and class ~= "" then
            local n = math.max(1, math.floor(tonumber(dt.amount) or 1))
            -- DarkRP keeps a gun's magazine and spare rounds per gun: the slot keeps totals
            local clip = tonumber(entry.clip1) and math.floor(entry.clip1) or fullClip(class)
            return { k = "weapon", c = class, n = n,
                clip = math.max(0, clip) * n,
                clip2 = tonumber(entry.clip2) and math.max(0, math.floor(entry.clip2)) * n or nil,
                ammo = math.max(0, math.floor(tonumber(entry.ammoadd) or 0)) * n }
        end
    elseif entry.Class == "rp1942_ammo_box" then
        local a, n = dt.AmmoType, math.floor(tonumber(dt.Amount) or 0)
        if isstring(a) and a ~= "" and n > 0 then return { k = "ammo", a = a, n = n } end
    end
end
INV.fromPocket = fromPocket

-- A stored item made into a real entity at pos, for ply
local function makeEntity(ply, item, pos)
    if item.k == "good" then
        local ent = RP1942.spawnGood and RP1942.spawnGood(item.id, pos, nil, item.q)
        if not IsValid(ent) then return nil end
        ent.RP1942_Holder = ply
        if ent.SetOwnerPlayer then ent:SetOwnerPlayer(ply) end   -- food: theirs to eat or sell
        ent.RP1942_NoStackUntil = CurTime() + 2   -- (not straight back into a crate it lands on)
        return ent
    elseif item.k == "weapon" then
        if not RP1942.weaponExists(item.c) then return nil end
        local ent = RP1942.makeSpawnedWeapon(item.c, pos, item.clip)
        if not IsValid(ent) then return nil end
        ent.clip2 = item.clip2
        ent.ammoadd = item.ammo or 0   -- exactly its share of what went in, not a fresh load
        return ent
    elseif item.k == "ammo" then
        return RP1942.makeAmmoBox and RP1942.makeAmmoBox(item.a, item.n, pos) or nil
    end
end

--[[---------------------------------------------------------------------------
Stacking. Every item is `n` units (goods, guns, or rounds of ammo), at most
INV.capOf(item) in a slot (guns: 1). A pocketed pile of guns comes in as one
item whose clip / clip2 / ammo are totals; splitting it into a slot per gun
shares them out exactly, so nothing is lost or made.
---------------------------------------------------------------------------]]
local POOLED = { "clip", "clip2", "ammo" }

-- Take k units off `item` as a new item (item keeps the rest)
local function split(item, k)
    local piece = table.Copy(item)
    piece.n = k
    for _, f in ipairs(POOLED) do
        if item[f] then
            piece[f] = math.floor(item[f] * k / item.n)
            item[f] = item[f] - piece[f]
        end
    end
    item.n = item.n - k
    return piece
end

-- Add `piece` into `into` (the same kind)
local function merge(into, piece)
    into.n = into.n + piece.n
    for _, f in ipairs(POOLED) do
        if into[f] or piece[f] then into[f] = (into[f] or 0) + (piece[f] or 0) end
    end
end

-- Put `item` into `items`: topping up the slots of the same kind first, then new slots
local function fill(items, item)
    for _, slot in ipairs(items) do
        if item.n <= 0 then return end
        local cap = INV.capOf(slot)
        if INV.sameKind(slot, item) and slot.n < cap then
            local k = math.min(cap - slot.n, item.n)
            if k == item.n then
                merge(slot, table.Copy(item))   -- all of it
                item.n = 0
            else
                merge(slot, split(item, k))     -- part of it (split leaves the rest in item)
            end
        end
    end
    while item.n > 0 do
        local k = math.min(INV.capOf(item), item.n)
        if k == item.n then
            items[#items + 1] = table.Copy(item)
            item.n = 0
        else
            items[#items + 1] = split(item, k)
        end
    end
end

-- Is there room for all of `item`?
local function canAdd(items, item)
    local room = (CFG.slots - #items) * INV.capOf(item)
    for _, slot in ipairs(items) do
        if INV.sameKind(slot, item) then room = room + math.max(0, INV.capOf(slot) - slot.n) end
    end
    return room >= item.n
end

-- The same items with like ones merged into as few slots as they fit
compact = function(items)
    local out = {}
    for _, it in ipairs(items) do fill(out, table.Copy(it)) end
    -- (an old file whose stacked guns now take a slot each can end up over
    -- the limit: nothing is thrown away, it just can't take more until there's room)
    return out
end
INV.compact = compact

--[[---------------------------------------------------------------------------
What anything in a pocket is called (the Inventory tab's pocket list)
---------------------------------------------------------------------------]]
local function prettyModel(model)
    local name = string.GetFileFromFilename(model or ""):gsub("%.mdl$", ""):gsub("[_%-]", " ")
    name = name:gsub("(%l)(%u)", "%1 %2")
    return name ~= "" and (name:sub(1, 1):upper() .. name:sub(2)) or nil
end

function INV.pocketLabel(entry)
    local item = fromPocket(entry)
    if item then
        if entry.Class == "rp1942_goods_crate" then return "Crate: " .. INV.label(item) end
        return INV.label(item)
    end
    local dt, class = entry.DT or {}, entry.Class or ""
    if class == "spawned_shipment" then
        local ship = CustomShipments and CustomShipments[tonumber(dt.contents) or 0]
        return "Shipment: " .. (ship and ship.name or "?") .. "  x" .. (tonumber(dt.count) or 0)
    elseif class == "spawned_money" then
        return DarkRP.formatMoney(tonumber(dt.amount) or 0)
    end
    local sent = scripted_ents.GetStored(class)
    local printName = sent and sent.t and sent.t.PrintName
    if isstring(printName) and printName ~= "" and printName ~= "Scripted Entity" then return printName end
    return prettyModel(entry.Model) or class
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
        list[#list + 1] = { i = idx, label = INV.pocketLabel(entry), ok = fromPocket(entry) ~= nil }
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
        RP1942.log("INVENTORY", "%s %s %s", ply:Nick(), what, INV.label({ k = item.k, id = item.id, q = item.q, c = item.c, a = item.a, n = n or item.n or 1 }))
    end
end

-- Pocket -> inventory. Returns true if it went in.
local function store(ply, idx, quiet)
    local pocket = ply.darkRPPocket
    local entry = pocket and pocket[idx]
    if not entry then return false end
    local item = fromPocket(entry)
    if not item then
        if not quiet then DarkRP.notify(ply, 1, 4, "That can't go in your inventory: only goods, weapons and ammo can.") end
        return false
    end
    local items = RP1942.inventoryOf(ply)
    if not canAdd(items, item) then
        if not quiet then DarkRP.notify(ply, 1, 4, "There isn't room for that in your inventory (" .. CFG.slots .. " slots).") end
        return false
    end
    -- out of the pocket first, then into the inventory
    ply:removePocketItem(idx)
    local n = item.n
    fill(items, item)
    save(ply)
    log(ply, "stored", item, n)
    return true
end

-- Out of slot `s`: into the pocket (toPocket) or onto the ground in front.
-- Goods and guns come out one at a time, ammo as one box with all of it.
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
    local k = item.k == "ammo" and item.n or 1
    local whole = k >= item.n
    local one = whole and table.Copy(item) or split(item, k)
    if whole then table.remove(items, s) end
    save(ply)
    -- ...then made real
    local pos = toPocket and (ply:GetPos() + Vector(0, 0, 40)) or RP1942.spawnInFront(ply, 60)
    local ent = makeEntity(ply, one, pos)
    if not IsValid(ent) then
        -- couldn't be made (shouldn't happen): put it back
        if canAdd(items, one) then fill(items, one) save(ply) end
        return DarkRP.notify(ply, 1, 4, "That couldn't be taken out right now.")
    end
    if toPocket and not RP1942.pocketOrLeave(ply, ent) then
        ent:SetPos(RP1942.spawnInFront(ply, 60))   -- pocket filled up meanwhile: in front of you
    end
    log(ply, toPocket and "took" or "dropped", one, one.n)
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
        if stored == 0 and skipped > 0 then DarkRP.notify(ply, 1, 4, "Nothing in your pocket can go in (only goods, weapons and ammo can, and only while there's room).") end
    elseif action == "take" then
        takeOut(ply, n, true)
    elseif action == "drop" then
        takeOut(ply, n, false)
    end
    ply.RP1942_Inv = compact(RP1942.inventoryOf(ply))   -- like items always end up together
    save(ply)
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
