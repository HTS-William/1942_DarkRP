--[[---------------------------------------------------------------------------
1942 DarkRP - F2 on doors (client)

    F2 on a door you can buy     buys it, straight away (no menu)
    F2 on a door you own         DarkRP's door menu (sell, co-owners, title)
    F2 on anything else          DarkRP's door menu, as before
    Shift + F2                   always the menu (staff: door settings on
                                 doors nobody owns yet)

The server does the buying exactly as the menu's Buy button would (darkrp
toggleown): the price, "you can't afford it" and the door limit all still
apply there.
---------------------------------------------------------------------------]]
local REACH = 200                -- units, the same as DarkRP's door menu
local lastBuy = { ent = nil, at = 0 }

-- DarkRP's own rule for when its menu shows "Buy door"
local function canBuy(ent, lp)
    if ent:isKeysOwnedBy(lp) then return false end
    local plain = not ent:isKeysOwned() and not ent:getKeysNonOwnable()
        and not ent:getKeysDoorGroup() and not ent:getKeysDoorTeams()
    return plain or ent:isKeysAllowedToOwn(lp)
end

hook.Add("ShowTeam", "RP1942_F2BuyDoor", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or lp:KeyDown(IN_SPEED) then return end   -- Shift: the full menu
    local tr = lp:GetEyeTrace()
    local ent = tr.Entity
    if not IsValid(ent) or not ent.isKeysOwnable or not ent:isKeysOwnable() then return end
    if tr.HitPos:DistToSqr(lp:EyePos()) > REACH * REACH then return end

    -- Just bought it and the server hasn't said so yet: "toggleown" again
    -- would sell it straight back, so wait
    if lastBuy.ent == ent and RealTime() - lastBuy.at < 2 and not ent:isKeysOwnedBy(lp) then return true end

    if not canBuy(ent, lp) then return end   -- owned / not for sale: DarkRP's menu
    lastBuy.ent, lastBuy.at = ent, RealTime()
    RunConsoleCommand("darkrp", "toggleown")
    return true   -- handled: no menu
end)
