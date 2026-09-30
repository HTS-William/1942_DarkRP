--[[---------------------------------------------------------------------------
1942 DarkRP - players who join before Steam has confirmed them (server)

ULib only knows a player's ULX rank once the engine's PlayerAuthed hook has
fired, which needs Steam to validate them. Until then, any ULX permission
check on that player throws "[ULIB] Unauthed player". ULX itself checks
one on PlayerInitialSpawn (ulx/base.lua, sendAutoCompletes), and an error
there stops the rest of PlayerInitialSpawn, DarkRP's included: the player
is never given a job and every later hook fails on them ("jobTable" nil).

So, on PlayerInitialSpawn, before any other hook, a player who isn't
authed yet gets an entry:
    local / LAN game   looked up the same way ULib does for bots
                       (ULib.ucl.probe: SteamID, IP or UniqueID in ULX's
                       users list), because Steam may never confirm them
    public server      a plain "user" entry, no rank at all, only so
                       nothing breaks. Their real rank is applied the
                       moment Steam confirms them (ULib redoes the lookup
                       on PlayerAuthed). An unconfirmed player is never
                       given a staff rank on a public server.
---------------------------------------------------------------------------]]
local function localGame()
    if not game.IsDedicated() then return true end   -- listen server / "local game"
    local lan = GetConVar("sv_lan")
    return lan ~= nil and lan:GetBool()
end

local function authIfNeeded(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    local ucl = ULib and ULib.ucl
    if not (ucl and ucl.authed and ucl.probe) then return end
    local uid = ply:UniqueID()
    if ucl.authed[uid] then return end

    if localGame() then
        ucl.probe(ply)
        MsgC(Color(201, 168, 92), "[1942] Local test game: ", Color(236, 228, 212),
            ply:Nick() .. " (" .. ply:SteamID() .. ") was never Steam-authenticated, so ULX was set up for them directly.\n")
    else
        ucl.authed[uid] = table.Copy(ULib.DEFAULT_GRANT_ACCESS)   -- "user", nothing more
        hook.Call(ULib.HOOK_UCLCHANGED)
        MsgC(Color(201, 168, 92), "[1942] ", Color(236, 228, 212),
            ply:Nick() .. " (" .. ply:SteamID() .. ") spawned before Steam confirmed them: treated as a user until it does.\n")
    end
end

-- HOOK_MONITOR_HIGH: runs before every normal PlayerInitialSpawn hook,
-- ULX's own included (the same slot ULib uses to set up bots)
hook.Add("PlayerInitialSpawn", "RP1942_EarlyAuth", authIfNeeded, HOOK_MONITOR_HIGH or -2)
