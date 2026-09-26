--> Client
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "config.lua" )

--> Server
include( "shared.lua" )
include( "config.lua" )

util.AddNetworkString( "tupac_dumpsters_cooldown" )

local CFG = tupac_dumpsters_config

function ENT:Initialize()
	--> Model
	self:SetModel( CFG.DumpsterModel )
	--> Color
	self:SetColor( CFG.DumpsterColor )
	self:SetModelScale( CFG.DumpsterSize )
	--> Physics
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	self.readyAt = {}      --> [SteamID64] = CurTime() when that player may search again
	self.searchers = {}    --> [player] = CurTime() when their search finishes
	self.drop = { money = 0, weapons = {} }   --> Resistance dead drop contents
	self:SetDeadDrop( 0 )
end

--[[---------------------------------------------------------------------------
Per-player cooldowns
---------------------------------------------------------------------------]]
function ENT:CooldownLeft( ply )
	return math.max( 0, ( self.readyAt[ ply:SteamID64() ] or 0 ) - CurTime() )
end

function ENT:StartCooldown( ply )
	local readyAt = CurTime() + CFG.CooldownTime
	self.readyAt[ ply:SteamID64() ] = readyAt
	--> Only this player's label needs to know
	net.Start( "tupac_dumpsters_cooldown" )
		net.WriteEntity( self )
		net.WriteFloat( readyAt )
	net.Send( ply )
end

--[[---------------------------------------------------------------------------
Searching: press E to start, keep holding E and looking at the dumpster
(the progress bar is the shared "hold" bar from rp1942_events/cl_events.lua)
---------------------------------------------------------------------------]]
local function setHold( ply, startTime, endTime, text )
	ply:SetNW2Float( "RP1942_HoldStart", startTime )
	ply:SetNW2Float( "RP1942_HoldEnd", endTime )
	ply:SetNW2String( "RP1942_HoldText", text or "" )
end

function ENT:HasDrop()
	return self.drop.money > 0 or #self.drop.weapons > 0
end

function ENT:Use( activator, caller )
	local ply = IsValid( caller ) and caller:IsPlayer() and caller or activator
	if not ( IsValid( ply ) and ply:IsPlayer() ) then return end
	if self.searchers[ ply ] then return end

	--> On cooldown: only a Resistance member collecting a dead drop gets through
	local collecting = self:HasDrop() and tupac_dumpsters_isDropper( ply )
	if self:CooldownLeft( ply ) > 0 and not collecting then
		DarkRP.notify( ply, 1, 4, CFG.CooldownMsg )
		return
	end

	local now = CurTime()
	self.searchers[ ply ] = now + CFG.SearchTime
	setHold( ply, now, now + CFG.SearchTime, "Searching the dumpster..." )
	self:EmitSound( CFG.UseSound, 70 )
	self.nextRummage = now + 0.5
end

function ENT:Think()
	local now = CurTime()

	for ply, doneAt in pairs( self.searchers ) do
		local ok = IsValid( ply ) and ply:Alive() and ply:KeyDown( IN_USE )
		if ok then
			local tr = ply:GetEyeTrace()
			ok = tr.Entity == self and tr.HitPos:Distance( ply:EyePos() ) <= CFG.SearchRange
		end

		if not ok then
			self.searchers[ ply ] = nil
			if IsValid( ply ) then setHold( ply, 0, 0 ) end
		elseif now >= doneAt then
			self.searchers[ ply ] = nil
			setHold( ply, 0, 0 )
			self:FinishSearch( ply )
		end
	end

	--> Rummaging noises while anyone is searching
	if next( self.searchers ) and now >= ( self.nextRummage or 0 ) then
		self.nextRummage = now + math.Rand( 0.5, 0.9 )
		self:EmitSound( table.Random( CFG.RummageSounds ), 65, math.random( 90, 110 ) )
	end

	self:NextThink( now + 0.1 )
	return true
end

