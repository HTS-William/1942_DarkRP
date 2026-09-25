--[[---------------------------------------------------------------------------
1942 DarkRP - F4 text pages (client)
One tab per page in sh_f4_pages.lua. In the text:
    # Heading   -> red bar        - Point  -> bullet        empty line -> space
---------------------------------------------------------------------------]]
local function buildPage(page, text)
    local UI = RP1942.F4UI
    local C = UI.C
    local gap = math.floor(8 * UI.scale())

    local list = vgui.Create("DScrollPanel", page)
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

    local first = true
    for raw in string.gmatch((text or "") .. "\n", "(.-)\r?\n") do
        local str = string.Trim(raw)
        if string.sub(str, 1, 2) == "# " then
            local bar = UI.categoryBar(list, string.sub(str, 3))
            bar:Dock(TOP)
            bar:DockMargin(0, first and 0 or gap, 0, gap)
        elseif string.sub(str, 1, 2) == "- " then
            line("•   " .. string.sub(str, 3), gap)
        elseif str == "" then
            local spacer = list:Add("Panel")
            spacer:Dock(TOP)
            spacer:SetTall(gap)
        else
            line(str)
        end
        if str ~= "" then first = false end
    end
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
