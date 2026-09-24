--[[---------------------------------------------------------------------------
1942 DarkRP - income tax (client): receives the rate table from the server.
---------------------------------------------------------------------------]]
net.Receive("RP1942_TaxRates", function()
    RP1942.TaxRates = net.ReadTable()
    hook.Run("RP1942_TaxRatesUpdated")
end)
