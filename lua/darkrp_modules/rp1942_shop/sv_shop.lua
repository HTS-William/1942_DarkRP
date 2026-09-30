--[[---------------------------------------------------------------------------
1942 DarkRP - shop purchases (server)

    RP1942.buyShopItem(ply, itemId, amount)
    amount 1 = one weapon; more = a crate of them (RP1942.ShopShipments)

Order of checks: the player's CURRENT job has a catalog -> the item is in
THAT catalog -> they can afford it -> it spawns -> only THEN is money taken.
Money is DarkRP's wallet: ply:canAfford / ply:addMoney.

Hook for other systems:  RP1942_ShopPurchase(ply, item, ent)
---------------------------------------------------------------------------]]
local SPAWN_DIST = 85   -- units in front of the player

local function spawnPos(ply)
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * SPAWN_DIST,
        filter = ply,
    })
    return tr.HitPos + tr.HitNormal * 12
end

-- Returns the spawned entity, or nil if the class doesn't exist
local function spawnItem(ply, item)
    local pos = spawnPos(ply)
    local ent

    if item.type == "weapon" then
        -- Probe the class first: spawned_weapon happily accepts a bad class
        -- and only fails when someone tries to pick it up
        local probe = ents.Create(item.class)
        if not IsValid(probe) then return nil end
        probe:Remove()

        ent = ents.Create("spawned_weapon")
        ent:SetModel(RP1942.getShopItemModel(item))
        ent:SetWeaponClass(item.class)
        ent.nodupe = true
        -- Comes loaded: a full magazine, or the grenade / mine / charge itself
        ent.clip1, ent.ammoadd = RP1942.weaponStartAmmo(item.class)
    else
        ent = ents.Create(item.class)
        if not IsValid(ent) then return nil end
    end

    ent:SetPos(pos)
    ent:Spawn()
    ent:Activate()
    if ent.CPPISetOwner then ent:CPPISetOwner(ply) end   -- prop protection ownership
    return ent
end

-- A crate holding `amount` of a weapon
local function spawnCrate(ply, item, amount)
    local probe = ents.Create(item.class)   -- the class must exist
    if not IsValid(probe) then return nil end
    probe:Remove()
    local crate = ents.Create("rp1942_weapon_crate")
    if not IsValid(crate) then return nil end
    crate:SetPos(spawnPos(ply) + Vector(0, 0, 10))
    crate:Spawn()
    crate:Activate()
    crate:SetWeaponClass(item.class)
    crate:SetWeaponName(item.name)
    crate:SetCount(amount)
    if crate.CPPISetOwner then crate:CPPISetOwner(ply) end
    return crate
end

function RP1942.buyShopItem(ply, itemId, amount)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:isArrested() then
        DarkRP.notify(ply, 1, 4, "You can't trade while you're under arrest.")
        return
    end
    local job = ply:getJobTable()
    local key = job and job.shop
    if not RP1942.getShopCatalog(key) then
        DarkRP.notify(ply, 1, 4, "Your job has no shop.")
        return
    end

    local item = RP1942.getShopItem(key, itemId)
    if not item then return end   -- not in this job's catalog: ignore silently

    amount = math.Clamp(math.floor(tonumber(amount) or 1), 1, (RP1942.ShopShipments and RP1942.ShopShipments.maxAmount) or 1)
    if item.type ~= "weapon" then amount = 1 end
    local unit = RP1942.getShopPrice(key, item)   -- the Supplier's follows the economy
    local price = unit * amount
    if not ply:canAfford(price) then
        DarkRP.notify(ply, 1, 4, "You can't afford " .. (amount > 1 and (amount .. "x ") or "") .. item.name .. " (" .. DarkRP.formatMoney(price) .. ").")
        return
    end

    local ent = amount > 1 and spawnCrate(ply, item, amount) or spawnItem(ply, item)
    if not IsValid(ent) then
        DarkRP.notify(ply, 1, 5, item.name .. " isn't available on this server yet. You were not charged.")
        MsgC(Color(255, 170, 0), "[1942] Shop '", key, "' item '", item.id, "': class '", item.class, "' does not exist.\n")
        return
    end

    ply:addMoney(-price)
    DarkRP.notify(ply, 0, 4, "You bought " .. (amount > 1 and ("a crate of " .. amount .. "x ") or "") .. item.name .. " for " .. DarkRP.formatMoney(price) .. ".")
    hook.Run("RP1942_ShopPurchase", ply, item, ent)
end
