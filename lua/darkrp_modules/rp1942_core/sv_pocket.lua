--[[---------------------------------------------------------------------------
1942 DarkRP - putting loot straight into DarkRP pockets (server)

Used by the dumpster, dead drops and the supply train. A pocketed item works
exactly like one the player pocketed themselves: take it out with the pocket
SWEP. Duplicates are fine (two of the same gun are two pocket items).

    RP1942.pocketRoom(ply)                     -> free pocket slots (0 without a pocket)
    RP1942.makeSpawnedWeapon(class, pos, clip) -> a DarkRP "spawned_weapon" lying at pos
    RP1942.pocketOrLeave(ply, ent)             -> true if it went into the pocket;
                                                  false leaves ent where it is
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

function RP1942.pocketRoom(ply)
    if not IsValid(ply) or not ply:HasWeapon("pocket") then return 0 end
    local job = RPExtraTeams[ply:Team()]
    local max = (job and job.maxpocket) or GAMEMODE.Config.pocketitems or 10
    return math.max(0, max - table.Count(ply.darkRPPocket or {}))
end

function RP1942.makeSpawnedWeapon(class, pos, clip)
    local stored = weapons.GetStored(class)
    local ent = ents.Create("spawned_weapon")
    if not IsValid(ent) then return nil end
    ent:SetModel((stored and stored.WorldModel ~= "" and stored.WorldModel) or "models/weapons/w_pistol.mdl")
    ent:SetWeaponClass(class)
    ent:SetPos(pos)
    local primary = stored and stored.Primary
    ent.clip1 = clip or (primary and primary.ClipSize)
    ent.ammoadd = 0
    ent.nodupe = true
    ent:Spawn()
    return ent
end

function RP1942.pocketOrLeave(ply, ent)
    if not IsValid(ent) or RP1942.pocketRoom(ply) <= 0 then return false end
    ply:addPocketItem(ent)
    return true
end
