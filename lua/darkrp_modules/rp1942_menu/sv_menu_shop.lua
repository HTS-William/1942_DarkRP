--[[---------------------------------------------------------------------------
Server handler for RP1942_ShopMenu's Buy button.
The purchase itself (checks, wallet, spawning) is in rp1942_shop/sv_shop.lua.
---------------------------------------------------------------------------]]
RP1942.addMenuHandler("RP1942_ShopMenu", "buy", function(ply, itemId)
    if not RP1942.buyShopItem then
        DarkRP.notify(ply, 1, 4, "The shop module is not loaded.")
        return
    end
    RP1942.buyShopItem(ply, itemId)
end)
