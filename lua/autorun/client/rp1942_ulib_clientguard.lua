--[[---------------------------------------------------------------------------
1942 DarkRP - no "[ULIB] Unauthed player" errors while joining (client)

When you join, the ULX menu (XGUI) builds itself as soon as your game has
loaded and asks "may I use this?" for every tab and command. Your rank list
only reaches your game a moment later, from the server. When it arrives
late (local test games especially), each of those questions throws
    [ULIB] Unauthed player

Until your rank list has arrived, those client-side checks now just answer
"no". As soon as it arrives, ULX's own UCLAuthed / UCLChanged hooks rebuild
the menu with your real permissions.

This only affects what your own screen shows. Every command is still
checked on the server, exactly as before.
---------------------------------------------------------------------------]]
if not (ULib and ULib.ucl and ULib.ucl.query) then return end
if ULib.ucl.RP1942_Guarded then return end   -- once (lua refresh)
ULib.ucl.RP1942_Guarded = true

local originalQuery = ULib.ucl.query

ULib.ucl.query = function(ply, access, hide)
    if access ~= nil and IsValid(ply) then
        local uid = game.SinglePlayer() and "1" or ply:UniqueID()   -- (the same fix ULib uses)
        if not ULib.ucl.authed[uid] then return false end           -- not arrived yet: "no", not an error
    end
    return originalQuery(ply, access, hide)
end
