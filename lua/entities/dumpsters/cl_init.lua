include( "shared.lua" )

surface.CreateFont( "RP1942_DumpsterTitle", { font = "Roboto", size = 34, weight = 800, extended = true } )
surface.CreateFont( "RP1942_DumpsterLine",  { font = "Roboto", size = 26, weight = 500, extended = true } )

--[[---------------------------------------------------------------------------
Floating label: a subclass of RP1942.Floater (rp1942_core/cl_floater.lua).
The base class handles position, facing, the distance cutoff and fade;
this class only says what the dumpster's panel shows. Styled like the
F4 menu / supply train label: a small dark card with a coloured strip.

Built on first draw rather than when this file loads, so it doesn't depend on
the order GMod loads entities vs. DarkRP modules. If rp1942_core is missing,
the dumpster still draws, just without a label.
---------------------------------------------------------------------------]]
local DumpsterLabel

--> This player's own cooldowns, sent by the server: [dumpster] = CurTime() when ready
local readyAt = setmetatable( {}, { __mode = "k" } )
net.Receive( "tupac_dumpsters_cooldown", function()
	local ent, t = net.ReadEntity(), net.ReadFloat()
	if IsValid( ent ) then readyAt[ ent ] = t end
end )

local function cooldownLeft( ent )
	return math.max( 0, ( readyAt[ ent ] or 0 ) - CurTime() )
end

local function colors()
	local f4 = RP1942 and RP1942.F4Config and RP1942.F4Config.colors or {}
	return {
		bg    = Color( 14, 13, 12, 215 ),
		strip = f4.gold or Color( 201, 168, 92 ),
		text  = f4.text or Color( 236, 228, 212 ),
		dim   = Color( 160, 152, 136 ),
		busy  = Color( 170, 60, 50 ),
		drop  = Color( 110, 170, 90 ),
	}
end

local function getLabel()
	if DumpsterLabel or not ( RP1942 and RP1942.Floater ) then return DumpsterLabel end

	local cfg = tupac_dumpsters_config or {}
	DumpsterLabel = RP1942.Floater:extend{
		scale    = 0.1,
		maxDist  = cfg.LabelDistance or 300,      --> not drawn beyond this (~52 units = 1 m)
		fadeDist = cfg.LabelFadeDistance or 80,   --> fades out over the last N units
	}

	--> Just above the lid, whatever the model's size
	function DumpsterLabel:GetDrawPos( ent )
		local center = ent:OBBCenter()
		return ent:LocalToWorld( Vector( center.x, center.y, ent:OBBMaxs().z ) ) + Vector( 0, 0, 22 )
	end

	function DumpsterLabel:Paint( ent )
		local C = colors()
		local drop = ent:GetDeadDrop() > 0 and tupac_dumpsters_isDropper( LocalPlayer() )
		local w, h = 300, drop and 122 or 88
		local x, y = -w / 2, -h

		local cooldown = cooldownLeft( ent )
		draw.RoundedBox( 0, x, y, w, h, C.bg )
		surface.SetDrawColor( cooldown > 0 and C.busy or C.strip )
		surface.DrawRect( x, y, 6, h )

		draw.SimpleText( "DUMPSTER", "RP1942_DumpsterTitle", x + 22, y + 10, C.text )
		if cooldown <= 0 then
			draw.SimpleText( "Hold E to search", "RP1942_DumpsterLine", x + 22, y + 50, C.dim )
		else
			draw.SimpleText( "Searched  ·  " .. string.FormattedTime( cooldown, "%01i:%02i" ), "RP1942_DumpsterLine", x + 22, y + 50, C.dim )
		end
		if drop then
			--> Only the Resistance ever sees this line
			draw.SimpleText( "Dead drop inside  ·  hold E", "RP1942_DumpsterLine", x + 22, y + 84, C.drop )
		end
	end

	return DumpsterLabel
end

function ENT:Draw()
	self:DrawModel()

	local label = getLabel()
	if label then label:Draw( self ) end
end

--> Must match the registration in init.lua, or the client only knows this
--> entity as "dumpsters" (the folder name) and ENT:Draw never gets used.
scripted_ents.Register( ENT, "tupac_dumpster" )
