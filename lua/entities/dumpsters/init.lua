--> Client
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "config.lua" )

--> Server
include( "shared.lua" )
include( "config.lua" )
--> Position
local spawn_pos = Vector( 0, 0, tupac_dumpsters_config.SpawnPos )

function ENT:Initialize()
	--> Model
	self:SetModel( tupac_dumpsters_config.DumpsterModel )
	--> Color
	self:SetColor( tupac_dumpsters_config.DumpsterColor )
	self:SetModelScale( tupac_dumpsters_config.DumpsterSize )
	--> Physics
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self:SetCooldown_Time(0)
end

function ENT:Use( activator, caller )
	if self:GetCooldown_Time() <= 0 then
		self:EmitSound( tupac_dumpsters_config.UseSound )
		self:CreateItems( caller )
		self:SetCooldown_Time( tupac_dumpsters_config.CooldownTime )
	else
		DarkRP.notify( caller, 1, 4, tupac_dumpsters_config.CooldownMsg )
	end
end

function ENT:CreateItems( ply )
	local isHobo = IsValid( ply ) and ply:IsPlayer()
		and RPExtraTeams[ ply:Team() ] and RPExtraTeams[ ply:Team() ].command == tupac_dumpsters_config.HoboJob

	local weaponChance = isHobo and tupac_dumpsters_config.HoboWeaponPercentage or tupac_dumpsters_config.WeaponPercentage
	local entityChance = isHobo and tupac_dumpsters_config.HoboEntityPercentage or tupac_dumpsters_config.EntityPercentage

	--> Per-entity timer names: with the job restriction gone, several players can
	--> use different dumpsters at once. A shared name like "tupac_dumpsters_spawn"
	--> would make the second Use() cancel and replace the first dumpster's timer.
	local spawnTimer = "tupac_dumpsters_spawn_" .. self:EntIndex()
	local cooldownTimer = "tupac_dumpsters_cooldown_" .. self:EntIndex()

	--> Creating items timer ( To prevent props from getting stuck together )
	timer.Create( spawnTimer, 0.2, math.random( tupac_dumpsters_config.MinItemsToCreate, tupac_dumpsters_config.MaxItemsToCreate ), function()
		if not IsValid( self ) then timer.Remove( spawnTimer ) return end
		if math.random( 0, 100 ) <= weaponChance then
			self:SpawnWeapon()
		elseif math.random( 0, 100 ) <= entityChance then
			self:SpawnEntity()
		elseif math.random( 0, 100 ) <= tupac_dumpsters_config.PropPercentage then
			self:SpawnProp()
		end
	end )
	--> Cooldown timer
	timer.Create( cooldownTimer, 1, tupac_dumpsters_config.CooldownTime, function()
		if not IsValid( self ) then timer.Remove( cooldownTimer ) return end
		if self:GetCooldown_Time() != 0 then
			self:SetCooldown_Time( self:GetCooldown_Time() - 1 )
		end
	end )
end

function ENT:SpawnWeapon()
	local class = table.Random( tupac_dumpsters_config.Weapons )
	local tupac_dumpsters_weapon = ents.Create( class )
	if not IsValid( tupac_dumpsters_weapon ) then
		MsgC( Color( 255, 170, 0 ), "[Dumpster] '", class, "' in tupac_dumpsters_config.Weapons isn't a valid entity/weapon class - check the spelling in config.lua.\n" )
		return
	end
	tupac_dumpsters_weapon:SetPos( self:GetPos() + spawn_pos )
	tupac_dumpsters_weapon:Spawn()
end
function ENT:SpawnEntity()
	local class = table.Random( tupac_dumpsters_config.Entities )
	local tupac_dumpsters_entity = ents.Create( class )
	if not IsValid( tupac_dumpsters_entity ) then
		MsgC( Color( 255, 170, 0 ), "[Dumpster] '", class, "' in tupac_dumpsters_config.Entities isn't a valid entity class - check the spelling in config.lua.\n" )
		return
	end
	tupac_dumpsters_entity:SetPos( self:GetPos() + spawn_pos )
	tupac_dumpsters_entity:Spawn()
end
function ENT:SpawnProp()


	local tupac_dumpsters_prop = ents.Create( "prop_physics" )
	tupac_dumpsters_prop:SetModel( table.Random( tupac_dumpsters_config.Props ) )
	tupac_dumpsters_prop:SetPos( self:GetPos() + spawn_pos )
	tupac_dumpsters_prop:Spawn()
	timer.Simple( tupac_dumpsters_config.PropRemovalTime, function()
		if tupac_dumpsters_prop:IsValid() then
			tupac_dumpsters_prop:Remove()
		end
	end )
end

--[[
	Name:		Create Dumpsters
]]

local tupac_dumpsters_spawn_positions = get_dumpsters_spawn_pos()
function spawn_tupac_dumpsters()
	for k, v in pairs( tupac_dumpsters_spawn_positions ) do
		local tupac_dumpster = ents.Create( "tupac_dumpster" )
		tupac_dumpster:SetPos( v[ "pos" ] )
		tupac_dumpster:SetAngles( v[ "ang" ] )
		tupac_dumpster:Spawn()
		tupac_dumpster:DropToFloor()
		local tupac_dumpster_phys = tupac_dumpster:GetPhysicsObject()
		tupac_dumpster_phys:EnableMotion( false )
	end
end

hook.Add( "InitPostEntity", "spawn_dumpsters", spawn_tupac_dumpsters )

--> The folder here is "dumpsters", but every ents.Create() call above uses
--> "tupac_dumpster". Without registering that name explicitly, GMod only
--> knows this entity as "dumpsters" and every ents.Create("tupac_dumpster")
--> call (including the one that spawns the dumpster itself) silently fails.
scripted_ents.Register( ENT, "tupac_dumpster" )

--[[---------------------------------------------------------------------------
Startup check: spawns (and immediately removes) one of every class in
Weapons/Entities so a bad classname shows up as a clear warning in console
at boot, instead of an ugly "Tried to use a NULL entity!" the first time a
player actually uses a dumpster and rolls that specific class.
---------------------------------------------------------------------------]]
hook.Add( "InitPostEntity", "tupac_dumpsters_sanity_check", function()
	local function checkList( list, label )
		for _, class in ipairs( list ) do
			local e = ents.Create( class )
			if IsValid( e ) then
				e:Remove()
			else
				MsgC( Color( 255, 170, 0 ), "[Dumpster] '", class, "' in tupac_dumpsters_config.", label, " is not a valid class - it will silently fail to spawn in-game.\n" )
			end
		end
	end

	checkList( tupac_dumpsters_config.Weapons, "Weapons" )
	checkList( tupac_dumpsters_config.Entities, "Entities" )
end )
