--[[---------------------------------------------------------------------------
1942 DarkRP - Reichsbank robbery (client): banner, alarm, the robbery HUD,
the Reich's marker on the vault, the start / join pop-ups, the initiator's
"let them in?" pop-ups and the staff settings menu.
---------------------------------------------------------------------------]]
local B = RP1942.Bank
local S = RP1942.bankSetting

local function fmt(sec)
    sec = math.max(0, math.ceil(sec))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function colors()
    local c = RP1942.F4Config and RP1942.F4Config.colors or {}
    return {
        bg = c.bg or Color(20, 19, 17, 248), bar = c.titleBar or Color(14, 13, 12),
        card = c.card or Color(38, 35, 31), gold = c.gold or Color(201, 168, 92),
        text = c.text or Color(236, 228, 212), sub = c.sub or Color(160, 152, 136),
        red = Color(200, 60, 50), redD = Color(128, 18, 16), green = Color(90, 170, 90), well = Color(46, 43, 39),
    }
end

local function fonts()
    local h = ScrH()
    surface.CreateFont("RP1942_BankHead",  { font = "Roboto", size = math.max(14, math.floor(h * 0.016)), weight = 800, extended = true })
    surface.CreateFont("RP1942_BankTime",  { font = "Roboto", size = math.max(28, math.floor(h * 0.042)), weight = 900, extended = true })
    surface.CreateFont("RP1942_BankBody",  { font = "Roboto", size = math.max(13, math.floor(h * 0.015)), weight = 500, extended = true })
end
fonts()
hook.Add("OnScreenSizeChanged", "RP1942_BankFonts", fonts)

net.Receive("RP1942_BankSettings", function()
    local t = util.JSONToTable(net.ReadString() or "")
    if istable(t) then B.settings = t end
end)

local function isReich() return RP1942.getFaction and RP1942.getFaction(LocalPlayer()) == "reich" end
local function active() return GetGlobal2Bool("rp1942_bank_active", false) end

--[[---------------------------------------------------------------------------
Banner + alarm
---------------------------------------------------------------------------]]
net.Receive("RP1942_BankEvent", function()
    local kind, a, b = net.ReadString(), net.ReadString(), net.ReadString()
    if not RP1942.showAlertBanner then return end
    if kind == "start" then
        RP1942.showAlertBanner("lockdown", B.text.title, isReich() and B.text.bodyReich or B.text.bodyOthers, 10,
            "- " .. a .. " is robbing the vault", function() return active() end)
    elseif kind == "won" then
        RP1942.showAlertBanner("lifted", B.text.wonTitle, a, 9, b)
    elseif kind == "lost" and b ~= "silent" then
        RP1942.showAlertBanner("lifted", B.text.lostTitle, a, 7)
    end
end)

-- The alarm loops at the vault while it's being robbed
local alarm, loading = nil, false
local function stopAlarm()
    if IsValid(alarm) then alarm:Stop() end
    alarm = nil
end
timer.Create("RP1942_BankAlarm", 0.5, 0, function()
    local vault = GetGlobal2Entity("rp1942_bank_vault", NULL)
    if not active() or not IsValid(vault) then stopAlarm() return end
    if IsValid(alarm) then alarm:SetPos(vault:WorldSpaceCenter()) return end
    if loading then return end
    local path = S("alarm")
    if not path or path == "" or not file.Exists(path, "GAME") then return end
    loading = true
    sound.PlayFile(path, "3d noplay", function(ch)
        loading = false
        if not IsValid(ch) then return end
        if not active() then ch:Stop() return end
        alarm = ch
        ch:SetPos(vault:WorldSpaceCenter())
        ch:Set3DFadeDistance(300, S("alarmRange") or 2500)
        ch:EnableLooping(true)
        ch:SetVolume(S("alarmVolume") or 1)
        ch:Play()
    end)
end)

