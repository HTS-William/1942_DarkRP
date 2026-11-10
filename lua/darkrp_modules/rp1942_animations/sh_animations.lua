--[[---------------------------------------------------------------------------
42Bros - animations (the keys' R menu), replacing DarkRP's list of buttons

With the keys out, press R anywhere but at a door: a RADIAL MENU opens
around your crosshair. Point at an animation and click it, or hold R, flick
the mouse toward one and let go. Right click, or the middle, closes it.

While you play it the camera swings out into third person and YOU move it:
the mouse turns it around you (without turning you), the mouse wheel moves
it closer or further. It zooms back into first person when the animation is
done, still facing where you were. Attacking or pressing E ends the view
early; everyone else sees the animation as before.

    sh_animations.lua    the list (below) and the cooldown
    sv_animations.lua    plays one for everyone (checked here, not trusted)
    cl_animations.lua    the radial menu and the camera

The cooldown and the list are checked by the server; the client asking only
picks one. Replaces DarkRP's _DarkRP_AnimationMenu / _DarkRP_DoAnimation
console commands (the keys SWEP still calls the menu one).
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Animations = RP1942.Animations or {}
local A = RP1942.Animations

A.cooldown = 2   -- seconds between animations

-- In the order they go round the circle, clockwise from the top
A.list = {
    { act = ACT_GMOD_GESTURE_WAVE,        name = "Wave" },
    { act = ACT_GMOD_GESTURE_BECON,       name = "Follow me" },
    { act = ACT_GMOD_GESTURE_AGREE,       name = "Thumbs up" },
    { act = ACT_GMOD_GESTURE_DISAGREE,    name = "No" },
    { act = ACT_GMOD_GESTURE_BOW,         name = "Bow" },
    { act = ACT_GMOD_TAUNT_LAUGH,         name = "Laugh" },
    { act = ACT_GMOD_TAUNT_PERSISTENCE,   name = "Pose" },
    { act = ACT_GMOD_TAUNT_MUSCLE,        name = "Flex" },
    { act = ACT_GMOD_TAUNT_DANCE,         name = "Dance" },
}
