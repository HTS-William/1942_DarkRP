--[[---------------------------------------------------------------------------
1942 DarkRP - who may use a staff command (shared)

RP1942.staffCan(ply, access, fallback)
    access    the ULX command it belongs to, e.g. "ulx addmarket"
    fallback  function(ply) used when ULX isn't running (e.g. IsSuperAdmin)

With ULX (and our lua/ulx/modules/sh/42bros.lua loaded), the answer comes
from ULX: give or take a command per rank in the ULX menu (Groups tab), and
the chat command (/addmarket) and the ULX one (ulx addmarket, the 42Bros
category) follow the same rule. Without ULX, the fallback decides.
The server console may always.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

function RP1942.staffCan(ply, access, fallback)
    if not IsValid(ply) then return true end   -- server console
    if RP1942.ULX42 and ULib and ULib.ucl and ULib.ucl.query then
        local ok, result = pcall(ULib.ucl.query, ply, access)
        if ok then return result == true end
    end
    if fallback then return fallback(ply) == true end
    return ply:IsSuperAdmin()
end
