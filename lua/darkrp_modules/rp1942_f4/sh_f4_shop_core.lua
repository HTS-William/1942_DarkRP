--[[---------------------------------------------------------------------------
1942 DarkRP - F4 shop logic (shared; the items are in sh_f4_shop.lua)

    RP1942.getF4ShopItems()        every item, each with a unique .id
    RP1942.getF4ShopItem(id)
    RP1942.canBuyF4Item(ply, item) -> true | false, reason

Built the same way on server and client, from the same data, so an item's
id means the same thing on both. Weapons (for the automatic ammo) only exist
once the game has loaded them, so the list is built after that.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local cache, byId

local function round10(n) return math.floor(n / 10 + 0.5) * 10 end

-- "ammo_792x57_mauser" -> "Ammo 792x57 Mauser" unless the game has a proper name
local function ammoName(ammo)
    if CLIENT then
        local key = "#" .. ammo .. "_ammo"
        local phrase = language.GetPhrase(key)
        if phrase and phrase ~= key and phrase ~= (ammo .. "_ammo") then return phrase end
    end
    local pretty = string.gsub(ammo, "_", " ")
    return (string.gsub(pretty, "(%a)([%w]*)", function(a, b) return string.upper(a) .. b end))
end

-- Price of a weapon, as the dealers would sell it before their own markup
local function basePrice(class)
    local cats = {}
    for _, c in ipairs(RP1942.ShopWeaponCategories or {}) do cats[c.name] = c.price end
    for _, w in ipairs(RP1942.ShopWeapons or {}) do
        if w.class == class then return w.price or cats[w.category] or 1000 end
    end
    return 1000
end

-- ammo type -> { biggest magazine, most expensive weapon price, weapon names }
local function scanAmmo(cfg)
    local classes, seen = {}, {}
    local function add(class) if class and not seen[class] then seen[class] = true; classes[#classes + 1] = class end end
    for _, w in ipairs(RP1942.ShopWeapons or {}) do add(w.class) end
    for _, job in ipairs(RPExtraTeams or {}) do for _, c in ipairs(job.weapons or {}) do add(c) end end
    for _, c in ipairs(cfg.extraWeapons or {}) do add(c) end

    local found = {}
    for _, class in ipairs(classes) do
        local wep = weapons.Get(class)
        local p = wep and wep.Primary
        local ammo, clip = p and p.Ammo, p and tonumber(p.ClipSize) or -1
        -- clip <= 0: melee and throwables (grenades are bought as weapons, not ammo)
        if ammo and ammo ~= "" and string.lower(ammo) ~= "none" and clip > 0 then
            local f = found[ammo] or { clip = 0, price = 0, users = {} }
            f.clip = math.max(f.clip, clip)
            f.price = math.max(f.price, basePrice(class))
            f.users[#f.users + 1] = (wep.PrintName and wep.PrintName ~= "") and wep.PrintName or class
            found[ammo] = f
        end
    end
    return found
end

local function build()
    local list, index = {}, {}
    local shop = RP1942.F4Shop or {}

    for i, it in ipairs(shop.items or {}) do
        local item = table.Copy(it)
        item.id = "item:" .. i
        item.category = item.category or "Supplies"
        list[#list + 1] = item
    end

    local cfg = shop.ammo
    if cfg and cfg.enabled then
        local found = scanAmmo(cfg)
        local types = table.GetKeys(found)
        table.sort(types)
        for _, ammo in ipairs(types) do
            local f, o = found[ammo], (cfg.overrides or {})[ammo] or {}
            if not o.hidden then
                local amount = o.amount or math.min(f.clip * (cfg.clipsPerBox or 2), cfg.maxPerBox or 150)
                local mags = amount / f.clip
                local users = table.concat(f.users, ", ", 1, math.min(#f.users, 4))
                if #f.users > 4 then users = users .. " and " .. (#f.users - 4) .. " more" end
                list[#list + 1] = {
                    id = "ammo:" .. ammo, type = "ammo", ammo = ammo, amount = amount,
                    name = o.name or ammoName(ammo),
                    price = o.price or math.max(cfg.minPrice or 20, round10(mags * f.price * (cfg.priceShare or 0.08))),
                    category = cfg.category or "Ammunition",
                    model = o.model or cfg.model,
                    description = "For: " .. users,
                }
            end
        end
    end

    for _, item in ipairs(list) do index[item.id] = item end
    return list, index
end

function RP1942.getF4ShopItems()
    if not cache then
        local list, index = build()
        if not RP1942.F4ShopReady then return list end   -- weapons not loaded yet: don't keep it
        cache, byId = list, index
    end
    return cache
end

function RP1942.getF4ShopItem(id)
    RP1942.getF4ShopItems()
    return byId and byId[id] or nil
end

function RP1942.canBuyF4Item(ply, item)
    if item.jobs then
        local job = RPExtraTeams[ply:Team()]
        if not (job and table.HasValue(item.jobs, job.command)) then
            return false, "Your job can't buy " .. item.name .. "."
        end
    end
    return true
end

hook.Add("InitPostEntity", "RP1942_F4ShopReady", function()
    RP1942.F4ShopReady = true
    cache, byId = nil, nil
end)

-- What the automatic ammo found (both realms)
concommand.Add("rp1942_listammo", function(ply)
    if SERVER and IsValid(ply) and not ply:IsAdmin() then return end
    local found = scanAmmo((RP1942.F4Shop or {}).ammo or {})
    local types = table.GetKeys(found)
    table.sort(types)
    print(string.format("[1942] %d ammo types found:", #types))
    for _, ammo in ipairs(types) do
        local f = found[ammo]
        print(string.format("  %-28s magazine %3d   used by: %s", ammo, f.clip, table.concat(f.users, ", ")))
    end
end)
