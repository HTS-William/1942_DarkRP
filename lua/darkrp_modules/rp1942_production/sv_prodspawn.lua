--[[---------------------------------------------------------------------------
1942 DarkRP - production spawner for staff (server)

A debug menu to spawn production things without buying them or working for
them: machines, flour, markets and every good at any quality, plus tools for
the machine you're looking at (finish its timer, remove it).

    Open it:  ULX menu > Cmds > 42Bros > prodspawn, !prodspawn, or /prodspawn
    Who:      with ULX, whoever has "ulx prodspawn" (Groups tab); without
              ULX, superadmins

Everything spawns at your crosshair, owned by you, and can be undone with Z.
Markets spawned here are NOT saved (use /addmarket for that), and derricks
spawned here stand where you aim, not on an oil site.
The client half is cl_prodspawn.lua.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_ProdSpawnOpen")
util.AddNetworkString("RP1942_ProdSpawn")

local function canSpawn(ply)
    return RP1942.staffCan(ply, "ulx prodspawn", function(p) return p:IsSuperAdmin() end)
end

function RP1942.openProdSpawn(ply)
    if not IsValid(ply) then return end
    if not canSpawn(ply) then
        DarkRP.notify(ply, 1, 4, "You aren't allowed to use the production spawner.")
        return
    end
    net.Start("RP1942_ProdSpawnOpen")
    net.Send(ply)
end

DarkRP.defineChatCommand("prodspawn", function(ply)
    RP1942.openProdSpawn(ply)
    return ""
end)

-- What the menu may spawn as a whole entity
local MACHINES = {
    rp1942_oven = true, rp1942_flour = true, rp1942_wine_barrel = true,
    rp1942_factory = true, rp1942_oil_rig = true, rp1942_market = true,
}

local function aim(ply)
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 600,
        filter = ply,
    })
    return tr
end

local function own(ent, ply)
    if ent.Setowning_ent then ent:Setowning_ent(ply) end
    if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
    ent.SID = ply.SID
end

local function addUndo(ply, ent, what)
    undo.Create(what)
    undo.AddEntity(ent)
    undo.SetPlayer(ply)
    undo.Finish()
end

local function spawnMachine(ply, class)
    local tr = aim(ply)
    local yaw = ply:EyeAngles().y + 180   -- facing you
    local ent = ents.Create(class)
    if not IsValid(ent) then return end
    ent:SetPos(tr.HitPos + tr.HitNormal * 4)
    ent:SetAngles(Angle(0, yaw, 0))
    ent:Spawn()
    ent:Activate()
    -- Stand it on what you're aiming at
    if tr.HitNormal.z > 0.5 then ent:SetPos(tr.HitPos - Vector(0, 0, ent:OBBMins().z) + Vector(0, 0, 1)) end
    own(ent, ply)

    if class == "rp1942_oil_rig" then
        ent:Anchor(ent:GetPos(), ent:GetAngles())   -- bolted down where it stands (no oil site used)
        ent:StartPump()
    elseif class == "rp1942_market" then
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
    end
    addUndo(ply, ent, "Production: " .. (ent.PrintName or class))
    ServerLog(string.format("[1942] %s spawned %s (production spawner)\n", ply:Nick(), class))
end

local function spawnGoods(ply, id, q, count, pocket)
    local good = RP1942.Goods[id]
    if not good then return end
    local tr = aim(ply)
    local pos = tr.HitPos + tr.HitNormal * 8
    if pocket then
        local pocketed, dropped = RP1942.giveGoods(ply, id, q, count, pos)
        DarkRP.notify(ply, 0, 4, "Spawned " .. count .. "x " .. RP1942.qualityName(q) .. " " .. good.name
            .. (dropped > 0 and (" (" .. dropped .. " didn't fit in your pocket)") or " into your pocket") .. ".")
    else
        undo.Create("Production: " .. good.name)
        for i = 1, count do
            local ent = RP1942.spawnGood(id, pos + Vector(0, 0, (i - 1) * 8), nil, q)
            if IsValid(ent) then
                ent.RP1942_Holder = ply
                undo.AddEntity(ent)
            end
        end
        undo.SetPlayer(ply)
        undo.Finish()
    end
    ServerLog(string.format("[1942] %s spawned %dx %s (%d stars, production spawner)\n", ply:Nick(), count, id, q))
end

-- Finish the timer of the machine you're looking at
local function finish(ply)
    local ent = aim(ply).Entity
    if not IsValid(ent) then return DarkRP.notify(ply, 1, 4, "Look at an oven, wine barrel, derrick or factory line.") end
    local class = ent:GetClass()
    if ent.GetOff and ent:GetOff() and ent.SetPower then ent:SetPower(true) end

    if class == "rp1942_oven" or class == "rp1942_oil_rig" then
        if ent:GetDoneAt() <= 0 then return DarkRP.notify(ply, 1, 4, "It isn't working on anything right now.") end
        ent:SetDoneAt(CurTime())
    elseif class == "rp1942_wine_barrel" then
        if ent:GetDoneAt() <= 0 then return DarkRP.notify(ply, 1, 4, "It isn't fermenting. Press START first.") end
        ent:SetDoneAt(CurTime())
    elseif class == "rp1942_factory" then
        if ent:GetState() == ent.STATE_DONE then return DarkRP.notify(ply, 1, 4, "The run is already done: COLLECT it.") end
        ent:Finish()
    else
        return DarkRP.notify(ply, 1, 4, "Look at an oven, wine barrel, derrick or factory line.")
    end
    DarkRP.notify(ply, 0, 4, "Finished. (The grade is whatever it had earned so far.)")
end

local function remove(ply)
    local ent = aim(ply).Entity
    if IsValid(ent) and (MACHINES[ent:GetClass()] or ent:GetClass() == "rp1942_good") then
        ServerLog(string.format("[1942] %s removed %s (production spawner)\n", ply:Nick(), ent:GetClass()))
        ent:Remove()
    else
        DarkRP.notify(ply, 1, 4, "Look at a production machine or a good.")
    end
end

net.Receive("RP1942_ProdSpawn", function(_, ply)
    if not canSpawn(ply) then return end
    if (ply.RP1942_NextProdSpawn or 0) > CurTime() then return end
    ply.RP1942_NextProdSpawn = CurTime() + 0.2

    local kind = net.ReadString()
    local id = net.ReadString()
    local q = math.Clamp(net.ReadUInt(2), 1, 3)
    local count = math.Clamp(net.ReadUInt(4), 1, 10)
    local pocket = net.ReadBool()

    if kind == "machine" and MACHINES[id] then
        spawnMachine(ply, id)
    elseif kind == "good" then
        spawnGoods(ply, id, q, count, pocket)
    elseif kind == "finish" then
        finish(ply)
    elseif kind == "remove" then
        remove(ply)
    end
end)
