--[[---------------------------------------------------------------------------
42Bros | OccupationRP - the gamemode (server)

DarkRP, under our own name, so the Garry's Mod main menu shows the 42Bros
logo (gamemodes/occupationrp/logo.png) instead of DarkRP's: the menu shows
the logo of the gamemode FOLDER the server runs. Everything else is DarkRP,
unchanged: all our code stays in lua/ (darkrp_modules, darkrp_customthings...).

    Server start line:   +gamemode occupationrp
    Needs:               DarkRP itself installed on the server (the base)

THE NAMES (they all have to line up)
    folder, .txt file, first line of the .txt    occupationrp
        GMod only sees a gamemode when all three match exactly.
    "title" in occupationrp.txt                  the main menu's gamemode list
    GetGameDescription below                     the server browser's column
    GM.Name                                      MUST stay "DarkRP", on both
        server and client: when it isn't, ULX switches on UTeam (it would
        take over players' teams from DarkRP's jobs) and EasyChat drops its
        DarkRP support.
DarkRP runs its "DarkRPStartedLoading" hook itself, so it isn't repeated here.
---------------------------------------------------------------------------]]
GM.Version = "1.0.0"
GM.Name    = "DarkRP"
GM.Author  = "42Bros, on DarkRP by FPtje Falco et al."

DeriveGamemode("darkrp")
DEFINE_BASECLASS("gamemode_darkrp")
GM.DarkRP = BaseClass

-- What the server browser shows in its gamemode column
function GM:GetGameDescription()
    return "42Bros | OccupationRP"
end

-- The main menu logo and icon, for players who don't have them yet
resource.AddFile("gamemodes/occupationrp/logo.png")
resource.AddFile("gamemodes/occupationrp/icon24.png")

-- DarkRP's own content (materials, models). The engine only sends the
-- running gamemode's Workshop item on its own, and that's now this one.
resource.AddWorkshop("248302805")
