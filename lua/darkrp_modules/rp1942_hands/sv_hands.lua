--[[---------------------------------------------------------------------------
1942 DarkRP - Hands (server): spawn holding them, and the push gesture
---------------------------------------------------------------------------]]
util.AddNetworkString("RP1942_HandsPush")

-- Everyone nearby sees the shove (cl_hands.lua plays it)
function RP1942.handsGesture(ply)
    net.Start("RP1942_HandsPush")
    net.WriteEntity(ply)
    net.SendPVS(ply:GetPos())
end

-- After DarkRP's loadout, switch to the hands
hook.Add("PlayerSpawn", "RP1942_Hands", function(ply)
    if not RP1942.HandsConfig.selectOnSpawn then return end
    timer.Simple(0, function()
        if IsValid(ply) and ply:Alive() and ply:HasWeapon("rp1942_hands") then ply:SelectWeapon("rp1942_hands") end
    end)
end)
