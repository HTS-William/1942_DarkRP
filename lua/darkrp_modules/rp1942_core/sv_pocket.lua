--[[---------------------------------------------------------------------------
1942 DarkRP - putting loot straight into DarkRP pockets (server)

Used by the dumpster, dead drops and the supply train. A pocketed item works
exactly like one the player pocketed themselves: take it out with the pocket
SWEP. Duplicates are fine (two of the same gun are two pocket items).

    RP1942.pocketRoom(ply)                     -> free pocket slots (0 without a pocket)
    RP1942.makeSpawnedWeapon(class, pos, clip, model)
                                               -> a DarkRP "spawned_weapon" lying at pos,
                                                  loaded (a magazine, or the grenade itself)
    RP1942.weaponExists(class)                 -> is that weapon installed?
    RP1942.spawnInFront(ply, dist)             -> a spot in front of the player (shops)
    RP1942.pocketOrLeave(ply, ent)             -> true if it went into the pocket;
                                                  false leaves ent where it is

The dealers' shop, the F4 shop and the padlocks all hand out weapons with
makeSpawnedWeapon, so they all arrive the same way.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

function RP1942.pocketRoom(ply)
    if not IsValid(ply) or not ply:HasWeapon("pocket") then return 0 end
    local job = RPExtraTeams[ply:Team()]
    local max = (job and job.maxpocket) or GAMEMODE.Config.pocketitems or 10
    return math.max(0, max - table.Count(ply.darkRPPocket or {}))
end

function RP1942.makeSpawnedWeapon(class, pos, clip, model)
    local stored = weapons.GetStored(class)
    local ent = ents.Create("spawned_weapon")
    if not IsValid(ent) then return nil end
    ent:SetModel(model or (stored and stored.WorldModel ~= "" and stored.WorldModel) or "models/weapons/w_pistol.mdl")
    ent:SetWeaponClass(class)
    ent:SetPos(pos)
    local clip1, ammoadd = RP1942.weaponStartAmmo(class)   -- sh_ammo.lua: a magazine, or the grenade itself
    ent.clip1 = clip or clip1
    ent.ammoadd = ammoadd
    ent.nodupe = true
    ent:Spawn()
    return ent
end

-- spawned_weapon happily takes a class that doesn't exist and only fails when
-- someone picks it up, so shops ask first
function RP1942.weaponExists(class)
    local probe = ents.Create(class)
    if not IsValid(probe) then return false end
    probe:Remove()
    return true
end

function RP1942.spawnInFront(ply, dist)
    local eye = ply:EyePos()
    local tr = util.TraceLine({ start = eye, endpos = eye + ply:GetAimVector() * (dist or 85), filter = ply })
    return tr.HitPos + tr.HitNormal * 12
end

function RP1942.pocketOrLeave(ply, ent)
    if not IsValid(ent) or RP1942.pocketRoom(ply) <= 0 then return false end
    ply:addPocketItem(ent)
    return true
end
