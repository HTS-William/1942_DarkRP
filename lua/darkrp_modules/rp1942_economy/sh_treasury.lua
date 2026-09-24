--[[---------------------------------------------------------------------------
1942 DarkRP - Reich treasury (shared)

One pot. Every income tax is deposited into it automatically.

    RP1942.getTreasury()     -> current balance (works on server and client)

Server only (sv_treasury.lua):
    RP1942.treasuryDeposit(amount, source)    -> new balance
    RP1942.treasuryWithdraw(amount, reason)   -> true / false (false = not enough funds)
    hook "RP1942_TreasuryChanged" (old, new, reason)

Currently shown only in the Führer's menu. Anything later that should be paid
for from the treasury (the APC, bonuses, the German Supplier...) calls
treasuryWithdraw; anything that pays into it calls treasuryDeposit.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Treasury = { KEY = "rp1942_treasury", START = 0 }

function RP1942.getTreasury()
    return GetGlobal2Int(RP1942.Treasury.KEY, RP1942.Treasury.START)
end
