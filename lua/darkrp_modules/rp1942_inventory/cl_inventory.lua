--[[---------------------------------------------------------------------------
42Bros - Inventory (client): the F4 menu's Inventory tab

    [ Inventory locked: why, if it is ]
    Your pocket      3 items, 2 free           Your inventory        5/24 slots
    Bread (fine)              [Store]          Wine (good) x4  [To pocket] [Drop]
    ...                                        ...
    [            Store all           ]

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

-- Built from the F4 menu's own parts (sh_f4.lua / cl_f4.lua), laid out like the
-- Law Board: a dark panel per column with a category bar on top, card rows,
-- the grey note when it's empty, and a full-width button under the rows.
-- Sizes follow UI.scale() like every other tab; a button only grows past its
-- usual width if its label wouldn't fit (very high resolutions).
local function textW(font, text)
    surface.SetFont(font)
    return (surface.GetTextSize(text))
end

RP1942.F4Tabs.inventory = {
    name = "Inventory",
    icon = "icon16/box.png",
    build = function(page)
        local UI = RP1942.F4UI
        local C = UI.C
        local s = UI.scale()
        local gap = math.floor(8 * s)
        local rowH = math.floor(38 * s)
        local btnPad = math.floor(12 * s)
        local btnW = math.floor(110 * s)
        for _, t in ipairs({ "Store", "To pocket", "Drop" }) do
            btnW = math.max(btnW, textW("RP1942_F4Button", t) + btnPad * 2)
        end

        -- the lock notice, shown above both columns while it's locked
        local lock = vgui.Create("DPanel", page)
        lock:Dock(TOP)
        lock:SetPaintBackground(false)
        lock:SetTall(0)
        local lockBar = UI.categoryBar(lock, "Inventory locked")
        lockBar:Dock(TOP)
        local lockText = vgui.Create("DLabel", lock)
        lockText:Dock(TOP)
        lockText:DockMargin(4, 4, 4, 0)
        lockText:SetFont("RP1942_F4Body")
        lockText:SetTextColor(C.sub)
        lockText:SetWrap(true)
        lockText:SetAutoStretchVertical(true)
        lockText:SetText("")
        -- its height follows the wrapped reason (known only once it's laid out)
        lock.Think = function()
            local want = (state and state.locked) and (lockBar:GetTall() + 4 + lockText:GetTall() + gap) or 0
            if lock:GetTall() ~= want then lock:SetTall(want) end
        end

        local cols = vgui.Create("DPanel", page)
        cols:Dock(FILL)
        cols:SetPaintBackground(false)

        local function column()
            local list = vgui.Create("DScrollPanel", cols)
            UI.styleScroll(list)
            list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
            list:GetCanvas():DockPadding(gap, gap, gap, gap)
            return list
        end
        local pocketList, invList = column(), column()

        -- side by side; on screens too narrow for an inventory row (a name and
        -- two buttons) in half the width, the pocket goes above the inventory
        local minColW = btnW * 2 + 12 + math.floor(200 * s) + gap * 2
        cols.PerformLayout = function(_, w, h)
            if w >= minColW * 2 + gap then
                local half = math.floor((w - gap) / 2)
                pocketList:SetPos(0, 0)            pocketList:SetSize(half, h)
                invList:SetPos(half + gap, 0)      invList:SetSize(w - half - gap, h)
            else
                local top = math.floor((h - gap) * 0.4)
                pocketList:SetPos(0, 0)            pocketList:SetSize(w, top)
                invList:SetPos(0, top + gap)       invList:SetSize(w, h - top - gap)
            end
        end

        local function bar(list, name, right)
            local b = UI.categoryBar(list, name, right)
            b:Dock(TOP)
            b:DockMargin(0, 0, 0, 4)
        end

        local function note(list, text)
            local l = list:Add("DLabel")
            l:Dock(TOP)
            l:DockMargin(4, 8, 4, 0)
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
                local room = w - math.floor(12 * s) - 8 - #buttons * (btnW + 6)
                draw.SimpleText(UI.fit(label, "RP1942_F4Body", room), "RP1942_F4Body", math.floor(12 * s), h / 2,
                    dim and C.sub or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            for i = #buttons, 1, -1 do
                local b = UI.button(r, buttons[i][1], buttons[i][2], buttons[i][3])
                b:Dock(RIGHT)
                b:DockMargin(6, 5, i == #buttons and 5 or 0, 5)
                b:SetWide(btnW)
            end
        end

        local function unlocked() return state ~= nil and not state.locked end

        rebuild = function()
            if not IsValid(page) then rebuild = nil return end
            local st = state or { items = {}, pocket = {}, slots = 0, pocketRoom = 0 }

            lockText:SetText(st.locked or "")

            -- the pocket
            pocketList:Clear()
            local n, free = #st.pocket, st.pocketRoom or 0
            bar(pocketList, "Your pocket", n .. (n == 1 and " item" or " items") .. ", " .. free .. " free")
            if n == 0 then
                note(pocketList, "Your pocket is empty. Pocket goods or a weapon (the pocket SWEP, or R with it) and store them here.")
            end
            for _, p in ipairs(st.pocket) do
                row(pocketList, p.label .. (p.ok and "" or "   (can't be stored)"), not p.ok, {
                    { "Store", function() ask("store", p.i) end, function() return p.ok and unlocked() end },
                })
            end
            if n > 0 then
                local all = UI.button(pocketList, "Store all", function() ask("storeall") end,
                    function() return unlocked() and #(state.pocket or {}) > 0 end)
                all:Dock(TOP)
                all:DockMargin(0, gap, 0, 0)
                all:SetTall(math.floor(36 * s))
            end

            -- the inventory
            invList:Clear()
            bar(invList, "Your inventory", (#st.items) .. "/" .. (st.slots or 0) .. " slots")
            if #st.items == 0 then
                note(invList, "Nothing stored yet. Goods (bread, wine, oil, parts...) and weapons can be stored, up to "
                    .. (RP1942.Inventory.config.stack) .. " of the same in a slot. What's in here stays when you die, leave or the server restarts.")
            end
            for i, it in ipairs(st.items) do
                row(invList, RP1942.Inventory.label(it), false, {
                    { "To pocket", function() ask("take", i) end, function() return unlocked() and (state.pocketRoom or 0) > 0 end },
                    { "Drop", function() ask("drop", i) end, unlocked },
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