function ENT:FinishSearch( ply )
	--> A dead drop is collected (Resistance) or confiscated (Reich) first
	if self:HasDrop() then
		if tupac_dumpsters_isDropper( ply ) then
			self:CollectDrop( ply )
			--> Collecting while on cooldown is free: no loot, no new cooldown
			if self:CooldownLeft( ply ) > 0 then return end
		elseif CFG.DeadDrops.reichConfiscate and RP1942 and RP1942.getFaction and RP1942.getFaction( ply ) == "reich" then
			self:ConfiscateDrop( ply )
		end
	end

	if self:CooldownLeft( ply ) > 0 then return end
	self:StartCooldown( ply )
	self.lastUser = ply
	self:CreateItems( ply )
end

--> Where loot appears: just above the lid, spread a little so items don't
--> stack inside each other. SpawnPos (config.lua) = height above the lid.
function ENT:LootPos()
	local mins, maxs = self:OBBMins(), self:OBBMaxs()
	local center = self:OBBCenter()
	local spread = math.min( maxs.x - mins.x, maxs.y - mins.y ) * 0.25
	local offset = Vector( center.x + math.Rand( -spread, spread ), center.y + math.Rand( -spread, spread ),
		maxs.z + ( CFG.SpawnPos or 8 ) )
	return self:LocalToWorld( offset )
end

--> Give a freshly spawned item a small toss toward whoever opened the lid
function ENT:TossLoot( ent )
	local phys = ent:GetPhysicsObject()
	if not IsValid( phys ) then return end
	phys:Wake()
	local target = IsValid( self.lastUser ) and self.lastUser:GetPos() or self:GetPos()
	local dir = target - self:GetPos()
	dir.z = 0
	dir:Normalize()
	phys:SetVelocity( dir * 90 + Vector( 0, 0, 110 ) )
end

function ENT:CreateItems( ply )
	local isHobo = IsValid( ply ) and ply:IsPlayer()
		and RPExtraTeams[ ply:Team() ] and RPExtraTeams[ ply:Team() ].command == CFG.HoboJob

	local weaponChance = isHobo and CFG.HoboWeaponPercentage or CFG.WeaponPercentage
	local entityChance = isHobo and CFG.HoboEntityPercentage or CFG.EntityPercentage
	local weaponsLeft = CFG.MaxWeaponsPerSearch or 1

	--> Per-entity timer name, so searches on different dumpsters never cancel each other.
	--> Items come out 0.2 s apart so props don't spawn inside each other.
	local spawnTimer = "tupac_dumpsters_spawn_" .. self:EntIndex()
	local count = math.random( CFG.MinItemsToCreate, CFG.MaxItemsToCreate )
	local done, pocketed, dropped = 0, {}, {}
	timer.Create( spawnTimer, 0.2, count, function()
		if not IsValid( self ) then timer.Remove( spawnTimer ) return end
		local name, inPocket
		if weaponsLeft > 0 and math.random( 1, 100 ) <= weaponChance then
			weaponsLeft = weaponsLeft - 1
			name, inPocket = self:SpawnWeapon( ply )
		elseif math.random( 1, 100 ) <= entityChance then
			name, inPocket = self:SpawnEntity( ply )
		elseif math.random( 1, 100 ) <= CFG.PropPercentage then
			self:SpawnProp()
		end
		if name then table.insert( inPocket and pocketed or dropped, name ) end

		--> After the last item: tell the player what they found and where it went
		done = done + 1
		if done == count and IsValid( ply ) then
			if #pocketed > 0 then
				DarkRP.notify( ply, 0, 5, "Into your pocket: " .. table.concat( pocketed, ", " ) .. "." )
			end
			if #dropped > 0 then
				DarkRP.notify( ply, 1, 5, "Your pocket is full. Left on the ground: " .. table.concat( dropped, ", " ) .. "." )
			end
		end
	end )
end

--> A friendly name for loot messages
local function lootName( class )
	if CFG.EntityNames and CFG.EntityNames[ class ] then return CFG.EntityNames[ class ] end
	local stored = weapons.GetStored( class ) or scripted_ents.GetStored( class )
	local t = stored and ( stored.t or stored )
	return ( t and t.PrintName and t.PrintName ~= "" and t.PrintName ) or class
end

