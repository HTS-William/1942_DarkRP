--[[---------------------------------------------------------------------------
42Bros - live broadcasts: a film camera and a cinema screen

The NEWSREEL CAMERA (a hand-held SWEP the Propaganda Minister carries) and
the placed FILM CAMERA (F4 shop, Tools) film live, and a CINEMA SCREEN (F4
shop, Tools) shows it, in black and white with a bit of old-film grain and
flicker. The shop's camera and screen are for the Propaganda Minister only.
The hand-held one films what its holder looks at, the placed one where its
lens points. Players around the screen also HEAR
what's going on around the camera:

    voice       anyone talking within `hearCamera` of the holder is heard by
                everyone within `hearScreen` of the screen
    sounds      gunshots, doors, footsteps... played around the holder are
                played again at the screen, for the same people

    Newsreel camera  left click   on air / off air (off when put away,
                                  dropped, or its holder dies)
                     right click  hold to zoom (the screen zooms too)
    Film camera      E            on air / off air (its owner, or staff)
                     physgun      aim it
    Cinema screen    E            change channel: the next camera that's on
                                  air, then off (its owner, or staff)

The screen and the placed camera go with the job: they're removed when their
owner changes to any other job (or leaves the server).

A camera on air shows a red ON AIR light, so everyone can see they're being
filmed and heard. People standing at the camera don't hear the screen as well.

    sh_broadcast.lua    these settings
    sv_broadcast.lua    who hears what, keeping the camera's spot sent to viewers
    cl_broadcast.lua    filming (render targets) and the relayed sounds
    lua/weapons/rp1942_newsreel_camera.lua, lua/entities/rp1942_film_camera,
    lua/entities/rp1942_cinema_screen
    (anything with :Broadcasting(), :BroadcastView() and :BroadcastName() can be
    a camera: add its class to the screen's list in rp1942_cinema_screen/init.lua)
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Broadcast = {
    hearCamera   = 350,    -- units around the camera that are picked up
    hearScreen   = 500,    -- units around the screen where it's heard
    viewRange    = 1500,   -- the screen is only drawn live this close (and the camera's spot is sent to you)
    fps          = 20,     -- frames a second the picture updates
    width        = 640,    -- the picture's resolution (16:9)
    height       = 360,
    fov          = 62,     -- (the camera's own zoom sets it while filming)
    soundsPerSec = 15,     -- most relayed sounds a second, per camera
}
