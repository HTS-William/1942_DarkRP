--[[---------------------------------------------------------------------------
1942 DarkRP - magazines hold a magazine (server)

A weapon pack SWEP is created with its whole DefaultClip (a magazine plus
the starting reserve, e.g. 40 rounds for a K98k with a 5-round magazine)
sitting in Clip1, and counts on the pickup path to move the rest into the
player's reserve. Job loadouts (ply:Give) skip that path, so players spawned
with 40 rounds in a 5-round rifle.

Whenever a player gets a weapon, a tick later (after DarkRP's own shop /
pocket code has set the magazine it wants), anything over the magazine's
capacity is moved into the reserve.
---------------------------------------------------------------------------]]
hook.Add("WeaponEquip", "RP1942_ClipFix", function(wep, ply)
    timer.Simple(0, function()
        if not IsValid(wep) or not IsValid(ply) or wep:GetOwner() ~= ply then return end
        local p = wep.Primary
        if not p then return end
        local cap = tonumber(p.ClipSize) or -1
        if wep.GetClip1Capacity then cap = wep:GetClip1Capacity() or cap end   -- akimbo pairs hold two
        if cap <= 0 then return end
        local clip = wep:Clip1()
        if clip <= cap then return end
        wep:SetClip1(cap)
        local ammo = wep:GetPrimaryAmmoType()
        if ammo and ammo >= 0 then ply:GiveAmmo(clip - cap, ammo, true) end
    end)
end)
