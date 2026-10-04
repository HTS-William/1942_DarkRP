--[[---------------------------------------------------------------------------
1942 DarkRP - things that can't go in a pocket (server)

The machines and fixtures are far too big for a coat pocket. Trying to pocket
one just shows the reason below. Add or remove classes in the list.

Still pocketable on purpose: goods, flour, scrap metal, the radio, ammo boxes
and weapon crates (the things meant to be carried around).
(Printers and oil rigs also block pocketing in their own files.)
---------------------------------------------------------------------------]]
local NO_POCKET = {
    rp1942_oven          = "The oven is far too heavy to pocket.",
    rp1942_wine_barrel   = "The wine barrel is far too heavy to pocket.",
    rp1942_factory       = "The factory line is far too heavy to pocket.",
    rp1942_oil_rig       = "It's bolted down.",
    rp1942_market        = "The market is far too heavy to pocket.",
    rp1942_printer       = "Printers are too heavy to pocket.",
    rp1942_printer_bank  = "Printers are too heavy to pocket.",
    rp1942_printer_illegal = "Printers are too heavy to pocket.",
    rp1942_bank_vault    = "The vault is far too heavy to pocket.",
    rp1942_dumpster      = "The dumpster is far too heavy to pocket.",
    rp1942_supply_train  = "You can't pocket the supply train.",
}

hook.Add("canPocket", "RP1942_NoPocket", function(_, ent)
    if not IsValid(ent) then return end
    local why = NO_POCKET[ent:GetClass()]
    if why then return false, why end
end)
