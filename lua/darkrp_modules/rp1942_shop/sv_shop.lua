--[[---------------------------------------------------------------------------
1942 DarkRP - shop purchases (server)

    RP1942.buyShopItem(ply, itemId)

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

function RP1942.buyShopItem(ply, itemId)
    local job = ply:getJobTable()
    local key = job and job.shop
    if not RP1942.getShopCatalog(key) then
        DarkRP.notify(ply, 1, 4, "Your job has no shop.")
        return
    end

    local item = RP1942.getShopItem(key, itemId)
    if not item then return end   -- not in this job's catalog: ignore silently

    if not ply:canAfford(item.price) then
        DarkRP.notify(ply, 1, 4, "You can't afford " .. item.name .. " (" .. DarkRP.formatMoney(item.price) .. ").")
        return
    end

    local ent = spawnItem(ply, item)
    if not IsValid(ent) then
        DarkRP.notify(ply, 1, 5, item.name .. " isn't available on this server yet. You were not charged.")
        MsgC(Color(255, 170, 0), "[1942] Shop '", key, "' item '", item.id, "': class '", item.class, "' does not exist.\n")
        return
    end

    ply:addMoney(-item.price)
    DarkRP.notify(ply, 0, 4, "You bought " .. item.name .. " for " .. DarkRP.formatMoney(item.price) .. ".")
    hook.Run("RP1942_ShopPurchase", ply, item, ent)
end
