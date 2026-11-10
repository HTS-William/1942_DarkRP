--[[---------------------------------------------------------------------------
42Bros - keeping the chat box clean (server)

Every message goes through here before anyone sees it: chat, OOC, adverts,
/me, PMs, anything typed in the chat box. Staff (admins) are left alone.
For everyone else:

    markup          EasyChat's tags (<flash>, <scale=...>, <texture=...>,
                    <background>...) are taken out. A <texture> tag also
                    makes everyone load a picture from a web link, which can
                    show that link's owner their IP addresses.
    invisible text  zero-width characters, right-to-left tricks and other
                    control characters are removed; line breaks become spaces
    zalgo           letters with heaps of accents stacked on them keep one
    stretching      the same character more than `maxRepeat` times in a row
                    is cut down ("noooooooooo" -> "nooooo"), and !!! / !1!1
                    at the end (EasyChat's big shouting text) to "!!"
    length          at most `maxLength` characters
    repeats         the same message again within `repeatSeconds` isn't sent
    local chat      reaches at most `maxLocalDistance` (the player's own
                    setting used to decide, so it could cover the map)

Names: tags in player names are switched off in EasyChat's settings at every
start (AllowTagsInNames), so nobody can wear markup in their name either.
---------------------------------------------------------------------------]]
local CFG = {
    maxLength        = 300,   -- characters per message
    maxRepeat        = 5,     -- the same character in a row
    repeatSeconds    = 15,    -- the same message again
    maxLocalDistance = 300,   -- units (DarkRP's own talking range is 250)
}

local function isStaff(ply)
    return IsValid(ply) and ply:IsAdmin()
end

-- Characters that draw nothing or turn text around
local INVISIBLE = {
    0x00AD, 0x034F, 0x061C, 0x115F, 0x1160, 0x17B4, 0x17B5, 0x180E,
    0x200B, 0x200C, 0x200D, 0x200E, 0x200F, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E,
    0x2060, 0x2061, 0x2062, 0x2063, 0x2064, 0x2066, 0x2067, 0x2068, 0x2069,
    0x3164, 0xFEFF, 0xFFA0,
}
local invisible = {}
for _, c in ipairs(INVISIBLE) do invisible[c] = true end

-- Accent marks that stack on the letter before them
local function isCombining(c)
    return (c >= 0x0300 and c <= 0x036F) or (c >= 0x0483 and c <= 0x0489) or (c >= 0x1AB0 and c <= 0x1AFF)
        or (c >= 0x1DC0 and c <= 0x1DFF) or (c >= 0x20D0 and c <= 0x20FF) or (c >= 0xFE20 and c <= 0xFE2F)
end

function RP1942.cleanChatText(msg)
    if not isstring(msg) then return "" end
    if not utf8.len(msg) then
        -- not valid text: keep the plain ASCII part
        msg = msg:gsub("[\128-\255]", "")
    end

    -- markup tags: <flash>, </flash>, <stop>, <color=255,0,0>, <texture=link,32>...
    -- (only these shapes: "x < y and z > w" is left alone)
    msg = msg:gsub("<%s*/?%s*%a[%w_]*%s*>", "")
    msg = msg:gsub("<%s*%a[%w_]*%s*=[^<>]*>", "")

    local out, run, last, combining = {}, 0, nil, 0
    for _, c in utf8.codes(msg) do
        if c == 10 or c == 13 or c == 9 then c = 32 end          -- line breaks, tabs -> space
        if c < 32 or c == 127 or (c >= 0x80 and c < 0xA0) or invisible[c] then
            -- dropped
        elseif isCombining(c) then
            combining = combining + 1
            if combining <= 1 then out[#out + 1] = utf8.char(c) end
        else
            combining = 0
            if c == last then run = run + 1 else run, last = 1, c end
            if run <= CFG.maxRepeat then out[#out + 1] = utf8.char(c) end
        end
    end
    msg = table.concat(out)

    -- EasyChat shows a message ending in !!! (or !1!1) as huge shouting text
    msg = msg:gsub("[!1]*![!1]*$", function(tail) return #tail >= 3 and "!!" or tail end)

    -- squeeze the spaces, trim, and cut to length
    msg = string.Trim((msg:gsub("  +", " ")))
    if (utf8.len(msg) or #msg) > CFG.maxLength then
        msg = msg:sub(1, (utf8.offset(msg, CFG.maxLength + 1) or (CFG.maxLength + 1)) - 1)
    end
    return msg
end

local lastMessage = {}   -- [player] = { text, time }

hook.Add("PlayerSayTransform", "RP1942_ChatRules", function(ply, datapack)
    if not IsValid(ply) or isStaff(ply) then return end
    local msg = RP1942.cleanChatText(datapack[1])
    if msg == "" then return false end

    local prev = lastMessage[ply]
    local now = CurTime()
    if prev and prev.text == string.lower(msg) and now - prev.time < CFG.repeatSeconds then
        DarkRP.notify(ply, 1, 3, "You just said that.")
        return false
    end
    lastMessage[ply] = { text = string.lower(msg), time = now }
    datapack[1] = msg
end)

hook.Add("PlayerDisconnected", "RP1942_ChatRules", function(ply) lastMessage[ply] = nil end)

-- EasyChat's own settings: no tags in names, a sane hard length cap, the local chat cap
local function applyEasyChat()
    if not EasyChat then return end
    EasyChat.MaxLocalDistance = CFG.maxLocalDistance
    local cfg = EasyChat.Config
    if cfg and cfg.AllowTagsInNames ~= false then
        cfg.AllowTagsInNames = false
        if cfg.Save then cfg:Save() end
        MsgC(Color(160, 220, 120), "[42Bros] Chat: tags in player names switched off.\n")
    end
    local maxChars = GetConVar("easychat_max_chars")
    if maxChars and maxChars:GetInt() > 1000 then RunConsoleCommand("easychat_max_chars", "1000") end
end
hook.Add("InitPostEntity", "RP1942_ChatRules", applyEasyChat)
if EasyChat then applyEasyChat() end   -- (a Lua refresh)
