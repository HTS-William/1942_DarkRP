--[[---------------------------------------------------------------------------
42Bros - players download the server's Workshop collection (server)

The server downloads the collection itself (+host_workshop_collection in the
start line), but players are only sent the map and the gamemode on their
own. Everything else (player models, the weapon pack...) has to be marked
for download with resource.AddWorkshop, one id at a time.

This does it automatically: every Workshop addon the server has mounted is
sent to players when they join. Add an item to the collection, restart, and
players get it. No list of ids to keep up to date.

SKIP: ids of server-only addons players don't need (pure Lua, no models,
materials or sounds). Skipping them only shortens the download; leaving
them in does no harm.
---------------------------------------------------------------------------]]
local SKIP = {
    -- ["123456789"] = true,
}

local sent, skipped = 0, 0
for _, addon in ipairs(engine.GetAddons()) do
    local id = addon.wsid and tostring(addon.wsid)
    if addon.mounted and id and id ~= "" and id ~= "0" then
        if SKIP[id] then
            skipped = skipped + 1
        else
            resource.AddWorkshop(id)
            sent = sent + 1
        end
    end
end

MsgC(Color(201, 168, 92), "[42Bros] ", color_white,
    string.format("Players will download %d Workshop item(s) from the collection (%d skipped).\n", sent, skipped))
