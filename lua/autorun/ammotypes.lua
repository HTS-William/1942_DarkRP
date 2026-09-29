hook.Add("Initialize", "OccpAmmoTypes", function()
	-- German Ammotypes
    game.AddAmmoType({
        name = "792x33mmkurz"
    })
    game.AddAmmoType({
        name = "panzerschreckrocket"
    })
    game.AddAmmoType({
        name = "792x57mm"
    })
    game.AddAmmoType({
        name = "9mmluger"
    })
    game.AddAmmoType({
        name = "380acp"
    })
    game.AddAmmoType({
        name = "flarecartridge"
    })
    game.AddAmmoType({
        name = "145x114"
    })
    game.AddAmmoType({
        name = "8mmnambu"
    })
    game.AddAmmoType({
        name = "763mauser"
    })
	
	-- American Ammotypes
    game.AddAmmoType({
        name = "45acp"
    })
    game.AddAmmoType({
        name = "30cal"
    })
    game.AddAmmoType({
        name = "30carbine"
    })
    game.AddAmmoType({
        name = "bazookarocket"
    })
    game.AddAmmoType({
        name = "762tokarev"
    })
    game.AddAmmoType({
        name = "25acp"
    })
    game.AddAmmoType({
        name = "32acp"
    })
    game.AddAmmoType({
        name = "38special"
    })
    game.AddAmmoType({
        name = "765french"
    })
    game.AddAmmoType({
        name = "75french"
    })
    game.AddAmmoType({
        name = "8mmfrench"
    })
    game.AddAmmoType({
        name = "303brit"
    })
    game.AddAmmoType({
        name = "762soviet"
    })
    game.AddAmmoType({
        name = "762nagantr"
    })
    game.AddAmmoType({
        name = "762x39"
    })
end)

-- Add the new ammo type to the language system for display purposes
if CLIENT then
    language.Add("panzerschreckrocket_ammo", "88MM Rakete")
    language.Add("792x33mmkurz_ammo", "7.92×33mm Kurz")
    language.Add("792x57mm_ammo", "7.92×57mm Mauser")
    language.Add("9mmluger_ammo", "9×19mm Parabellum")
    language.Add("380acp_ammo", "9mm Kurz")
    language.Add("flarecartridge_ammo", "Flare Cartridge")
    language.Add("145x114_ammo", "14.5×114mm APIT")
    language.Add("8mmnambu_ammo", "8×22mm Nambu")
    language.Add("763mauser_ammo", "	7.63×25mm Mauser")
	
    language.Add("762tokarev_ammo", "7.62×25mm Tokarev")
    language.Add("762soviet_ammo", "7.62×54mmR")
    language.Add("45acp_ammo", ".45 ACP")
    language.Add("25acp_ammo", ".25 ACP")
    language.Add("32acp_ammo", ".32 ACP")
    language.Add("30cal_ammo", ".30 Caliber")
    language.Add("38special_ammo", ".38 Special")
    language.Add("765french_ammo", "7.65×20mm Longue")
    language.Add("30carbine_ammo", ".30 Carbine")
    language.Add("75french_ammo", "7.5×54mm French")
    language.Add("8mmfrench_ammo", "8x27mm French Ordnance")
    language.Add("303brit_ammo", ".303 British")
    language.Add("762x39_ammo", "7.62×39mm M43")
    language.Add("bazookarocket_ammo", "Rocket 2.36 Inch")
    language.Add("45acp_ammo", ".45 ACP")
    language.Add("762nagantr_ammo", "7.62x38mmR Nagant")
end