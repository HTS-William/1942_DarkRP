--[[---------------------------------------------------------------------------
42Bros - Inventory (shared: settings and what an item looks like)

Every player has an inventory that's kept between sessions and restarts:
storage on top of the DarkRP pocket. It's the F4 menu's Inventory tab:

    YOUR POCKET          the pocket's items, each with STORE (and STORE ALL)
    YOUR INVENTORY       the stored items, each with TO POCKET and DROP

What can be stored (anything else stays in the pocket):
    goods           bread, wine, oil, parts... at their quality, up to
                    `stack` of the same good and quality in one slot
    weapons         a pocketed gun, with exactly the ammo it had (its magazine
                    and any spare rounds that come with it), never refilled

Saved on the server only, one file per player:
    data/rp1942/inventory/<SteamID64>.json
It survives death, disconnects and restarts. It can't be used while you're
dead, arrested, being handcuffed, or for `hurtLock` seconds after you were
hurt, so it can't save loot from a fight (pockets drop on death).

Staff: !inventory <name> shows what a player has stored (ULX, 42Bros).
The server side is sv_inventory.lua, the F4 tab cl_inventory.lua.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Inventory = RP1942.Inventory or {}
local INV = RP1942.Inventory

INV.config = {
    slots    = 24,    -- slots per player
    stack    = 10,    -- the same good at the same quality (or the same gun) per slot
    hurtLock = 15,    -- seconds after being hurt by a player before it opens again
}

-- What a stored item is called ("Bread (fine)", "Kar98k", "Wine (excellent) ×3")
function INV.label(item)
    if not istable(item) then return "?" end
    local name
    if item.k == "good" then
        local good = RP1942.Goods and RP1942.Goods[item.id]
        name = (good and good.name) or item.id or "?"
        local q = math.Clamp(tonumber(item.q) or 1, 1, 3)
        local quality = RP1942.qualityName and RP1942.qualityName(q) or (q .. " stars")
        name = name .. " (" .. quality .. ")"
    elseif item.k == "weapon" then
        local stored = weapons.GetStored(item.c or "")
        name = (stored and stored.PrintName and stored.PrintName ~= "" and stored.PrintName) or item.c or "?"
        if language and language.GetPhrase and CLIENT then name = language.GetPhrase(name) end
    else
        name = "?"
    end
    if (item.n or 1) > 1 then name = name .. "  x" .. item.n end
    return name
end

-- Can two stored items share a slot?
function INV.sameKind(a, b)
    if a.k ~= b.k then return false end
    if a.k == "good" then return a.id == b.id and a.q == b.q end
    -- a gun keeps exactly the ammo it went in with, so only identical ones share a slot
    if a.k == "weapon" then return a.c == b.c and (a.clip or -1) == (b.clip or -1) and (a.ammo or 0) == (b.ammo or 0) end
    return false
end
