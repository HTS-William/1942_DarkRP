--[[---------------------------------------------------------------------------
1942 DarkRP - playing a radio's stream (client, shared by every radio entity)

Both the wireless set (rp1942_radio) and the factory's Radio Set good
(rp1942_good with Good = "radio") play the same way. An entity with
GetURL / GetVolume calls these:
    RP1942.radioThink(ent)      each client think: start / stop / follow
    RP1942.radioStop(ent)       on remove
    RP1942.radioStatus(ent)     -> text for its label ("Playing", "No signal")
In lua/autorun so it exists before any entity script loads.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local master  = CreateClientConVar("rp1942_radio_volume", "1", true, false, "Your volume for every radio (0-1)", 0, 1)
local enabled = CreateClientConVar("rp1942_radio", "1", true, false, "Hear the radios (0 = silence them all)", 0, 1)

local function start(ent, url)
    local range = RP1942.radioSetting and RP1942.radioSetting("range") or 900
    local near  = RP1942.radioSetting and RP1942.radioSetting("nearRange") or 150
    ent.radioLoading = true
    sound.PlayURL(url, "3d noblock", function(chan, err, errName)
        if not IsValid(ent) or ent.radioURL ~= url then
            if IsValid(chan) then chan:Stop() end
            return
        end
        ent.radioLoading = false
        if not IsValid(chan) then
            ent.radioFailed = errName or tostring(err)
            return
        end
        ent.radioFailed = nil
        chan:Set3DFadeDistance(near, range)
        chan:SetPos(ent:GetPos())
        chan:SetVolume(ent:GetVolume() * master:GetFloat())
        chan:Play()
        ent.radioChannel = chan
    end)
end

function RP1942.radioStop(ent)
    if IsValid(ent.radioChannel) then ent.radioChannel:Stop() end
    ent.radioChannel = nil
    ent.radioLoading = false
    ent.radioFailed = nil
end

function RP1942.radioThink(ent)
    local url = enabled:GetBool() and ent:GetURL() or ""
    if url ~= ent.radioURL then
        RP1942.radioStop(ent)
        ent.radioURL = url
        if url ~= "" then start(ent, url) end
    end
    if IsValid(ent.radioChannel) then
        ent.radioChannel:SetPos(ent:GetPos())
        ent.radioChannel:SetVolume(ent:GetVolume() * master:GetFloat())
    end
end

function RP1942.radioStatus(ent)
    if ent:GetURL() == "" then return "Off" end
    if ent.radioLoading then return "Tuning in..." end
    if ent.radioFailed then return "No signal (" .. tostring(ent.radioFailed) .. ")" end
    if not enabled:GetBool() then return "Muted (rp1942_radio 0)" end
    return "Playing"
end
