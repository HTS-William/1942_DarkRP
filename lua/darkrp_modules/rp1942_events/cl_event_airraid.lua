--[[---------------------------------------------------------------------------
1942 DarkRP - air raid (client): the siren for everyone, and the banner.
Server: sv_event_airraid.lua
---------------------------------------------------------------------------]]
local CFG = RP1942.Events.airraid
local siren

local function stopSiren()
    if IsValid(siren) then siren:Stop() end
    siren = nil
end

net.Receive("RP1942_AirRaid", function()
    local on, msg = net.ReadBool(), net.ReadString()
    local from = net.ReadFloat()   -- joined mid-raid: start part-way through
    stopSiren()
    if on then
        sound.PlayFile("sound/" .. CFG.sound, "noplay", function(ch)
            if not IsValid(ch) then return end
            siren = ch
            ch:SetVolume(1)
            if from > 0 then ch:SetTime(from) end
            ch:Play()
        end)
        if msg ~= "" and RP1942.showAlertBanner then
            RP1942.showAlertBanner("lockdown", "AIR RAID", msg, 10, nil,
                function() return GetGlobal2Bool("RP1942_AirRaid", false) end)
        end
    elseif msg ~= "" and RP1942.showAlertBanner then
        RP1942.showAlertBanner("lifted", "ALL CLEAR", msg, 7)
    end
end)
