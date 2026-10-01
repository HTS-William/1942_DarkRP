--[[---------------------------------------------------------------------------
1942 DarkRP - handcuffs (server): grabbing, the 8 seconds, the arrest
---------------------------------------------------------------------------]]
local CFG = RP1942.HandcuffsConfig
local CUFFS = "rp1942_handcuffs"

-- Players download the handcuff models (this addon's models/weapons/spy and
-- materials/models/spy/handcuffs). AddFile on a .mdl brings its .vvd, .vtx
-- and .phy along; on a .vmt, its texture.
resource.AddFile("models/weapons/spy/handcuffs.mdl")
resource.AddFile("models/weapons/spy/w_handcuffs.mdl")
resource.AddFile("materials/models/spy/handcuffs/handcuffs.vmt")
resource.AddSingleFile("materials/models/spy/handcuffs/nodraw.vmt")

local active = {}   -- arrester -> { target, finish }

local function setBar(ply, start, finish, text)
    if not IsValid(ply) then return end
    ply:SetNW2Float("RP1942_HoldStart", start)
    ply:SetNW2Float("RP1942_HoldEnd", finish)
    ply:SetNW2String("RP1942_HoldText", text or "")
end

-- Let go. why: told to the arrester (nil = quietly); the prisoner hears they're free.
local function stop(arrester, why)
    local c = active[arrester]
    if not c then return end
    active[arrester] = nil
    local target = c.target
    setBar(arrester, 0, 0, "")
    if IsValid(target) then
        setBar(target, 0, 0, "")
        target:SetNW2Entity("RP1942_CuffedBy", NULL)
    end
    if why then
        if IsValid(arrester) then DarkRP.notify(arrester, 1, 4, "Handcuffing stopped: " .. why .. ".") end
        if IsValid(target) and target:Alive() then DarkRP.notify(target, 0, 4, "You're no longer being handcuffed.") end
    end
end
RP1942.handcuffStop = stop

local function canArrest(arrester, target)
    local ok, msg = hook.Call("canArrest", DarkRP.hooks, arrester, target)
    if not ok then
        DarkRP.notify(arrester, 1, 5, msg or "You can't arrest them.")
        return false
    end
    return true
end

-- true when the grab worked (the weapon then plays its animation)
function RP1942.handcuffStart(arrester, target)
    if active[arrester] or RP1942.isBeingCuffed(arrester) then return end
    if not (IsValid(target) and target:IsPlayer() and target:Alive()) or target == arrester then return end
    if target:isArrested() then return DarkRP.notify(arrester, 1, 4, "They're already arrested.") end
    if RP1942.isBeingCuffed(target) then return DarkRP.notify(arrester, 1, 4, "Someone is already handcuffing them.") end
    if not canArrest(arrester, target) then return end

    if target:InVehicle() then target:ExitVehicle() end
    local now = CurTime()
    active[arrester] = { target = target, finish = now + CFG.time }
    target:SetNW2Entity("RP1942_CuffedBy", arrester)
    setBar(arrester, now, now + CFG.time, "Handcuffing " .. target:Nick() .. "...")
    setBar(target, now, now + CFG.time, arrester:Nick() .. " is handcuffing you...")
    target:EmitSound("physics/metal/chain_impact_soft" .. math.random(1, 3) .. ".wav", 70)
    return true
end

local function finish(arrester, target)
    stop(arrester)
    if not canArrest(arrester, target) then return end   -- asked again: things may have changed
    target:EmitSound("doors/door_latch3.wav", 65)
    target:arrest(nil, arrester)
    DarkRP.notify(target, 0, 20, DarkRP.getPhrase("youre_arrested_by", arrester:Nick()))
    if arrester.SteamName then
        DarkRP.log(arrester:Nick() .. " (" .. arrester:SteamID() .. ") arrested " .. target:Nick(), Color(0, 255, 255))
    end
end

local function whyStop(arrester, target)
    if not IsValid(arrester) or not arrester:Alive() then return "you died" end
    if not IsValid(target) or not target:Alive() then return "they died" end
    if arrester:isArrested() then return "you were arrested" end
    if target:isArrested() then return false end   -- someone else arrested them: nothing to say
    local wep = arrester:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= CUFFS then return "you put the handcuffs away" end
    if arrester:InVehicle() or target:InVehicle() then return "someone got into a seat" end
    if arrester:GetPos():DistToSqr(target:GetPos()) > CFG.keepRange * CFG.keepRange then return "they're too far away" end
end

hook.Add("Think", "RP1942_Handcuffs", function()
    if next(active) == nil then return end
    local now = CurTime()
    for arrester, c in pairs(active) do
        local why = whyStop(arrester, c.target)
        if why ~= nil then
            stop(arrester, why or nil)
        elseif now >= c.finish then
            finish(arrester, c.target)
        end
    end
end)

-- The prisoner can't get out of it another way
hook.Add("CanPlayerSuicide", "RP1942_Handcuffs", function(ply)
    if RP1942.isBeingCuffed(ply) then return false end
end)

hook.Add("playerCanChangeTeam", "RP1942_Handcuffs", function(ply)
    if RP1942.isBeingCuffed(ply) then return false, "You can't change jobs while being handcuffed." end
end)

hook.Add("PlayerDisconnected", "RP1942_Handcuffs", function(ply)
    if active[ply] then stop(ply) end
    local by = RP1942.cuffedBy(ply)
    if by and active[by] then
        ServerLog(string.format("[1942] %s (%s) left while being handcuffed by %s\n", ply:Nick(), ply:SteamID(), by:Nick()))
        stop(by)
        DarkRP.notify(by, 1, 6, ply:Nick() .. " left the server while being handcuffed.")
    end
end)

-- Nobody hands their cuffs to someone else
hook.Add("canDropWeapon", "RP1942_Handcuffs", function(ply, wep)
    if IsValid(wep) and wep:GetClass() == CUFFS then return false end
end)
