--[[---------------------------------------------------------------------------
Server handlers for RP1942_FuhrerMenu.
Only reachable by a player whose CURRENT job has menu = "RP1942_FuhrerMenu".
---------------------------------------------------------------------------]]
local STEP = 10

local function changeEconomy(ply, delta)
    if not RP1942.addEconomy then
        DarkRP.notify(ply, 1, 4, "The economy module is not loaded.")
        return
    end

    local value = RP1942.addEconomy(delta, "Führer debug menu (" .. ply:Nick() .. ")")
    DarkRP.notify(ply, 0, 4, string.format("Economy is now %d: %s", value, RP1942.getEconomyTier(value).text))
end

RP1942.addMenuHandler("RP1942_FuhrerMenu", "economy_up",   function(ply) changeEconomy(ply,  STEP) end)
RP1942.addMenuHandler("RP1942_FuhrerMenu", "economy_down", function(ply) changeEconomy(ply, -STEP) end)
