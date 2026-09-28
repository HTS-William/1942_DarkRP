rp1942_dumpsters_config = {

}

rp1942_dumpsters_config.DumpsterModel = "models/props_junk/trashdumpster01a.mdl" --> The model of the dumpster ( Default: "models/props_junk/trashdumpster01a.mdl" )
rp1942_dumpsters_config.DumpsterColor = Color( 255, 255, 255 ) --> The color of the dumpster ( Default: Color( 255, 255, 255 ) )
rp1942_dumpsters_config.DumpsterSize = 1 --> The size of the dumpster ( Multiplier. Default: 1 )
rp1942_dumpsters_config.UseSound = "doors/door_metal_gate_move1.wav" --> The lid opening when someone starts searching
rp1942_dumpsters_config.SpawnPos = 8 --> How far above the dumpster's LID items appear, then get a small toss toward the player ( Default: 8 )
rp1942_dumpsters_config.LabelDistance = 300 --> The floating label isn't drawn beyond this distance ( ~52 units = 1 m )

--> Searching: hold E on the dumpster. Letting go, looking away or walking off cancels it.
rp1942_dumpsters_config.SearchTime = 3 --> Seconds of holding E
rp1942_dumpsters_config.SearchRange = 110 --> How close you have to stay ( units )
rp1942_dumpsters_config.RummageSounds = { --> Played while someone searches, so people nearby hear it
	"physics/cardboard/cardboard_box_impact_soft1.wav",
	"physics/cardboard/cardboard_box_impact_soft5.wav",
	"physics/metal/metal_box_impact_soft2.wav",
	"physics/plastic/plastic_box_impact_soft1.wav",
}

rp1942_dumpsters_config.MinItemsToCreate = 2 --> Minimum amount of items does the dumpster create each time? ( Default: 2 )
rp1942_dumpsters_config.MaxItemsToCreate = 5 --> Maximum amount of items does the dumpster create each time? ( Default: 5 )
--> Chance of each item being a weapon / an entity, for anyone using the dumpster
--> ( Keep each at 100 or less ). Each search rolls once per item.
rp1942_dumpsters_config.WeaponPercentage = 2
rp1942_dumpsters_config.EntityPercentage = 11
rp1942_dumpsters_config.PropPercentage = 100 --> catch-all if the rolls above miss
rp1942_dumpsters_config.MaxWeaponsPerSearch = 1 --> Never more than this many guns from one search
--> Boosted odds used instead of the two above when the player using the
--> dumpster holds the job named in HoboJob (a command from jobs.lua).
rp1942_dumpsters_config.HoboJob = "hobo"
rp1942_dumpsters_config.HoboWeaponPercentage = 5
rp1942_dumpsters_config.HoboEntityPercentage = 20
--> Production goods (rp1942_production) found in the trash, always at the low
--> quality below, so players have something to sell at a market. Rolled per
--> item after the weapon roll, before the entity roll.
rp1942_dumpsters_config.GoodsPercentage = 12
rp1942_dumpsters_config.HoboGoodsPercentage = 25
rp1942_dumpsters_config.MaxGoodsPerSearch = 2
rp1942_dumpsters_config.GoodsQuality = 1 --> 1 = poor (1 star), 2 = fine, 3 = excellent
rp1942_dumpsters_config.Goods = { --> good id (RP1942.Goods in sh_production.lua) = how likely, relative to the others
	rations = 30,
	boots   = 30,
	bread   = 15,
	pot     = 8,
	kettle  = 7,
	wine    = 6,
	clock   = 3,
	radio   = 1,
}
rp1942_dumpsters_config.CooldownTime = 270 --> Seconds before the SAME player can search the SAME dumpster again.
                                          --> Everyone has their own cooldown.
rp1942_dumpsters_config.PocketLoot = true --> Weapons and entities go straight into the searcher's DarkRP pocket.
                                        --> A full pocket: they're tossed out onto the ground instead.
                                        --> ( Junk props are always tossed out. )
