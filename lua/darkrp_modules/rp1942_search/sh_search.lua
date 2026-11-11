--[[---------------------------------------------------------------------------
42Bros - the weapon checker (rp1942_weapon_checker), instead of DarkRP's

Look at a player up close and:

    Left click      PAT DOWN (patTime seconds): the weapons they're carrying
    Right click     SEARCH THEIR POCKETS (searchTime seconds): the weapons
                    they're carrying, and everything in their pocket
    Reload          give back everything that was confiscated from them

Hold still next to them while the bar fills: if either of you moves away
(more than `range`), the search stops. They see who's searching them.

When it's done a list opens: every weapon (and in a pocket search, every
pocket item) by name. Weapons, shipments and ammo can be CONFISCATED, one by
one or all at once. Tools that aren't weapons (keys, hands, physgun, the
toolgun, the camera, batons, handcuffs...) aren't listed: see `hidden`.

Confiscated things are kept for the player (not destroyed): Reload with the
checker on them gives them all back. They're gone if the player leaves.
Every search and confiscation is logged ([42Bros][SEARCH], rp1942_logs).

    sh_search.lua    these settings
    sv_search.lua    the searching, confiscating and giving back
    cl_search.lua    the list
    lua/weapons/rp1942_weapon_checker.lua   the SWEP itself
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Search = {
    patTime    = 3,      -- seconds for a pat down
    searchTime = 8,      -- seconds for a pocket search
    range      = 110,    -- units: how close you have to stay
    keepFor    = 90,     -- seconds a finished search's list can still be acted on

    -- Never listed (stock GMod tools and things everyone or the Reich carries).
    -- DarkRP's default weapons (settings.lua, GM.Config.DefaultWeapons) are added on top.
    hidden = {
        weapon_physgun = true, weapon_physcannon = true, gmod_tool = true, gmod_camera = true,
        keys = true, pocket = true, rp1942_hands = true,
        stunstick = true, arrest_stick = true, unarrest_stick = true, rp1942_handcuffs = true,
        door_ram = true, weaponchecker = true, rp1942_weapon_checker = true,
        weapon_keypadchecker = true, med_kit = true, rp1942_newsreel_camera = true,
        weapon_extinguisher = true, weapon_extinguisher_infinite = true,
    },

    -- Pocket items that can be confiscated, besides weapons
    takeable = { spawned_weapon = true, spawned_shipment = true, rp1942_ammo_box = true },
}

function RP1942.searchHidden(class)
    if RP1942.Search.hidden[class] then return true end
    for _, c in ipairs(GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.DefaultWeapons or {}) do
        if c == class then return true end
    end
    return false
end

-- A weapon's name ("Karabiner 98k"), from its class
function RP1942.weaponName(class)
    local stored = weapons.GetStored(class or "")
    local name = stored and stored.PrintName
    if not isstring(name) or name == "" or name == "Scripted Weapon" then name = class or "?" end
    if CLIENT and language and language.GetPhrase then name = language.GetPhrase(name) end
    return name
end
