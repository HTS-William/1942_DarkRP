--[[---------------------------------------------------------------------------
1942 DarkRP - Reich treasury (shared)

One pot. Every income tax is deposited into it automatically. The balance is
kept across restarts (sv_treasury.lua).

    RP1942.getTreasury()     -> current balance (works on server and client)
    RP1942.treasuryFrozen()  -> true while the Reichsbank vault is being robbed:
                                nothing can be spent from the treasury until
                                it's over (only the robbers' haul and staff)

Server only (sv_treasury.lua):
    RP1942.treasuryDeposit(amount, source)    -> new balance
    RP1942.treasuryWithdraw(amount, reason)   -> true / false (false = not enough funds)
    hook "RP1942_TreasuryChanged" (old, new, reason)

Currently shown only in the Führer's menu. Anything later that should be paid
for from the treasury (the APC, bonuses, the German Supplier...) calls
treasuryWithdraw; anything that pays into it calls treasuryDeposit.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Treasury = { KEY = "rp1942_treasury", START = 0 }   -- START: the very first balance, before anything is saved

function RP1942.getTreasury()
    return GetGlobal2Int(RP1942.Treasury.KEY, RP1942.Treasury.START)
end

-- While the vault is being robbed, the Reich can't spend from the treasury
-- (no draining it before the robbers get their share)
RP1942.TreasuryFrozenText = "The Reichsbank is being robbed: the treasury is frozen until the robbery is over."
function RP1942.treasuryFrozen()
    return RP1942.bankState ~= nil and RP1942.bankState().active == true
end
