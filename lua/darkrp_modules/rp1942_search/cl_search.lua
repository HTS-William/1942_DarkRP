--[[---------------------------------------------------------------------------
42Bros - the weapon checker (client): the list a search opens, and the bar
the player being searched sees. Built from the F4 menu's parts (RP1942.F4UI)
so it looks like the rest of the server's menus. See sh_search.lua.
---------------------------------------------------------------------------]]
local frame

local function take(what, key)
    net.Start("RP1942_SearchTake")
    net.WriteString(what)
    net.WriteString(tostring(key or ""))
    net.SendToServer()
end

local function open(target, kind, data)
    local UI = RP1942.F4UI
    if not UI then return end
    local C = UI.C
    local s = UI.scale()
    local gap = math.floor(8 * s)
    local rowH = math.floor(38 * s)

    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetSize(math.min(ScrW() - 32, math.floor(560 * s)), math.min(ScrH() - 32, math.floor(620 * s)))
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame:DockPadding(gap, math.floor(46 * s) + gap, gap, gap)
    local name = IsValid(target) and target:Nick() or "?"
    frame.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(8, 0, 0, w, math.floor(46 * s), C.titleBar, true, true, false, false)
        surface.SetDrawColor(C.tabActive)
        surface.DrawRect(0, math.floor(46 * s) - 2, w, 2)
        draw.SimpleText(UI.fit((kind == "pocket" and "Pocket search: " or "Pat down: ") .. name, "RP1942_F4Head", w - 24), "RP1942_F4Head",
            12, math.floor(23 * s), C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    -- close if they wander off
    frame.Think = function(self)
        if not IsValid(target) or LocalPlayer():GetPos():DistToSqr(target:GetPos()) > (RP1942.Search.range * 1.5) ^ 2 then self:Remove() end
    end

    local close = UI.button(frame, "Close", function() frame:Remove() end)
    close:Dock(BOTTOM)
    close:SetTall(math.floor(36 * s))
    close:DockMargin(0, gap, 0, 0)

    local anything = #data.carried > 0
    for _, p in ipairs(data.pocket) do if p.take then anything = true end end
    if anything then
        local all = UI.button(frame, "Confiscate all", function() take("all") end)
        all:Dock(BOTTOM)
        all:SetTall(math.floor(36 * s))
        all:DockMargin(0, gap, 0, 0)
    end

    local list = vgui.Create("DScrollPanel", frame)
    list:Dock(FILL)
    UI.styleScroll(list)
    list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
    list:GetCanvas():DockPadding(gap, gap, gap, gap)

    local btnW = math.floor(124 * s)
    surface.SetFont("RP1942_F4Button")
    btnW = math.max(btnW, select(1, surface.GetTextSize("Confiscate")) + math.floor(24 * s))

    local function bar(text, right)
        local b = UI.categoryBar(list, text, right)
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 4)
    end
    local function note(text)
        local l = list:Add("DLabel")
        l:Dock(TOP)
        l:DockMargin(4, 8, 4, gap)
        l:SetFont("RP1942_F4Body")
        l:SetTextColor(C.sub)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        l:SetText(text)
    end
    local function row(label, onTake, dim)
        local r = list:Add("DPanel")
        r:Dock(TOP)
        r:DockMargin(0, 0, 0, 4)
        r:SetTall(rowH)
        r.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, C.card)
            draw.SimpleText(UI.fit(label, "RP1942_F4Body", w - 24 - (onTake and btnW + 6 or 0)), "RP1942_F4Body",
                math.floor(12 * s), h / 2, dim and C.sub or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        if onTake then
            local b = UI.button(r, "Confiscate", onTake)
            b:Dock(RIGHT)
            b:DockMargin(6, 5, 5, 5)
            b:SetWide(btnW)
        end
    end

    bar("Carrying", #data.carried .. (#data.carried == 1 and " weapon" or " weapons"))
    if #data.carried == 0 then note("No weapons.") end
    for _, c in ipairs(data.carried) do
        row(c.name, function() take("carried", c.class) end)
    end

    if kind == "pocket" then
        local spacer = list:Add("Panel")
        spacer:Dock(TOP)
        spacer:SetTall(gap)
        bar("In their pocket", #data.pocket .. (#data.pocket == 1 and " item" or " items"))
        if #data.pocket == 0 then note("Their pocket is empty.") end
        for _, p in ipairs(data.pocket) do
            row(p.name, p.take and function() take("pocket", p.idx) end or nil, not p.take)
        end
    end
end

net.Receive("RP1942_SearchList", function()
    local target = net.ReadEntity()
    local kind = net.ReadString()
    local data = net.ReadTable()
    open(target, kind, data)
end)

-- The player being searched: who, and how long
hook.Add("HUDPaint", "RP1942_Searched", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local by = lp:GetNW2Entity("RP1942_SearchedBy")
    if not IsValid(by) then return end
    local start, finish = lp:GetNW2Float("RP1942_SearchStart"), lp:GetNW2Float("RP1942_SearchEnd")
    if CurTime() > finish + 0.5 then return end
    local UI = RP1942.F4UI
    local C = UI and UI.C or { text = color_white, card = Color(38, 35, 31), button = Color(128, 26, 24) }
    local w, h = math.floor(ScrW() * 0.22), math.max(18, math.floor(ScrH() * 0.022))
    local x, y = ScrW() / 2 - w / 2, ScrH() * 0.62
    local f = math.Clamp((CurTime() - start) / math.max(0.01, finish - start), 0, 1)
    draw.RoundedBox(4, x, y, w, h, C.card)
    draw.RoundedBox(4, x, y, w * f, h, C.button)
    draw.SimpleText(by:Nick() .. " is searching you", "RP1942_F4Body", ScrW() / 2, y - 4, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end)
