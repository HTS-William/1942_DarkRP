--[[---------------------------------------------------------------------------
42Bros - Inventory (client): the F4 menu's Inventory tab

    [ locked notice, if it is ]
    YOUR POCKET   3/10            [STORE ALL]   YOUR INVENTORY   5/24 slots
    Bread ★★☆          [STORE]                  Wine ★★★ ×4     [TO POCKET] [DROP]
    ...                                          ...

Everything is done on the server (sv_inventory.lua); this only shows the
last list it sent and asks for changes.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local state           -- the last RP1942_InvSync
local shown           -- what the tab last drew (redrawn only when it changes)
local rebuild         -- the open tab's redraw, if the tab is open

local function ask(action, n)
    net.Start("RP1942_Inv")
    net.WriteString(action)
    net.WriteUInt(n or 0, 16)
    net.SendToServer()
end

net.Receive("RP1942_InvSync", function()
    state = net.ReadTable()
    local sig = util.TableToJSON(state)
    if rebuild and sig ~= shown then
        shown = sig
        rebuild()
    end
end)

RP1942.F4Tabs.inventory = {
    name = "Inventory",
    icon = "icon16/box.png",
    build = function(page)
        local UI = RP1942.F4UI
        local C = UI.C
        local s = UI.scale()
        local gap = math.floor(8 * s)
        local rowH = math.floor(38 * s)
        local btnW = math.floor(124 * s)   -- "TO POCKET" fits with room to spare

        local lock = vgui.Create("DPanel", page)
        lock:Dock(TOP)
        lock:SetTall(0)
        lock:DockMargin(0, 0, 0, 0)
        lock.Paint = function(_, w, h)
            if h <= 0 or not (state and state.locked) then return end
            draw.RoundedBox(4, 0, 0, w, h, Color(110, 32, 26))
            draw.SimpleText(state.locked, "RP1942_F4Body", 12, h / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local cols = vgui.Create("DPanel", page)
        cols:Dock(FILL)
        cols:SetPaintBackground(false)

        local function column(parent)
            local col = vgui.Create("DPanel", parent)
            col:SetPaintBackground(false)
            local head = vgui.Create("DPanel", col)
            head:Dock(TOP)
            head:SetTall(math.floor(34 * s))
            head:SetPaintBackground(false)
            local list = vgui.Create("DScrollPanel", col)
            list:Dock(FILL)
            list:DockMargin(0, 4, 0, 0)
            UI.styleScroll(list)
            list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
            list:GetCanvas():DockPadding(gap, gap, gap, gap)
            return col, head, list
        end
        local left, leftHead, pocketList = column(cols)
        local right, rightHead, invList = column(cols)
        cols.PerformLayout = function(_, w, h)
            local half = math.floor((w - gap) / 2)
            left:SetPos(0, 0)        left:SetSize(half, h)
            right:SetPos(half + gap, 0) right:SetSize(w - half - gap, h)
        end

        local function emptyLine(list, text)
            local l = list:Add("DLabel")
            l:Dock(TOP)
            l:DockMargin(4, 6, 4, 0)
            l:SetFont("RP1942_F4Body")
            l:SetTextColor(C.sub)
            l:SetWrap(true)
            l:SetAutoStretchVertical(true)
            l:SetText(text)
        end

        local function row(list, label, dim, buttons)
            local r = list:Add("DPanel")
            r:Dock(TOP)
            r:DockMargin(0, 0, 0, 4)
            r:SetTall(rowH)
            r.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, C.card)
                local textW = w - 16 - #buttons * (btnW + 6)
                draw.SimpleText(UI.fit(label, "RP1942_F4Body", textW), "RP1942_F4Body", 10, h / 2, dim and C.sub or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            for i = #buttons, 1, -1 do
                local b = UI.button(r, buttons[i][1], buttons[i][2], buttons[i][3])
                b:Dock(RIGHT)
                b:DockMargin(6, 5, i == #buttons and 5 or 0, 5)
                b:SetWide(btnW)
            end
        end

        local function unlocked() return state ~= nil and not state.locked end

        local storeAll
        rebuild = function()
            if not IsValid(page) then rebuild = nil return end
            local st = state or { items = {}, pocket = {}, slots = 0, pocketRoom = 0 }
            lock:SetTall(st.locked and math.floor(36 * s) or 0)
            lock:DockMargin(0, 0, 0, st.locked and gap or 0)

            -- headers
            leftHead:Clear()
            local lb = UI.categoryBar(leftHead, "YOUR POCKET", (#st.pocket) .. " item(s)  ·  " .. (st.pocketRoom or 0) .. " free")
            lb:Dock(FILL)
            storeAll = UI.button(lb, "STORE ALL", function() ask("storeall") end, function() return unlocked() and #(state.pocket or {}) > 0 end)
            storeAll:Dock(RIGHT)
            storeAll:DockMargin(0, 4, 4, 4)
            storeAll:SetWide(math.floor(110 * s))
            rightHead:Clear()
            local rb = UI.categoryBar(rightHead, "YOUR INVENTORY", (#st.items) .. "/" .. (st.slots or 0) .. " slots  ·  kept between visits")
            rb:Dock(FILL)

            -- the pocket
            pocketList:Clear()
            if #st.pocket == 0 then
                emptyLine(pocketList, "Your pocket is empty. Pocket goods or a weapon (the pocket SWEP, or R with it) and store them here.")
            end
            for _, p in ipairs(st.pocket) do
                row(pocketList, p.label .. (p.ok and "" or "   (can't be stored)"), not p.ok, {
                    { "STORE", function() ask("store", p.i) end, function() return p.ok and unlocked() end },
                })
            end

            -- the inventory
            invList:Clear()
            if #st.items == 0 then
                emptyLine(invList, "Nothing stored yet. Goods (bread, wine, oil, parts...) and weapons can be stored, up to "
                    .. (RP1942.Inventory.config.stack) .. " of the same in a slot. What's in here stays when you die, leave or the server restarts.")
            end
            for i, it in ipairs(st.items) do
                row(invList, RP1942.Inventory.label(it), false, {
                    { "TO POCKET", function() ask("take", i) end, function() return unlocked() and (state.pocketRoom or 0) > 0 end },
                    { "DROP", function() ask("drop", i) end, unlocked },
                })
            end
        end

        -- ask for the lists now, and again every couple of seconds (the lock's countdown)
        ask("sync")
        rebuild()
        local nextAsk = RealTime() + 2
        page.Think = function()
            if RealTime() >= nextAsk then
                nextAsk = RealTime() + 2
                ask("sync")
            end
        end
        page.OnRemove = function()
            rebuild = nil
            shown = nil
            ask("close")
        end
    end,
}
