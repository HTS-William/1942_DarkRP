--[[---------------------------------------------------------------------------
1942 DarkRP - ULX in local test games

ULib only lets a player use ULX once the engine's PlayerAuthed hook has fired
for them, which needs Steam to validate that client. In a local game with a
second copy of the game joining (or sv_lan 1), that can never happen, and
every ULX menu (XGUI) query for that player errors with
    [ULIB] Unauthed player

On a local / listen / LAN server only, a player still not authed when they
spawn is looked up the same way ULib does for bots (ULib.ucl.probe): by
SteamID, IP or UniqueID in ULX's users list, or the default "user" group.
If real Steam authentication arrives later, ULib redoes it properly.

It does nothing on a public dedicated server (sv_lan 0), where an
unvalidated player must never be handed a staff rank.
---------------------------------------------------------------------------]]
local function localGame()
    if not game.IsDedicated() then return true end   -- listen server / "local game"
    local lan = GetConVar("sv_lan")
    return lan ~= nil and lan:GetBool()
end

local function authIfNeeded(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    if not (ULib and ULib.ucl and ULib.ucl.authed and ULib.ucl.probe) then return end
    if ULib.ucl.authed[ply:UniqueID()] then return end
    ULib.ucl.probe(ply)
    MsgC(Color(201, 168, 92), "[1942] Local test game: ", Color(236, 228, 212),
        ply:Nick() .. " (" .. ply:SteamID() .. ") was never Steam-authenticated, so ULX was set up for them directly.\n")
end

hook.Add("PlayerInitialSpawn", "RP1942_LocalTestAuth", function(ply)
    if not localGame() then return end
    timer.Simple(0, function() authIfNeeded(ply) end)   -- right after the engine's own join handling
    timer.Simple(5, function() authIfNeeded(ply) end)   -- and again, in case the first was too early
end)
