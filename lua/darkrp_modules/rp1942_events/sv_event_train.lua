--[[---------------------------------------------------------------------------
1942 DarkRP - supply train event (server)
The train entity (lua/entities/rp1942_supply_train) does the driving and the
robbing; this just places it and hooks it into the scheduler.
---------------------------------------------------------------------------]]
local CFG = RP1942.Events.train
local train

-- Snap a point on the line down onto whatever is under it (the rails)
local function ground(pos)
    if not CFG.groundTrace then return pos + Vector(0, 0, CFG.zOffset or 0) end
    local tr = util.TraceLine({
        start  = pos + Vector(0, 0, 32),
        endpos = pos - Vector(0, 0, 256),
        mask   = MASK_SOLID_BRUSHONLY,   -- the world only, not players standing on the line
    })
    local z = tr.Hit and tr.HitPos.z or pos.z
    return Vector(pos.x, pos.y, z + (CFG.zOffset or 0))
end

RP1942.registerEvent("train", {
    name   = "Supply train",
    config = CFG,

    canStart = function()
        if not util.IsValidModel(CFG.model) then return false, "model " .. CFG.model .. " is missing" end
        return true
    end,

    start = function()
        local a, s, b = ground(CFG.start), ground(CFG.stop or CFG.start), ground(CFG.finish)
        -- Keep it perfectly level even if the traces land a hair apart
        s.z, b.z = a.z, a.z

        local ent = ents.Create("rp1942_supply_train")
        if not IsValid(ent) then
            ErrorNoHalt("[1942] Supply train: couldn't create rp1942_supply_train\n")
            return false
        end
        ent:SetRoute(a, s, b)
        ent:Spawn()
        ent:Activate()
        train = ent

        if RP1942.alert and CFG.msgStart then RP1942.alert(CFG.msgStart, "wanted") end
    end,

    isActive = function() return IsValid(train) end,

    stop = function()
        if IsValid(train) then train:Remove() end
    end,
})

-- Warn once at startup about weapon classes that aren't installed
hook.Add("InitPostEntity", "RP1942_TrainCheck", function()
    for class in pairs(CFG.weapons) do
        if not weapons.GetStored(class) then
            MsgC(Color(255, 180, 60), "[1942] Supply train: weapon '" .. class .. "' isn't installed; it will never drop.\n")
        end
    end
    if not util.IsValidModel(CFG.model) then
        MsgC(Color(255, 180, 60), "[1942] Supply train: model '" .. CFG.model .. "' is missing; the event can't run.\n")
    end
end)
