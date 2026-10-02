--[[---------------------------------------------------------------------------
1942 DarkRP - Reich boots: Day of Defeat: Source footsteps (shared)

Every Reich job walks with DoD:S's hobnailed-boot footsteps instead of the
Half-Life 2 ones, except the jobs in NOT_THESE below. The surface still
counts: concrete, wood, metal, grass, mud, snow, water... each has its own
set, picked from the sound the game would have played.

The sounds come from the server's dod_content_pack addon
(sound/player/footsteps/male/), so players get them with that pack.
---------------------------------------------------------------------------]]
local NOT_THESE = {          -- Reich jobs that keep normal footsteps (job commands)
    gersupplier = true,      -- German Supplier
    banker      = true,      -- Reich Banker
    fuhrer      = true,      -- Führer
    gestapo     = true,      -- Gestapo (plain clothes: boots would give them away)
}

local DIR = "player/footsteps/male/"   -- in dod_content_pack
local SETS = {               -- DoD:S has 6 of each
    chainlink = true, concrete = true, dirt = true, duct = true, grass = true, gravel = true,
    ice = true, ladder = true, metal = true, metalgrate = true, mud = true, sand = true,
    slosh = true, snow = true, tile = true, wade = true, wet = true, wood = true, woodpanel = true,
}
-- HL2 surface sounds with no DoD:S set of the same name
local ALIAS = { wood_box = "wood", wood_crate = "wood", woodpanel = "woodpanel", metal_box = "metal",
    metalvent = "duct", rubber = "concrete", glass = "tile", plaster = "concrete", carpet = "dirt" }

local function wearsBoots(ply)
    if not (RP1942.getFaction and RP1942.getFaction(ply) == "reich") then return false end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    return not (job and NOT_THESE[job.command])
end

-- "player/footsteps/concrete3.wav" -> "concrete"
local function setFor(snd)
    local name = string.match(string.lower(snd or ""), "([%a_]+)%d*%.wav$") or ""
    name = ALIAS[name] or name
    return SETS[name] and name or "concrete"
end

hook.Add("PlayerFootstep", "RP1942_ReichBoots", function(ply, pos, foot, snd, volume)
    if not wearsBoots(ply) then return end
    ply:EmitSound(DIR .. setFor(snd) .. math.random(1, 6) .. ".wav", 75, math.random(97, 103), volume)
    return true   -- instead of the normal step
end)
