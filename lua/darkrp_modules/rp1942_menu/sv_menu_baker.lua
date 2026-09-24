--[[---------------------------------------------------------------------------
EXAMPLE: server handlers for RP1942_BakerMenu.
Only reachable by a player whose CURRENT job has menu = "RP1942_BakerMenu".
Anything else a handler needs (cooldowns, money, range) it checks itself.
---------------------------------------------------------------------------]]
local COOLDOWN = 120

RP1942.addMenuHandler("RP1942_BakerMenu", "announce_bread", function(ply)
    local now = CurTime()
    if (ply.RP1942_NextBreadAd or 0) > now then
        DarkRP.notify(ply, 1, 4, string.format("You can announce again in %d seconds.", math.ceil(ply.RP1942_NextBreadAd - now)))
        return
    end
    ply.RP1942_NextBreadAd = now + COOLDOWN

    DarkRP.notifyAll(0, 6, ply:Nick() .. "'s bakery has fresh bread.")
end)
