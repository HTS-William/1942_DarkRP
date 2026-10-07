--[[---------------------------------------------------------------------------
1942 DarkRP - the NLR zone (server). Settings: sh_nlr.lua
---------------------------------------------------------------------------]]
local CFG = RP1942.NLR

local function release(ply, quiet)
    if not IsValid(ply) then return end
    if ply.RP1942_NLRHeld then
        ply.RP1942_NLRHeld = nil
        ply:Freeze(false)
        ply:GodDisable()
        if not quiet then DarkRP.notify(ply, 0, 5, "Your NLR is over: you're free to go.") end
    end
    ply:SetNW2Float("RP1942_NLREnd", 0)
    ply:SetNW2Float("RP1942_NLRWarn", 0)
    ply:SetNW2Bool("RP1942_NLRHeld", false)
end

-- Lift a player's NLR now (staff, or a rule break that caused the death)
function RP1942.clearNLR(ply)
    if not IsValid(ply) then return false end
    local had = ply:GetNW2Float("RP1942_NLREnd", 0) > CurTime()
    release(ply, true)
    return had
end

hook.Add("PlayerDeath", "RP1942_NLR", function(victim)
    if not CFG.enabled or not IsValid(victim) then return end
    local job = victim.getJobTable and victim:getJobTable()
    if job and CFG.exempt[job.command] then return end
    release(victim, true)   -- a new death replaces the old zone
    victim:SetNW2Vector("RP1942_NLRPos", victim:GetPos())
    victim:SetNW2Float("RP1942_NLREnd", CurTime() + CFG.time)
end)

-- Back in their zone too long: to spawn, held there until the NLR is over
local function sendBack(ply)
    ply:Spawn()
    ply:Freeze(true)
    ply:GodEnable()
    ply.RP1942_NLRHeld = true
    ply:SetNW2Bool("RP1942_NLRHeld", true)
    ply:SetNW2Float("RP1942_NLRWarn", 0)
    local left = math.ceil(ply:GetNW2Float("RP1942_NLREnd", 0) - CurTime())
    DarkRP.notify(ply, 1, 8, "You broke NLR: sent back to spawn and held there for the rest of it (" .. left .. "s).")
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and RP1942.isF4Staff and RP1942.isF4Staff(p) then
            p:ChatPrint("[NLR] " .. ply:Nick() .. " stayed in their NLR zone and was sent back to spawn.")
        end
    end
end

timer.Create("RP1942_NLR", 0.5, 0, function()
    local now = CurTime()
    local r2 = CFG.radius * CFG.radius
    for _, ply in ipairs(player.GetAll()) do
        local ends = ply:GetNW2Float("RP1942_NLREnd", 0)
        if ends > 0 and ends <= now then
            release(ply)                                       -- over
        elseif ends > now and ply:Alive() and not ply.RP1942_NLRHeld then
            local arrested = ply.isArrested and ply:isArrested()
            local inside = not arrested and ply:GetPos():DistToSqr(ply:GetNW2Vector("RP1942_NLRPos", vector_origin)) < r2
            local warnBy = ply:GetNW2Float("RP1942_NLRWarn", 0)
            if inside and warnBy == 0 then
                ply:SetNW2Float("RP1942_NLRWarn", now + CFG.grace)
                DarkRP.notify(ply, 1, CFG.grace, "You're back where you died (NLR). Leave within " .. CFG.grace .. " seconds or you'll be sent to spawn.")
            elseif inside and now >= warnBy then
                sendBack(ply)
            elseif not inside and warnBy > 0 then
                ply:SetNW2Float("RP1942_NLRWarn", 0)          -- left in time
            end
        end
    end
end)

-- Held players stay held through a respawn (e.g. a job change that respawns)
hook.Add("PlayerSpawn", "RP1942_NLR", function(ply)
    if ply.RP1942_NLRHeld then
        timer.Simple(0, function()
            if IsValid(ply) and ply.RP1942_NLRHeld then ply:Freeze(true) ply:GodEnable() end
        end)
    end
end)

