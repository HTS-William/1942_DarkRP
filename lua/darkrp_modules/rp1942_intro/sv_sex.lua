--[[---------------------------------------------------------------------------
1942 DarkRP - men's and women's models that fit the name (server). See sh_sex.lua
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_SetSex")

local PDATA = "rp1942_sex"

hook.Add("PlayerInitialSpawn", "RP1942_Sex", function(ply)
    local s = ply:GetPData(PDATA, "")
    if s == "f" or s == "m" then ply:SetNW2String("RP1942_Sex", s) end
end)

-- Pick the model: only when the job has models of both kinds. An outfit the
-- player picked in F4 is kept as long as it's the right kind (so switching
-- Herr / Frau on the form always changes it). Anything else: DarkRP as usual.
local function chooseModel(ply)
    local job = ply:getJobTable()
    if not (job and istable(job.model)) or job.PlayerSetModel then return end
    if not GAMEMODE.Config.enforceplayermodel then return end
    if ply.RP1942_DisguiseModel then return end   -- the wardrobe's (rp1942_core/sv_disguise.lua)
    local sex = RP1942.playerSex(ply)
    local list = RP1942.jobModelsFor(job, sex)
    if not list or #list == #job.model then return end   -- only one kind: nothing to choose
    local pref = string.lower(ply.getPreferredModel and ply:getPreferredModel(ply:Team()) or "")
    for _, m in ipairs(list) do
        if string.lower(m) == pref then return m end   -- his own pick, and it fits
    end
    return list[math.random(#list)]
end

hook.Add("PlayerSetModel", "RP1942_Sex", function(ply)
    local model = chooseModel(ply)
    if not model then return end
    ply:SetModel(model)
    ply:SetupHands()
    return true
end)

-- From the Meldeamt form: "f" or "m"
net.Receive("RP1942_SetSex", function(_, ply)
    if (ply.RP1942_NextSex or 0) > CurTime() then return end
    ply.RP1942_NextSex = CurTime() + 2
    local s = net.ReadString()
    if s ~= "f" and s ~= "m" then return end
    ply:SetNW2String("RP1942_Sex", s)
    ply:SetPData(PDATA, s)
    -- Wearing a model of the other kind? Change it now.
    if ply:Alive() and RP1942.modelSex(ply:GetModel()) ~= s then
        local model = chooseModel(ply)
        if model then
            ply:SetModel(model)
            ply:SetupHands()
        end
    end
end)
