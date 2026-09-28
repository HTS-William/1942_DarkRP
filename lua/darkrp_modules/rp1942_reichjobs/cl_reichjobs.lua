--[[---------------------------------------------------------------------------
1942 DarkRP - Reich jobs (client): plays your unit's music, for you only
(settings: sh_reichjobs.lua)

The client watches its own job, so the music starts whatever changed it
(F4, chat command, a vote, an admin). The server's message
(sv_reichjobs.lua) is a backup; the same track is never started twice.

Console:
    rp1942_job_music 0/1        turn it off / on for yourself
    rp1942_job_music_stop       stop the song that's playing
    rp1942_job_music_test       play your current job's track and print
                                what's going on (for when you hear nothing)
---------------------------------------------------------------------------]]
local musicOn = CreateClientConVar("rp1942_job_music", "1", true, false,
    "Play your Reich unit's music when you take a job", 0, 1)

-- Kept here so it isn't garbage collected mid-song
local channel, playing, token = nil, nil, 0

local function stop()
    if IsValid(channel) then channel:Stop() end
    channel, playing = nil, nil
    token = token + 1   -- any song still loading is dropped when it arrives
end

local function trackFor(teamNr)
    local job = RPExtraTeams and RPExtraTeams[teamNr]
    local cfg = RP1942.ReichJobs
    return job and cfg and cfg.music[job.command] or nil
end

local function volume()
    local music = GetConVar("snd_musicvolume")
    local v = ((RP1942.ReichJobs and RP1942.ReichJobs.musicVolume) or 0.6) * (music and music:GetFloat() or 1)
    return v, music and music:GetFloat()
end

local function play(path, verbose)
    if not path or path == "" then stop() return end
    -- Same track already playing or still loading: keep it going
    if path == playing and (not IsValid(channel) or channel:GetState() == GMOD_CHANNEL_PLAYING) then return end
    stop()
    if not musicOn:GetBool() then
        if verbose then print("[1942] Job music is turned off for you (rp1942_job_music 0).") end
        return
    end

    local vol, musicSlider = volume()
    if verbose then
        print("[1942] Job music: " .. path .. "  file found: " .. tostring(file.Exists(path, "GAME"))
            .. "  volume: " .. string.format("%.2f", vol) .. " (music slider " .. tostring(musicSlider) .. ")")
    end
    playing = path
    local mine = token
    sound.PlayFile(path, "noplay", function(ch, errId, err)
        if not IsValid(ch) then
            MsgC(Color(255, 170, 0), "[1942] Job music '", path, "' failed to play: ", tostring(err or errId),
                file.Exists(path, "GAME") and "\n" or " (the file isn't on this computer: it wasn't downloaded from the server)\n")
            if mine == token then playing = nil end
            return
        end
        if mine ~= token then ch:Stop() return end   -- changed job (or stopped) while it loaded
        channel = ch
        ch:SetVolume(vol)
        ch:Play()
        if verbose then print("[1942] Job music playing.") end
    end)
end

concommand.Add("rp1942_job_music_stop", function() stop() end, nil, "Stop the job music that's playing")
concommand.Add("rp1942_job_music_test", function()
    local ply = LocalPlayer()
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    local path = trackFor(ply:Team())
    print("[1942] Your job: " .. tostring(job and job.name) .. " (" .. tostring(job and job.command) .. ")  track: " .. tostring(path or "none"))
    if path then stop() play(path, true) end
end, nil, "Play your current job's music and print diagnostics")

cvars.AddChangeCallback("rp1942_job_music", function(_, _, new)
    if new == "0" then stop() end
end, "RP1942_JobMusic")

-- Watch our own job
local lastTeam
timer.Create("RP1942_JobMusicWatch", 0.25, 0, function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local t = ply:Team()
    if lastTeam == nil then lastTeam = t return end   -- just joined: no music for the job we spawned in
    if t == lastTeam then return end
    lastTeam = t
    play(trackFor(t))
end)

-- Backup: the server's message on a job change
net.Receive("RP1942_JobMusic", function()
    play(net.ReadString())
end)
