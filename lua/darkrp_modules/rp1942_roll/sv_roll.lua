--[[---------------------------------------------------------------------------
1942 DarkRP - /roll (server). Settings: RP1942.RollConfig in sh_roll.lua.
---------------------------------------------------------------------------]]
local CFG = RP1942.RollConfig
local USAGE = "Usage: /roll, /roll 20, /roll 5 50 or /roll 2d6"

-- What to roll, from what was typed. Returns a spec, or nil and a message.
function RP1942.parseRoll(args)
    args = string.lower(string.Trim(args or ""))
    if args == "" then return { min = 1, max = CFG.defaultMax } end

    -- dice: 2d6, d20
    local count, sides = string.match(args, "^(%d*)d(%d+)$")
    if sides then
        count, sides = tonumber(count) or 1, tonumber(sides)
        if count < 1 or count > CFG.maxDice then return nil, "You can roll 1 to " .. CFG.maxDice .. " dice at once." end
        if sides < 2 or sides > CFG.maxValue then return nil, "Dice need between 2 and " .. CFG.maxValue .. " sides." end
        return { dice = count, sides = sides }
    end

    -- a range: "5 50" or "5-50"
    local a, b = string.match(args, "^(%d+)%s+(%d+)$")
    if not a then a, b = string.match(args, "^(%d+)%s*%-%s*(%d+)$") end
    if a then
        a, b = tonumber(a), tonumber(b)
        if a > b then a, b = b, a end
        if b > CFG.maxValue then return nil, "The highest you can roll up to is " .. CFG.maxValue .. "." end
        return { min = a, max = b }
    end

    -- a maximum: "20"
    local m = tonumber(string.match(args, "^(%d+)$"))
    if m then
        if m < 1 or m > CFG.maxValue then return nil, "Roll up to a number from 1 to " .. CFG.maxValue .. "." end
        return { min = 1, max = m }
    end

    return nil, USAGE
end

-- Rolls it. Returns the text that follows "Name rolls ".
function RP1942.doRoll(spec)
    if spec.dice then
        local rolls, total = {}, 0
        for i = 1, spec.dice do
            rolls[i] = math.random(1, spec.sides)
            total = total + rolls[i]
        end
        if spec.dice == 1 then return string.format("d%d: %d", spec.sides, total) end
        return string.format("%dd%d: %s = %d", spec.dice, spec.sides, table.concat(rolls, " + "), total)
    end
    return string.format("%d  (%d-%d)", math.random(spec.min, spec.max), spec.min, spec.max)
end

DarkRP.defineChatCommand("roll", function(ply, args)
    local spec, err = RP1942.parseRoll(args)
    if not spec then
        DarkRP.notify(ply, 1, 4, err)
        return ""
    end

    local text = ply:Nick() .. " rolls " .. RP1942.doRoll(spec)
    local everyone = CFG.range == "global" or GAMEMODE.Config.alltalk
    local dist = CFG.distance or GAMEMODE.Config.meDistance or 250
    local origin = ply:EyePos()

    for _, target in ipairs(player.GetHumans()) do
        if everyone or target == ply or target:EyePos():DistToSqr(origin) <= dist * dist then
            DarkRP.talkToPerson(target, CFG.color, text, nil, nil, ply)
        end
    end
    ServerLog("[1942] Roll: " .. text .. "\n")
    return ""
end, CFG.cooldown)
