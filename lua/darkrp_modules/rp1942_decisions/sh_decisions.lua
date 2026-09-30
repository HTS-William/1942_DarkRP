--[[---------------------------------------------------------------------------
1942 DarkRP - the Führer's decisions (shared: the settings)

While a Führer is in office, every 3-5 minutes a window pops up for him with
one situation and three answers. Each answer has an impact level: the
riskier it is, the lower its odds and the bigger the swing in the economy.

    impact      odds of success    economy points won / lost
    low         70 - 90 %           5 - 10
    moderate    40 - 70 %          10 - 15
    high        20 - 50 %          15 - 25

The odds and the points are rolled fresh, within those ranges, each time an
answer is picked. Then:
    the Führer    reads what happened (the answer's success / failure text)
    everyone      "The Führer chose wisely, and the economy increased by N%."
                  "The Führer chose poorly, and the economy decreased by N%."
(N is the points the economy bar actually moved: it can't go past 1 or 110.)

Questions come from a shuffled deck (sh_decisions_questions.lua): every one
is asked once before any comes round again, and the same one is never asked
twice in a row, even across a reshuffle or a server restart.

If the Führer closes the window he can reopen it with /decision until the
time runs out. No answer in time = he ignored it: the economy drops by
ignorePenalty (10) points and everyone is told.

STAFF (ULX 42Bros)
    !fuhrerquestion [number]   send a decision now: to the Führer, or to you
                               if nobody is in office (so you can test it).
                               A number (1-13...) picks that question.
                               It really changes the economy when answered.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Decisions = RP1942.Decisions or {}
local D = RP1942.Decisions

D.settings = {
    enabled     = true,
    intervalMin = 180,    -- seconds between decisions (3 min)...
    intervalMax = 300,    -- ...to 5 min, random each time
    answerTime  = 90,     -- seconds the Führer has to answer
    showOdds    = false,  -- show each answer's odds and stakes in the window
    ignorePenalty = 10,   -- economy points lost when the Führer lets a decision run out (0 = none)
    resultTime  = 9,      -- seconds everyone's banner stays up
}

-- Odds are 0-1; points are whole economy points (the bar runs 1-110)
D.impacts = {
    low      = { name = "LOW IMPACT",      chance = { 0.70, 0.90 }, points = { 5, 10 },  color = Color(112, 150, 88) },
    moderate = { name = "MODERATE IMPACT", chance = { 0.40, 0.70 }, points = { 10, 15 }, color = Color(205, 150, 60) },
    high     = { name = "HIGH IMPACT",     chance = { 0.20, 0.50 }, points = { 15, 25 }, color = Color(190, 58, 48) },
}

D.text = {
    wiseTitle  = "THE FÜHRER CHOSE WISELY",
    wiseBody   = "The Führer chose wisely, and the economy increased by %d%%.",
    wiseCapped = "The Führer chose wisely, but the economy can't grow any further.",
    poorTitle  = "THE FÜHRER CHOSE POORLY",
    poorBody   = "The Führer chose poorly, and the economy decreased by %d%%.",
    poorCapped = "The Führer chose poorly, but the economy can't fall any further.",
    ignoredTitle  = "THE FÜHRER FAILED TO DECIDE",
    ignoredBody   = "The Führer didn't make a decision in time, and the economy decreased by %d%%.",
    ignoredCapped = "The Führer didn't make a decision in time, but the economy can't fall any further.",
    ignoredSelf   = "You didn't make a decision in time. The economy decreased by %d%%.",
}

D.questions = D.questions or {}   -- filled by sh_decisions_questions.lua

function RP1942.decisionImpact(id)
    return D.impacts[id] or D.impacts.low
end

DarkRP.declareChatCommand{
    command = "decision",
    description = "Führer: reopen the decision waiting for you.",
    delay = 1,
}
