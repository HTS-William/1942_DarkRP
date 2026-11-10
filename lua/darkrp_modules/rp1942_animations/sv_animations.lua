--[[---------------------------------------------------------------------------
42Bros - animations (server): plays one for everyone. See sh_animations.lua.
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_Anim")
local A = RP1942.Animations

local allowed = {}
for i, a in ipairs(A.list) do allowed[i] = a.act end

local function play(ply, cmd, args)
    if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then return end
    if ply.isArrested and ply:isArrested() then return end
    local i = tonumber(args[1] or "")
    local act = i and allowed[math.floor(i)]
    if not act then return end
    local now = CurTime()
    if (ply.RP1942_NextAnim or 0) > now then return end
    ply.RP1942_NextAnim = now + A.cooldown

    net.Start("RP1942_Anim")
    net.WriteEntity(ply)
    net.WriteUInt(math.floor(i), 8)
    net.Broadcast()
end
concommand.Add("rp1942_animation", play)

-- DarkRP's own command (any old binds) goes through the same checks: it
-- sends an ACT number, which is looked up in our list
local function darkrpCommand(ply, cmd, args)
    local act = tonumber(args[1] or "")
    for i, a in ipairs(A.list) do
        if a.act == act then return play(ply, cmd, { i }) end
    end
end
concommand.Add("_DarkRP_DoAnimation", darkrpCommand)
hook.Add("Initialize", "RP1942_Animations", function() concommand.Add("_DarkRP_DoAnimation", darkrpCommand) end)
