--[[---------------------------------------------------------------------------
1942 DarkRP - F4 shop purchases (server)

The client only sends an item id; everything is checked here. Money is taken
only after the item was actually given or spawned.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_F4Buy")

local function spawnPos(ply) return RP1942.spawnInFront(ply, 85) end   -- rp1942_core/sv_pocket.lua

local function owned(ply, item)
    local n = 0
    local class = item.type == "good" and "rp1942_good" or item.class
    for _, e in ipairs(ents.FindByClass(class)) do
        if e.RP1942_ShopOwner == ply and (item.type ~= "good" or e:GetGood() == item.good) then n = n + 1 end
    end
    return n
end

-- Gives or spawns the item. Returns true if it worked.
local function deliver(ply, item)
    if item.type == "ammo" then
        ply:GiveAmmo(item.amount, item.ammo)
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

    if (item.type == "entity" or item.type == "good") and item.max and owned(ply, item) >= item.max then
        return DarkRP.notify(ply, 1, 4, "You can't have more than " .. item.max .. " of " .. item.name .. ".")
    end
    local price = RP1942.f4ItemPrice(item)
    if not ply:canAfford(price) then
        return DarkRP.notify(ply, 1, 4, "You can't afford " .. item.name .. " (" .. DarkRP.formatMoney(price) .. ").")
    end

    if not deliver(ply, item) then
        DarkRP.notify(ply, 1, 5, item.name .. " isn't available on this server. You were not charged.")
        MsgC(Color(255, 170, 0), "[1942] F4 shop item '", item.name, "': class '", tostring(item.class), "' does not exist.\n")
        return
    end

    ply:addMoney(-price)
    local what = item.type == "ammo" and (item.amount .. " x " .. item.name) or item.name
    DarkRP.notify(ply, 0, 4, "You bought " .. what .. " for " .. DarkRP.formatMoney(price) .. ".")
    hook.Run("RP1942_F4ShopPurchase", ply, item)
end)
