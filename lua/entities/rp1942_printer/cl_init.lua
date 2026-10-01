include("shared.lua")

--[[---------------------------------------------------------------------------
The printer's panel: flat, in the F4 menu's colours. Floats above the
printer (or mount it with the rp1942_panel_* commands like the machines).
Main view: tray, next print, temperature, COLLECT / UPGRADES / POWER
(and SEIZE for the Reich on an illegal printer). Upgrades view: 4 rows.
---------------------------------------------------------------------------]]
ENT.PanelSize  = { w = 520, h = 640 }
ENT.PanelScale = 0.04
ENT.PanelLift  = 8
ENT.PanelNoBackground = true

surface.CreateFont("RP1942_PrinterBig", { font = "Roboto", size = 58, weight = 800, extended = true })

local function colors()   -- the shared palette (rp1942_core/cl_theme.lua)
    local C = RP1942.col
    return {
        panel = C("panel"), card = C("card"), gold = C("gold"), text = C("text"), sub = C("sub"), well = C("well"),
        green = C("good"), greenD = C("categoryAlt"), red = C("bad"), redD = C("tabActive"), amber = C("warn"),
        button = C("button"), neutral = C("neutral"),
    }
end

local function tag(text, x, y, col, C)
    surface.SetFont("RP1942_PanelSmall")
    local tw, th = surface.GetTextSize(text)
    draw.RoundedBox(4, x - tw - 20, y, tw + 20, th + 8, col)
    draw.SimpleText(text, "RP1942_PanelSmall", x - 10, y + (th + 8) / 2, C.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

local function bar(P, x, y, w, frac, col, label, right, C)
    draw.SimpleText(label, "RP1942_PanelSmall", x, y - 24, C.sub)
    if right then draw.SimpleText(right, "RP1942_PanelSmall", x + w, y - 24, C.text, TEXT_ALIGN_RIGHT) end
    draw.RoundedBox(4, x, y, w, 16, C.well)
    if frac > 0 then draw.RoundedBox(4, x, y, math.max(8, math.floor(w * math.Clamp(frac, 0, 1))), 16, col) end
end

-- Views are per player: switching to Upgrades only changes what you see
function ENT:OnLocalPress(id)
    if id == "upgrades" then self.view = "upgrades" elseif id == "back" then self.view = nil end
end

function ENT:PanelFast()
    return not self:GetOff() and self:Heat() >= self:Config().heat.warn
end

function ENT:PaintMain(P, w, h, C)
    local c = self:Config()
    local lp = LocalPlayer()
    local x, iw = 30, w - 60
    local accent = self:IsBank() and C.green or C.red
    local off = self:GetOff()
    local heat = self:Heat()

    -- Header
    draw.SimpleText(self.PrintName, "RP1942_PanelTitle", x, 22, C.text)
    tag(self:IsBank() and "LEGAL" or "ILLEGAL", w - 24, 26, self:IsBank() and C.greenD or C.redD, C)
    local owner = self:Getowning_ent()
    draw.SimpleText("Owner: " .. (IsValid(owner) and owner:Nick() or "nobody"), "RP1942_PanelSmall", x, 66, C.sub)
    surface.SetDrawColor(60, 56, 50)
    surface.DrawRect(x, 96, iw, 1)

    -- Tray
    draw.SimpleText("IN THE TRAY", "RP1942_PanelSmall", x, 110, C.sub)
    draw.SimpleText(DarkRP.formatMoney(self:GetStored()), "RP1942_PrinterBig", x, 130, C.gold)

    -- Next print and heat
    local interval = self:PrintInterval()
    local left = math.max(self:GetNextPrint() - self:Now(), 0)
    bar(P, x, 234, iw, 1 - left / interval, off and C.neutral or accent, off and "NEXT PRINT (OFF)" or "NEXT PRINT", RP1942.clock(left), C)
    local hotCol = heat >= c.heat.warn and C.red or (heat >= 50 and C.amber or C.green)
    bar(P, x, 294, iw, heat / 100, hotCol, off and "TEMPERATURE (COOLING DOWN)" or "TEMPERATURE", math.floor(heat) .. "°", C)

    -- Warning / status
    local y = 326
    local blowIn = self:TimeToBlow()
    if not off and heat >= c.heat.warn and blowIn then
        local flash = math.floor(RealTime() * 3) % 2 == 0
        draw.RoundedBox(5, x, y, iw, 38, flash and C.redD or Color(80, 20, 18))
        draw.SimpleText("OVERHEATING  ·  EXPLODES IN " .. RP1942.clock(blowIn) .. "  ·  SWITCH IT OFF", "RP1942_PanelSmall", w / 2, y + 19, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 50
    elseif self:HeatRise() <= 0 then
        draw.SimpleText("Cooling maxed: it stays cool while it runs.", "RP1942_PanelSmall", x, y + 8, C.green)
        y = y + 40
    else
        y = y + 12
    end

    -- Details
    local function line(label, value, col)
        draw.SimpleText(label, "RP1942_PanelBody", x, y, C.sub)
        draw.SimpleText(value, "RP1942_PanelBody", x + iw, y, col or C.text, TEXT_ALIGN_RIGHT)
        y = y + 30
    end
    local amount = self:PrintAmount()
    if self:IsBank() then
        local share = RP1942.printerTreasuryShare()
        local econ = RP1942.getEconomy and RP1942.getEconomy() or 50
        line("Economy", tostring(econ))
        line("Treasury share", math.floor(share * 100 + 0.5) .. "%")
        line("You keep", DarkRP.formatMoney(amount - math.floor(amount * share)) .. " a print", C.green)
    else
        line("Per print", DarkRP.formatMoney(amount))
        line("Fine if the Reich seizes it", DarkRP.formatMoney(c.seizeFine or 0))
    end
    line("Prints every", interval .. " s")

    -- Buttons
    local bw = math.floor((iw - 12) / 2)
    P:Button("collect", x, h - 128, bw, 52, self:GetStored() > 0 and "COLLECT" or "EMPTY", { enabled = self:GetStored() > 0, color = self:IsBank() and C.greenD or C.button })
    P:Button("local:upgrades", x + bw + 12, h - 128, bw, 52, "UPGRADES", { color = C.neutral })
    local reich = RP1942.isFaction and RP1942.isFaction(lp, "reich")
    if not self:IsBank() and reich and owner ~= lp then
        P:Button("power", x, h - 66, bw, 48, off and "SWITCH ON" or "SWITCH OFF", { color = C.neutral })
        P:Button("seize", x + bw + 12, h - 66, bw, 48, "SEIZE", { color = C.redD })
    else
        P:Button("power", x, h - 66, iw, 48, off and "SWITCHED OFF  ·  SWITCH ON" or "RUNNING  ·  SWITCH OFF TO COOL", { color = off and C.neutral or C.greenD })
    end
end

function ENT:PaintUpgrades(P, w, h, C)
    local c = self:Config()
    local x, iw = 30, w - 60
    draw.SimpleText("Upgrades", "RP1942_PanelTitle", x, 22, C.text)
    local mine = self:Getowning_ent() == LocalPlayer()
    draw.SimpleText(mine and "Each tier costs more. They stay with the printer." or "Only the owner can buy upgrades.", "RP1942_PanelSmall", x, 66, C.sub)

    local y = 100
    for _, id in ipairs(c.order) do
        local def = c.upgrades[id]
        local tier = self:Tier(id)
        draw.RoundedBox(6, x, y, iw, 104, C.card)
        draw.SimpleText(def.name, "RP1942_PanelHead", x + 16, y + 12, C.text)
        local desc = def.desc
        if id == "output" then   -- the rate differs by printer, so it's filled in here
            desc = "+" .. math.floor(self:OutputPer() * 100 + 0.5) .. "% money per print, per tier"
        end
        draw.SimpleText(desc, "RP1942_PanelSmall", x + 16, y + 42, C.sub)
        for i = 1, c.tiers do
            draw.RoundedBox(2, x + 16 + (i - 1) * 30, y + 76, 24, 12, i <= tier and (tier >= c.tiers and C.green or C.gold) or C.well)
        end
        local maxed = tier >= c.tiers
        local label = maxed and "MAXED" or ("BUY  " .. DarkRP.formatMoney(def.cost[tier + 1] or 0))
        P:Button("buy:" .. id, x + iw - 196, y + 26, 180, 52, label, { enabled = mine and not maxed, color = C.button })
        y = y + 114
    end
    P:Button("local:back", x, h - 70, iw, 50, "BACK", { color = C.neutral })
end

function ENT:PaintPanel(P, w, h)
    local C = colors()
    draw.RoundedBox(10, 0, 0, w, h, C.panel)
    surface.SetDrawColor(self:IsBank() and C.green or C.red)
    surface.DrawRect(0, 8, 8, h - 16)
    if self.view == "upgrades" then self:PaintUpgrades(P, w, h, C) else self:PaintMain(P, w, h, C) end
end

-- Smoke when it's overheating
function ENT:Think()
    if self:GetOff() or self:Heat() < self:Config().heat.warn then return end
    if (self.nextSmoke or 0) > CurTime() then return end
    self.nextSmoke = CurTime() + 0.25
    local em = ParticleEmitter(self:GetPos())
    if not em then return end
    local top = self:LocalToWorld(Vector(self:OBBCenter().x, self:OBBCenter().y, self:OBBMaxs().z))
    local p = em:Add("particle/smokesprites_000" .. math.random(1, 9), top)
    if p then
        p:SetVelocity(Vector(math.Rand(-8, 8), math.Rand(-8, 8), math.Rand(30, 50)))
        p:SetDieTime(2.5)
        p:SetStartAlpha(120)
        p:SetEndAlpha(0)
        p:SetStartSize(6)
        p:SetEndSize(26)
        p:SetColor(70, 70, 70)
        p:SetRoll(math.Rand(0, 360))
    end
    em:Finish()
end

function ENT:Draw()
    self:DrawModel()
    if RP1942.drawPanel then RP1942.drawPanel(self) end
end
