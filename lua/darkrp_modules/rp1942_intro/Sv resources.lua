--[[---------------------------------------------------------------------------
1942 DarkRP - send intro files to players (server)

resource.AddFile tells connecting players to download the file. Without it,
the file only exists on the server and players hear nothing.
---------------------------------------------------------------------------]]
local music = RP1942.IntroMusic

if music and music.path then
    if file.Exists(music.path, "GAME") then
        resource.AddFile(music.path)
    else
        MsgC(Color(255, 170, 0), "[1942] Intro music not found at '", music.path,
            "'. Put it in the addon's sound/ folder or change RP1942.IntroMusic.path.\n")
    end
end
