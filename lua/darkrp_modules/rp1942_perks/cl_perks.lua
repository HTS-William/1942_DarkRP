--[[---------------------------------------------------------------------------
1942 DarkRP - the Führer's perks (client): the "Perks" section of his menu
(rp1942_menu/cl_menu_fuhrer.lua calls RP1942.addPerkSection). Settings: sh_perks.lua
---------------------------------------------------------------------------]]
local function status(p)
    local cd = RP1942.perkCooldown(p.id)
    if p.id == "apc" then
        local car = GetGlobal2Entity("RP1942_APC")
        if IsValid(car) then
            return string.format("Out now  ·  %d / %d health", car:GetNW2Int("RP1942_APCHealth", 0), car:GetNW2Int("RP1942_APCMax", 0))
        end
    elseif p.id == "paybonus" and RP1942.payBonusLeft() > 0 then
        return "Running  ·  " .. RP1942.perkClock(RP1942.payBonusLeft()) .. " left (buying adds time)"
    end
    if cd > 0 then return "Ready again in " .. RP1942.perkClock(cd) end
    local t = RP1942.getTreasury and RP1942.getTreasury() or 0
    return t >= p.price and "Ready" or "The treasury can't afford it"
end

function RP1942.addPerkSection(panel)
    panel:AddSection("Perks for the Reich")
    panel:AddText("Paid from the treasury. Reich soldiers are the Wehrmacht, Waffen-SS and Leibstandarte.")
    for _, p in ipairs(RP1942.Perks.list) do
        panel:AddText(p.name .. "  ·  " .. DarkRP.formatMoney(p.price) .. "\n" .. p.desc)
        local line = panel:AddText("")
        local base = line.Think
        line.Think = function(s)
            if base then base(s) end
            local text = "Status:  " .. status(p)
            if s:GetText() ~= text then s:SetText(text) end
        end
        panel:AddButton("Buy: " .. p.name .. " (" .. DarkRP.formatMoney(p.price) .. ")", function() panel:Request("perk_buy", p.id) end)
    end
end

-- The gun's state for the driver, above the bottom middle of the screen
hook.Add("HUDPaint", "RP1942_APCCannon", function()
    local lp = LocalPlayer()
    local car = IsValid(lp) and lp:InVehicle() and lp:GetVehicle()
    if not (IsValid(car) and car == GetGlobal2Entity("RP1942_APC")) then return end
    local left = car:GetNW2Float("RP1942_APCReady", 0) - CurTime()
    local total = math.max(car:GetNW2Float("RP1942_APCReload", 6), 0.1)
    local C = RP1942.col
    local w, h = math.floor(ScrH() * 0.22), math.floor(ScrH() * 0.034)
    local x, y = math.floor((ScrW() - w) / 2), math.floor(ScrH() * 0.82)
    draw.RoundedBox(6, x, y, w, h, C("bg"))
    if left > 0 then
        draw.RoundedBox(4, x + 4, y + h - 8, math.floor((w - 8) * (1 - left / total)), 4, C("gold"))
    end
    local cost = RP1942.Perks.apc.cannon and RP1942.Perks.apc.cannon.shotCost or 0
    local text = left > 0 and string.format("GUN  ·  RELOADING %.1f", left)
        or ("GUN READY  ·  LEFT CLICK" .. (cost > 0 and ("  ·  " .. DarkRP.formatMoney(cost)) or ""))
    draw.SimpleText(text, "RP1942_HudNotice", x + w / 2, y + (h - 6) / 2, left > 0 and C("sub") or C("text"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local hp, mx = car:GetNW2Int("RP1942_APCHealth", 0), math.max(car:GetNW2Int("RP1942_APCMax", 1), 1)
    draw.SimpleText(string.format("ARMOUR  %d / %d", hp, mx), "RP1942_HudNotice", x + w / 2, y - 4, hp / mx < 0.3 and C("bad") or C("sub"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end)
