include( "config.lua" )
ENT.Type 												= "anim" --> Entity type
ENT.Base												= "base_anim" --> Entity base
ENT.PrintName										= "Dumpster"
ENT.Author											= "Claude & William"
ENT.Purpose											= ""
ENT.AutomaticFrameAdvance 				= true
ENT.Spawnable										= true
ENT.AdminSpawnable							= true
function ENT:SetupDataTables()
	--> How many things are hidden in it as a Resistance dead drop (the label
	--> only shows this to the Resistance)
	self:NetworkVar( "Int", 0, "DeadDrop" )
end

--> Can this player leave / collect dead drops?
function tupac_dumpsters_isDropper( ply )
	local dd = tupac_dumpsters_config.DeadDrops
	if not ( dd and dd.enabled ) or not IsValid( ply ) then return false end
	return RP1942 and RP1942.getFaction and RP1942.getFaction( ply ) == dd.faction
end

--> Chat commands (declared on both sides so DarkRP's help lists them)
if DarkRP and DarkRP.declareChatCommand then
	DarkRP.declareChatCommand{
		command = "adddumpster",
		description = "Admin: place a dumpster where you're looking (saved for this map)",
		delay = 1,
	}
	DarkRP.declareChatCommand{
		command = "removedumpster",
		description = "Admin: remove the dumpster you're looking at (and from the save)",
		delay = 1,
	}
	DarkRP.declareChatCommand{
		command = "deaddrop",
		description = "Resistance: hide money (/deaddrop 500) or your weapon (/deaddrop weapon) in the dumpster you're looking at",
		delay = 1.5,
	}
end
