--[[---------------------------------------------------------------------------
1942 DarkRP - wanted by the Reich (shared config)

Built on DarkRP's own wanted status, so everything DarkRP already does with
it keeps working: police can arrest wanted players, /unwanted clears it, and
it runs out on its own after a while.

What this adds:
    - Killing a member of the Reich makes you wanted automatically
    - A bright WANTED tag above wanted players' names (replaces DarkRP's text)
    - "Reich Alert!" boxes when someone becomes wanted or is cleared
      (replaces DarkRP's centre-screen "wanted by the police" message)

Files:
    sh_wanted.lua   this config
    sv_wanted.lua   the kill rule and the alerts (server)
    cl_wanted.lua   the tag above heads and the alert boxes (client)
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.Wanted = {
    --[[-----------------------------------------------------------------------
    Reasons for being wanted. To add a new one, add a line here:
        key = { text = "shown under WANTED", time = seconds wanted },
    then, from any server code:
        RP1942.makeWanted(ply, "key")            -- the Reich made them wanted
        RP1942.makeWanted(ply, "key", officer)   -- a player made them wanted
    time can be left out to use DarkRP's GM.Config.wantedtime.
    text may contain %s, filled from extra arguments to makeWanted.
    -----------------------------------------------------------------------]]
    reasons = {
        reich_kill = { text = "For killing a Reich official", time = 300 },
        -- Examples, ready to switch on once something calls them:
        -- curfew     = { text = "For breaking curfew", time = 120 },
        -- theft      = { text = "For theft", time = 180 },
        -- contraband = { text = "For possessing contraband", time = 240 },
    },

    -- The automatic rule: killing a Reich member (reason "reich_kill")
    killMakesWanted = true,
    exemptFactions  = { reich = true },-- killers in these factions don't become wanted
                                       -- (e.g. the Gestapo executing a traitor)

    -- The tag above wanted players
    showReason      = true,            -- small reason line under WANTED
    tagMaxDistance  = 800,             -- game units (about 40 per metre): beyond this, no tag.
                                       -- It fades out over the last quarter of the distance.

    -- Alert boxes
    alertTitle      = "Reich Alert!",
    alertSeconds    = 8,
    alertMax        = 4,               -- at most this many on screen at once
    alertPosition   = "topleft",       -- "topleft", "topright" or "topcenter"
    alertSound      = "buttons/blip1.wav", -- false for silence
    wantedText      = "%s is now wanted by the Reich!",
    unwantedText    = "%s is no longer wanted by the Reich.",   -- cleared or ran out
    arrestedText    = "%s has been arrested by the Reich.",
    killedText      = "%s, wanted by the Reich, has been killed.",

    -- What the wanted player sees themselves: a small tag in a corner
    selfIndicator   = true,
    selfText        = "WANTED",
    selfPosition    = "topright",      -- "topleft", "topright" or "topcenter"
    selfSound       = "buttons/button10.wav", -- once, when you become wanted; false = off

    --[[-----------------------------------------------------------------------
    Colours. Color(red, green, blue, alpha), each 0-255 (alpha optional).
    -----------------------------------------------------------------------]]
    colors = {
        tag        = Color(255, 25, 25),         -- "WANTED" above the head
        tagPulse   = Color(255, 120, 100),       -- WANTED pulses towards this
        tagShadow  = Color(0, 0, 0, 230),
        reason     = Color(255, 200, 190),       -- reason line under WANTED

        alertBg    = Color(22, 21, 19, 225),     -- alert box background
        alertTitle = Color(170, 165, 155),       -- small "Reich Alert!" heading
        alertLine  = Color(170, 25, 25),         -- red line under the heading
        alertText  = Color(255, 255, 255),       -- the big message
        alertClear = Color(120, 200, 120),       -- line colour for "no longer wanted"

        selfBg     = Color(22, 21, 19, 225),     -- your own corner tag
        selfAccent = Color(170, 25, 25),         -- its red bar and pulsing dot
        selfText   = Color(255, 25, 25),         -- "WANTED"
    },
}
