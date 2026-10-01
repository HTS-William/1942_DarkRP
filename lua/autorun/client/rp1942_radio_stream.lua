--[[---------------------------------------------------------------------------
1942 DarkRP - playing a radio's stream (client, shared by every radio entity)

Both the wireless set (rp1942_radio) and the factory's Radio Set good
(rp1942_good with Good = "radio") play the same way. An entity with
GetURL / GetVolume calls these:
    RP1942.radioThink(ent)      from its client Think: registers it
    RP1942.radioStop(ent)       on remove
    RP1942.radioStatus(ent)     -> text for its label ("Playing", "No signal")
In lua/autorun so it exists before any entity script loads.

HOW LOUD
The volume is worked out here, from how far you are from the set:
    within nearRange (150)      full volume
    nearRange -> range (900)    fades smoothly down
    beyond range                silent
    beyond range x 1.3          the stream is stopped altogether (no
                                download for radios across the map), and
                                started again when you come back in range
The game's own 3D fade isn't used for the volume: it only lowers a sound
down to a floor, it never makes it silent. 3D still places the sound left /
right. One loop handles every radio, so a set that's out of view (dormant)
can't get stuck playing.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local master  = CreateClientConVar("rp1942_radio_volume", "1", true, false, "Your volume for every radio (0-1)", 0, 1)
local enabled = CreateClientConVar("rp1942_radio", "1", true, false, "Hear the radios (0 = silence them all)", 0, 1)

local radios = {}   -- every radio entity seen: ent -> true

local function setting(key, default)
    return RP1942.radioSetting and RP1942.radioSetting(key) or default
end

local function start(ent, url)
    local range = setting("range", 900)
    ent.radioLoading = true
    ent.radioPlaying = url
    sound.PlayURL(url, "3d noblock", function(chan, err, errName)
        if not IsValid(ent) or ent.radioPlaying ~= url then
            if IsValid(chan) then chan:Stop() end
            return
        end
        ent.radioLoading = false
        if not IsValid(chan) then
            ent.radioFailed = errName or tostring(err)
            return
        end
        ent.radioFailed = nil
        -- 3D only for direction: its own fade starts far beyond our range
        chan:Set3DFadeDistance(range * 4, range * 8)
        chan:SetPos(ent:GetPos())
        chan:SetVolume(0)   -- the loop below sets the real volume
        chan:Play()
        ent.radioChannel = chan
    end)
end

function RP1942.radioStop(ent)
    if IsValid(ent.radioChannel) then ent.radioChannel:Stop() end
    ent.radioChannel = nil
    ent.radioLoading = false
    ent.radioFailed = nil
    ent.radioPlaying = nil
end

function RP1942.radioThink(ent)
    radios[ent] = true
end

-- 1 near the set, 0 at `range` and beyond
local function falloff(dist, near, range)
    if dist <= near then return 1 end
    if dist >= range then return 0 end
    local t = (dist - near) / (range - near)
    return (1 - t) * (1 - t)
end

local nextUpdate = 0
hook.Add("Think", "RP1942_RadioStreams", function()
    local now = RealTime()
    if now < nextUpdate then return end
    nextUpdate = now + 0.1

    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local ear = lp:EyePos()
    local near, range = setting("nearRange", 150), setting("range", 900)
    local stopAt, startAt = range * 1.3, range * 1.1
    local on, vol = enabled:GetBool(), master:GetFloat()

    for ent in pairs(radios) do
        if not IsValid(ent) then
            radios[ent] = nil
        else
            local url = on and ent:GetURL() or ""
            local dist = ent:IsDormant() and math.huge or ear:Distance(ent:GetPos())
            -- Should it be streaming? (a gap between the start and stop
            -- distances, so walking along the edge doesn't restart it)
            local want = url ~= "" and (dist < startAt or (ent.radioPlaying == url and dist < stopAt))
            if not want then
                if ent.radioPlaying then RP1942.radioStop(ent) end
            elseif ent.radioPlaying ~= url then
                RP1942.radioStop(ent)
                start(ent, url)
            end

            local chan = ent.radioChannel
            if IsValid(chan) then
                chan:SetPos(ent:GetPos())
                chan:SetVolume(math.Clamp(ent:GetVolume() * vol * falloff(dist, near, range), 0, 1))
            end
        end
    end
end)

function RP1942.radioStatus(ent)
    if ent:GetURL() == "" then return "Off" end
    if not enabled:GetBool() then return "Muted (rp1942_radio 0)" end
    if ent.radioFailed then return "No signal (" .. tostring(ent.radioFailed) .. ")" end
    if ent.radioLoading or not IsValid(ent.radioChannel) then return "Tuning in..." end
    return "Playing"
end