rp1942_dumpsters_config.PropRemovalTime = 5 --> How long it takes for the props to be removed ( Default: 15 )
rp1942_dumpsters_config.CooldownMsg = "You've already searched this dumpster. Try again later." --> Shown when someone on cooldown tries again
rp1942_dumpsters_config.Props = { --> Random junk that spawns (removed after PropRemovalTime)
	"models/props_junk/garbage_glassbottle001a.mdl",
	"models/props_junk/garbage_glassbottle002a.mdl",
	"models/props_junk/garbage_glassbottle003a.mdl",
	"models/props_junk/garbage_metalcan001a.mdl",
	"models/props_junk/garbage_metalcan002a.mdl",
	"models/props_junk/garbage_milkcarton001a.mdl",
	"models/props_junk/garbage_milkcarton002a.mdl",
	"models/props_junk/garbage_newspaper001a.mdl",
	"models/props_junk/garbage_plasticbottle003a.mdl",
	"models/props_junk/glassbottle01a.mdl",
}
rp1942_dumpsters_config.Weapons = { --> Random weapons that spawn
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
rp1942_dumpsters_config.Entities = {
	"item_ammo_pistol",
	"item_ammo_smg1",
	"item_ammo_ar2",
	"item_box_buckshot",
	"item_healthkit",
}
--> Names shown in "Into your pocket: ..." for classes without a proper name
rp1942_dumpsters_config.EntityNames = {
	item_ammo_pistol  = "Pistol ammo",
	item_ammo_smg1    = "SMG ammo",
	item_ammo_ar2     = "Rifle ammo",
	item_box_buckshot = "Shotgun shells",
	item_healthkit    = "Medkit",
	lockpick          = "Lockpick",
}

--> Placing dumpsters in game (saved per map in data/rp1942/dumpsters_<map>.json):
-->     /adddumpster      places one where you're looking, facing you
-->     /removedumpster   removes the one you're looking at (and from the save)
--> Who may use those commands:
-->     or spawn one from !prodspawn and save it with /saveprod (like any machine)
rp1942_dumpsters_config.AdminCheck = function( ply ) return ply:IsSuperAdmin() end   --> without ULX; with ULX it's set per rank (Groups > 42Bros)

--> Fixed spawn positions, spawned on every map load. map = "..." limits an
--> entry to that map; without it, it spawns on every map. Dumpsters placed
--> with /adddumpster don't need to be listed here, but /getdumpsterpos turns
--> all of this map's dumpsters into this table (copied to your clipboard):
--> paste it over the table below. Saved dumpsters that are hardcoded here
--> won't spawn twice.
rp1942_dumpsters_config.AddSpawnPos = {
	{
		pos = Vector( 805.174500, 276.007233, -79.968750 ),
		ang = Angle( 7.724401, -91.468979, 0.000000 	),
	},
}

--> Resistance dead drops: hide money or a weapon in a dumpster for another
--> member to collect. Look at a dumpster and type:
-->     /deaddrop 500        leave 500 in it
-->     /deaddrop weapon     leave the weapon in your hands
--> Any Resistance member who searches that dumpster collects it, even if their
--> own search cooldown hasn't run out: money into their wallet, weapons into
--> their pocket. Whatever doesn't fit in their pocket stays in the drop. Only the Resistance can
--> see that a dumpster holds a drop.
rp1942_dumpsters_config.DeadDrops = {
	enabled         = true,
	faction         = "resistance", --> who can leave and collect drops
	maxItems        = 4,            --> weapons + money bundles per dumpster
	maxMoney        = 50000,        --> most money one dumpster can hold
	reichConfiscate = true,         --> a Reich member searching it finds the drop: the money goes
	                                --> to the Reich treasury, the weapons are destroyed
}

--> Don't touch anything below
function get_dumpsters_spawn_pos()
	return rp1942_dumpsters_config.AddSpawnPos
end