--> Weapons and entities go straight into the searcher's pocket (CFG.PocketLoot).
--> A full pocket, or PocketLoot = false: tossed out of the dumpster instead.
--> Returns the item's name and whether it was pocketed.
function ENT:GiveLoot( ply, ent, class )
	if CFG.PocketLoot and RP1942.pocketOrLeave and RP1942.pocketOrLeave( ply, ent ) then
		return lootName( class ), true
	end
	self:TossLoot( ent )
	return lootName( class ), false
end

function ENT:SpawnWeapon( ply )
	local class = table.Random( CFG.Weapons )
	--> A DarkRP "spawned_weapon" (the same thing a dropped or bought gun is),
	--> so it can be pocketed, picked up with E and shows its name
	local wep = RP1942.makeSpawnedWeapon and RP1942.makeSpawnedWeapon( class, self:LootPos() )
	if not IsValid( wep ) then
		MsgC( Color( 255, 170, 0 ), "[Dumpster] couldn't create a weapon for '", class, "'.\n" )
		return
	end
	return self:GiveLoot( ply, wep, class )
end

function ENT:SpawnEntity( ply )
	local class = table.Random( CFG.Entities )
	local ent = ents.Create( class )
	if not IsValid( ent ) then
		MsgC( Color( 255, 170, 0 ), "[Dumpster] '", class, "' in tupac_dumpsters_config.Entities isn't a valid entity class - check the spelling in config.lua.\n" )
		return
	end
	ent:SetPos( self:LootPos() )
	ent:Spawn()
	return self:GiveLoot( ply, ent, class )
end

function ENT:SpawnProp()
	local prop = ents.Create( "prop_physics" )
	prop:SetModel( table.Random( CFG.Props ) )
	prop:SetPos( self:LootPos() )
	prop:Spawn()
	self:TossLoot( prop )
	timer.Simple( CFG.PropRemovalTime, function()
		if IsValid( prop ) then prop:Remove() end
	end )
end

