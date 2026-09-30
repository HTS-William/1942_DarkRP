--[[---------------------------------------------------------------------------
1942 DarkRP - the wireless set. Press E to tune it (a station from the list
or any direct stream link). Plays for everyone near it. Settings, stations
and the menu: darkrp_modules/rp1942_radio.
---------------------------------------------------------------------------]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Radio"
ENT.Author = "1942 DarkRP"
ENT.Category = "1942 DarkRP"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "URL")        -- "" = off
    self:NetworkVar("String", 1, "Station")    -- name shown above the set
    self:NetworkVar("Float",  0, "Volume")     -- 0-1, the set's own knob
end
