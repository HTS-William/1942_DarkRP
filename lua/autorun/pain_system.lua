--[[---------------------------------------------------------------------------
    Pain System
    Gamemode-independent: works on Sandbox, DarkRP, TTT, etc.

    - Voices pain based on where a player was hit (leg / arm / torso)
    - Leg hits stop the player from jumping and sprinting for a while
    - Fall damage voices leg pain
---------------------------------------------------------------------------]]

PainSystem = PainSystem or {}

-----------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------
local CFG = {
    LegInjuryDuration = 20,     -- Seconds a leg shot prevents jump/sprint. 0 = until respawn.
    FallCripplesLegs  = false,  -- Should fall damage also stop jump/sprint?
    HealRestoreLegs   = 0.75,   -- Healing up to this fraction of max health restores legs. false = disabled.
    AllowNPCAttackers = false,  -- Should NPCs shooting players also trigger pain?
    SoundCooldown     = 0.75,   -- Min seconds between pain sounds per player (prevents spam from shotguns/SMGs)
    SoundLevel        = 75,     -- Sound level in dB (75 = normal voice range)
    UseFemaleVoices   = true,   -- Female player models use vo/npc/female01/ versions of the same lines
    HeadCategory      = "torso" -- Sound set for headshots ("torso", "arm", "leg", or false for silence)
}
PainSystem.Config = CFG

local NW_LEGS = "PainSys_LegsUntil"

function PainSystem.HasLegInjury(ply)
    return ply:GetNW2Float(NW_LEGS, 0) > CurTime()
end

-----------------------------------------------------------------------------
-- SHARED: movement restriction (runs on client + server so prediction stays smooth)
-----------------------------------------------------------------------------
hook.Add("StartCommand", "PainSystem_BlockInput", function(ply, cmd)
    if not PainSystem.HasLegInjury(ply) then return end
    cmd:RemoveKey(IN_JUMP)
    cmd:RemoveKey(IN_SPEED)
end)

hook.Add("SetupMove", "PainSystem_LimitSpeed", function(ply, mv, cmd)
    if not PainSystem.HasLegInjury(ply) then return end

    mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(bit.bor(IN_JUMP, IN_SPEED))))

    local walk = ply:GetWalkSpeed()
    if mv:GetMaxClientSpeed() > walk then
        mv:SetMaxClientSpeed(walk)
    end
end)

if CLIENT then return end

-----------------------------------------------------------------------------
-- SERVER
-----------------------------------------------------------------------------
AddCSLuaFile()

local SOUNDS = {
    leg = {
        "vo/npc/male01/myleg01.wav",
        "vo/npc/male01/myleg02.wav",
    },
    arm = {
        "vo/npc/male01/myarm01.wav",
        "vo/npc/male01/myarm02.wav",
    },
    torso = {
        "vo/npc/male01/hitingut01.wav",
        "vo/npc/male01/hitingut02.wav",
        "vo/npc/male01/mygut02.wav",
    },
}

for _, list in pairs(SOUNDS) do
    for _, snd in ipairs(list) do
        util.PrecacheSound(snd)
        util.PrecacheSound((snd:gsub("/male01/", "/female01/")))
    end
end

local HITGROUP_CATEGORY = {
    [HITGROUP_LEFTLEG]  = "leg",
    [HITGROUP_RIGHTLEG] = "leg",
    [HITGROUP_LEFTARM]  = "arm",
    [HITGROUP_RIGHTARM] = "arm",
    [HITGROUP_CHEST]    = "torso",
    [HITGROUP_STOMACH]  = "torso",
    [HITGROUP_GENERIC]  = "torso",
    [HITGROUP_GEAR]     = "torso",
}

local FEMALE_HINTS = { "female", "alyx", "mossman", "chell" }

local function IsFemale(ply)
    local mdl = string.lower(ply:GetModel() or "")
    for _, hint in ipairs(FEMALE_HINTS) do
        if mdl:find(hint, 1, true) then return true end
    end
    return false
end