--[[---------------------------------------------------------------------------
Resistance dead drops
---------------------------------------------------------------------------]]
function ENT:UpdateDropCount()
	self:SetDeadDrop( #self.drop.weapons + ( self.drop.money > 0 and 1 or 0 ) )
end

--> "TT-33, TT-33, Luger" -> "2x TT-33, Luger"
local function countedList( names )
	local order, counts = {}, {}
	for _, n in ipairs( names ) do
		if not counts[ n ] then order[ #order + 1 ] = n end
		counts[ n ] = ( counts[ n ] or 0 ) + 1
	end
	for i, n in ipairs( order ) do
		if counts[ n ] > 1 then order[ i ] = counts[ n ] .. "x " .. n end
	end
	return table.concat( order, ", " )
end

--> Money goes into the wallet, weapons into the pocket (duplicates are fine:
--> each gun is its own pocket item). Whatever doesn't fit in the pocket stays
--> in the drop for the next member.
function ENT:CollectDrop( ply )
	local got, left = {}, {}
	if self.drop.money > 0 then
		ply:addMoney( self.drop.money )
		got[ #got + 1 ] = DarkRP.formatMoney( self.drop.money )
	end
	for _, w in ipairs( self.drop.weapons ) do
		local wep = RP1942.pocketRoom( ply ) > 0 and RP1942.makeSpawnedWeapon( w.class, ply:GetPos() + Vector( 0, 0, 40 ), w.clip )
		if IsValid( wep ) and RP1942.pocketOrLeave( ply, wep ) then
			got[ #got + 1 ] = w.name
		else
			if IsValid( wep ) then wep:Remove() end
			left[ #left + 1 ] = w
		end
	end
	self.drop = { money = 0, weapons = left }
	self:UpdateDropCount()

	if #got > 0 then
		DarkRP.notify( ply, 0, 6, "You collected from the dead drop: " .. countedList( got ) .. "." )
	end
	if #left > 0 then
		local names = {}
		for _, w in ipairs( left ) do names[ #names + 1 ] = w.name end
		DarkRP.notify( ply, 1, 6, "Your pocket is full. Left in the drop: " .. countedList( names ) .. "." )
	end
end

function ENT:ConfiscateDrop( ply )
	local money = self.drop.money
	if money > 0 and RP1942.treasuryDeposit then RP1942.treasuryDeposit( money, "confiscated dead drop" ) end
	self.drop = { money = 0, weapons = {} }
	self:UpdateDropCount()
	DarkRP.notify( ply, 0, 6, "You found a Resistance dead drop and confiscated it"
		.. ( money > 0 and ( " (" .. DarkRP.formatMoney( money ) .. " to the treasury)" ) or "" ) .. "." )
end

--> The dumpster a player is looking at, close enough to use
local function lookedAtDumpster( ply, range )
	local tr = ply:GetEyeTrace()
	local ent = tr.Entity
	if not IsValid( ent ) or ent:GetClass() ~= "rp1942_dumpster" then return nil end
	if tr.HitPos:Distance( ply:EyePos() ) > ( range or CFG.SearchRange ) then return nil end
	return ent
end

local function deadDrop( ply, args )
	local dd = CFG.DeadDrops
	if not tupac_dumpsters_isDropper( ply ) then
		DarkRP.notify( ply, 1, 4, "Only the Resistance can leave dead drops." )
		return ""
	end
	local ent = lookedAtDumpster( ply )
	if not ent then
		DarkRP.notify( ply, 1, 4, "Look at a dumpster up close to leave a dead drop." )
		return ""
	end
	if ent:GetDeadDrop() >= dd.maxItems then
		DarkRP.notify( ply, 1, 4, "This dumpster can't hide anything more." )
		return ""
	end

	args = string.lower( string.Trim( args or "" ) )
	if args == "weapon" or args == "gun" then
		local wep = ply:GetActiveWeapon()
		if not IsValid( wep ) or not hook.Call( "canDropWeapon", GAMEMODE, ply, wep ) then
			DarkRP.notify( ply, 1, 4, "You can't hide the weapon you're holding." )
			return ""
		end
		local ammoType = wep:GetPrimaryAmmoType()
		table.insert( ent.drop.weapons, {
			class = wep:GetClass(),
			name = wep:GetPrintName() or wep:GetClass(),
			clip = wep:Clip1() >= 0 and wep:Clip1() or nil,
			ammoType = ammoType and ammoType >= 0 and game.GetAmmoName( ammoType ) or nil,
		} )
		local name = wep:GetPrintName() or wep:GetClass()
		ply:StripWeapon( wep:GetClass() )
		ent:UpdateDropCount()
		DarkRP.notify( ply, 0, 5, "You hid your " .. name .. " in the dumpster." )
		return ""
	end

	local amount = math.floor( tonumber( args ) or 0 )
	if amount <= 0 then
		DarkRP.notify( ply, 1, 5, "Usage: /deaddrop <amount>  or  /deaddrop weapon" )
		return ""
	end
	if ent.drop.money + amount > dd.maxMoney then
		DarkRP.notify( ply, 1, 4, "A dumpster can hide at most " .. DarkRP.formatMoney( dd.maxMoney ) .. "." )
		return ""
	end
	if not ply:canAfford( amount ) then
		DarkRP.notify( ply, 1, 4, "You don't have " .. DarkRP.formatMoney( amount ) .. "." )
		return ""
	end
	ply:addMoney( -amount )
	ent.drop.money = ent.drop.money + amount
	ent:UpdateDropCount()
	DarkRP.notify( ply, 0, 5, "You hid " .. DarkRP.formatMoney( amount ) .. " in the dumpster." )
	return ""
end
DarkRP.defineChatCommand( "deaddrop", deadDrop )

--[[---------------------------------------------------------------------------
Placing dumpsters: fixed ones from config.lua, plus ones placed in game with
/adddumpster, saved per map in data/rp1942/dumpsters_<map>.json
---------------------------------------------------------------------------]]
local SAVE_DIR = "rp1942"
local function saveFile() return SAVE_DIR .. "/dumpsters_" .. game.GetMap() .. ".json" end

local function loadSaved()
	local raw = file.Read( saveFile(), "DATA" )
	local list = raw and util.JSONToTable( raw ) or {}
	return list
end

local function writeSaved( list )
	file.CreateDir( SAVE_DIR )
	file.Write( saveFile(), util.TableToJSON( list, true ) )
end

local function spawnDumpster( pos, ang, saveId )
	local d = ents.Create( "rp1942_dumpster" )
	if not IsValid( d ) then return end
	d:SetPos( pos )
	d:SetAngles( ang )
	d:Spawn()
	d.saveId = saveId
	local phys = d:GetPhysicsObject()
	if IsValid( phys ) then phys:EnableMotion( false ) end
	return d
end

function spawn_tupac_dumpsters()
	for _, v in pairs( get_dumpsters_spawn_pos() ) do
		local d = spawnDumpster( v.pos, v.ang )
		if IsValid( d ) then
			d:DropToFloor()
			local phys = d:GetPhysicsObject()
			if IsValid( phys ) then phys:EnableMotion( false ) end
		end
	end
	for id, v in pairs( loadSaved() ) do
		spawnDumpster( Vector( v.x, v.y, v.z ), Angle( 0, v.yaw, 0 ), id )
	end
end

hook.Add( "InitPostEntity", "spawn_dumpsters", spawn_tupac_dumpsters )
hook.Add( "PostCleanupMap", "spawn_dumpsters", spawn_tupac_dumpsters )   --> admin map cleanups don't delete them for good

local function allowed( ply )
	if CFG.AdminCheck( ply ) then return true end
	DarkRP.notify( ply, 1, 4, "You aren't allowed to place dumpsters." )
	return false
end

DarkRP.defineChatCommand( "adddumpster", function( ply )
	if not allowed( ply ) then return "" end
	local tr = ply:GetEyeTrace()
	if not tr.Hit or tr.HitPos:Distance( ply:EyePos() ) > 400 then
		DarkRP.notify( ply, 1, 4, "Look at the floor where the dumpster should go." )
		return ""
	end

	local ang = Angle( 0, ply:EyeAngles().y + 180, 0 )   --> facing you
	local d = spawnDumpster( tr.HitPos + Vector( 0, 0, 4 ), ang )
	if not IsValid( d ) then return "" end
	d:DropToFloor()
	local phys = d:GetPhysicsObject()
	if IsValid( phys ) then phys:EnableMotion( false ) end

	local list = loadSaved()
	local id = tostring( os.time() ) .. "_" .. math.random( 1000, 9999 )
	local pos = d:GetPos()
	list[ id ] = { x = pos.x, y = pos.y, z = pos.z, yaw = ang.y }
	writeSaved( list )
	d.saveId = id

	DarkRP.notify( ply, 0, 5, "Dumpster placed and saved for this map." )
	ServerLog( string.format( "[1942] %s placed a dumpster at %s\n", ply:Nick(), tostring( pos ) ) )
	return ""
end )

DarkRP.defineChatCommand( "removedumpster", function( ply )
	if not allowed( ply ) then return "" end
	local d = lookedAtDumpster( ply, 400 )
	if not d then
		DarkRP.notify( ply, 1, 4, "Look at a dumpster to remove it." )
		return ""
	end

	if d.saveId then
		local list = loadSaved()
		list[ d.saveId ] = nil
		writeSaved( list )
		DarkRP.notify( ply, 0, 5, "Dumpster removed and deleted from this map's save." )
	else
		DarkRP.notify( ply, 0, 8, "Dumpster removed until the next restart. It's listed in config.lua (AddSpawnPos); delete it there to remove it for good." )
	end
	ServerLog( string.format( "[1942] %s removed a dumpster at %s\n", ply:Nick(), tostring( d:GetPos() ) ) )
	d:Remove()
	return ""
end )

function ENT:OnRemove()
	timer.Remove( "tupac_dumpsters_spawn_" .. self:EntIndex() )
	for ply in pairs( self.searchers or {} ) do
		if IsValid( ply ) then setHold( ply, 0, 0 ) end
	end
end

--> The entity's class name comes from its folder: lua/entities/rp1942_dumpster
--> -> "rp1942_dumpster", the name every ents.Create() above uses. (It used to
--> live in a folder called "dumpsters" and was registered a second time by
--> hand, which put two dumpsters in the spawn menu.)

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

	checkList( CFG.Weapons, "Weapons" )
	checkList( CFG.Entities, "Entities" )
end )
