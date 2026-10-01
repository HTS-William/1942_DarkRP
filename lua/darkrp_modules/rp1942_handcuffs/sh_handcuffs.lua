--[[---------------------------------------------------------------------------
1942 DarkRP - handcuffs (shared: the settings, and holding the prisoner still)

Replaces DarkRP's arrest baton (one hit, instantly arrested) for every job
that has W.arrest (rp1942_core/sh_config.lua: arrest = "rp1942_handcuffs").

    LEFT CLICK a player   grab them: they're frozen (can't move, shoot, use,
                          jump, sit, noclip, change job or kill themselves)
                          and a progress bar runs for both of you. After
                          `time` seconds they're arrested, as with the baton.
    RIGHT CLICK           let go

It stops (no arrest) if you walk more than keepRange away, put the cuffs
away, or either of you dies, sits in a vehicle or gets arrested meanwhile.
Who can be arrested is DarkRP's usual check (canArrest): the Reich can't be,
a jail position must be set, and so on; asked again at the end.

Files: sh_handcuffs.lua (this), sv_handcuffs.lua, lua/weapons/rp1942_handcuffs.lua.
The bar is core's hold bar (rp1942_core/cl_holdbar.lua).
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.HandcuffsConfig = {
    time      = 8,     -- seconds to handcuff someone
    range     = 90,    -- how close you must be to grab them
    keepRange = 130,   -- move further away than this and you let go
}

-- The arrester while this player is being handcuffed, or nil
function RP1942.cuffedBy(ply)
    local by = IsValid(ply) and ply:GetNW2Entity("RP1942_CuffedBy")
    if IsValid(by) then return by end
end
function RP1942.isBeingCuffed(ply) return RP1942.cuffedBy(ply) ~= nil end

-- Frozen: no movement, no buttons (shared, so the client predicts it too)
hook.Add("StartCommand", "RP1942_Handcuffs", function(ply, cmd)
    if not RP1942.isBeingCuffed(ply) then return end
    cmd:ClearMovement()
    cmd:ClearButtons()
end)

hook.Add("SetupMove", "RP1942_Handcuffs", function(ply, mv)
    if not RP1942.isBeingCuffed(ply) then return end
    mv:SetForwardSpeed(0)
    mv:SetSideSpeed(0)
    mv:SetUpSpeed(0)
    local v = mv:GetVelocity()
    mv:SetVelocity(Vector(0, 0, math.min(v.z, 0)))   -- no sliding away; still falls
end)

hook.Add("PlayerNoClip", "RP1942_Handcuffs", function(ply, desired)
    if desired and RP1942.isBeingCuffed(ply) then return false end
end)
