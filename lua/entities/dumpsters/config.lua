tupac_dumpsters_config = {

}

tupac_dumpsters_config.DumpsterModel = "models/props_junk/trashdumpster01a.mdl" --> The model of the dumpster ( Default: "models/props_junk/trashdumpster01a.mdl" )
tupac_dumpsters_config.DumpsterColor = Color( 255, 255, 255 ) --> The color of the dumpster ( Default: Color( 255, 255, 255 ) )
tupac_dumpsters_config.DumpsterSize = 1 --> The size of the dumpster ( Multiplier. Default: 1 )
tupac_dumpsters_config.UseSound = "doors/door_metal_gate_move1.wav" --> The sound the dumpster makes when it's used ( Default: "doors/door_metal_gate_move1.wav" )
tupac_dumpsters_config.SpawnPos = 100 --> How far up does the random item spawn? ( Default: 100 )
tupac_dumpsters_config.MinItemsToCreate = 2 --> Minimum amount of items does the dumpster create each time? ( Default: 2 )
tupac_dumpsters_config.MaxItemsToCreate = 5 --> Maximum amount of items does the dumpster create each time? ( Default: 5 )
--> Base chance of each outcome, for anyone using the dumpster
--> ( Keep each at 100 or less )
tupac_dumpsters_config.WeaponPercentage = 7
tupac_dumpsters_config.EntityPercentage = 11
tupac_dumpsters_config.PropPercentage = 100 --> catch-all if the rolls above miss
--> Boosted odds used instead of the two above when the player using the
--> dumpster holds the job named in HoboJob (a command from jobs.lua).
tupac_dumpsters_config.HoboJob = "hobo"
tupac_dumpsters_config.HoboWeaponPercentage = 15
tupac_dumpsters_config.HoboEntityPercentage = 20
tupac_dumpsters_config.CooldownTime = 270 --> The cooldown time ( In seconds )
tupac_dumpsters_config.PropRemovalTime = 5 --> How long it takes for the props to be removed ( Default: 15 )
tupac_dumpsters_config.CooldownMsg = "Please wait out the cooldown time!" --> The message that appears in chat when there is a cooldown and someone hits 'use' on the dumpster ( Default: "Please wait out the cooldown time!" )
--> Anyone can use the dumpster now - see HoboJob above for the loot bonus.
tupac_dumpsters_config.Props = { --> Random props that spawn
	"models/props_c17/BriefCase001a.mdl",
	"models/props_c17/streetsign001c.mdl",
	"models/props_lab/desklamp01.mdl",
	"models/props_lab/frame002a.mdl",
	"models/props_c17/doll01.mdl",
	"models/Gibs/wood_gib01e.mdl",
	"models/props_c17/clock01.mdl",
}
--> Random weapons that spawn. The originals here ("mcv_*") were from a
--> different weapon base entirely and aren't installed on this server.
--> These match the placeholder classes already defined in
--> rp1942_core/sh_config.lua (RP1942.Weapons) - update both together once
--> your real weapon pack is installed.
tupac_dumpsters_config.Weapons = { --> Random weapons that spawn
	"lockpick",
	"mcv_vz24",
	"mcv_kar98q",
	"mcv_wrench",
	"mcv_babybrowning",
	"mcv_vcpistol",
	"mcv_vcpistol2",
	"mcv_tt33",
}
--> Random entities that spawn. The originals here ("cw_ammo_*", "weed_seed")
--> were from unrelated addons (a different weapon base, a drugs addon) that
--> aren't installed on this server. These are stock HL2 entities that always
--> exist, so the dumpster works out of the box; swap in your own once you
--> have ammo pickups for the rp1942 weapons.
tupac_dumpsters_config.Entities = {
	"item_ammo_pistol",
	"item_ammo_smg1",
	"item_ammo_ar2",
	"item_box_buckshot",
	"item_healthkit",
}
tupac_dumpsters_config.AddSpawnPos = { --> The spawn positions
	{
		pos = Vector( 805.174500, 276.007233, -79.968750 ),
		ang = Angle( 7.724401, -91.468979, 0.000000 	),
	},
}
--> Don't touch anything below
function get_dumpsters_spawn_pos()
	return tupac_dumpsters_config.AddSpawnPos
end
