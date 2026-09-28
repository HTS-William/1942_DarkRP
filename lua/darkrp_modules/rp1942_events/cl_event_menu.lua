--[[---------------------------------------------------------------------------
1942 DarkRP - world event settings menu (client). Opened by the server
(sv_event_menu.lua) with the current settings; in the F4 menu's style.
Times are shown in minutes.
---------------------------------------------------------------------------]]
local frame

local function open(data)
    if IsValid(frame) then frame:Remove() end
    local UI = RP1942.F4UI
    if not UI then return end
    local C, s = UI.C, UI.scale()
    local pad, titleH = math.floor(14 * s), math.floor(46 * s)
    local rowH = math.floor(36 * s)

    frame = vgui.Create("EditablePanel")
    frame:SetSize(math.floor(620 * s), math.floor(640 * s))
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(8, 0, 0, w, titleH, C.titleBar, true, true, false, false)
        surface.SetDrawColor(C.tabActive)
        surface.DrawRect(0, titleH - 2, w, 2)
        draw.SimpleText("WORLD EVENTS", "RP1942_F4Title", pad, titleH / 2, C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetFont("RP1942_F4Title")
        local tw = surface.GetTextSize("WORLD EVENTS ")
        draw.SimpleText("·  Settings", "RP1942_F4Title", pad + tw, titleH / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

    local function header(text)
        local bar = UI.categoryBar(body, text)
        bar:Dock(TOP)
        bar:DockMargin(0, 0, 0, 6)
    end

    -- A labelled row with something on the right
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

    local function number(parent, value, decimals)
        local e = vgui.Create("DTextEntry", parent)
        e:Dock(RIGHT)
        e:DockMargin(4, 4, 4, 4)
        e:SetWide(math.floor(90 * s))
        e:SetFont("RP1942_F4Body")
        e:SetNumeric(true)
        e:SetText(decimals and string.format("%." .. decimals .. "f", value) or tostring(value))
        e:SetTextColor(C.text)
        e:SetCursorColor(C.gold)
        e:SetPaintBackground(false)
        e.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, C.entry)
            surface.SetDrawColor(self:HasFocus() and C.gold or C.tabHover)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            self:DrawTextEntryText(C.text, Color(C.gold.r, C.gold.g, C.gold.b, 90), C.gold)
        end
        e.Value = function(self) return tonumber(self:GetValue()) end
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

    local function mins(sec) return math.Round((sec or 0) / 60, 1) end

    -- Status
    header("NOW")
    local status = row("", nil)
    status.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, C.card)
        local left = data.nextIn or -1
        local nextText = left >= 0 and string.format("Next automatic event in %d:%02d", math.floor(left / 60), math.floor(left % 60)) or "No event scheduled"
        local run = data.running ~= "" and ("Running: " .. data.running) or "Nothing running"
        draw.SimpleText(run .. "   ·   " .. nextText .. "   ·   " .. data.players .. " online", "RP1942_F4Body", 10, h / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local startedAt = RealTime()
    status.Think = function()
        if data.nextIn and data.nextIn >= 0 then
            data.nextIn = math.max(0, data._next0 - (RealTime() - startedAt))
        end
    end
    data._next0 = data.nextIn or -1

    -- Timer
    header("AUTOMATIC EVENTS")
    local enabled = toggle(row("Automatic events", "Off = only staff start events"), data.enabled)
    local minE = number(row("Minutes between events (shortest)", "Min and max the same = a fixed gap"), mins(data.intervalMin), 1)
    local maxE = number(row("Minutes between events (longest)", "Different from the shortest = a random gap"), mins(data.intervalMax), 1)
    local first = number(row("Minutes before the first event", "After a map change or restart"), mins(data.firstDelay), 1)
    local minP = number(row("Player minimum", "No automatic events below this many online"), data.minPlayers)
    local retry = number(row("Retry after (minutes)", "When nothing could run (too few players). 0 = wait a full gap"), mins(data.retryDelay), 1)

    -- Each event
    local evRows = {}
    header("EVENTS")
    for id, e in SortedPairs(data.events or {}) do
        local r = row(e.name or id, "id: " .. id)
        local startBtn = UI.button(r, "Start now", function()
            net.Start("RP1942_EventMenuAction") net.WriteString("start:" .. id) net.SendToServer()
        end)
        startBtn:Dock(RIGHT)
        startBtn:DockMargin(4, 4, 4, 4)
        startBtn:SetWide(math.floor(100 * s))
        local tog = toggle(r, e.enabled)
        local mp = number(r, e.minPlayers)
        mp:SetTooltip("Player minimum for this event")
        evRows[id] = { tog = tog, mp = mp }
    end
    if data.running ~= "" then
        local r = row("Stop the running event", data.running)
        local b = UI.button(r, "Stop", function()
            net.Start("RP1942_EventMenuAction") net.WriteString("stop") net.SendToServer()
        end)
        b:Dock(RIGHT)
        b:DockMargin(4, 4, 4, 4)
        b:SetWide(math.floor(100 * s))
    end

    -- Save
    local save = UI.button(frame, "Save", function()
        local t = {
            enabled = enabled.on,
            intervalMin = (minE:Value() or mins(data.intervalMin)) * 60,
            intervalMax = (maxE:Value() or mins(data.intervalMax)) * 60,
            firstDelay = (first:Value() or mins(data.firstDelay)) * 60,
            minPlayers = minP:Value() or data.minPlayers,
            retryDelay = (retry:Value() or mins(data.retryDelay)) * 60,
            events = {},
        }
        if t.intervalMax < t.intervalMin then t.intervalMax = t.intervalMin end
        for id, r in pairs(evRows) do t.events[id] = { enabled = r.tog.on, minPlayers = r.mp:Value() } end
        net.Start("RP1942_EventMenuSave")
        net.WriteString(util.TableToJSON(t))
        net.SendToServer()
    end)
    save:SetSize(math.floor(160 * s), rowH)
    save:SetPos(frame:GetWide() - pad - save:GetWide(), frame:GetTall() - pad - rowH)
end

net.Receive("RP1942_EventMenu", function()
    local data = util.JSONToTable(net.ReadString() or "")
    if istable(data) then open(data) end
end)
