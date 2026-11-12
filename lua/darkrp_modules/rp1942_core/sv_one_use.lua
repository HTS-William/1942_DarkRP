--[[---------------------------------------------------------------------------
42Bros - throwables and placeables are used once (server)

Grenades, smoke grenades, molotovs, dynamite, charges and mines (weapons
based on RP1942.WeaponStartAmmo.bases, sh_ammo.lua) come with one of their
ammo each: buy one, throw or place it, and it's gone. Refills aren't sold
(the F4 Shop's ammo list leaves them out), so a new one is bought from a
dealer.

Buying several of the same one still works: each adds one to what you're
carrying, so two grenades bought = two throws.

Here: once one runs out (no ammo left for it), the empty weapon is taken
away after a short moment, so nobody is left holding a grenade they can't
throw. The moment lets the throw / placing finish first.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local GRACE = 2       -- seconds empty before it's taken away
local oneUse = {}     -- [class] = true / false (cached)

local function isOneUse(class)
    if oneUse[class] == nil then
        local found = false
        for base in pairs(RP1942.WeaponStartAmmo and RP1942.WeaponStartAmmo.bases or {}) do
            if class == base or weapons.IsBasedOn(class, base) then found = true break end
        end
        oneUse[class] = found
    end
    return oneUse[class]
end
RP1942.isOneUseWeapon = isOneUse

timer.Create("RP1942_OneUse", 0.5, 0, function()
    local now = CurTime()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            for _, wep in ipairs(ply:GetWeapons()) do
                local class = IsValid(wep) and wep:GetClass()
                if class and isOneUse(class) then
                    local ammo = wep:GetPrimaryAmmoType()
                    local empty = ammo and ammo >= 0 and ply:GetAmmoCount(ammo) <= 0 and wep:Clip1() <= 0
                    if not empty then
                        wep.RP1942_EmptySince = nil
                    elseif not wep.RP1942_EmptySince then
                        wep.RP1942_EmptySince = now
                    elseif now - wep.RP1942_EmptySince >= GRACE then
                        ply:StripWeapon(class)
                    end
                end
            end
        end
    end
end)