local function PlayPain(ply, category)
    local list = category and SOUNDS[category]
    if not list then return end

    local now = CurTime()
    if (ply.PainSys_NextSound or 0) > now then return end
    ply.PainSys_NextSound = now + CFG.SoundCooldown

    local snd = list[math.random(#list)]
    if CFG.UseFemaleVoices and IsFemale(ply) then
        snd = snd:gsub("/male01/", "/female01/")
    end

    ply:EmitSound(snd, CFG.SoundLevel, math.random(96, 104), 1, CHAN_VOICE)
end

function PainSystem.InjureLegs(ply, duration)
    duration = duration or CFG.LegInjuryDuration
    local untilTime = (duration > 0) and (CurTime() + duration) or 1e9
    ply:SetNW2Float(NW_LEGS, math.max(ply:GetNW2Float(NW_LEGS, 0), untilTime))

    -- Remember the lowest health since injury, so legs only restore after an actual heal
    ply.PainSys_LowestHealth = math.min(ply.PainSys_LowestHealth or ply:Health(), ply:Health())
end

function PainSystem.HealLegs(ply)
    ply:SetNW2Float(NW_LEGS, 0)
    ply.PainSys_LowestHealth = nil
end

-- Health can be restored by anything (medkits, chargers, admin commands, other
-- addons), and there's no single hook for it, so check injured players on a short timer.
timer.Create("PainSystem_HealCheck", 0.25, 0, function()
    local threshold = CFG.HealRestoreLegs
    if not threshold then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and PainSystem.HasLegInjury(ply) then
            local hp      = ply:Health()
            local maxHp   = math.max(ply:GetMaxHealth(), 1)
            local lowest  = ply.PainSys_LowestHealth or hp

            if hp < lowest then
                ply.PainSys_LowestHealth = hp
            elseif hp > lowest and hp >= maxHp * threshold then
                PainSystem.HealLegs(ply)
            end
        end
    end
end)

-- Remember which hitgroup was struck. Returns nothing so it never interferes
-- with other addons/gamemodes that scale damage here.
hook.Add("ScalePlayerDamage", "PainSystem_RecordHitgroup", function(ply, hitgroup, dmginfo)
    ply.PainSys_HitGroup = hitgroup
    ply.PainSys_HitTime  = CurTime()
end)

local function GetHitGroup(ply, dmginfo)
    if ply.PainSys_HitTime == CurTime() and ply.PainSys_HitGroup then
        return ply.PainSys_HitGroup
    end
    -- Fallback if another addon's ScalePlayerDamage hook returned early before ours
    if dmginfo:IsBulletDamage() then
        return ply:LastHitGroup()
    end
    return nil
end

-- Runs AFTER damage is applied, so god mode, spawn protection, team-kill
-- blockers, etc. that cancel damage won't cause a pain sound.
hook.Add("PostEntityTakeDamage", "PainSystem_React", function(ply, dmginfo, took)
    if not took or not IsValid(ply) or not ply:IsPlayer() then return end
    if not ply:Alive() or ply:Health() <= 0 then return end

    if PainSystem.HasLegInjury(ply) then
        ply.PainSys_LowestHealth = math.min(ply.PainSys_LowestHealth or ply:Health(), ply:Health())
    end

    -- Falling
    if dmginfo:IsFallDamage() then
        PlayPain(ply, "leg")
        if CFG.FallCripplesLegs then PainSystem.InjureLegs(ply) end
        return
    end

    local attacker = dmginfo:GetAttacker()

    -- Other self-inflicted damage (own grenade, RPG, etc.)
    if attacker == ply then
        PlayPain(ply, "torso")
        return
    end

    -- Only react to players (and optionally NPCs)
    if not IsValid(attacker) then return end
    if not (attacker:IsPlayer() or (CFG.AllowNPCAttackers and attacker:IsNPC())) then return end

    local hitgroup = GetHitGroup(ply, dmginfo)
    local category

    if hitgroup == HITGROUP_HEAD then
        category = CFG.HeadCategory
    else
        category = HITGROUP_CATEGORY[hitgroup] or "torso"
    end

    if not category then return end

    PlayPain(ply, category)

    if category == "leg" and hitgroup ~= nil then
        PainSystem.InjureLegs(ply)
    end
end)

-- Clear leg injuries on death / respawn
hook.Add("PlayerSpawn", "PainSystem_Reset", PainSystem.HealLegs)
hook.Add("PlayerDeath", "PainSystem_ResetDeath", function(ply) PainSystem.HealLegs(ply) end)
