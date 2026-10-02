--[[---------------------------------------------------------------------------
1942 DarkRP - the Führer's perks (shared)                       <- edit prices here

The Führer buys perks for the Reich from the treasury, in his menu (F3,
"Perks"). Each costs treasury money and has a cooldown before it can be
bought again.

    apc       the Sd.Kfz. 222 armoured car, owned by the Wehrmacht Driver, at the APC garage staff marked on
              this map (!setapcspot). Only the Wehrmacht Driver drives it.
              One at a time; it stays until it's destroyed. Its gun fires
              Panzerschreck rockets (the driver's left click).
    kevlar    every Reich soldier online gets full armour, right now
    paybonus  Reich soldiers' wages are raised for a while

"Reich soldiers": Reich jobs in the Wehrmacht, Waffen-SS or Leibstandarte
(not the Gestapo, scientist, supplier or the Führer himself).

Files: sh_perks.lua (this), sv_perks.lua (buying, the APC), cl_perks.lua
(the section in the Führer's menu).
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.Perks = {
    soldierBranches = { wehrmacht = true, waffen_ss = true, leibstandarte = true },

    list = {   -- shown in this order
        {
            id = "apc", name = "Armoured car (Sd.Kfz. 222)",
            desc = "An armoured car at the APC garage, for the Wehrmacht Driver. Stays until it's destroyed.",
            price = 60000, cooldown = 600,          -- seconds after it's destroyed before another can be bought
        },
        {
            id = "kevlar", name = "Kevlar issue",
            desc = "Every Reich soldier online gets full armour, now.",
            price = 20000, cooldown = 600,
        },
        {
            id = "paybonus", name = "Soldiers' pay bonus",
            desc = "Reich soldiers' wages are raised by half for 20 minutes.",
            price = 25000, cooldown = 0,            -- can be bought again while running: it adds the time on
            minutes = 20, mult = 1.5,
        },
    },

    apc = {
        model    = "models/tank222.mdl",
        script   = "scripts/vehicles/pog_apc.txt",
        health   = 2000,                          -- damage it takes before it's destroyed
        drivers  = { wehrdriver = true },         -- job commands that may drive it
        blastDamage = 150, blastRadius = 300,     -- when it's destroyed
        -- Its gun: the driver's left click fires a Panzerschreck rocket where he looks
        cannon = {
            projectile = "mcv_proj_panzerschreck",
            weapon     = "mcv_panzerschreck",     -- its flight (speed, drop) is copied from this weapon
            reload     = 6,                       -- seconds between shots
            shotCost   = 500,                     -- each shot costs the driver this much of his own money (0 = free)
            sound      = "MCV_Weapon_RPG7.Single",
            -- Where the rocket leaves the car, from the middle of its roof:
            -- forward = towards the front (units), up = above the roof (negative: below it).
            -- Tune it live: rp1942_apc_muzzle <forward> <up> in console (superadmin), then paste the numbers here.
            muzzle     = { forward = 40, up = -24 },
        },
    },
}

-- 125 -> "2:05" (both realms: RP1942.clock is client-only)
function RP1942.perkClock(seconds)
    seconds = math.max(math.ceil(seconds or 0), 0)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function RP1942.getPerk(id)
    for _, p in ipairs(RP1942.Perks.list) do if p.id == id then return p end end
end

function RP1942.isReichSoldier(ply)
    if not (IsValid(ply) and RP1942.getFaction and RP1942.getFaction(ply) == "reich") then return false end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    return job ~= nil and RP1942.Perks.soldierBranches[job.branch or ""] == true
end

-- Shared state (set by the server)
--   GetGlobal2Float("RP1942_PerkCD_<id>")    when the perk can be bought again
--   GetGlobal2Float("RP1942_PayBonusUntil")   end of the pay bonus
--   GetGlobal2Entity("RP1942_APC")            the armoured car, while it exists
function RP1942.perkCooldown(id)
    return math.max(GetGlobal2Float("RP1942_PerkCD_" .. id, 0) - CurTime(), 0)
end

function RP1942.payBonusLeft()
    return math.max(GetGlobal2Float("RP1942_PayBonusUntil", 0) - CurTime(), 0)
end

-- Wage multiplier for a player (used by the payday in rp1942_economy/sv_economy.lua)
function RP1942.salaryBonus(ply)
    if RP1942.payBonusLeft() <= 0 or not RP1942.isReichSoldier(ply) then return 1 end
    local p = RP1942.getPerk("paybonus")
    return p and p.mult or 1
end
