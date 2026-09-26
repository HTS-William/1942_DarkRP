tupac_dumpsters_config = {

}

tupac_dumpsters_config.DumpsterModel = "models/props_junk/trashdumpster01a.mdl" --> The model of the dumpster ( Default: "models/props_junk/trashdumpster01a.mdl" )
tupac_dumpsters_config.DumpsterColor = Color( 255, 255, 255 ) --> The color of the dumpster ( Default: Color( 255, 255, 255 ) )
tupac_dumpsters_config.DumpsterSize = 1 --> The size of the dumpster ( Multiplier. Default: 1 )
tupac_dumpsters_config.UseSound = "doors/door_metal_gate_move1.wav" --> The lid opening when someone starts searching
tupac_dumpsters_config.SpawnPos = 8 --> How far above the dumpster's LID items appear, then get a small toss toward the player ( Default: 8 )
tupac_dumpsters_config.LabelDistance = 300 --> The floating label isn't drawn beyond this distance ( ~52 units = 1 m )

--> Searching: hold E on the dumpster. Letting go, looking away or walking off cancels it.
tupac_dumpsters_config.SearchTime = 3 --> Seconds of holding E
tupac_dumpsters_config.SearchRange = 110 --> How close you have to stay ( units )
tupac_dumpsters_config.RummageSounds = { --> Played while someone searches, so people nearby hear it
	"physics/cardboard/cardboard_box_impact_soft1.wav",
	"physics/cardboard/cardboard_box_impact_soft5.wav",
	"physics/metal/metal_box_impact_soft2.wav",
	"physics/plastic/plastic_box_impact_soft1.wav",
}

tupac_dumpsters_config.MinItemsToCreate = 2 --> Minimum amount of items does the dumpster create each time? ( Default: 2 )
tupac_dumpsters_config.MaxItemsToCreate = 5 --> Maximum amount of items does the dumpster create each time? ( Default: 5 )
--> Chance of each item being a weapon / an entity, for anyone using the dumpster
--> ( Keep each at 100 or less ). Each search rolls once per item.
tupac_dumpsters_config.WeaponPercentage = 2
tupac_dumpsters_config.EntityPercentage = 11
tupac_dumpsters_config.PropPercentage = 100 --> catch-all if the rolls above miss
tupac_dumpsters_config.MaxWeaponsPerSearch = 1 --> Never more than this many guns from one search
--> Boosted odds used instead of the two above when the player using the
--> dumpster holds the job named in HoboJob (a command from jobs.lua).
tupac_dumpsters_config.HoboJob = "hobo"
tupac_dumpsters_config.HoboWeaponPercentage = 5
tupac_dumpsters_config.HoboEntityPercentage = 20
tupac_dumpsters_config.CooldownTime = 270 --> Seconds before the SAME player can search the SAME dumpster again.
                                          --> Everyone has their own cooldown.
tupac_dumpsters_config.PropRemovalTime = 5 --> How long it takes for the props to be removed ( Default: 15 )
tupac_dumpsters_config.CooldownMsg = "You've already searched this dumpster. Try again later." --> Shown when someone on cooldown tries again
tupac_dumpsters_config.Props = { --> Random props that spawn
	"models/props_c17/BriefCase001a.mdl",
	"models/props_c17/streetsign001c.mdl",
	"models/props_lab/desklamp01.mdl",
	"models/props_lab/frame002a.mdl",
	"models/props_c17/doll01.mdl",
	"models/Gibs/wood_gib01e.mdl",
	"models/props_c17/clock01.mdl",
}
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
--> Random entities that spawn. Stock HL2 entities that always exist; swap in
--> your own once you have ammo pickups for the rp1942 weapons.
tupac_dumpsters_config.Entities = {
	"item_ammo_pistol",
	"item_ammo_smg1",
	"item_ammo_ar2",
	"item_box_buckshot",
	"item_healthkit",
}

--> Placing dumpsters in game (saved per map in data/rp1942/dumpsters_<map>.json):
-->     /adddumpster      places one where you're looking, facing you
-->     /removedumpster   removes the one you're looking at (and from the save)
--> Who may use those commands:
tupac_dumpsters_config.AdminCheck = function( ply ) return ply:IsSuperAdmin() end

--> Fixed spawn positions (always spawned, on every map load). Dumpsters placed
--> with /adddumpster don't need to be listed here.
tupac_dumpsters_config.AddSpawnPos = {
	{
		pos = Vector( 805.174500, 276.007233, -79.968750 ),
		ang = Angle( 7.724401, -91.468979, 0.000000 	),
	},
}

--> Resistance dead drops: hide money or a weapon in a dumpster for another
--> member to collect. Look at a dumpster and type:
-->     /deaddrop 500        leave 500 in it
-->     /deaddrop weapon     leave the weapon in your hands
--> Any Resistance member who searches that dumpster takes everything in it,
--> even if their own search cooldown hasn't run out. Only the Resistance can
--> see that a dumpster holds a drop.
tupac_dumpsters_config.DeadDrops = {
	enabled         = true,
	faction         = "resistance", --> who can leave and collect drops
	maxItems        = 4,            --> weapons + money bundles per dumpster
	maxMoney        = 50000,        --> most money one dumpster can hold
	reichConfiscate = true,         --> a Reich member searching it finds the drop: the money goes
	                                --> to the Reich treasury, the weapons are destroyed
}

--> Don't touch anything below
function get_dumpsters_spawn_pos()
	return tupac_dumpsters_config.AddSpawnPos
end
