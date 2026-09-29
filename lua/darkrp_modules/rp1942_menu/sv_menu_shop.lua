--[[---------------------------------------------------------------------------
Server handler for RP1942_ShopMenu's Buy button.
The purchase itself (checks, wallet, spawning) is in rp1942_shop/sv_shop.lua.
---------------------------------------------------------------------------]]
-- arg: "<item id>" or "<item id>:<amount>"
RP1942.addMenuHandler("RP1942_ShopMenu", "buy", function(ply, arg)
    if not RP1942.buyShopItem then
        DarkRP.notify(ply, 1, 4, "The shop module is not loaded.")
        return
    end
    local itemId, amount = string.match(arg or "", "^([%w_]+):?(%d*)$")
    if not itemId then return end
    RP1942.buyShopItem(ply, itemId, tonumber(amount) or 1)
end)
