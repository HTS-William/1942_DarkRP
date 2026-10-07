--[[---------------------------------------------------------------------------
1942 DarkRP - the NLR zone (shared: settings)

When you die, a bubble (the NLR zone) is left where you died, for the length
of the New Life Rule. Only you see it. Walk into it and you're warned to get
out; still inside when the warning runs out, you're sent back to spawn and
held there (frozen, and unhurt) until your NLR is over.

    !clearnlr <player>   staff: lift someone's NLR (e.g. they died to a rule break)

Server: sv_nlr.lua. Client (the bubble, the timer, the warning): cl_nlr.lua.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.NLR = {
    enabled = true,
    time    = 180,     -- seconds the NLR lasts after a death (3 minutes, as in the rules)
    radius  = 750,     -- size of the zone, in units, around where you died (about 19 m)
    grace   = 10,      -- seconds to leave the zone once warned
    -- Jobs (by command) that never get an NLR zone
    exempt  = { staffduty = true },
}

-- The local player's / a player's NLR state, from what the server networks
function RP1942.nlrState(ply)
    local ends = ply:GetNW2Float("RP1942_NLREnd", 0)
    if ends <= CurTime() then return nil end
    return {
        pos    = ply:GetNW2Vector("RP1942_NLRPos", vector_origin),
        ends   = ends,
        warnBy = ply:GetNW2Float("RP1942_NLRWarn", 0),   -- 0 = not warned
        held   = ply:GetNW2Bool("RP1942_NLRHeld", false),
    }
end
