--[[---------------------------------------------------------------------------
1942 DarkRP - the Führer's laws are kept across restarts (server)

DarkRP keeps its laws in memory only, so a restart put them back to the fixed
ones (GM.Config.DefaultLaws). This saves the laws the Führer added in
data/rp1942/laws.json whenever they change (added, removed, reset) and puts
them back when the server starts. The fixed laws aren't saved: they always
come from the config.

A change of Führer doesn't reset them either (GM.Config.shouldResetLaws is
false): the laws stand until a Führer removes or resets them.
---------------------------------------------------------------------------]]
local store = RP1942.dataStore("laws")
local MAX_LAWS = 12          -- DarkRP's own limit
local restored = false       -- never overwrite the saved laws before they're back

local function fixedCount()
    return #(GAMEMODE.Config.DefaultLaws or {})
end

local function save()
    if not restored or not DarkRP.getLaws then return end
    local laws, added = DarkRP.getLaws(), {}
    for i = fixedCount() + 1, #laws do added[#added + 1] = laws[i] end
    store.save({ laws = added })
end
local function saveSoon() timer.Simple(0, save) end   -- after DarkRP has finished the change

local function restore()
    local laws = DarkRP.getLaws and DarkRP.getLaws()
    if not laws then return end
    for _, law in ipairs(store.load().laws or {}) do
        if isstring(law) and law ~= "" and #laws < MAX_LAWS then
            table.insert(laws, law)
            umsg.Start("DRP_AddLaw")   -- anyone already in hears it; later joiners get them from DarkRP
                umsg.String(law)
            umsg.End()
        end
    end
    restored = true
end

hook.Add("addLaw", "RP1942_SaveLaws", saveSoon)
hook.Add("removeLaw", "RP1942_SaveLaws", saveSoon)
hook.Add("ShutDown", "RP1942_SaveLaws", save)

hook.Add("InitPostEntity", "RP1942_SaveLaws", function()
    -- DarkRP fills its law list on the first tick: restore after that
    timer.Simple(1, restore)
    -- Resets (the /resetlaws command, the menu's Reset) all go through here
    local reset = DarkRP.resetLaws
    if reset then
        DarkRP.resetLaws = function(...)
            reset(...)
            saveSoon()
        end
    end
end)
