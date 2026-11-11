--[[---------------------------------------------------------------------------
42Bros - live broadcasts (server). See sh_broadcast.lua.

Every half second it works out, for each camera on air and each screen
showing it, who's talking at the camera and who's listening at the screen.
Voice uses that table (2D, so it's heard at the screen at full volume);
sounds made around a camera are sent to the listeners as they happen.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_BcastSound")
local CFG = RP1942.Broadcast

local links = {}     -- { cam, screen, listeners = { ply... } } for every screen showing a camera on air
local relay = {}     -- relay[listener][talker] = true

-- A camera that's filming: the hand-held newsreel camera, out and on air
local function onAir(cam) return IsValid(cam) and cam.Broadcasting and cam:Broadcasting() end
RP1942.broadcastOnAir = onAir

-- Where a camera is: a hand-held one is where its holder is
local function camPos(cam)
    local owner = cam:IsWeapon() and cam:GetOwner()
    return IsValid(owner) and owner:GetPos() or cam:GetPos()
end

local function update()
    links, relay = {}, {}
    local hearCam, hearScreen = CFG.hearCamera ^ 2, CFG.hearScreen ^ 2
    for _, screen in ipairs(ents.FindByClass("rp1942_cinema_screen")) do
        local cam = screen:GetCamera()
        if onAir(cam) then
            local cPos, scrPos = camPos(cam), screen:GetPos()
            local talkers, listeners = {}, {}
            for _, p in ipairs(player.GetAll()) do
                local pos = p:GetPos()
                local atCam = pos:DistToSqr(cPos) <= hearCam
                if atCam then talkers[#talkers + 1] = p
                elseif pos:DistToSqr(scrPos) <= hearScreen then listeners[#listeners + 1] = p end
            end
            for _, l in ipairs(listeners) do
                relay[l] = relay[l] or {}
                for _, t in ipairs(talkers) do relay[l][t] = true end
            end
            links[#links + 1] = { cam = cam, screen = screen, listeners = listeners }
        end
    end
end
timer.Create("RP1942_Broadcast", 0.5, 0, update)

-- Voice from the camera, heard at the screen
hook.Add("PlayerCanHearPlayersVoice", "RP1942_Broadcast", function(listener, talker)
    local r = relay[listener]
    if not (r and r[talker]) then return end
    if EasyChat and EasyChat.IsBlockedPlayer and EasyChat.IsBlockedPlayer(listener, talker:SteamID()) then return end
    return true, false
end)

-- Sounds made around the camera, played again at the screen
local sent = {}   -- [camera] = { second, count }
hook.Add("EntityEmitSound", "RP1942_Broadcast", function(t)
    if #links == 0 then return end
    local ent = t.Entity
    local pos = t.Pos or (IsValid(ent) and ent:GetPos())
    if not pos or not isstring(t.SoundName) or #t.SoundName > 200 then return end
    local hearCam = CFG.hearCamera ^ 2
    for _, link in ipairs(links) do
        local cam = link.cam
        if IsValid(cam) and IsValid(link.screen) and #link.listeners > 0 and pos:DistToSqr(camPos(cam)) <= hearCam and ent ~= link.screen then
            local now = math.floor(CurTime())
            local s = sent[cam]
            if not s or s[1] ~= now then s = { now, 0 } sent[cam] = s end
            if s[2] < CFG.soundsPerSec then
                s[2] = s[2] + 1
                local alive = {}
                for _, l in ipairs(link.listeners) do if IsValid(l) then alive[#alive + 1] = l end end
                net.Start("RP1942_BcastSound", true)   -- (unreliable: a late sound is no use)
                net.WriteEntity(link.screen)
                net.WriteString(t.SoundName)
                net.WriteUInt(math.Clamp(math.floor(t.SoundLevel or 75), 0, 255), 8)
                net.WriteUInt(math.Clamp(math.floor(t.Pitch or 100), 0, 255), 8)
                net.WriteFloat(math.Clamp(t.Volume or 1, 0, 1))
                net.Send(alive)
            end
        end
    end
end)

-- Viewers near a screen get the world around its camera sent to them, or
-- the picture would be missing everyone standing there
hook.Add("SetupPlayerVisibility", "RP1942_Broadcast", function(ply)
    if #links == 0 then return end
    local range = CFG.viewRange ^ 2
    local pos = ply:GetPos()
    for _, link in ipairs(links) do
        if IsValid(link.cam) and IsValid(link.screen) and pos:DistToSqr(link.screen:GetPos()) <= range then
            AddOriginToPVS((link.cam:BroadcastView()))
        end
    end
end)

hook.Add("PlayerDisconnected", "RP1942_Broadcast", function(ply) relay[ply] = nil end)

-- Whose is it (shop buyer, DarkRP owner, prop protection)? Staff can always use it.
function RP1942.broadcastCanUse(ent, ply)
    if not IsValid(ply) then return false end
    if ply:IsAdmin() then return true end
    if ent.RP1942_ShopOwner == ply then return true end
    if ent.Getowning_ent and ent:Getowning_ent() == ply then return true end
    if ent.CPPIGetOwner and ent:CPPIGetOwner() == ply then return true end
    return false
end
