hook.Add('Initialize', 'ComradeAmmoTypes', function()
	-- German Ammotypes
    game.AddAmmoType({
        name = '792x33mmkurz'
    })
    game.AddAmmoType({
        name = 'panzerschreckrocket'
    })
    game.AddAmmoType({
        name = '792x57mm'
    })
    game.AddAmmoType({
        name = '9mmluger'
    })
    game.AddAmmoType({
        name = '380acp'
    })
    game.AddAmmoType({
        name = 'flarecartridge'
    })
    game.AddAmmoType({
        name = '145x114'
    })
    game.AddAmmoType({
        name = '8mmnambu'
    })
	
	-- American Ammotypes
    game.AddAmmoType({
        name = '45acp'
    })
    game.AddAmmoType({
        name = '30cal'
    })
    game.AddAmmoType({
        name = '30carbine'
    })
    game.AddAmmoType({
        name = 'bazookarocket'
    })
end)

-- Add the new ammo type to the language system for display purposes
if CLIENT then
    language.Add("panzerschreckrocket", "88MM Rakete")
    language.Add("792x33mmkurz", "7.92×33mm Kurz")
    language.Add("792x57mm", "7.92×57mm Mauser")
    language.Add("9mmluger", "9×19mm Parabellum")
    language.Add("380acp", "9mm Kurz")
    language.Add("flarecartridge", "Flare Cartridge")
    language.Add("145x114", "14.5×114mm APIT")
    language.Add("8mmnambu", "8×22mm Nambu")
	
    language.Add("762tokarev", "7.62×25mm Tokarev")
    language.Add("45acp", ".45 ACP")
    language.Add("25acp", ".25 ACP")
    language.Add("32acp", ".32 ACP")
    language.Add("30cal", ".30 Caliber")
    language.Add("38special", ".38 Special")
    language.Add("765french", "7.65×20mm Longue")
    language.Add("30carbine", ".30 Carbine")
    language.Add("75french", "7.5×54mm French")
    language.Add("8mmfrench", "8x27mm French Ordnance")
    language.Add("303brit", ".303 British")
    language.Add("762x39", "7.62×39mm M43")
    language.Add("bazookarocket", "Rocket 2.36 Inch")
    language.Add("45acp", ".45 ACP")
end