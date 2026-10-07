--[[---------------------------------------------------------------------------
1942 DarkRP - F4 Law Board tab (client)

    LAWS OF THE REICH                                   8 laws
    ┌───────────────────────────────────────────────────────────┐
    │ 1.  Do not attack Reich officials.             FIXED       │
    │ ...                                                        │
    │ 6.  Curfew from sundown: stay indoors.         THE FÜHRER  │
    └───────────────────────────────────────────────────────────┘
    (MARTIAL LAW IS IN EFFECT  -  while there's a lockdown)

The same laws as every law board in the city (DarkRP.getLaws()). The first
ones are the fixed laws (GM.Config.DefaultLaws in settings.lua); the rest
were added by the Führer (F3). It updates by itself when a law changes.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local function currentLaws()
    return DarkRP.getLaws and DarkRP.getLaws() or {}
end

local function signature(laws)
    return #laws .. "\1" .. table.concat(laws, "\1") .. "\1" .. tostring(GetGlobalBool("DarkRP_LockDown", false))
end

RP1942.F4Tabs.laws = {
    name = "Law Board",
    icon = "icon16/script.png",
    build = function(page)
        local UI = RP1942.F4UI
        local C = UI.C
        local s = UI.scale()
        local gap = math.floor(8 * s)

        local list = vgui.Create("DScrollPanel", page)
        list:Dock(FILL)
        UI.styleScroll(list)
        list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        list:GetCanvas():DockPadding(gap, gap, gap, gap)

        local shown
        local function rebuild()
            local laws = currentLaws()
            shown = signature(laws)
            list:Clear()
            local fixed = #(GAMEMODE.Config.DefaultLaws or {})

            if GetGlobalBool("DarkRP_LockDown", false) then
                local ml = UI.categoryBar(list, "MARTIAL LAW IS IN EFFECT", "Stay in your homes")
                ml:Dock(TOP)
                ml:DockMargin(0, 0, 0, gap)
            end

            local bar = UI.categoryBar(list, "Laws of the Reich", #laws .. (#laws == 1 and " law" or " laws"))
            bar:Dock(TOP)
            bar:DockMargin(0, 0, 0, 4)

            if #laws == 0 then
                local none = list:Add("DLabel")
                none:Dock(TOP)
                none:DockMargin(4, 8, 4, 0)
                none:SetFont("RP1942_F4Body")
                none:SetTextColor(C.sub)
                none:SetText("There are no laws right now.")
                none:SizeToContentsY()
                return
            end

            for i, law in ipairs(laws) do
                local isFixed = i <= fixed
                local row = list:Add("DPanel")
                row:Dock(TOP)
                row:DockMargin(0, 0, 0, 4)
                row:DockPadding(math.floor(12 * s), math.floor(8 * s), math.floor(120 * s), math.floor(8 * s))
                row.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, C.card)
                    surface.SetDrawColor(isFixed and C.sub or C.gold)
                    surface.DrawRect(0, 0, math.max(3, math.floor(4 * s)), h)
                    draw.SimpleText(isFixed and "FIXED" or "THE FÜHRER", "RP1942_F4Small", w - math.floor(12 * s), h / 2,
                        isFixed and C.sub or C.gold, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                local lbl = row:Add("DLabel")
                lbl:Dock(TOP)
                lbl:SetFont("RP1942_F4Body")
                lbl:SetTextColor(C.text)
                lbl:SetWrap(true)
                lbl:SetAutoStretchVertical(true)
                lbl:SetText(i .. ".  " .. string.gsub(law, "\n", " "))
                local padY = math.floor(8 * s)
                row.PerformLayout = function(r, w, h)
                    local want = lbl:GetTall() + padY * 2
                    if h ~= want then r:SetTall(want) end
                end
            end

            local note = list:Add("DLabel")
            note:Dock(TOP)
            note:DockMargin(4, gap, 4, 0)
            note:SetFont("RP1942_F4Small")
            note:SetTextColor(C.sub)
            note:SetWrap(true)
            note:SetAutoStretchVertical(true)
            note:SetText("The same laws are posted on every law board in the city. The fixed laws always apply; the Führer adds and removes the others from his office (F3).")
        end

        -- Follow law changes (and martial law) while the tab is open
        local nextCheck = 0
        page.Think = function()
            if RealTime() < nextCheck then return end
            nextCheck = RealTime() + 0.5
            if signature(currentLaws()) ~= shown then rebuild() end
        end
        rebuild()
    end,
}
