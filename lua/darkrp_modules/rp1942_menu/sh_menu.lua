--[[---------------------------------------------------------------------------
1942 DarkRP - job menus (shared)

How it fits together:
    cl_menu_base.lua     RP1942_MenuBase: the boilerplate panel every menu inherits
    cl_menu_*.lua        job menus: vgui.Register("Name", PANEL, "RP1942_MenuBase")
    sv_menu_*.lua        server handlers for the buttons in those menus
    jobs.lua             a job opts in with:  menu = "RP1942_BakerMenu",
                         (jobs without a `menu` field have no menu)

Opening: /jobmenu in chat, or the console command rp1942_menu
(players can bind it: bind g rp1942_menu)

Security: a menu button never does anything on the client. It sends
"action name + optional text" to the server, and the server only runs it if the
player's CURRENT job uses that menu and a handler for that action exists.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.MenuHandlers = RP1942.MenuHandlers or {}

--[[---------------------------------------------------------------------------
RP1942.addMenuHandler(menuClass, action, function(ply, arg) ... end)

Defined here (shared) rather than in sv_menu.lua because files in a module
load in reverse alphabetical order, so sv_menu_baker.lua runs BEFORE
sv_menu.lua. sh_ files always load before sv_ files, so this is always ready.
Only the server ever calls the handlers.
---------------------------------------------------------------------------]]
function RP1942.addMenuHandler(menuClass, action, fn)
    RP1942.MenuHandlers[menuClass] = RP1942.MenuHandlers[menuClass] or {}
    RP1942.MenuHandlers[menuClass][action] = fn
end

-- The menu class a player's current job uses (nil = no menu)
function RP1942.getJobMenu(ply)
    local job = RPExtraTeams[ply:Team()]
    return job and job.menu
end

DarkRP.declareChatCommand{
    command = "jobmenu",
    description = "Open your job's menu (if it has one).",
    delay = 1,
}
