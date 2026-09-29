--[[---------------------------------------------------------------------------
1942 DarkRP - production spawner for staff (server)

A debug menu to spawn production things without buying them or working for
them: machines, flour, markets and every good at any quality, plus tools for
the machine you're looking at (finish its timer, remove it).

    Open it:  ULX menu > Cmds > 42Bros > prodspawn, !prodspawn, or !prodspawn
    Who:      with ULX, whoever has "ulx prodspawn" (Groups tab); without
              ULX, superadmins

Everything spawns at your crosshair, owned by you, and can be undone with Z.
Derricks spawned here stand where you aim, not on an oil site.

Making placed machines permanent (saved per map in
data/rp1942/prodsaves_<map>.json, respawned on every map start and cleanup,
frozen in place and owned by nobody, so any player can use them):
    !saveprod      the machine you're looking at
    !saveprodall   every machine you placed from this menu and haven't saved
    !unsaveprod    the saved machine you're looking at: removed, and from the save
    !prodsaves     how many are saved on this map (and highlights them for a minute)
The menu's TOOLS row has buttons for the first three.
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


-- What the menu may spawn as a whole entity
local MACHINES = {
    rp1942_oven = true, rp1942_flour = true, rp1942_wine_barrel = true,
    rp1942_factory = true, rp1942_oil_rig = true, rp1942_market = true,
    rp1942_printer_bank = true, rp1942_printer_illegal = true,
    rp1942_dumpster = true,
    rp1942_bank_vault = true,
    darkrp_laws = true,         -- a law board (the Führer's laws); save it with !saveprod   -- the Reichsbank (rp1942_bank): save it with !saveprod, or place it with !addvault
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
    ent.RP1942_ProdSpawnedBy = ply

    if class == "rp1942_oil_rig" then
        ent:Anchor(ent:GetPos(), ent:GetAngles())   -- bolted down where it stands (no oil site used)
        ent:StartPump()
    elseif class == "rp1942_market" or class == "rp1942_dumpster" or class == "rp1942_bank_vault" or class == "darkrp_laws" then
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
    elseif class == "rp1942_printer_bank" or class == "rp1942_printer_illegal" then
        ent:DoPrint()   -- prints once, right now
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
        if ent.RP1942_SaveId then
            DarkRP.notify(ply, 0, 5, "That one was saved: it's gone for now but comes back on restart. Use !unsaveprod to remove it for good.")
        end
        ent:Remove()
    else
        DarkRP.notify(ply, 1, 4, "Look at a production machine or a good.")
    end
end

--[[---------------------------------------------------------------------------
Permanent machines
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_ProdSaves")

local SAVE_DIR = "rp1942"
local function saveFile() return SAVE_DIR .. "/prodsaves_" .. game.GetMap() .. ".json" end
local function loadSaves()
    local raw = file.Read(saveFile(), "DATA")
    return raw and util.JSONToTable(raw) or {}
end
local function writeSaves(list)
    file.CreateDir(SAVE_DIR)
    file.Write(saveFile(), util.TableToJSON(list, true))
end

local function freeze(ent)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) phys:Sleep() end
end

local function spawnSaved(id, v)
    if not MACHINES[v.class] then return end
    -- Already one there (e.g. a dumpster also hardcoded in its config, or
    -- placed with !adddumpster / !addmarket): don't stack a second
    local here = Vector(v.x, v.y, v.z)
    for _, other in ipairs(ents.FindInSphere(here, 32)) do
        if other:GetClass() == v.class then
            other.RP1942_SaveId = id
            return other
        end
    end
    local ent = ents.Create(v.class)
    if not IsValid(ent) then return end
    local pos, ang = Vector(v.x, v.y, v.z), Angle(v.p or 0, v.yaw or 0, v.r or 0)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    ent.RP1942_SaveId = id
    if v.class == "rp1942_oil_rig" then
        ent:Anchor(pos, ang)
        ent:StartPump()
    else
        freeze(ent)
    end
    return ent
end

local function spawnAllSaved()
    local n = 0
    for id, v in pairs(loadSaves()) do
        if IsValid(spawnSaved(id, v)) then n = n + 1 end
    end
    if n > 0 then MsgC(Color(160, 220, 120), "[1942] Production: spawned " .. n .. " saved machine(s).\n") end
end
hook.Add("InitPostEntity", "RP1942_ProdSaves", function() timer.Simple(1, spawnAllSaved) end)
hook.Add("PostCleanupMap", "RP1942_ProdSaves", function() timer.Simple(0.5, spawnAllSaved) end)   -- after the dumpsters' and markets' own respawns

-- Add one machine to the save; returns true if it was newly saved
local function saveOne(ent, list)
    if ent.RP1942_SaveId and list[ent.RP1942_SaveId] then return false end
    local id = tostring(os.time()) .. "_" .. ent:EntIndex() .. "_" .. math.random(1000, 9999)
    local pos, ang = ent:GetPos(), ent:GetAngles()
    list[id] = { class = ent:GetClass(), x = pos.x, y = pos.y, z = pos.z, p = ang.p, yaw = ang.y, r = ang.r }
    ent.RP1942_SaveId = id
    ent.RP1942_ProdSpawnedBy = nil
    if ent:GetClass() == "rp1942_oil_rig" then ent:Anchor(pos, ang) else freeze(ent) end
    return true
end

local function saveCan(ply)
    if RP1942.staffCan(ply, "ulx saveprod", function(p) return p:IsSuperAdmin() end) then return true end
    DarkRP.notify(ply, 1, 4, "You aren't allowed to save production machines.")
    return false
end

local function lookedAtMachine(ply)
    local ent = aim(ply).Entity
    if IsValid(ent) and MACHINES[ent:GetClass()] then return ent end
    DarkRP.notify(ply, 1, 4, "Look at a production machine (oven, flour, barrel, factory line, derrick, market, printer, dumpster, bank vault or law board).")
end

function RP1942.prodSave(ply)
    if not saveCan(ply) then return end
    local ent = lookedAtMachine(ply)
    if not ent then return end
    local list = loadSaves()
    if not saveOne(ent, list) then return DarkRP.notify(ply, 1, 4, "That " .. (ent.PrintName or "machine") .. " is already saved.") end
    writeSaves(list)
    DarkRP.notify(ply, 0, 5, (ent.PrintName or "Machine") .. " saved: it will be here after every restart. (!unsaveprod to undo)")
    ServerLog(string.format("[1942] %s saved a %s at %s\n", ply:Nick(), ent:GetClass(), tostring(ent:GetPos())))
end

function RP1942.prodSaveAll(ply)
    if not saveCan(ply) then return end
    local list, n = loadSaves(), 0
    for _, ent in ipairs(ents.GetAll()) do
        if ent.RP1942_ProdSpawnedBy == ply and MACHINES[ent:GetClass()] and saveOne(ent, list) then n = n + 1 end
    end
    if n == 0 then return DarkRP.notify(ply, 1, 4, "You have no unsaved machines placed from the production spawner.") end
    writeSaves(list)
    DarkRP.notify(ply, 0, 5, "Saved " .. n .. " machine(s) for this map.")
    ServerLog(string.format("[1942] %s saved %d production machine(s)\n", ply:Nick(), n))
end

function RP1942.prodUnsave(ply)
    if not saveCan(ply) then return end
    local ent = lookedAtMachine(ply)
    if not ent then return end
    local list = loadSaves()
    if not (ent.RP1942_SaveId and list[ent.RP1942_SaveId]) then
        return DarkRP.notify(ply, 1, 4, "That " .. (ent.PrintName or "machine") .. " isn't saved. (Remove it from the spawner's tools, or Z)")
    end
    list[ent.RP1942_SaveId] = nil
    writeSaves(list)
    ServerLog(string.format("[1942] %s unsaved a %s at %s\n", ply:Nick(), ent:GetClass(), tostring(ent:GetPos())))
    ent:Remove()
    DarkRP.notify(ply, 0, 5, "Removed, and from this map's save.")
end

function RP1942.prodSaves(ply)
    if not saveCan(ply) then return end
    local counts, total, spots = {}, 0, {}
    for _, v in pairs(loadSaves()) do
        counts[v.class] = (counts[v.class] or 0) + 1
        total = total + 1
        spots[#spots + 1] = Vector(v.x, v.y, v.z)
    end
    if total == 0 then return DarkRP.notify(ply, 0, 5, "No saved machines on this map yet. Look at one and use !saveprod.") end
    local parts = {}
    for class, n in SortedPairs(counts) do
        local stored = scripted_ents.GetStored(class)
        parts[#parts + 1] = n .. "x " .. ((stored and stored.t and stored.t.PrintName) or class)
    end
    DarkRP.notify(ply, 0, 8, total .. " saved machine(s): " .. table.concat(parts, ", ") .. ". Highlighted for a minute.")
    net.Start("RP1942_ProdSaves")
    net.WriteUInt(math.min(#spots, 255), 8)
    for i = 1, math.min(#spots, 255) do net.WriteVector(spots[i]) end
    net.Send(ply)
end

RP1942.defineStaffCommand("saveprod", function(ply) RP1942.prodSave(ply) return "" end)
RP1942.defineStaffCommand("saveprodall", function(ply) RP1942.prodSaveAll(ply) return "" end)
RP1942.defineStaffCommand("unsaveprod", function(ply) RP1942.prodUnsave(ply) return "" end)
RP1942.defineStaffCommand("prodsaves", function(ply) RP1942.prodSaves(ply) return "" end)

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
    elseif kind == "save" then
        RP1942.prodSave(ply)
    elseif kind == "saveall" then
        RP1942.prodSaveAll(ply)
    elseif kind == "unsave" then
        RP1942.prodUnsave(ply)
    end
end)
