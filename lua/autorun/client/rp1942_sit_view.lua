--[[---------------------------------------------------------------------------
1942 DarkRP - third person while sitting (client)

Sitting players are kept hittable (lua/autorun/server/rp1942_sit_rules.lua:
a seat is no shield). Garry's Mod's seat third-person camera pulls back from
your head with a trace that ignores the seat but not you, so it hit your own
body straight away and the camera stayed glued to your head.

This is Garry's Mod's own seat camera (GM:CalcVehicleView), only for
SitAnywhere seats, with you (and anyone sat on the same seat) left out of
the trace. Other vehicles are untouched.
---------------------------------------------------------------------------]]
local WALL = 4

local function isSitSeat(veh)
    return IsValid(veh) and veh:GetClass() == "prop_vehicle_prisoner_pod"
        and (veh:GetNWBool("SitAnywhereSeat", false) or veh:GetModel() == "models/nova/airboat_seat.mdl" and veh:GetNoDraw())
end

hook.Add("CalcVehicleView", "RP1942_SitThirdPerson", function(veh, ply, view)
    if not isSitSeat(veh) or veh.GetThirdPersonMode == nil or ply:GetViewEntity() ~= ply then return end
    if not veh:GetThirdPersonMode() then return end

    local mn, mx = veh:GetRenderBounds()
    local radius = (mn - mx):Length()
    radius = radius + radius * veh:GetCameraDistance()
    local target = view.origin + view.angles:Forward() * -radius

    local tr = util.TraceHull({
        start = view.origin, endpos = target,
        mins = Vector(-WALL, -WALL, -WALL), maxs = Vector(WALL, WALL, WALL),
        filter = function(e)
            if e == ply or e:IsPlayer() or e:IsVehicle() then return false end
            local c = e:GetClass()
            -- as Garry's Mod's own: skip what may be attached to the seat
            return not (string.StartWith(c, "prop_physics") or string.StartWith(c, "prop_dynamic")
                or string.StartWith(c, "phys_bone_follower") or string.StartWith(c, "prop_ragdoll")
                or string.StartWith(c, "gmod_"))
        end,
    })
    view.origin = tr.HitPos
    if tr.Hit and not tr.StartSolid then view.origin = view.origin + tr.HitNormal * WALL end
    view.drawviewer = true
    return view
end)
