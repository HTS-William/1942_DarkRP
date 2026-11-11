--[[---------------------------------------------------------------------------
42Bros - reports (client): the report form, the staff list and the staff
counter. Built from the F4 menu's parts (RP1942.F4UI) so it looks like the
rest of the server's menus. See sh_reports.lua.
---------------------------------------------------------------------------]]
local reports = {}      -- the open reports (staff only)
local listFrame         -- the staff list, while it's open
local rebuildList

local function window(title, w, h)
    local UI = RP1942.F4UI
    local C, s = UI.C, UI.scale()
    local f = vgui.Create("DFrame")
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(true)
    f:SetSize(math.min(ScrW() - 32, math.floor(w * s)), math.min(ScrH() - 32, math.floor(h * s)))
    f:Center()
    f:MakePopup()
    local gap = math.floor(8 * s)
    f:DockPadding(gap, math.floor(46 * s) + gap, gap, gap)
    f.Paint = function(_, pw, ph)
        draw.RoundedBox(8, 0, 0, pw, ph, C.bg)
        draw.RoundedBoxEx(8, 0, 0, pw, math.floor(46 * s), C.titleBar, true, true, false, false)
        surface.SetDrawColor(C.tabActive)
        surface.DrawRect(0, math.floor(46 * s) - 2, pw, 2)
        draw.SimpleText(title, "RP1942_F4Head", 12, math.floor(23 * s), C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return f, gap, s, C, UI
end

--[[---------------------------------------------------------------------------
The report form (/report, or @ on its own)
---------------------------------------------------------------------------]]
local function openForm()
    if not RP1942.F4UI then return end
    local f, gap, s, C, UI = window("Report a rule break", 520, 440)

    local function label(text)
        local l = vgui.Create("DLabel", f)
        l:Dock(TOP)
        l:DockMargin(2, 0, 2, 4)
        l:SetFont("RP1942_F4Body")
        l:SetTextColor(C.sub)
        l:SetText(text)
        l:SizeToContentsY()
    end

    label("Who is it about? (optional)")
    local who = vgui.Create("DComboBox", f)
    who:Dock(TOP)
    who:DockMargin(0, 0, 0, gap)
    who:SetTall(math.floor(32 * s))
    who:SetFont("RP1942_F4Body")
    who:SetValue("Nobody in particular")
    who:AddChoice("Nobody in particular", "")
    local names = {}
    for _, p in ipairs(player.GetAll()) do
        if p ~= LocalPlayer() then names[#names + 1] = p end
    end
    table.sort(names, function(a, b) return a:Nick():lower() < b:Nick():lower() end)
    for _, p in ipairs(names) do who:AddChoice(p:Nick(), p:SteamID64()) end

    label("What happened? Who, what, and where.")
    local text = vgui.Create("DTextEntry", f)
    text:Dock(FILL)
    text:SetMultiline(true)
    text:SetFont("RP1942_F4Body")
    text:SetUpdateOnType(true)

    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:DockMargin(0, gap, 0, 0)
    row:SetTall(math.floor(36 * s))
    row:SetPaintBackground(false)
    local send = UI.button(row, "Send report", function()
        local _, about = who:GetSelected()
        net.Start("RP1942_ReportSend")
        net.WriteString(about or "")
        net.WriteString(string.sub(text:GetValue() or "", 1, RP1942.Reports.maxLength))
        net.SendToServer()
        f:Remove()
    end, function() return #string.Trim(text:GetValue() or "") >= RP1942.Reports.minLength end)
    local cancel = UI.button(row, "Cancel", function() f:Remove() end)
    row.PerformLayout = function(_, w, h)
        local half = math.floor((w - gap) / 2)
        send:SetPos(0, 0) send:SetSize(half, h)
        cancel:SetPos(half + gap, 0) cancel:SetSize(w - half - gap, h)
    end
    text:RequestFocus()
end
net.Receive("RP1942_ReportForm", openForm)

--[[---------------------------------------------------------------------------
The staff list (!reports)
---------------------------------------------------------------------------]]
local function act(action, id, note)
    net.Start("RP1942_ReportAct")
    net.WriteString(action)
    net.WriteUInt(id, 32)
    net.WriteString(note or "")
    net.SendToServer()
end

local function ago(t)
    local d = math.max(0, os.time() - (t or os.time()))
    if d < 60 then return d .. "s ago" end
    if d < 3600 then return math.floor(d / 60) .. "m ago" end
    return math.floor(d / 3600) .. "h ago"
end

local function openList()
    if not RP1942.F4UI then return end
    if IsValid(listFrame) then listFrame:Remove() end
    local f, gap, s, C, UI = window("Reports", 760, 640)
    listFrame = f
    f:SetKeyboardInputEnabled(false)

    local close = UI.button(f, "Close", function() f:Remove() end)
    close:Dock(BOTTOM)
    close:DockMargin(0, gap, 0, 0)
    close:SetTall(math.floor(36 * s))

    local list = vgui.Create("DScrollPanel", f)
    list:Dock(FILL)
    UI.styleScroll(list)
    list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
    list:GetCanvas():DockPadding(gap, gap, gap, gap)

    local btnH = math.floor(30 * s)
    rebuildList = function()
        if not IsValid(list) then return end
        list:Clear()
        local bar = UI.categoryBar(list, "Open reports", #reports .. (#reports == 1 and " report" or " reports"))
        bar:Dock(TOP)
        bar:DockMargin(0, 0, 0, 4)
        if #reports == 0 then
            local l = list:Add("DLabel")
            l:Dock(TOP)
            l:DockMargin(4, 8, 4, 0)
            l:SetFont("RP1942_F4Body")
            l:SetTextColor(C.sub)
            l:SetText("Nothing open.")
            l:SizeToContentsY()
            return
        end
        local me = LocalPlayer():SteamID64()
        for _, r in ipairs(reports) do
            local card = list:Add("DPanel")
            card:Dock(TOP)
            card:DockMargin(0, 0, 0, gap)
            card:DockPadding(math.floor(12 * s), math.floor(8 * s), math.floor(8 * s), math.floor(8 * s))
            card.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, C.card)
                if r.claimed then
                    surface.SetDrawColor(C.gold)
                    surface.DrawRect(0, 0, 3, h)
                end
            end

            local head = vgui.Create("DLabel", card)
            head:Dock(TOP)
            head:SetFont("RP1942_F4Button")
            head:SetTextColor(C.text)
            head:SetText("#" .. r.id .. "   " .. r.byName .. (r.byOnline and "" or " (offline)")
                .. (r.aboutName ~= "" and ("  ->  " .. r.aboutName .. (r.aboutOnline and "" or " (offline)")) or ""))
            head:SizeToContentsY()

            local sub = vgui.Create("DLabel", card)
            sub:Dock(TOP)
            sub:DockMargin(0, 2, 0, 4)
            sub:SetFont("RP1942_F4Small")
            sub:SetTextColor(r.claimed and C.gold or C.sub)
            sub:SetText(ago(r.at) .. "   ·   " .. (r.claimed and ("Taken by " .. r.claimedName) or "Nobody's on it"))
            sub:SizeToContentsY()

            local body = vgui.Create("DLabel", card)
            body:Dock(TOP)
            body:SetFont("RP1942_F4Body")
            body:SetTextColor(C.text)
            body:SetWrap(true)
            body:SetAutoStretchVertical(true)
            body:SetText(r.text)

            local row = vgui.Create("DPanel", card)
            row:Dock(TOP)
            row:DockMargin(0, gap, 0, 0)
            row:SetTall(btnH)
            row:SetPaintBackground(false)
            local buttons = {}
            local mine = r.claimed == me
            buttons[#buttons + 1] = UI.button(row, mine and "Release" or "Claim", function() act(mine and "release" or "claim", r.id) end,
                function() return mine or not r.claimed end)
            buttons[#buttons + 1] = UI.button(row, "Go to", function() act("goto", r.id) end, function() return r.byOnline end)
            buttons[#buttons + 1] = UI.button(row, "Bring", function() act("bring", r.id) end, function() return r.byOnline end)
            if r.aboutName ~= "" then
                buttons[#buttons + 1] = UI.button(row, "Clean up", function()
                    Derma_Query("Remove everything " .. r.aboutName .. " owns in the world (props, entities, padlocks...)?", "Clean up",
                        "Remove it all", function() act("cleanup", r.id) end, "Cancel")
                end, function() return r.aboutOnline end)
            end
            buttons[#buttons + 1] = UI.button(row, "Close", function()
                Derma_StringRequest("Close report #" .. r.id, "A note for " .. r.byName .. " (optional):", "",
                    function(note) act("close", r.id, note) end, nil, "Close it", "Cancel")
            end)
            row.PerformLayout = function(_, w, h)
                local n = #buttons
                local bw = math.floor((w - (n - 1) * 6) / n)
                for i, b in ipairs(buttons) do
                    b:SetPos((i - 1) * (bw + 6), 0)
                    b:SetSize(i == n and (w - (n - 1) * (bw + 6)) or bw, h)
                end
            end
            -- as tall as what's in it (the text wraps to the card's width)
            card.PerformLayout = function(self)
                local _, top, _, bottom = self:GetDockPadding()
                local h = top + bottom
                for _, child in ipairs(self:GetChildren()) do
                    local _, mt, _, mb = child:GetDockMargin()
                    h = h + child:GetTall() + mt + mb
                end
                if self:GetTall() ~= h then self:SetTall(h) end
            end
        end
    end
    rebuildList()
end

net.Receive("RP1942_ReportList", function()
    local open = net.ReadBool()
    reports = net.ReadTable() or {}
    RP1942.ReportsStaff = true
    if open then openList()
    elseif IsValid(listFrame) and rebuildList then rebuildList() end
end)

-- Staff: how many are open, in the corner
hook.Add("HUDPaint", "RP1942_Reports", function()
    if not RP1942.ReportsStaff or #reports == 0 then return end
    local UI = RP1942.F4UI
    local C = UI and UI.C or { card = Color(38, 35, 31), text = color_white, gold = Color(201, 168, 92) }
    local waiting = 0
    for _, r in ipairs(reports) do if not r.claimed then waiting = waiting + 1 end end
    local text = #reports .. " open report" .. (#reports == 1 and "" or "s") .. (waiting > 0 and ("  ·  " .. waiting .. " waiting") or "") .. "   !reports"
    surface.SetFont("RP1942_F4Body")
    local tw, th = surface.GetTextSize(text)
    local x, y = ScrW() - tw - 36, math.floor(ScrH() * 0.02)
    draw.RoundedBox(4, x, y, tw + 24, th + 12, C.card)
    surface.SetDrawColor(waiting > 0 and Color(200, 60, 50) or C.gold)
    surface.DrawRect(x, y, 3, th + 12)
    draw.SimpleText(text, "RP1942_F4Body", x + 14, y + 6, C.text)
end)
