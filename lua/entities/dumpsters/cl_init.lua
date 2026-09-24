include( "shared.lua" )
--> Only sizes 65/80/150 are ever drawn below - the original version created
--> 150 fonts (one per size 1-150) on every client load, which is wasted work.
local function j_scoreboard_createfont( i, name, font_name )
	local font_size = i
	surface.CreateFont( name .. font_size,{
		font = font_name,
		size = font_size,
		weight = 500
	} )
end

for _, size in ipairs( { 65, 80, 150 } ) do
	j_scoreboard_createfont( size, "tupac_dumpsters_font_", "Bebas Neue Bold" )
end

--[[---------------------------------------------------------------------------
Floating label: a subclass of RP1942.Floater (rp1942_core/cl_floater.lua).
The base class handles position, facing, the distance cutoff and fade;
this class only says what the dumpster's panel shows.

Built on first draw rather than when this file loads, so it doesn't depend on
the order GMod loads entities vs. DarkRP modules. If rp1942_core is missing,
the dumpster still draws, just without a label.
---------------------------------------------------------------------------]]
local COLOR_PANEL = Color( 0, 0, 0, 200 )
local DumpsterLabel

local function getLabel()
	if DumpsterLabel or not ( RP1942 and RP1942.Floater ) then return DumpsterLabel end

	local cfg = tupac_dumpsters_config or {}
	DumpsterLabel = RP1942.Floater:extend{
		offset   = Vector( 0, 0, 50 ),
		scale    = 0.1,
		maxDist  = cfg.LabelDistance or 400,      --> not drawn beyond this (~52 units = 1 m)
		fadeDist = cfg.LabelFadeDistance or 100,  --> fades out over the last N units
	}

	function DumpsterLabel:Paint( ent )
		draw.RoundedBox( 0, -300, -400, 600, 300, COLOR_PANEL )

		local cooldown = ent:GetCooldown_Time()
		if cooldown <= 0 then
			draw.DrawText( "Dumpster", "tupac_dumpsters_font_150", 0, -400, color_white, 1 )
			draw.DrawText( "Press E to USE", "tupac_dumpsters_font_80", 0, -280, color_white, 1 )
			draw.DrawText( "Hobos find better loot.", "tupac_dumpsters_font_65", 0, -200, color_white, 1 )
		else
			draw.DrawText( "Cooldown:", "tupac_dumpsters_font_65", 0, -400, color_white, 1 )
			draw.DrawText( string.FormattedTime( cooldown, "%01i:%02i" ), "tupac_dumpsters_font_150", 0, -300, color_white, 1 )
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
