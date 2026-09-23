--[[---------------------------------------------------------------------------
1942 DarkRP - disabled defaults

Everything stock DarkRP ships that doesn't belong in 1942 is switched off
here. true = disabled, false = enabled.

Anything that referenced a stock job (agendas, door groups, group chats,
demote groups, hitmen) is disabled too: those jobs no longer exist, and our
own versions live in darkrp_customthings/.
---------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
Modules
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["modules"] = {
    ["afk"]              = true,
    ["chatsounds"]       = false,
    ["events"]           = false,
    ["fpp"]              = false,
    ["f1menu"]           = false,
    ["f4menu"]           = false,   -- set true once our own F4 exists
    ["hitmenu"]          = true,    -- no hitmen in 1942
    ["hud"]              = false,   -- set true once our own HUD exists
    ["hungermod"]        = true,    -- TODO: decide. Enabling it makes the Baker's bread matter (rationing).
    ["playerscale"]      = false,
    ["sleep"]            = false,
    ["fadmin"]           = false,   -- set true if you run ULX/SAM instead
    ["animations"]       = false,
    ["chatindicator"]    = false,
}

--[[---------------------------------------------------------------------------
Jobs: all stock jobs off. Replacements are in darkrp_customthings/jobs.lua
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["jobs"] = {
    ["chief"]     = true,
    ["citizen"]   = true,
    ["cook"]      = true,
    ["cp"]        = true,
    ["gangster"]  = true,
    ["gundealer"] = true,
    ["hobo"]      = true,
    ["mayor"]     = true,
    ["medic"]     = true,
    ["mobboss"]   = true,
}

--[[---------------------------------------------------------------------------
Shipments and pistols: modern CS:S guns, all off
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["shipments"] = {
    ["AK47"]         = true,
    ["Desert eagle"] = true,
    ["Fiveseven"]    = true,
    ["Glock"]        = true,
    ["M4"]           = true,
    ["Mac 10"]       = true,
    ["MP5"]          = true,
    ["P228"]         = true,
    ["Pump shotgun"] = true,
    ["Sniper rifle"] = true,
}

--[[---------------------------------------------------------------------------
Entities
The tip jar stays: shopkeepers and bakers can use it.
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["entities"] = {
    ["Drug lab"]      = true,
    ["Gun lab"]       = true,
    ["Money printer"] = true,   -- replaced by the Banker's Reichsbank printers
    ["Microwave"]     = true,
    ["Tip Jar"]       = false,
}

--[[---------------------------------------------------------------------------
Vehicles (DarkRP ships none)
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["vehicles"] = {

}

--[[---------------------------------------------------------------------------
Food (only used when hungermod is enabled). Modern packaging, all off.
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["food"] = {
    ["Banana"]           = true,
    ["Bunch of bananas"] = true,
    ["Melon"]            = true,
    ["Glass bottle"]     = true,
    ["Pop can"]          = true,
    ["Plastic bottle"]   = true,
    ["Milk"]             = true,
    ["Bottle 1"]         = true,
    ["Bottle 2"]         = true,
    ["Bottle 3"]         = true,
    ["Orange"]           = true,
}

--[[---------------------------------------------------------------------------
Door groups (referenced stock jobs)
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["doorgroups"] = {
    ["Cops and Mayor only"] = true,
    ["Gundealer only"]      = true,
}

--[[---------------------------------------------------------------------------
Ammo packets: period weapons use their own ammo types
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["ammo"] = {
    ["Pistol ammo"]  = true,
    ["Rifle ammo"]   = true,
    ["Shotgun ammo"] = true,
}

--[[---------------------------------------------------------------------------
Agendas (replaced in darkrp_customthings/agendas.lua)
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["agendas"] = {
    ["Gangster's agenda"] = true,
    ["Police agenda"] = true,
}

--[[---------------------------------------------------------------------------
Group chats (replaced in darkrp_customthings/groupchats.lua)
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["groupchat"] = {
    [1] = true, -- Police group chat
    [2] = true, -- Gangsters and mobboss
    [3] = true, -- Same team
}

--[[---------------------------------------------------------------------------
Hitmen
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["hitmen"] = {
    ["mobboss"] = true,
}

--[[---------------------------------------------------------------------------
Demote groups (replaced in darkrp_customthings/demotegroups.lua)
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["demotegroups"] = {
    ["Cops"]      = true,
    ["Gangsters"] = true,
}

--[[---------------------------------------------------------------------------
Workarounds
DarkRP works around some bugs in GMod and other addons that aren't maintained
(properly). Disabling workarounds will cause those things to break again.
---------------------------------------------------------------------------]]
DarkRP.disabledDefaults["workarounds"] = {
    ["os.date() Windows crash"]                      = false,
    ["SkidCheck"]                                    = false,
    ["Error on edict limit"]                         = false,
    ["Durgz witty sayings"]                          = false,
    ["ULX /me command"]                              = false,
    ["gm_save"]                                      = false,
    ["rp_downtown_v4c_v2 rooftop spawn"]             = false,
    ["White flashbang flashes"]                      = false,
    ["APAnti"]                                       = false,
    ["Wire field generator exploit fix"]             = false,
    ["Door tool class fix"]                          = false,
    ["Constraint crash exploit fix"]                 = false,
    ["Deprecated console commands"]                  = false,
    ["disable CAC"]                                  = false,
}
