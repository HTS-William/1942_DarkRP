--[[---------------------------------------------------------------------------
1942 DarkRP - Reichsbank robbery (shared)

HOW IT PLAYS
    1. START   Someone outside the Reich presses E on the Reichsbank vault
               and confirms. Only with enough Reich online (minReich) and
               the bank off cooldown. The alarm sounds, everyone gets a
               banner, and the robber is WANTED.
    2. CREW    For the first joinWindow seconds, others press E on the vault
               to ask to join. The initiator accepts or refuses each one
               (a pop-up). Accepted crew are WANTED too.
    3. HOLD    The initiator must survive for `duration`, free, and within
               holdRadius of the vault. Dying, being arrested, changing job,
               leaving the game, or staying outside the radius for
               leaveGrace seconds FAILS the robbery. Crew members can die:
               they just drop out of the crew.
    4. PAYOUT  Time up with the initiator standing: the WHOLE treasury is
               emptied and split evenly between the initiator and the crew
               still alive, free and within the radius. Then the cooldown.

The bank is the vault entity (rp1942_bank_vault), not an area: "inside the
bank" means within holdRadius of it. Its model is a setting.

STAFF (ULX 42Bros, or chat with /)
    !addvault        place the vault where you're looking (saved per map)
    !removevault     remove the vault you're looking at (and from the save)
    !banksettings    settings menu: every value below, plus status and the
                     debug buttons (start / stop / finish / reset cooldown)
    !bankstart [name]   start a robbery now with that player (or you) as the
                     initiator, ignoring every requirement
    !bankstop        call off the robbery: no payout, no cooldown
    !bankfinish      end the timer now: the robbery succeeds and pays out
    !bankcooldown    clear the cooldown
    !bankstatus      what the bank is doing right now
Who may: "ulx banksettings" (and "ulx addvault") in ULX Groups; without ULX,
superadmins.

The settings below are the defaults. Changes made in !banksettings are saved
in data/rp1942/bank.json and win over these.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.Bank = RP1942.Bank or {}
local B = RP1942.Bank

B.defaults = {
    enabled     = true,
    duration    = 600,    -- seconds the initiator must hold out (10 min)
    cooldown    = 2700,   -- seconds after a robbery (won or lost) before the next (45 min)
    joinWindow  = 30,     -- seconds after the start when others can ask to join
    crewMax     = 4,      -- crew size, the initiator included
    minReich    = 5,      -- Reich players online needed to start
    holdRadius  = 700,    -- units from the vault that count as "in the bank" (~52 units = 1 m)
    leaveGrace  = 10,     -- seconds the initiator may be outside before it fails
    useRange    = 130,    -- how close you must be to press E on the vault
    killReward  = 1000,   -- paid to a Reich member who kills or arrests the initiator
    model       = "models/props_wasteland/controlroom_storagecloset001a.mdl",
    alarm       = "sounds/bankalarm.mp3",   -- loops at the vault while it's robbed
    alarmVolume = 1,
    alarmRange  = 2500,   -- units: how far the alarm carries
    ignoreReichMinimum = false,   -- testing: robberies start with any number of Reich online
}

-- Jobs (by command) that can never rob the bank. The Reich can't either.
B.blockedJobs = { banker = true }

B.text = {
    title      = "BANK ROBBERY: REICHSBANK",
    bodyReich  = "The treasury is being robbed. Retake the Reichsbank before the time runs out!",
    bodyOthers = "The Reichsbank is being robbed.",
    wanted     = "For robbing the Reichsbank",
    wonTitle   = "THE REICHSBANK HAS BEEN ROBBED",
    won        = "%s was taken from the Reich treasury.",
    lostTitle  = "BANK ROBBERY FOILED",
}

-- The live settings (the server loads bank.json over the defaults and sends
-- them to every client)
B.settings = B.settings or table.Copy(B.defaults)

function RP1942.bankSetting(key)
    local v = B.settings[key]
    if v == nil then v = B.defaults[key] end
    return v
end

-- What the bank is doing, readable on both sides
function RP1942.bankState()
    return {
        active    = GetGlobal2Bool("rp1942_bank_active", false),
        endsAt    = GetGlobal2Float("rp1942_bank_ends", 0),
        joinEnds  = GetGlobal2Float("rp1942_bank_join", 0),
        cooldown  = GetGlobal2Float("rp1942_bank_cd", 0),
        initiator = GetGlobal2Entity("rp1942_bank_init", NULL),
        vault     = GetGlobal2Entity("rp1942_bank_vault", NULL),
    }
end

-- Can this player take part at all? (false, reason)
function RP1942.bankCanRob(ply)
    if not IsValid(ply) then return false, "?" end
    if RP1942.getFaction and RP1942.getFaction(ply) == "reich" then return false, "The Reich doesn't rob its own bank." end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    if job and B.blockedJobs[job.command] then return false, "Your job can't rob the bank." end
    return true
end

function RP1942.bankIsCrew(ply)
    return IsValid(ply) and ply:GetNW2Bool("RP1942_BankCrew", false)
end

