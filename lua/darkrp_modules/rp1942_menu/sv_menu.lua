--[[---------------------------------------------------------------------------
1942 DarkRP - job menus (server)

One entry point for every button in every job menu.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_MenuAction")
util.AddNetworkString("RP1942_OpenMenu")

local RATE = 0.5          -- seconds between menu actions per player
local MAX_ARG = 200       -- longest text argument a button may send

net.Receive("RP1942_MenuAction", function(_, ply)
    if not IsValid(ply) then return end

    -- Rate limit before reading anything else
    local now = CurTime()
    if (ply.RP1942_NextMenuAction or 0) > now then return end
    ply.RP1942_NextMenuAction = now + RATE

    local action = net.ReadString()
    local arg = net.ReadString()
    if #action == 0 or #action > 64 or #arg > MAX_ARG then return end

    -- Only handlers of the menu the player's CURRENT job uses are reachable
    local menuClass = RP1942.getJobMenu(ply)
    local handlers = menuClass and RP1942.MenuHandlers[menuClass]
    local handler = handlers and handlers[action]
    if not handler then return end

    handler(ply, arg)
end)

-- /jobmenu opens it too (chat commands run on the server, the menu is clientside)
DarkRP.defineChatCommand("jobmenu", function(ply)
    net.Start("RP1942_OpenMenu")
    net.Send(ply)
    return ""
end)
