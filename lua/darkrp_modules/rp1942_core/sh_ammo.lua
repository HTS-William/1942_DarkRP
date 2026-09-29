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
}

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
