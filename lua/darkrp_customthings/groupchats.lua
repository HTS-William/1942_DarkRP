--[[---------------------------------------------------------------------------
1942 DarkRP - group chats (/g)

DarkRP calls these as f(listener, speaker); speaker can be nil when it only
asks whether the listener has access at all.
---------------------------------------------------------------------------]]
local function factionChat(faction)
    return function(listener, speaker)
        if RP1942.getFaction(listener) ~= faction then return false end
        return speaker == nil or RP1942.getFaction(speaker) == faction
    end
end

-- Reich field radio
DarkRP.createGroupChat(factionChat("reich"))

-- Resistance network
DarkRP.createGroupChat(factionChat("resistance"))

-- Everyone else: same job only (e.g. Bakers talking shop)
DarkRP.createGroupChat(function(listener, speaker)
    if RP1942.getFaction(listener) ~= "civilian" then return false end
    return speaker == nil or speaker:Team() == listener:Team()
end)
