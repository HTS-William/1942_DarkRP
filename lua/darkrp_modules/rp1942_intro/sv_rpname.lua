--[[---------------------------------------------------------------------------
1942 DarkRP - /register (server): tells the player's game to open the form
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_OpenRPName")

DarkRP.defineChatCommand("register", function(ply)
    net.Start("RP1942_OpenRPName")
    net.Send(ply)
    return ""
end)
