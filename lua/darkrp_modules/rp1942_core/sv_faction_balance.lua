--[[---------------------------------------------------------------------------
1942 DarkRP - faction balance (server)

DarkRP's `max` only caps a single job. This caps whole factions so the Reich
can't swallow the server (and vice versa). Rules live in RP1942.Config.Balance.

IMPORTANT: return nothing (nil) when allowing. Returning true from a
playerCanChangeTeam hook would skip every other addon's checks.
---------------------------------------------------------------------------]]
local factionNames = {
    reich      = "The Reich",
    resistance = "The Resistance",
}

hook.Add("playerCanChangeTeam", "RP1942_FactionBalance", function(ply, teamNr, force)
    if force then return end

    local target = RP1942.getJobFaction(teamNr)
    local rule = RP1942.Config.Balance[target]
    if not rule then return end

    -- Moving between jobs of the same faction doesn't grow it
    if RP1942.getFaction(ply) == target then return end

    local current  = RP1942.countFaction(target, ply)
    local opponent = RP1942.countFaction(rule.opponent, ply)
    local cap      = rule.floor + rule.perOpponent * opponent

    if current >= cap then
        return false, string.format("%s is at full strength (%d/%d). The other side needs more players first.",
            factionNames[target] or target, current, cap)
    end
end)
