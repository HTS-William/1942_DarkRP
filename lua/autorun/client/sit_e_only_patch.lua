--============================================================
-- SitAnywhere E-Only Patch
-- Press E to sit on the world or a plain prop, while keeping the old
-- Alt + E method (which can sit on anything SitAnywhere allows).
-- Client-side only.
--============================================================

if not CLIENT then return end

local enabled = CreateClientConVar("an_sit_e_only", "1", true, false, "Enable E-only sitting.")
local maxDist = CreateClientConVar("an_sit_e_only_dist", "90", true, false, "Max distance for E-only sit trace.")

local nextSit = 0

-- What a plain E may sit on: the world (walls, benches built into the map)
-- and ordinary props. Anything that DOES something when you press E on it in
-- this gamemode (doors, machines, dumpsters, markets, crates, the vault,
-- goods, dropped weapons, printers, vehicles, players, NPCs, buttons) is
-- left alone, so E still does that. Alt + E can still sit on those.
local SIT_CLASSES = {
    ["prop_physics"] = true,
    ["prop_physics_multiplayer"] = true,
    ["prop_dynamic"] = true,
    ["func_brush"] = true,
    ["func_wall"] = true,
    ["func_detail"] = true,
}

local function PlainSeat(ent)
    if not IsValid(ent) then return true end   -- the world
    if ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() then return false end
    local class = ent:GetClass()
    if not SIT_CLASSES[class] then return false end
    -- A prop you're about to pick up or use with E (a spawned weapon, an
    -- item) isn't a seat either
    if ent.Use or ent.PlayerUse then return false end
    return true
end

hook.Add("KeyPress", "AN_SitAnywhere_EOnlyPatch", function(ply, key)
    if ply ~= LocalPlayer() then return end
    if key ~= IN_USE then return end
    if not enabled:GetBool() then return end
    if CurTime() < nextSit then return end
    if not ply:Alive() then return end
    if ply:InVehicle() then return end
    if ply:Crouching() then return end
    if ply.getDarkRPVar and ply:getDarkRPVar("Arrested") then return end
    -- Looking at a machine's control panel: E presses the button
    if RP1942 and RP1942.PanelLook and RP1942.PanelLook.t and CurTime() - RP1942.PanelLook.t < 0.2 then return end

    -- Do not interfere while holding Walk/Alt.
    -- This keeps the original Alt + E method working normally.
    if ply:KeyDown(IN_WALK) then return end

    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * maxDist:GetFloat(),
        filter = ply
    })

    if not tr.Hit then return end

    -- Only plain props and the map itself
    if not PlainSeat(tr.Entity) then return end

    nextSit = CurTime() + 0.75

    -- SitAnywhere supports +sit, so we simply trigger it.
    RunConsoleCommand("+sit")

    timer.Simple(0.05, function()
        RunConsoleCommand("-sit")
    end)
end)