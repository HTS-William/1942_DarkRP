--[[---------------------------------------------------------------------------
42Bros - reports: players report rule breaks, staff handle them

PLAYERS
    @ <what happened>     sends a report (the rules already say "report with @")
    /report               a form: who it's about (or nobody) and what happened
    /report <text>        sends one straight away
    You're told when it's sent, when a staff member takes it, and when it's
    closed. Reports wait until staff are online. At most `maxOpen` open at a
    time each, and one every `cooldown` seconds.

STAFF (anyone with "ulx reports", operators and up by default)
    Every new report shows in chat with a sound, and a counter in the corner
    shows how many are open.
    !reports              the list: who reported whom, what happened, how long
                          ago, who's on it. On each one:
        Claim / Release   "I'm on it", so two staff don't both go
        Go to             you to the reporter      (needs "ulx goto")
        Bring             the reporter to you      (needs "ulx bring")
        Clean up          removes everything the reported player owns in the
                          world (needs "ulx cleanplayer")
        Close             with a note for the reporter (optional)
    Staff's own @ is still ULX's admin chat.

Open reports are saved (data/rp1942/reports.json), so a restart doesn't lose
them. Everything is logged as [42Bros][REPORT] (rp1942_logs).

    sv_reports.lua   the reports, the actions and the checks
    cl_reports.lua   the form, the list and the counter
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Reports = {
    maxOpen   = 2,     -- open reports per player
    cooldown  = 30,    -- seconds between reports
    maxLength = 400,   -- characters
    minLength = 5,
}

DarkRP.declareChatCommand{
    command = "report",
    description = "Report a rule break to staff: /report opens a form, /report <text> sends it. @ <text> works too.",
    delay = 1.5,
}
