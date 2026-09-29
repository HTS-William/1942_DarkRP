--[[---------------------------------------------------------------------------
1942 DarkRP - the period ammo types (shared)

Replaces Half-Life 2's ammo (Pistol, SMG1, AR2...) for the weapon pack. Each
type is registered with the game (if nothing registered it already) and gets
a proper name for the HUD and menus.

    RP1942.AmmoTypes          the list: { id, name }  (in this order)
    RP1942.ammoName(id)       "792x57mm" -> "7.92×57mm Mauser"

What the F4 Shop sells of each (box size, price): RP1942.F4Shop.ammo in
rp1942_f4/sh_f4_shop.lua. Dumpster ammo: rp1942_dumpster/config.lua.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.AmmoTypes = {
    -- German
    { id = "792x33mmkurz",        name = "7.92×33mm Kurz" },
    { id = "792x57mm",            name = "7.92×57mm Mauser" },
    { id = "9mmluger",            name = "9×19mm Parabellum" },
    { id = "380acp",              name = ".380 ACP" },
    { id = "763mauser",           name = "7.63×25mm Mauser" },
    { id = "8mmnambu",            name = "8mm Nambu" },
    { id = "145x114",             name = "14.5×114mm" },
    { id = "panzerschreckrocket", name = "Panzerschreck Rocket" },
    { id = "flarecartridge",      name = "Flare Cartridge" },
    -- American, British, French, Soviet
    { id = "45acp",               name = ".45 ACP" },
    { id = "30cal",               name = ".30-06 Springfield" },
    { id = "30carbine",           name = ".30 Carbine" },
    { id = "25acp",               name = ".25 ACP" },
    { id = "32acp",               name = ".32 ACP" },
    { id = "38special",           name = ".38 Special" },
    { id = "bazookarocket",       name = "Bazooka Rocket" },
    { id = "303brit",             name = ".303 British" },
    { id = "765french",           name = "7.65mm French Longue" },
    { id = "75french",            name = "7.5mm French" },
    { id = "8mmfrench",           name = "8mm Lebel" },
    { id = "762tokarev",          name = "7.62×25mm Tokarev" },
    { id = "762soviet",           name = "7.62×54mmR" },
    { id = "762nagantr",          name = "7.62×38mmR Nagant" },
    { id = "762x39",              name = "7.62×39mm" },
    { id = "buckshot",            name = "12-Gauge Buckshot" },   -- the shotguns (Half-Life 2's type, kept)
    -- Equipment (registered by the weapon pack itself)
    { id = "mcv_grenade",           name = "Hand Grenade" },
    { id = "mcv_molotov",           name = "Molotov Cocktail" },
    { id = "mcv_mine",              name = "Mine" },
    { id = "mcv_explosive_charge",  name = "Explosive Charge" },
    { id = "mcv_flamethrower_fuel", name = "Flamethrower Fuel" },
    { id = "mcv_crossbowbolt",      name = "Crossbow Bolt" },
    { id = "mcv_flareround",        name = "Flare Round" },
}

--[[---------------------------------------------------------------------------
Ammo that comes WITH a weapon when it's bought, found or taken from a crate.
    Guns: a full magazine.
    Throwables and placeables (grenades, molotovs, dynamite, mines): `each`
    of their ammo, so the one you bought can be thrown / placed.
    Anything else without a magazine (the flamethrower): its DefaultClip.
    byClass overrides any weapon, e.g. mcv_mk2 = 2 for two grenades.
---------------------------------------------------------------------------]]
RP1942.WeaponStartAmmo = {
    each    = 1,
    bases   = { mcv_throwable = true, mcv_placeable = true },
    byClass = {},
}

-- How to fill a spawned_weapon for class: returns clip1, ammoadd
function RP1942.weaponStartAmmo(class)
    local stored = weapons.GetStored(class)
    local p = stored and stored.Primary
    if not p then return nil, 0 end
    local cfg = RP1942.WeaponStartAmmo
    local clip = tonumber(p.ClipSize) or -1
    if cfg.byClass[class] then
        return (clip > 0) and math.min(clip, cfg.byClass[class]) or nil, (clip > 0) and 0 or cfg.byClass[class]
    end
    if clip > 0 then return clip, 0 end                         -- a gun: a full magazine
    local ammo = p.Ammo
    if not ammo or ammo == "" or string.lower(ammo) == "none" then return nil, 0 end
    if cfg.bases[stored.Base] then return nil, cfg.each end     -- a grenade, molotov, charge, mine
    return nil, math.max(tonumber(p.DefaultClip) or 0, 0)       -- e.g. flamethrower fuel
end

local names = {}
for _, a in ipairs(RP1942.AmmoTypes) do names[a.id] = a.name end

function RP1942.ammoName(id)
    return names[id] or id
end

-- Register them (both realms need it). Skipped for any the weapon pack has
-- already registered, so nothing is doubled up.
hook.Add("Initialize", "RP1942_AmmoTypes", function()
    for _, a in ipairs(RP1942.AmmoTypes) do
        if not game.GetAmmoID or game.GetAmmoID(a.id) == -1 then
            game.AddAmmoType({ name = a.id })
        end
        if CLIENT then language.Add(a.id .. "_ammo", a.name) end   -- the HUD's ammo name
    end
end)
