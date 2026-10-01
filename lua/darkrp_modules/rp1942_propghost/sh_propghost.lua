--[[---------------------------------------------------------------------------
1942 DarkRP - prop ghosting (shared config)

While a prop is held with the physgun it turns see-through and passes through
players and other props (it still hits the world), so a held prop can't
push, trap or kill anyone. When it's let go it turns solid again as soon as
nobody is standing inside it; until then it stays ghosted and keeps checking.
Everyone gets this, staff included. It works alongside FPP (which only
ghosts spam and huge props, and un-ghosts them when picked up).

The server side is sv_propghost.lua.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.PropGhost = {
    enabled = true,
    alpha   = 140,          -- how see-through a ghosted prop is (0 = invisible, 255 = solid)
    recheck = 0.5,          -- seconds between "is anyone inside it?" checks after letting go

    -- Never ghosted: these classes, and any class starting with these prefixes.
    -- (Bolted-down things like markets and rigs can't be picked up anyway.)
    exclude = {
        player = true, rp1942_market = true, rp1942_oil_rig = true, rp1942_dumpster = true,
    },
    excludePrefix = { "npc_", "prop_vehicle", "gmod_sent_vehicle", "func_", "prop_door" },
}
