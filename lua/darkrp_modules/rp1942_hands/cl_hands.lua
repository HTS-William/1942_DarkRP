--[[---------------------------------------------------------------------------
1942 DarkRP - Hands (client): the push gesture, seen by everyone nearby
---------------------------------------------------------------------------]]
net.Receive("RP1942_HandsPush", function()
    local ply = net.ReadEntity()
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local act = ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND or ACT_GMOD_GESTURE_ITEM_PLACE
    ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, act, true)
end)
