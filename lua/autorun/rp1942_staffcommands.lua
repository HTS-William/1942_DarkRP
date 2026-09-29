--[[---------------------------------------------------------------------------
1942 DarkRP - staff commands (the ! ones)

Every staff command is a ULX command in the 42Bros tab (lua/ulx/modules/sh/
42bros.lua): typed with ! in chat (!addmarket), ulx in console, or clicked in
the ULX menu. There are no /chat duplicates any more.

The "look at" commands keep their code next to the thing they work on
(markets, oil sites, dumpsters, the vault, saved machines). They register it
here with RP1942.defineStaffCommand, and 42bros.lua runs it. ULX has already
checked the rank by then, and each one checks again (RP1942.staffCan).

This file lives in lua/autorun so it loads before any entity or DarkRP
module registers a command (entities and modules load in an order we don't
control; autorun always comes first).

    RP1942.defineStaffCommand(name, function(ply, args) ... end)   (server)
    RP1942.runStaffCommand(ply, name, args)  -> true if it exists
---------------------------------------------------------------------------]]
AddCSLuaFile()

RP1942 = RP1942 or {}
RP1942.StaffCommands = RP1942.StaffCommands or {}

function RP1942.defineStaffCommand(name, fn)
    RP1942.StaffCommands[string.lower(name)] = fn
end

function RP1942.runStaffCommand(ply, name, args)
    local fn = RP1942.StaffCommands[string.lower(name)]
    if not fn then return false end
    fn(ply, args or "")
    return true
end
