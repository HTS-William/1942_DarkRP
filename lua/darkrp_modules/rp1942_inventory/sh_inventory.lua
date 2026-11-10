--[[---------------------------------------------------------------------------
42Bros - Inventory (shared: settings and what an item looks like)

Every player has an inventory that's kept between sessions and restarts:
storage on top of the DarkRP pocket. It's the F4 menu's Inventory tab:

    Your pocket          the pocket's items by name, each with Store, and
                         Store all under them
    Your inventory       the stored items, each with To pocket and Drop

What can be stored (anything else stays in the pocket):
    goods           bread, wine, oil, parts... at their quality, up to
                    `stack` of the same good and quality in one slot. A crate
                    of goods goes in as the goods inside it.
    weapons         pocketed guns, one per slot (guns never stack), each
                    with exactly the ammo it had: its magazine and spare
                    rounds. A pocketed pile of several guns takes a slot each.
    ammo            ammo boxes, as rounds: up to `ammoStack` rounds of the
                    same ammo in a slot. Taken out as one box with all of it.

Like goods and ammo always merge: anything going in fills the slots that
already hold the same thing first, and the slots are tidied after every change.

Saved on the server only, one file per player:
    data/rp1942/inventory/<SteamID64>.json
It survives death, disconnects and restarts. It can't be used while you're
dead, arrested, being handcuffed, or for `hurtLock` seconds after you were
hurt, so it can't save loot from a fight (pockets drop on death).

Staff: !inventory <name> shows what a player has stored (ULX, 42Bros).
Every store / take / drop is logged as [42Bros][INVENTORY] (rp1942_logs).
The server side is sv_inventory.lua, the F4 tab cl_inventory.lua.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Inventory = RP1942.Inventory or {}
local INV = RP1942.Inventory

INV.config = {
    slots     = 24,    -- slots per player
    stack     = 10,    -- the same good at the same quality per slot (guns: always 1)
    ammoStack = 300,   -- rounds of the same ammo per slot
    hurtLock  = 15,    -- seconds after being hurt by a player before it opens again
}

-- How many of `item` fit in one slot (for ammo, rounds). Guns don't stack.
function INV.capOf(item)
    if item.k == "weapon" then return 1 end
    return item.k == "ammo" and INV.config.ammoStack or INV.config.stack
end

-- What a stored item is called ("Bread (fine)  x3", "Kar98k", "7.92mm Mauser  (60 rounds)")
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
    elseif item.k == "ammo" then
        local ammo = RP1942.ammoName and RP1942.ammoName(item.a) or item.a or "?"
        return ammo .. "  (" .. (item.n or 0) .. " rounds)"
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
    if a.k == "weapon" then return false end   -- guns never stack: one per slot
    if a.k == "ammo" then return a.a == b.a end
    return false
end
