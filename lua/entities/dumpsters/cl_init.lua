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
function ENT:Draw()
	self:DrawModel()
	local jump = math.abs( math.cos( CurTime() * 3 ) )
	local Ang = self:GetAngles()
	Ang:RotateAroundAxis(Ang:Up(), 90);
	Ang:RotateAroundAxis(Ang:Forward(), 90);
	local Offset = Vector( 0, 0, 50 )
	local Pos = self:GetPos() + Offset
	cam.Start3D2D( Pos, Angle( 0, LocalPlayer():EyeAngles().y - 90, 90 ), 0.1 )
		draw.RoundedBox( 0, -300, -400, 600, 300, Color( 0, 0, 0, 200 ) )
		if self:GetCooldown_Time() <= 0 then
			draw.DrawText( "Dumpster", "tupac_dumpsters_font_150", 0, -400, color_white, 1 )
			draw.DrawText( "Press E to USE", "tupac_dumpsters_font_80", 0, -280, color_white, 1 )
			draw.DrawText( "Job restricted.", "tupac_dumpsters_font_65", 0, -200, color_white, 1 )
		elseif self:GetCooldown_Time() > 0 then
			draw.DrawText( "Cooldown:", "tupac_dumpsters_font_65", 0, -400, color_white, 1 )
			draw.DrawText( string.FormattedTime( self:GetCooldown_Time(), "%01i:%02i"), "tupac_dumpsters_font_150", 0, -300, color_white, 1 )
		end
	cam.End3D2D()
end

--> Must match the registration in init.lua, or the client only knows this
--> entity as "dumpsters" (the folder name) and ENT:Draw never gets used.
scripted_ents.Register( ENT, "tupac_dumpster" )
