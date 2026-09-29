--============================================================
-- SitAnywhere E-Only Patch
-- Press E to sit, while keeping the old Alt + E method.
-- Client-side only.
--============================================================

if not CLIENT then return end

local enabled = CreateClientConVar("an_sit_e_only", "1", true, false, "Enable E-only sitting.")
local maxDist = CreateClientConVar("an_sit_e_only_dist", "90", true, false, "Max distance for E-only sit trace.")

local nextSit = 0

local BLOCKED_CLASSES = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true,
    ["func_button"] = true,
    ["gmod_button"] = true,
}

local function CanUseEntity(ent)
    if not IsValid(ent) then return false end

    if ent:IsVehicle() then return true end
    if ent:IsNPC() then return true end

    local class = ent:GetClass()
    if BLOCKED_CLASSES[class] then return true end

    return false
end

hook.Add("KeyPress", "AN_SitAnywhere_EOnlyPatch", function(ply, key)
    if ply ~= LocalPlayer() then return end
    if key ~= IN_USE then return end
    if not enabled:GetBool() then return end
    if CurTime() < nextSit then return end
    if not ply:Alive() then return end
    if ply:InVehicle() then return end
    if ply:Crouching() then return end

    -- Do not interfere while holding Walk/Alt.
    -- This keeps the original Alt + E method working normally.
    if ply:KeyDown(IN_WALK) then return end

    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * maxDist:GetFloat(),
        filter = ply
    })

    if not tr.Hit then return end

    -- Do not sit when pressing E on doors, buttons, vehicles, NPCs, etc.
    if CanUseEntity(tr.Entity) then return end

    nextSit = CurTime() + 0.75

    -- SitAnywhere supports +sit, so we simply trigger it.
    RunConsoleCommand("+sit")

    timer.Simple(0.05, function()
        RunConsoleCommand("-sit")
    end)
end)