--[[---------------------------------------------------------------------------
1942 DarkRP - Reich supply train (world event)
Settings live in darkrp_modules/rp1942_events/sh_events.lua
(RP1942.Events.train). Started by the world events scheduler or by an admin
with "rp1942_event train"; not meant to be spawned from the Q menu.
---------------------------------------------------------------------------]]
ENT.Type        = "anim"
ENT.Base        = "base_anim"
ENT.PrintName   = "Reich Supply Train"
ENT.Author      = "Claude & William"
ENT.Spawnable   = false
ENT.RenderGroup = RENDERGROUP_BOTH   -- so the fade-out at the end draws

-- Phases
ENT.ARRIVING  = 0   -- rolling in to the station
ENT.STOPPED   = 1   -- waiting at the station
ENT.DEPARTING = 2   -- on its way to the end of the line
ENT.LEAVING   = 3   -- reached the end, vanishing

function ENT:SetupDataTables()
    self:NetworkVar("Int",    0, "Phase")
    self:NetworkVar("Int",    1, "Crates")
    self:NetworkVar("Float",  0, "PhaseStart")
    self:NetworkVar("Vector", 0, "RouteA")   -- spawn point (behind the start)
    self:NetworkVar("Vector", 1, "RouteB")   -- end of the line
    self:NetworkVar("Vector", 2, "RouteS")   -- the station stop
end

function ENT:GetConfig()
    return RP1942 and RP1942.Events and RP1942.Events.train or {}
end

-- May this player rob the train at all? (faction rule only)
function ENT:CanRob(ply)
    local blocked = self:GetConfig().blockedFactions or {}
    local faction = RP1942.getFaction and RP1942.getFaction(ply)
    return not (faction and blocked[faction])
end

--[[---------------------------------------------------------------------------
Distance travelled t seconds after departing, over a line of length dist:
speeds up for accelTime seconds, cruises, brakes over accelTime seconds.
Returns the distance and whether it has arrived.
---------------------------------------------------------------------------]]
function ENT.Travelled(t, dist, speed, accelTime)
    if dist <= 0 or t <= 0 then return 0, dist <= 0 end
    local a = speed / math.max(accelTime, 0.01)
    local ta = speed / a
    local da = 0.5 * a * ta * ta

    if 2 * da >= dist then   -- too short to reach full speed: speed up, then brake
        ta = math.sqrt(dist / a)
        if t < ta then return 0.5 * a * t * t, false end
        local t2 = t - ta
        if t2 >= ta then return dist, true end
        return dist / 2 + a * ta * t2 - 0.5 * a * t2 * t2, false
    end

    local tc = (dist - 2 * da) / speed
    if t < ta then return 0.5 * a * t * t, false end
    if t < ta + tc then return da + speed * (t - ta), false end
    local t3 = t - ta - tc
    if t3 >= ta then return dist, true end
    return da + speed * tc + speed * t3 - 0.5 * a * t3 * t3, false
end
