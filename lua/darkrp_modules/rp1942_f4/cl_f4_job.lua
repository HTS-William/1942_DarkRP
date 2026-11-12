--[[---------------------------------------------------------------------------
42Bros - F4 job tab (client): the current job's own abilities

Only for jobs with a `menu` in jobs.lua (today the Gestapo and Operative's
wardrobe and the Führer's office). The tab is named after the job's
`menuTab` ("Wardrobe", "Führer's Office"), and holds that job's menu
(rp1942_menu: the same panel that used to open on F3), in the F4 menu's
colours. Production jobs have none, and the dealers sell from the top of
their Shop tab instead.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local function jobMenu(ply)
    local job = RPExtraTeams[ply:Team()]
    if not (job and job.menu and vgui.GetControlTable(job.menu)) then return nil end
    return job
end

-- The job menus' colour table, from the F4 menu's colours
local function theme()
    local C = RP1942.F4UI.C
    return {
        bg = C.panel, header = C.category,
        accent = C.button, accentHover = C.buttonHover,
        text = C.text, sub = C.sub,
    }
end

-- Text boxes in the menu need the keyboard while you type (the F4 menu
-- normally leaves it with the game): the same as the F4 menu's own boxes
local function keyboardFor(panel)
    for _, child in ipairs(panel:GetChildren()) do
        if child:GetClassName() == "TextEntry" and not child.RP1942_F4Keys then
            child.RP1942_F4Keys = true
            local gain, lose = child.OnGetFocus, child.OnLoseFocus
            child.OnGetFocus = function(self, ...)
                if IsValid(RP1942.F4Panel) then RP1942.F4Panel:SetKeyboardInputEnabled(true) end
                if gain then return gain(self, ...) end
            end
            child.OnLoseFocus = function(self, ...)
                if IsValid(RP1942.F4Panel) then RP1942.F4Panel:SetKeyboardInputEnabled(false) end
                if lose then return lose(self, ...) end
                return DTextEntry.OnLoseFocus(self, ...)
            end
        end
        keyboardFor(child)
    end
end

RP1942.F4Tabs.job = {
    name = "Job",
    icon = "icon16/user_suit.png",
    canSee = function(ply)
        local job = jobMenu(ply)
        if job then RP1942.F4Tabs.job.name = job.menuTab or job.name end
        return job ~= nil
    end,
    build = function(page)
        local job = jobMenu(LocalPlayer())
        if not job then return end
        local menu = vgui.Create(job.menu, page)
        menu:Dock(FILL)
        menu:SetupEmbedded(job, theme())
        -- menus that rebuild themselves (the wardrobe's tabs) get new boxes: check now and then
        local nextCheck = 0
        page.Think = function()
            if RealTime() < nextCheck then return end
            nextCheck = RealTime() + 0.5
            if IsValid(menu) then keyboardFor(menu) end
        end
    end,
}
