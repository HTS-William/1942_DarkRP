--[[---------------------------------------------------------------------------
1942 DarkRP - F4 Appearance tab (server)

Players change the bodygroups (helmet, gear, sleeves...) and skin of the
model they're wearing right now. The choices are remembered per model, in
the player's own saved data (PData, garrysmod/sv.db), so they come back:
    - after a respawn or a job change back to the same model
    - after putting the same wardrobe model on again
    - on their next visit

How: once a second, any player whose model changed gets the choices saved
for the new model put back. That covers DarkRP, the wardrobe and anything
else that sets a model, without hooking each of them.

Client: cl_f4_appearance.lua. Settings: RP1942.F4Config.appearance (sh_f4.lua).
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_Appearance")

local RATE = 0.08   -- seconds between changes from one player

local function cfg() return RP1942.F4Config.appearance or {} end

local function key(model)
    return "rp1942_look_" .. util.CRC(string.lower(model or ""))
end

local function load(ply, model)
    return util.JSONToTable(ply:GetPData(key(model), "") or "") or {}
end

local function save(ply)
    local model = ply:GetModel()
    local t = { skin = ply:GetSkin(), bg = {} }
    for id = 0, ply:GetNumBodyGroups() - 1 do
        local v = ply:GetBodygroup(id)
        if v ~= 0 then t.bg[tostring(id)] = v end
    end
    if t.skin == 0 and next(t.bg) == nil then
        ply:RemovePData(key(model))       -- all defaults: nothing to keep
    else
        ply:SetPData(key(model), util.TableToJSON(t))
    end
end

-- Put back what this player chose for the model they're wearing
function RP1942.applySavedAppearance(ply)
    if not IsValid(ply) then return end
    local model = ply:GetModel()
    ply.RP1942_LookModel = model
    if cfg().enabled == false then return end
    local t = load(ply, model)
    if cfg().skins ~= false and tonumber(t.skin) and t.skin < ply:SkinCount() then ply:SetSkin(t.skin) end
    for id, v in pairs(istable(t.bg) and t.bg or {}) do
        id, v = tonumber(id), tonumber(v)
        if id and v and id < ply:GetNumBodyGroups() and v < ply:GetBodygroupCount(id) then ply:SetBodygroup(id, v) end
    end
end

timer.Create("RP1942_Appearance", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply.RP1942_LookModel ~= ply:GetModel() then RP1942.applySavedAppearance(ply) end
    end
end)

-- kind: "bg" (id, value), "skin" (value) or "reset"
net.Receive("RP1942_Appearance", function(_, ply)
    if not IsValid(ply) or not ply:Alive() or cfg().enabled == false then return end
    local now = CurTime()
    if (ply.RP1942_NextLook or 0) > now then return end
    ply.RP1942_NextLook = now + RATE

    local kind = net.ReadString()
    if kind == "bg" then
        local id, v = net.ReadUInt(8), net.ReadUInt(8)
        if id >= ply:GetNumBodyGroups() or v >= ply:GetBodygroupCount(id) then return end
        ply:SetBodygroup(id, v)
    elseif kind == "skin" then
        local v = net.ReadUInt(8)
        if cfg().skins == false or v >= ply:SkinCount() then return end
        ply:SetSkin(v)
    elseif kind == "reset" then
        ply:SetSkin(0)
        for id = 0, ply:GetNumBodyGroups() - 1 do ply:SetBodygroup(id, 0) end
    else
        return
    end
    ply.RP1942_LookModel = ply:GetModel()
    save(ply)
end)
