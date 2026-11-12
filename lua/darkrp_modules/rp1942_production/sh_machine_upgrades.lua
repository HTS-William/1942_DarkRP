--[[---------------------------------------------------------------------------
42Bros - machine upgrades and battery power

UPGRADES (the oven, the factory line, the oil rig)
    Bought by the machine's owner from its panel: UPGRADES (top right), then
    BUY on a row. 3 tiers each. They belong to that machine: gone when it's
    removed, its owner changes job or leaves. (The wine barrel is used up
    each batch, so it has none.)

        Speed       a batch takes less time            (x0.85 / x0.72 / x0.60)
        Output      more per batch: +1 loaf / +1 item per tier; the oil rig
                    a 1-in-3 chance of an extra barrel per tier (tier 3: always)
        Steadier    an easier batch: the oven's fire cools slower with a wider
                    green; the factory has fewer faults and the wrong repair
                    costs less; the rig's pressure wanders less, with a wider
                    green and more time in the red before the alarm and blowout
        Fuel        (factory, rig) a battery lasts longer (x1.25 / x1.55 / x2)

BATTERY POWER (the factory line and the oil rig)
    They run on batteries (F4 shop, Production): push one into the
    machine to charge it. A full charge lasts `powerMinutes` of running (only
    while it's actually working). It holds up to two batteries' worth; a
    battery bounces off while it's more than half full. With no charge left
    the machine switches itself off, its run paused, until a battery goes in.

Settings: `MachineUpgrades` below; powerMinutes in RP1942.Production.factory
and .oil (sh_production.lua). The tiers are NW2Ints "RP1942_Up_<id>" on the
machine; ENT:Config() returns the machine's settings with them applied.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.MachineUpgrades = {
    tiers = 3,
    defs = {
        speed  = { name = "Speed",    mult = { 0.85, 0.72, 0.60 } },
        output = { name = "Output" },
        steady = { name = "Steadier" },
        fuel   = { name = "Fuel efficiency", mult = { 1.25, 1.55, 2.0 } },   -- how much longer a battery lasts
    },
    -- Which upgrades each machine has, and the price of tiers 1, 2, 3
    machines = {
        oven    = { order = { "speed", "output", "steady" },         cost = { 300, 600, 1200 } },
        factory = { order = { "speed", "output", "steady", "fuel" }, cost = { 500, 1000, 2000 } },
        oil     = { order = { "speed", "output", "steady", "fuel" }, cost = { 800, 1600, 3200 } },
    },
    -- What a row says (filled in for the machine)
    desc = {
        oven    = { speed = "Bakes faster", output = "+1 loaf per bake, per tier", steady = "The fire cools slower; a wider green" },
        factory = { speed = "Runs faster", output = "+1 item per run, per tier", steady = "Fewer faults; wrong repairs cost less", fuel = "A battery lasts longer" },
        oil     = { speed = "Fills the tank faster", output = "1 in 3 chance per tier of an extra barrel", steady = "Steadier pressure; a wider green; longer to the alarm", fuel = "A battery lasts longer" },
    },
}
local U = RP1942.MachineUpgrades

RP1942.Battery = {
    model  = "models/items/car_battery01.mdl",
    charge = 100,     -- what one battery adds (%)
    max    = 200,     -- what a machine holds (%)
}

function RP1942.machineTier(ent, id)
    return IsValid(ent) and ent:GetNW2Int("RP1942_Up_" .. id, 0) or 0
end

-- The machine's settings with its upgrades applied (cached until they change)
function RP1942.upgradedConfig(ent, kind)
    local base = RP1942.Production[kind]
    local s, o, st, f = RP1942.machineTier(ent, "speed"), RP1942.machineTier(ent, "output"), RP1942.machineTier(ent, "steady"), RP1942.machineTier(ent, "fuel")
    local key = s .. o .. st .. f
    if ent.RP1942_CfgKey == key and ent.RP1942_Cfg then return ent.RP1942_Cfg end
    if key == "0000" then
        ent.RP1942_CfgKey, ent.RP1942_Cfg = key, base
        return base
    end
    local c = table.Copy(base)
    local speed = s > 0 and U.defs.speed.mult[s] or 1
    c.outputTier = o
    if kind == "oven" then
        c.bakeTime = math.floor(base.bakeTime * speed)
        c.heat.cool = base.heat.cool * (1 - 0.15 * st)
        c.heat.cold = base.heat.cold - 4 * st
        c.heat.hot  = base.heat.hot + 4 * st
    elseif kind == "factory" then
        c.runTime = math.floor(base.runTime * speed)
        c.items = base.items + o
        -- faults per run: 1-3 -> 1-2 -> 0-2 -> 0-1 (never none for sure)
        if st > 0 then
            local lo = math.max(0, base.halts[1] - math.floor(st / 2))
            local hi = math.max(lo + 1, base.halts[2] - ({ 1, 1, 2 })[st])
            c.halts = { lo, hi }
        end
        c.wrongFix = base.wrongFix * (1 - 0.25 * st)
    elseif kind == "oil" then
        c.pumpTime = math.floor(base.pumpTime * speed)
        c.pressure.vary = (base.pressure.vary or 0) * (1 - 0.25 * st)
        c.pressure.low  = base.pressure.low - 4 * st
        c.pressure.high = base.pressure.high + 4 * st
        c.blowout.warnAfter = base.blowout.warnAfter + 5 * st
        c.blowout.explodeAfter = base.blowout.explodeAfter + 10 * st
    end
    if base.powerMinutes then
        c.powerMinutes = base.powerMinutes * (f > 0 and U.defs.fuel.mult[f] or 1)
    end
    ent.RP1942_CfgKey, ent.RP1942_Cfg = key, c
    return c
end

-- Battery charge used per second of running, in %
function RP1942.powerDrain(ent)
    local c = ent:Config()
    return 100 / (math.max(c.powerMinutes or 8, 0.1) * 60)
end

if SERVER then
    -- BUY on the upgrades view (the panel press handler already checked it's
    -- the owner's, close and in sight)
    function RP1942.buyMachineUpgrade(ent, ply, kind, id)
        local m = U.machines[kind]
        local def = U.defs[id]
        if not (m and def and table.HasValue(m.order, id)) then return end
        local tier = RP1942.machineTier(ent, id)
        if tier >= U.tiers then return end
        local cost = m.cost[tier + 1] or 0
        if not ply:canAfford(cost) then
            return DarkRP.notify(ply, 1, 4, "You can't afford that (" .. DarkRP.formatMoney(cost) .. ").")
        end
        ply:addMoney(-cost)
        ent:SetNW2Int("RP1942_Up_" .. id, tier + 1)
        DarkRP.notify(ply, 0, 4, def.name .. " upgraded to tier " .. (tier + 1) .. ".")
        ent:EmitSound("buttons/lever7.wav", 60)
        if RP1942.log then
            RP1942.log("MONEY", "%s bought %s tier %d for their %s (%s)", ply:Nick(), def.name, tier + 1, ent.PrintName or kind, DarkRP.formatMoney(cost))
        end
        return true
    end

    -- A battery pushed into a powered machine. Returns true if it went in.
    function RP1942.chargeMachine(ent, battery)
        local B = RP1942.Battery
        if ent:GetCharge() > B.max - B.charge then return false end   -- (more than half full: it bounces off)
        battery.RP1942_Used = true
        battery:Remove()
        ent:SetCharge(math.min(ent:GetCharge() + B.charge, B.max))
        ent:EmitSound("items/battery_pickup.wav", 65)
        ent.RP1942_EverCharged = true
        if ent.RP1942_NoPower then
            ent.RP1942_NoPower = nil
            ent:SetPower(true)
        end
        return true
    end

    -- Run down the charge while it's working; at 0 it switches itself off
    function RP1942.drainMachine(ent, working)
        local now = CurTime()
        local dt = now - (ent.RP1942_LastDrain or now)
        ent.RP1942_LastDrain = now
        if not working or ent:GetOff() then return end
        local charge = ent:GetCharge() - RP1942.powerDrain(ent) * dt
        if charge > 0 then
            ent:SetCharge(charge)
            return
        end
        ent:SetCharge(0)
        ent.RP1942_NoPower = true
        ent:SetPower(false)
        ent:EmitSound("ambient/machines/spindown.wav", 70)
        local owner = ent.Getowning_ent and ent:Getowning_ent()
        if IsValid(owner) then
            DarkRP.notify(owner, 1, 7, ent.RP1942_EverCharged
                and ("Your " .. (ent.PrintName or "machine") .. " ran out of power. Push a battery into it.")
                or ("Your " .. (ent.PrintName or "machine") .. " needs power: push a battery into it (F4 shop, Production)."))
        end
    end
end

if CLIENT then
    --[[-----------------------------------------------------------------------
    The UPGRADES view on a machine's panel (in the panels' own style)
    -------------------------------------------------------------------------]]
    function RP1942.paintMachineUpgrades(ent, P, w, h, kind, accent)
        local C = RP1942.PanelColors
        local m = U.machines[kind]
        local x, iw = 28, w - 56
        P:Title("UPGRADES", accent)
        local mine = not IsValid(ent:Getowning_ent()) or ent:Getowning_ent() == LocalPlayer()
        P:Text(mine and "3 tiers each. They stay with this machine." or "Only the owner can buy upgrades.", "RP1942_PanelSmall", x, 70, C.dim)
        local y = 100
        local rowH = math.floor((h - 100 - 82) / #m.order) - 8
        for _, id in ipairs(m.order) do
            local tier = RP1942.machineTier(ent, id)
            draw.RoundedBox(4, x, y, iw, rowH, C.well)
            P:Text(U.defs[id].name, "RP1942_PanelHead", x + 14, y + 10, C.text)
            local desc = U.desc[kind][id] or ""
            P:Text(RP1942.fitText and RP1942.fitText(desc, "RP1942_PanelSmall", iw - 220) or desc, "RP1942_PanelSmall", x + 14, y + 38, C.dim)
            for i = 1, U.tiers do
                draw.RoundedBox(2, x + 14 + (i - 1) * 30, y + rowH - 22, 24, 10, i <= tier and (tier >= U.tiers and Color(110, 190, 110) or C.gold) or C.bg)
            end
            local maxed = tier >= U.tiers
            P:Button("buy:" .. id, x + iw - 186, y + (rowH - 48) / 2, 172, 48, maxed and "MAXED" or ("BUY  " .. DarkRP.formatMoney(m.cost[tier + 1] or 0)),
                { enabled = mine and not maxed, color = accent, font = "RP1942_PanelButtonSmall" })
            y = y + rowH + 8
        end
        P:Button("local:back", x, h - 74, iw, 52, "BACK", { color = C.button })
    end

    -- The UPGRADES button, top right of a machine's main view
    function RP1942.machineUpgradesButton(P, w)
        P:Button("local:upgrades", w - 28 - 150, 10, 150, 38, "UPGRADES", { color = RP1942.PanelColors.button, font = "RP1942_PanelButtonSmall" })
    end

    -- "Battery 64%" (red when low), right-aligned at (x, y): the panels put it
    -- beside their progress bar
    function RP1942.paintBattery(ent, P, x, y)
        local charge = ent:GetCharge()
        local col = charge <= 0 and Color(230, 110, 96) or (charge < 20 and Color(230, 180, 90) or Color(140, 220, 140))
        P:Text("Battery " .. math.floor(charge + 0.5) .. "%", "RP1942_PanelBody", x, y, col, TEXT_ALIGN_RIGHT)
    end
end
