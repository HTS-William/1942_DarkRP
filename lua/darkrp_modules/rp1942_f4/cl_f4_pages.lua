--[[---------------------------------------------------------------------------
1942 DarkRP - F4 text pages (client)
One tab per page in sh_f4_pages.lua. In the text:
    # Heading   -> red bar        - Point  -> bullet        empty line -> space
    #staff Heading -> a section only staff see (RP1942.isF4Staff)

Every page has:
    a search bar     shows only the lines that contain every word typed,
                     under their section's heading. A section whose own
                     name matches shows whole. Words can be split between
                     the heading and the line ("padlock warrant").
    a contents list  (pages with 5 or more sections) down the left: click a
                     section to jump to it. While searching it lists only the
                     sections with matches, and how many.
---------------------------------------------------------------------------]]
local CONTENTS_FROM = 5   -- sections a page needs before it gets the contents list

-- The page's text as sections: { title, staff, items = { { kind, text } } }
local function parse(text, isStaff)
    local sections, cur = {}, { items = {} }
    sections[1] = cur
    local hidden = false
    for raw in string.gmatch((text or "") .. "\n", "(.-)\r?\n") do
        local str = string.Trim(raw)
        local staffHead = string.match(str, "^#staff%s+(.+)$")
        local head = staffHead or (string.sub(str, 1, 2) == "# " and string.sub(str, 3)) or nil
        if head then
            hidden = staffHead ~= nil and not isStaff
            cur = { title = head, staff = staffHead ~= nil, items = {} }
            if not hidden then sections[#sections + 1] = cur end
        elseif not hidden then
            if string.sub(str, 1, 2) == "- " then
                cur.items[#cur.items + 1] = { kind = "bullet", text = string.sub(str, 3) }
            elseif str == "" then
                cur.items[#cur.items + 1] = { kind = "space" }
            else
                cur.items[#cur.items + 1] = { kind = "line", text = str }
            end
        end
    end
    -- drop an empty untitled start
    if not sections[1].title and #sections[1].items == 0 then table.remove(sections, 1) end
    return sections
end

local function words(query)
    local list = {}
    for w in string.gmatch(string.lower(query or ""), "%S+") do list[#list + 1] = w end
    return list
end

local function hasAll(haystack, ws)
    for _, w in ipairs(ws) do
        if not string.find(haystack, w, 1, true) then return false end
    end
    return true
end

-- What to show for a query: { section, items, count } per section with anything to show
local function filter(sections, query)
    local ws = words(query)
    local out = {}
    for _, sec in ipairs(sections) do
        if #ws == 0 then
            out[#out + 1] = { section = sec, items = sec.items, count = 0 }
        else
            local title = string.lower(sec.title or "")
            if sec.title and hasAll(title, ws) then
                local n = 0
                for _, it in ipairs(sec.items) do if it.kind ~= "space" then n = n + 1 end end
                out[#out + 1] = { section = sec, items = sec.items, count = math.max(n, 1) }
            else
                local hits = {}
                for _, it in ipairs(sec.items) do
                    if it.text and hasAll(title .. " " .. string.lower(it.text), ws) then hits[#hits + 1] = it end
                end
                if #hits > 0 then out[#out + 1] = { section = sec, items = hits, count = #hits } end
            end
        end
    end
    return out
end

local function buildPage(page, text)
    local UI = RP1942.F4UI
    local C = UI.C
    local s = UI.scale()
    local gap = math.floor(8 * s)
    local sections = parse(text, RP1942.isF4Staff and RP1942.isF4Staff(LocalPlayer()))
    local titled = 0
    for _, sec in ipairs(sections) do if sec.title then titled = titled + 1 end end

    -- Search bar
    local top = vgui.Create("Panel", page)
    top:Dock(TOP)
    top:SetTall(math.floor(34 * s))
    top:DockMargin(0, 0, 0, gap)

    local content = vgui.Create("Panel", page)
    content:Dock(FILL)

    local sidebar
    if titled >= CONTENTS_FROM then
        sidebar = vgui.Create("DScrollPanel", content)
        sidebar:Dock(LEFT)
        sidebar:DockMargin(0, 0, gap, 0)
        UI.styleScroll(sidebar)
        sidebar.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        sidebar:GetCanvas():DockPadding(4, 4, 4, 4)
        content.PerformLayout = function(_, w)
            sidebar:SetWide(math.floor(math.Clamp(w * 0.26, 160 * s, 300 * s)))
        end
    end

    local list = vgui.Create("DScrollPanel", content)
    list:Dock(FILL)
    UI.styleScroll(list)
    list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
    list:GetCanvas():DockPadding(gap, gap, gap, gap)

    local function line(str, indent)
        local l = list:Add("DLabel")
        l:Dock(TOP)
        l:DockMargin(gap + (indent or 0), 0, gap * 2, 4)
        l:SetFont("RP1942_F4Body")
        l:SetTextColor(C.text)
        l:SetText(str)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
    end

    local function contentsButton(sec, count, bar)
        local b = sidebar:Add("DButton")
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 2)
        b:SetTall(math.floor(26 * s))
        b:SetText("")
        b.hover = 0
        local label = sec.title
        b.Paint = function(btn, w, h)
            btn.hover = Lerp(FrameTime() * 12, btn.hover, btn:IsHovered() and 1 or 0)
            if btn.hover > 0.01 then draw.RoundedBox(4, 0, 0, w, h, Color(C.cardHover.r, C.cardHover.g, C.cardHover.b, 255 * btn.hover)) end
            local right = count > 0 and tostring(count) or nil
            local rw = 0
            if right then
                surface.SetFont("RP1942_F4Small")
                rw = surface.GetTextSize(right) + 12
                draw.SimpleText(right, "RP1942_F4Small", w - 8, h / 2, C.gold, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            draw.SimpleText(UI.fit(label, "RP1942_F4Body", w - 16 - rw), "RP1942_F4Body", 8, h / 2,
                sec.staff and C.gold or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            if IsValid(bar) then list:ScrollToChild(bar) end
        end
    end

    local function render(query)
        list:Clear()
        if IsValid(sidebar) then sidebar:Clear() end
        local shown = filter(sections, query)
        local searching = #words(query) > 0

        if #shown == 0 then
            line("Nothing matches \"" .. string.Trim(query) .. "\". Try fewer or shorter words.")
            return
        end
        local first = true
        for _, entry in ipairs(shown) do
            local sec = entry.section
            local bar
            if sec.title then
                bar = UI.categoryBar(list, sec.title, searching and (entry.count .. (entry.count == 1 and " match" or " matches")) or nil)
                bar:Dock(TOP)
                bar:DockMargin(0, first and 0 or gap, 0, gap)
                first = false
                if IsValid(sidebar) then contentsButton(sec, searching and entry.count or 0, bar) end
            end
            for _, it in ipairs(entry.items) do
                if it.kind == "bullet" then
                    line("•   " .. it.text, gap)
                elseif it.kind == "line" then
                    line(it.text)
                elseif not searching then
                    local spacer = list:Add("Panel")
                    spacer:Dock(TOP)
                    spacer:SetTall(gap)
                end
                first = false
            end
        end
    end

    local entry = UI.textEntry(top, "", function(t) render(t) end)
    entry:Dock(FILL)
    entry:SetUpdateOnType(true)
    entry.OnValueChange = function(_, v)
        -- wait for a pause in typing before rebuilding the page
        timer.Create("RP1942_F4PageSearch", 0.15, 1, function()
            if IsValid(list) then render(v) end
        end)
    end
    local basePaint = entry.Paint
    entry.Paint = function(self, w, h)
        basePaint(self, w, h)
        if self:GetValue() == "" and not self:HasFocus() then
            draw.SimpleText("Search this page...  (padlock, taxes, warrant, raid...)", "RP1942_F4Body", 10, h / 2,
                C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local clear = vgui.Create("DButton", top)
    clear:Dock(RIGHT)
    clear:DockMargin(gap / 2, 0, 0, 0)
    clear:SetWide(math.floor(34 * s))
    clear:SetText("")
    clear.Paint = function(btn, w, h)
        if entry:GetValue() == "" then return end
        draw.RoundedBox(4, 0, 0, w, h, btn:IsHovered() and C.buttonHover or C.button)
        draw.SimpleText("×", "RP1942_F4Head", w / 2, h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    clear.DoClick = function()
        if entry:GetValue() == "" then return end
        entry:SetText("")
        render("")
    end

    render("")
end

-- Called by the F4 window for the "pages" entry in RP1942.F4Config.tabs
function RP1942.F4PageTabs()
    local tabs = {}
    for _, p in ipairs(RP1942.F4Pages or {}) do
        tabs[#tabs + 1] = {
            name = p.tab or "Page",
            icon = p.icon,
            build = function(page) buildPage(page, p.text) end,
        }
    end
    return tabs
end
