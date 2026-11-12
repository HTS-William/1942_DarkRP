--[[---------------------------------------------------------------------------
42Bros - the sandbox settings (XGUI's Settings > Sandbox tab) survive restarts

The game doesn't reliably save these on a hosted server, so they went back
to the defaults on every restart. Now:

    - DEFAULTS below are applied at every start (the server's settings)
    - anything changed in XGUI (or the console) is saved straight away to
      data/rp1942/sandbox_settings.json, and wins over DEFAULTS from then on

So set them in XGUI as usual and they stay. To go back to the DEFAULTS below,
delete data/rp1942/sandbox_settings.json and restart. Changes are logged
([42Bros][SETUP]).
---------------------------------------------------------------------------]]
local FILE = "rp1942/sandbox_settings.json"

local DEFAULTS = {
    -- left column
    sbox_weapons             = 1,     -- give weapons on spawn
    sbox_godmode             = 0,     -- players have god mode
    sbox_playershurtplayers  = 1,     -- allow PvP
    sbox_noclip              = 0,     -- allow noclip (staff still have ULX noclip)
    sbox_bonemanip_npc       = 1,     -- bone manipulation: NPCs
    sbox_bonemanip_player    = 0,     --                    players
    sbox_bonemanip_misc      = 0,     --                    everything
    physgun_limited          = 0,     -- limited physgun
    physgun_maxrange         = 4096,  -- max beam range
    physgun_teleportDistance = 0,     -- teleport distance
    physgun_maxSpeed         = 5000,  -- max prop speed

    -- the limits: only props can be spawned (10 each); the F4 shop and DarkRP's
    -- own entities have their own limits and don't use these
    sbox_maxprops      = 10,
    sbox_maxballoons   = 0,  sbox_maxbuttons  = 0,  sbox_maxcameras  = 0,
    sbox_maxdynamite   = 0,  sbox_maxeffects  = 0,  sbox_maxemitters = 0,
    sbox_maxhoverballs = 0,  sbox_maxlamps    = 0,  sbox_maxlights   = 0,
    sbox_maxnpcs       = 0,  sbox_maxragdolls = 0,  sbox_maxsents    = 0,
    sbox_maxthrusters  = 0,  sbox_maxvehicles = 0,  sbox_maxwheels   = 0,
}

local saved = {}
local applying = false

local function load()
    local raw = file.Read(FILE, "DATA")
    local data = raw and util.JSONToTable(raw)
    saved = istable(data) and data or {}
end

local function save()
    file.CreateDir("rp1942")
    file.Write(FILE, util.TableToJSON(saved, true))
end

local function apply()
    applying = true
    for name, value in pairs(DEFAULTS) do
        if ConVarExists(name) then
            local want = saved[name] ~= nil and saved[name] or value
            if GetConVar(name):GetString() ~= tostring(want) then
                RunConsoleCommand(name, tostring(want))
            end
        end
    end
    -- (RunConsoleCommand takes effect next frame: stop ignoring changes after that)
    timer.Simple(1, function() applying = false end)
end

local watching = false
local function watch()
    if watching then return end
    watching = true
    for name in pairs(DEFAULTS) do
        cvars.AddChangeCallback(name, function(_, old, new)
            if applying or old == new then return end
            saved[name] = tonumber(new) or new
            save()
            if RP1942 and RP1942.log then RP1942.log("SETUP", "Sandbox setting %s: %s -> %s (saved)", name, old, new) end
        end, "RP1942_SandboxSettings")
    end
end

-- After the gamemode has made the settings and server.cfg has run; again a
-- few seconds later in case something else sets them at start
hook.Add("InitPostEntity", "RP1942_SandboxSettings", function()
    load()
    apply()
    watch()
    timer.Simple(5, apply)
end)
