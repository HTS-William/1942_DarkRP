--> ClientAddCSLuaFile( "cl_init.lua" )AddCSLuaFile( "shared.lua" )AddCSLuaFile( "config.lua" )--> Serverinclude( "shared.lua" )include( "config.lua" )
--> Positionlocal spawn_pos = Vector( 0, 0, tupac_dumpsters_config.SpawnPos )

function ENT:Initialize()	--> Model	self:SetModel( tupac_dumpsters_config.DumpsterModel )	--> Color	self:SetColor( tupac_dumpsters_config.DumpsterColor )	self:SetModelScale( tupac_dumpsters_config.DumpsterSize )	--> Physics	self:PhysicsInit( SOLID_VPHYSICS )	self:SetMoveType( MOVETYPE_VPHYSICS )	self:SetSolid( SOLID_VPHYSICS )	self:SetUseType( SIMPLE_USE )	self:SetCooldown_Time(0)end

function ENT:Use( a, c )	if table.HasValue( tupac_dumpsters_config.AllowedJobs, c:Team() ) then		if self:GetCooldown_Time() <= 0 then			self:EmitSound( tupac_dumpsters_config.UseSound )			self:CreateItems()			self:SetCooldown_Time( tupac_dumpsters_config.CooldownTime )		elseif !( self:GetCooldown_Time() <= 0 ) then			c:SendLua( [[ chat.AddText( Color( 255, 25, 25 ), "[DUMPSTER] ", color_white, tupac_dumpsters_config.CooldownMsg ) ]] )		end --> End of Cooldown check	else		c:SendLua( [[ chat.AddText( Color( 255, 25, 25 ), "[DUMPSTER] ", color_white, tupac_dumpsters_config.WrongJobMsg ) ]] )	end --> End of team checkend

function ENT:CreateItems()	--[[	--> Destroy the create items timer	timer.Destroy( "tupac_dumpsters_spawn" )	--> Destroy the cooldown timer	timer.Destroy( "tupac_dumpsters_cooldown" )	]]	--> Creating items timer ( To prevent props from getting stuck together )	timer.Create( "tupac_dumpsters_spawn", 0.2, math.random( tupac_dumpsters_config.MinItemsToCreate, tupac_dumpsters_config.MaxItemsToCreate ), functio`n()		if math.random( 0, 100 ) <= tupac_dumpsters_config.WeaponPercentage then			self:SpawnWeapon()		elseif math.random( 0, 100 ) <= tupac_dumpsters_config.EntityPercentage then			self:SpawnEntity()		elseif math.random( 0, 100 ) <= tupac_dumpsters_config.PropPercentage then			self:SpawnProp()		end	end )	--> Cooldown timer	timer.Create( "tupac_dumpsters_cooldown", 1, tupac_dumpsters_config.CooldownTime, function()		if self:GetCooldown_Time() != 0 then			self:SetCooldown_Time( self:GetCooldown_Time() - 1 )		end	end )end

function ENT:SpawnWeapon()	local tupac_dumpsters_weapon = ents.Create( table.Random( tupac_dumpsters_config.Weapons ) )	tupac_dumpsters_weapon:SetPos( self:GetPos() + spawn_pos )	tupac_dumpsters_weapon:Spawn()end
function ENT:SpawnEntity()	local tupac_dumpsters_entity = ents.Create( table.Random( tupac_dumpsters_config.Entities ) )	tupac_dumpsters_entity:SetPos( self:GetPos() + spawn_pos )	tupac_dumpsters_entity:Spawn()end
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