--[[---------------------------------------------------------------------------
The robbery panel (everyone, while it runs) and the Reich's marker
---------------------------------------------------------------------------]]
hook.Add("HUDPaint", "RP1942_Bank", function()
    if not active() then return end
    local C = colors()
    local st = RP1942.bankState()
    local now = CurTime()
    local me = LocalPlayer()
    local crew = RP1942.bankIsCrew(me)
    local reich = isReich()

    local w = math.floor(math.Clamp(ScrW() * 0.17, 250, 380))
    local x, y = ScrW() - w - 20, math.floor(ScrH() * 0.22)
    local orders = RP1942.OrdersRect   -- the Orders panel (rp1942_hud/cl_orders.lua) sits above it
    if orders and orders.x > ScrW() / 2 then y = math.max(y, orders.y + orders.h + 12) end
    local lines = {}
    local ini = st.initiator
    lines[#lines + 1] = { "Robber: " .. (IsValid(ini) and ini:Nick() or "?"), C.text }
    lines[#lines + 1] = { "At stake: " .. DarkRP.formatMoney(RP1942.getTreasury and RP1942.getTreasury() or 0), C.gold }
    if st.joinEnds > now and not reich then
        lines[#lines + 1] = { crew and ("Crew can join: " .. fmt(st.joinEnds - now)) or ("Press E on the vault to ask to join: " .. fmt(st.joinEnds - now)), C.sub }
    end
    if crew then
        local out = IsValid(ini) and ini:GetNW2Float("RP1942_BankOutside", 0) or 0
        if out > 0 then
            lines[#lines + 1] = { (ini == me and "GET BACK TO THE VAULT: " or (ini:Nick() .. " LEFT THE BANK: ")) .. fmt(S("leaveGrace") - (now - out)), C.red }
        elseif ini == me then
            lines[#lines + 1] = { "Stay alive and near the vault", C.green }
        else
            lines[#lines + 1] = { "Keep " .. (IsValid(ini) and ini:Nick() or "them") .. " alive", C.green }
        end
    elseif reich then
        lines[#lines + 1] = { "Kill or arrest the robber to stop it", C.red }
    end

    local lh = draw.GetFontHeight("RP1942_BankBody") + 4
    local h = 16 + draw.GetFontHeight("RP1942_BankHead") + draw.GetFontHeight("RP1942_BankTime") + 18 + #lines * lh + 12
    draw.RoundedBox(6, x, y, w, h, Color(20, 19, 17, 225))
    surface.SetDrawColor(C.red)
    surface.DrawRect(x, y, 4, h)
    local cy = y + 10
    draw.SimpleText("BANK ROBBERY", "RP1942_BankHead", x + 16, cy, C.red)
    cy = cy + draw.GetFontHeight("RP1942_BankHead")
    draw.SimpleText(fmt(st.endsAt - now), "RP1942_BankTime", x + 16, cy, C.text)
    cy = cy + draw.GetFontHeight("RP1942_BankTime") + 4
    local dur = math.max(S("duration") or 600, 1)
    local frac = math.Clamp(1 - (st.endsAt - now) / dur, 0, 1)
    draw.RoundedBox(3, x + 16, cy, w - 32, 8, C.well)
    draw.RoundedBox(3, x + 16, cy, math.max(6, (w - 32) * frac), 8, C.red)
    cy = cy + 18
    for _, l in ipairs(lines) do
        draw.SimpleText(l[1], "RP1942_BankBody", x + 16, cy, l[2])
        cy = cy + lh
    end

    -- Marker on the vault for the Reich and the crew
    local vault = st.vault
    if (reich or crew) and IsValid(vault) then
        local pos = vault:WorldSpaceCenter() + Vector(0, 0, 60)
        local sp = pos:ToScreen()
        if sp.visible then
            local d = math.floor(me:GetPos():Distance(vault:GetPos()) / 52.5)
            local pulse = 0.6 + 0.4 * math.abs(math.sin(RealTime() * 3))
            surface.SetDrawColor(C.red.r, C.red.g, C.red.b, 255 * pulse)
            surface.DrawOutlinedRect(sp.x - 10, sp.y - 10, 20, 20, 2)
            draw.SimpleTextOutlined("REICHSBANK  ·  " .. d .. " m", "RP1942_BankBody", sp.x, sp.y - 16, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 200))
        end
    end
end)

--[[---------------------------------------------------------------------------
Pop-ups: confirm starting / asking to join; the initiator's "let them in?"
---------------------------------------------------------------------------]]
local function popup(title, body, yesText, onYes, onNo, expires, keepKeys)
    local C = colors()
    local s = math.Clamp(ScrH() / 1080, 0.75, 1.5)
    local f = vgui.Create("EditablePanel")
    f:SetSize(math.floor(440 * s), math.floor(210 * s))
    f:MakePopup()
    if keepKeys then f:SetKeyboardInputEnabled(false) end   -- you can still move while it's up
    f.expires = expires
    f.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(8, 0, 0, w, math.floor(40 * s), C.bar, true, true, false, false)
        surface.SetDrawColor(C.red)
        surface.DrawRect(0, math.floor(40 * s) - 2, w, 2)
        draw.SimpleText(title, "RP1942_BankHead", 14, math.floor(20 * s), C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if self.expires then
            draw.SimpleText(fmt(self.expires - CurTime()), "RP1942_BankHead", w - 14, math.floor(20 * s), C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    f.Think = function(self)
        if self.expires and CurTime() > self.expires then self:Remove() end
    end
    local lbl = vgui.Create("DLabel", f)
    lbl:SetPos(14, math.floor(50 * s))
    lbl:SetSize(f:GetWide() - 28, math.floor(100 * s))
    lbl:SetFont("RP1942_BankBody")
    lbl:SetTextColor(C.text)
    lbl:SetWrap(true)
    lbl:SetContentAlignment(7)
    lbl:SetText(body)
    local function btn(text, col, x, fn)
        local b = vgui.Create("DButton", f)
        b:SetText("")
        b:SetSize((f:GetWide() - 42) / 2, math.floor(38 * s))
        b:SetPos(x, f:GetTall() - b:GetTall() - 12)
        b.Paint = function(self, w, h)
            draw.RoundedBox(5, 0, 0, w, h, self:IsHovered() and Color(col.r + 25, col.g + 20, col.b + 15) or col)
            draw.SimpleText(text, "RP1942_BankHead", w / 2, h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function() surface.PlaySound("ui/buttonclick.wav") f:Remove() if fn then fn() end end
        return b
    end
    btn(yesText, C.redD, 14, onYes)
    btn("Cancel", Color(52, 48, 42), 28 + (f:GetWide() - 42) / 2, onNo)
    return f
end

local prompt
net.Receive("RP1942_BankPrompt", function()
    local kind, text = net.ReadString(), net.ReadString()
    if IsValid(prompt) then prompt:Remove() end
    local title, body = string.match(text, "^([^\n]+)\n(.*)$")
    prompt = popup(title or "Reichsbank", body or text, kind == "start" and "ROB THE BANK" or "ASK TO JOIN", function()
        net.Start("RP1942_BankPromptAnswer")
        net.WriteString(kind)
        net.SendToServer()
    end, nil, CurTime() + 15)
    prompt:Center()
end)

-- The initiator's pop-ups, stacked on the left, one per player asking
local asks = {}
local function layoutAsks()
    local y = math.floor(ScrH() * 0.3)
    for i = #asks, 1, -1 do
        if not IsValid(asks[i]) then table.remove(asks, i) end
    end
    for _, p in ipairs(asks) do
        p:SetPos(20, y)
        y = y + p:GetTall() + 8
    end
end
net.Receive("RP1942_BankJoinAsk", function()
    local who, ends = net.ReadEntity(), net.ReadFloat()
    if not IsValid(who) then return end
    local function answer(yes)
        net.Start("RP1942_BankJoinAnswer")
        net.WriteEntity(who)
        net.WriteBool(yes)
        net.SendToServer()
        timer.Simple(0, layoutAsks)
    end
    local p = popup("Join your crew?", who:Nick() .. " wants to join the robbery. Let them in?", "LET THEM IN",
        function() answer(true) end, function() answer(false) end, ends + 2, true)
    asks[#asks + 1] = p
    layoutAsks()
    surface.PlaySound("buttons/button17.wav")
end)

--[[---------------------------------------------------------------------------
Staff: !banksettings
---------------------------------------------------------------------------]]
local frame
local FIELDS = {
    { "NOW" },
    { "enabled", "Bank robberies", "Off = nobody can start one (staff debug still works)", "bool" },
    { "ignoreReichMinimum", "Ignore the Reich minimum", "Testing: robberies start with any number of Reich online", "bool" },
    { "TIMING" },
    { "duration", "Robbery length (minutes)", "How long the robber must hold the bank", "min" },
    { "cooldown", "Cooldown (minutes)", "After a robbery, won or lost, before the next", "min" },
    { "joinWindow", "Join window (seconds)", "How long others can ask to join after the start", "num" },
    { "leaveGrace", "Grace outside (seconds)", "How long the robber may be away from the vault", "num" },
    { "RULES" },
    { "minReich", "Reich online needed", "Reich players online to start a robbery", "num" },
    { "crewMax", "Crew size", "Most robbers, the initiator included", "num" },
    { "holdRadius", "Bank radius (units)", "Distance from the vault that counts as in the bank (52 = 1 m)", "num" },
    { "useRange", "Use range (units)", "How close you must be to press E on the vault", "num" },
    { "killReward", "Reward (R.M.)", "For the Reich member who kills or arrests the robber", "num" },
    { "LOOK AND SOUND" },
    { "model", "Vault model", "Any installed model path. Changes every vault now", "text" },
    { "alarm", "Alarm sound", "A file in the addon, e.g. sounds/bankalarm.mp3", "text" },
    { "alarmVolume", "Alarm volume (0-1)", nil, "dec" },
    { "alarmRange", "Alarm range (units)", "How far the alarm carries", "num" },
}

local function openMenu(data)
    if IsValid(frame) then frame:Remove() end
    local UI = RP1942.F4UI
    if not UI then return end
    local C, s = UI.C, UI.scale()
    local pad, titleH, rowH = math.floor(14 * s), math.floor(46 * s), math.floor(38 * s)

    frame = vgui.Create("EditablePanel")
    frame:SetSize(math.floor(640 * s), math.floor(700 * s))
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(8, 0, 0, w, titleH, C.titleBar, true, true, false, false)
        surface.SetDrawColor(C.tabActive)
        surface.DrawRect(0, titleH - 2, w, 2)
        draw.SimpleText("REICHSBANK  ·  Robbery settings", "RP1942_F4Title", pad, titleH / 2, C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetSize(titleH, titleH)
    close:SetPos(frame:GetWide() - titleH, 0)
    close.DoClick = function() frame:Remove() end
    close.Paint = function(b, w, h)
        surface.SetDrawColor(b:IsHovered() and C.text or C.sub)
        local p = math.floor(w * 0.36)
        surface.DrawLine(p, p, w - p, h - p)
        surface.DrawLine(w - p, p, p, h - p)
    end

    local body = vgui.Create("DScrollPanel", frame)
    body:SetPos(pad, titleH + pad)
    body:SetSize(frame:GetWide() - pad * 2, frame:GetTall() - titleH - pad * 3 - rowH)
    UI.styleScroll(body)

    local function row(label, hint)
        local r = body:Add("DPanel")
        r:Dock(TOP)
        r:DockMargin(0, 0, 0, 4)
        r:SetTall(rowH)
        r.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, C.card)
            draw.SimpleText(label, "RP1942_F4Body", 10, hint and h * 0.36 or h / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if hint then draw.SimpleText(hint, "RP1942_F4Small", 10, h * 0.74, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
        end
        return r
    end
    local function entry(parent, value, wide, numeric)
        local e = vgui.Create("DTextEntry", parent)
        e:Dock(RIGHT)
        e:DockMargin(4, 4, 4, 4)
        e:SetWide(math.floor(wide * s))
        e:SetFont("RP1942_F4Body")
        e:SetNumeric(numeric == true)
        e:SetText(tostring(value))
        e:SetTextColor(C.text)
        e:SetCursorColor(C.gold)
        e:SetPaintBackground(false)
        e.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, C.entry)
            surface.SetDrawColor(self:HasFocus() and C.gold or C.tabHover)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            self:DrawTextEntryText(C.text, Color(C.gold.r, C.gold.g, C.gold.b, 90), C.gold)
        end
        return e
    end
    local function toggle(parent, on)
        local b = vgui.Create("DButton", parent)
        b:Dock(RIGHT)
        b:DockMargin(4, 4, 4, 4)
        b:SetWide(math.floor(90 * s))
        b:SetText("")
        b.on = on
        b.DoClick = function(self) self.on = not self.on surface.PlaySound("ui/buttonclick.wav") end
        b.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, self.on and C.categoryAlt or C.disabled)
            draw.SimpleText(self.on and "ON" or "OFF", "RP1942_F4Button", w / 2, h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return b
    end

    -- Status + debug
    local st = UI.categoryBar(body, "STATUS")
    st:Dock(TOP)
    st:DockMargin(0, 0, 0, 6)
    for _, l in ipairs(data._status or {}) do row(l) end
    local dbg = row("Debug", "Start ignores every requirement; stop pays nothing and skips the cooldown")
    for _, a in ipairs({ { "cooldown", "Clear cooldown" }, { "finish", "Finish now" }, { "stop", "Stop" }, { "start", "Start (me)" } }) do
        local b = UI.button(dbg, a[2], function()
            net.Start("RP1942_BankMenuAction") net.WriteString(a[1]) net.SendToServer()
        end)
        b:Dock(RIGHT)
        b:DockMargin(4, 4, 4, 4)
        b:SetWide(math.floor(104 * s))
    end

    local inputs = {}
    for _, fdef in ipairs(FIELDS) do
        local key, label, hint, kind = fdef[1], fdef[2], fdef[3], fdef[4]
        if not label then
            local bar = UI.categoryBar(body, key)
            bar:Dock(TOP)
            bar:DockMargin(0, 8, 0, 6)
        else
            local r = row(label, hint)
            local v = data[key]
            if kind == "bool" then
                inputs[key] = { kind = kind, w = toggle(r, v == true) }
            elseif kind == "text" then
                inputs[key] = { kind = kind, w = entry(r, v or "", 330) }
            elseif kind == "min" then
                inputs[key] = { kind = kind, w = entry(r, math.Round((v or 0) / 60, 1), 90, true) }
            else
                inputs[key] = { kind = kind, w = entry(r, v or 0, 90, kind ~= "dec") }
            end
        end
    end

    local save = UI.button(frame, "Save", function()
        local t = {}
        for key, i in pairs(inputs) do
            if i.kind == "bool" then t[key] = i.w.on
            elseif i.kind == "text" then t[key] = i.w:GetValue()
            elseif i.kind == "min" then t[key] = (tonumber(i.w:GetValue()) or 0) * 60
            else t[key] = tonumber(i.w:GetValue()) end
        end
        net.Start("RP1942_BankMenuSave")
        net.WriteString(util.TableToJSON(t))
        net.SendToServer()
    end)
    save:SetSize(math.floor(160 * s), rowH)
    save:SetPos(frame:GetWide() - pad - save:GetWide(), frame:GetTall() - pad - rowH)
end

net.Receive("RP1942_BankMenu", function()
    local t = util.JSONToTable(net.ReadString() or "")
    if istable(t) then openMenu(t) end
end)
