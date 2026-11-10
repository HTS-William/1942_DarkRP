--[[---------------------------------------------------------------------------
42Bros - F4 shop purchases (server)

The client only sends an item id; everything is checked here. Money is taken
only after the item was actually given or spawned.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_F4Buy")

local function spawnPos(ply) return RP1942.spawnInFront(ply, 85) end   -- rp1942_core/sv_pocket.lua

-- Bought ammo arrives as a labelled box on the ground (rp1942_ammo_box), not
-- straight into your weapon. At most this many unopened boxes each, so the
-- shop can't be spammed into a pile of them. Boxes that merged count as all
-- the boxes in them, and a crate of shop goods as all the goods in it.
local MAX_AMMO_BOXES = 5

local function ammoBoxesOf(ply)
    local n = 0
    for _, e in ipairs(ents.FindByClass("rp1942_ammo_box")) do
        if e.RP1942_ShopOwner == ply then n = n + (e.RP1942_Boxes or 1) end   -- merged boxes still count
    end
    return n
end

local function owned(ply, item)
    -- a Radio Set: every radio they have, pocket and inventory included (rp1942_radio)
    local good = item.type == "good" and RP1942.Goods and RP1942.Goods[item.good]
    if good and good.radio and RP1942.radiosHeld then return RP1942.radiosHeld(ply) end
    local n = 0
    local classes = item.type == "good" and { "rp1942_good", "rp1942_goods_crate" } or { item.class }
    for _, class in ipairs(classes) do
        for _, e in ipairs(ents.FindByClass(class)) do
            if e.RP1942_ShopOwner == ply and (item.type ~= "good" or e:GetGood() == item.good) then
                n = n + (RP1942.goodCount and RP1942.goodCount(e) or 1)   -- a crate counts what's in it
            end
        end
    end
    return n
end

-- Gives or spawns the item. Returns true if it worked.
local function deliver(ply, item)
    if item.type == "ammo" then
        local box = RP1942.makeAmmoBox and RP1942.makeAmmoBox(item.ammo, item.amount, spawnPos(ply))
        if not IsValid(box) then return false end
        box.RP1942_ShopOwner = ply   -- only the buyer opens it (rp1942_ammo_box)
        if box.CPPISetOwner then box:CPPISetOwner(ply) end   -- and it goes when they leave
        return true
    end

    local ent
    if item.type == "good" then
        ent = RP1942.spawnGood and RP1942.spawnGood(item.good, spawnPos(ply), nil, item.quality or 3)
        if not IsValid(ent) then return false end
        ent.RP1942_Holder = ply
        ent.RP1942_ShopOwner = ply
        return true
    elseif item.type == "weapon" then
        -- the same as the dealers' guns: loaded, if it takes ammo (rp1942_core/sv_pocket.lua)
        if not RP1942.weaponExists(item.class) then return false end
        ent = RP1942.makeSpawnedWeapon(item.class, spawnPos(ply), nil, item.model)
        if not IsValid(ent) then return false end
    else
        ent = ents.Create(item.class)
        if not IsValid(ent) then return false end
        ent:SetPos(spawnPos(ply))
        ent:Spawn()
    end

    ent:Activate()
    ent.RP1942_ShopOwner = ply
    if ent.Setowning_ent then ent:Setowning_ent(ply) end
    if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
    return true
end

net.Receive("RP1942_F4Buy", function(_, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local now = CurTime()
    if (ply.RP1942_NextF4Buy or 0) > now then return end
    ply.RP1942_NextF4Buy = now + 0.3

    local item = RP1942.getF4ShopItem(net.ReadString())
    if not item then return end
    if ply:isArrested() then return DarkRP.notify(ply, 1, 4, "You can't buy anything while you're under arrest.") end

    local ok, why = RP1942.canBuyF4Item(ply, item)
    if not ok then return DarkRP.notify(ply, 1, 4, why) end

    local max = item.max
    local good = item.type == "good" and RP1942.Goods and RP1942.Goods[item.good]
    if good and good.radio and RP1942.radioSetting then max = RP1942.radioSetting("perPlayer") or max end
    if (item.type == "entity" or item.type == "good") and max and owned(ply, item) >= max then
        return DarkRP.notify(ply, 1, 4, "You can't have more than " .. max .. " of " .. item.name
            .. (good and good.radio and " (counting the ones in your pocket and inventory)." or "."))
    end
    if item.type == "ammo" and ammoBoxesOf(ply) >= MAX_AMMO_BOXES then
        return DarkRP.notify(ply, 1, 4, "Pick up the ammo you've already bought first (" .. MAX_AMMO_BOXES .. " boxes are waiting for you).")
    end
    local price = RP1942.f4ItemPrice(item)
    if not ply:canAfford(price) then
        return DarkRP.notify(ply, 1, 4, "You can't afford " .. item.name .. " (" .. DarkRP.formatMoney(price) .. ").")
    end

    if not deliver(ply, item) then
        DarkRP.notify(ply, 1, 5, item.name .. " isn't available on this server. You were not charged.")
        MsgC(Color(255, 170, 0), "[42Bros] F4 shop item '", item.name, "': class '", tostring(item.class), "' does not exist.\n")
        return
    end

    ply:addMoney(-price)
    local what = item.type == "ammo" and (item.amount .. " x " .. item.name) or item.name
    DarkRP.notify(ply, 0, 4, "You bought " .. what .. " for " .. DarkRP.formatMoney(price) .. "." .. (item.type == "ammo" and " Press E on the box to take it." or ""))
    hook.Run("RP1942_F4ShopPurchase", ply, item, price)
end)
