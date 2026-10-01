--[[---------------------------------------------------------------------------
1942 DarkRP - F4 Appearance tab (client)

    [ your model, turning slowly ]   SKIN            < 2 / 3 >
                                     BODYGROUPS
                                     Helmet          < Stahlhelm >
                                     Gear            < None >
                                     ...
                                     [ RESET TO DEFAULT ]

Changes the model you're wearing right now. Each change is sent to the
server (sv_f4_appearance.lua), which checks it and remembers it for that
model. The rows follow your model: change job or wardrobe model and the tab
shows the new one's options.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local function send(kind, a, b)
    net.Start("RP1942_Appearance")
    net.WriteString(kind)
    if a then net.WriteUInt(a, 8) end
    if b then net.WriteUInt(b, 8) end
    net.SendToServer()
end

-- "head_gear" -> "Head gear"; "helmet_on.smd" -> "Helmet on"; blank -> "None"
local function pretty(name, fallback)
    name = string.Trim(string.gsub(string.gsub(tostring(name or ""), "%.smd$", ""), "[_%-]+", " "))
    if name == "" or name:lower() == "blank" or name:lower() == "none" or name:lower() == "empty" then return fallback end
    return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
end

-- What the current model offers: { { id, name, options = { [0] = "None", ... }, count } }
local function readGroups(ply)
    local list = {}
    for _, g in ipairs(ply:GetBodyGroups() or {}) do
        if (g.num or 0) > 1 then
            local opts = {}
            for i = 0, g.num - 1 do opts[i] = pretty(g.submodels and g.submodels[i], i == 0 and "None" or ("Option " .. i)) end
            list[#list + 1] = { id = g.id, name = pretty(g.name, "Part " .. g.id), options = opts, count = g.num }
        end
    end
    return list
end

RP1942.F4Tabs.appearance = {
    name = "Appearance",
    icon = "icon16/user_suit.png",
    canSee = function() return (RP1942.F4Config.appearance or {}).enabled ~= false end,
    build = function(page)
        local UI = RP1942.F4UI
        local C = UI.C
        local s = UI.scale()
        local gap = math.floor(8 * s)
        local CFG = RP1942.F4Config.appearance or {}

        ------------------------------------------------------------ the preview
        local left = vgui.Create("DPanel", page)
        left:Dock(LEFT)
        left:DockMargin(0, 0, gap, 0)
        page.PerformLayout = function(_, w) left:SetWide(math.floor(w * 0.36)) end
        left.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end

        local mp = vgui.Create("DModelPanel", left)
        mp:Dock(FILL)
        mp:SetFOV(32)
        mp:SetMouseInputEnabled(false)
        mp.LayoutEntity = function(self, ent)
            ent:SetAngles(Angle(0, RealTime() * 25 % 360, 0))
            self:RunAnimation()
        end
        local function frame()
            local ent = mp:GetEntity()
            if not IsValid(ent) then return end
            local seq = ent:LookupSequence("idle_all_01")
            if seq and seq > 0 then ent:ResetSequence(seq) end
            mp:SetCamPos(Vector(95, 0, 40))
            mp:SetLookAt(Vector(0, 0, 36))
        end

        ------------------------------------------------------------ the options
        local list = vgui.Create("DScrollPanel", page)
        list:Dock(FILL)
        UI.styleScroll(list)
        list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        list:GetCanvas():DockPadding(gap, gap, gap, gap)

        -- A row: name on the left, the current choice, < and > to step through
        local function stepper(name, count, get, set)
            local row = list:Add("DPanel")
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 4)
            row:SetTall(math.floor(40 * s))
            row:DockPadding(0, math.floor(5 * s), math.floor(6 * s), math.floor(5 * s))
            -- Quick clicks step on from what was last asked for, not from what
            -- the server has confirmed so far (that arrives a moment later)
            local asked, askedAt = nil, 0
            local function step(d)
                local from = (asked and RealTime() - askedAt < 0.6) and asked or get()
                asked, askedAt = (from + d) % count, RealTime()
                set(asked)
            end
            local nextB = UI.button(row, ">", function() step(1) end)
            nextB:Dock(RIGHT)
            nextB:SetWide(math.floor(40 * s))
            local label = vgui.Create("DPanel", row)
            label:Dock(RIGHT)
            label:SetWide(math.floor(220 * s))
            label:DockMargin(4, 0, 4, 0)
            label.Paint = function(_, w, h)
                local v, text = get()
                draw.RoundedBox(4, 0, 0, w, h, C.bg)
                text = UI.fit(text or tostring(v), "RP1942_F4Body", w - 12)
                draw.SimpleText(text, "RP1942_F4Body", w / 2, h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            local prevB = UI.button(row, "<", function() step(-1) end)
            prevB:Dock(RIGHT)
            prevB:SetWide(math.floor(40 * s))
            row.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, C.tab)
                draw.SimpleText(name, "RP1942_F4Body", math.floor(12 * s), h / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        local shownModel
        local function rebuild()
            local ply = LocalPlayer()
            shownModel = ply:GetModel()
            list:Clear()
            mp:SetModel(shownModel)
            frame()

            local groups = readGroups(ply)
            local skins = (CFG.skins ~= false) and ply:SkinCount() or 1
            if #groups == 0 and skins <= 1 then
                local none = list:Add("DLabel")
                none:Dock(TOP)
                none:DockMargin(4, 8, 4, 0)
                none:SetFont("RP1942_F4Body")
                none:SetTextColor(C.sub)
                none:SetWrap(true)
                none:SetAutoStretchVertical(true)
                none:SetText("The model you're wearing has nothing to change.")
                return
            end

            if skins > 1 then
                local bar = UI.categoryBar(list, "Skin", skins .. " versions")
                bar:Dock(TOP)
                bar:DockMargin(0, 0, 0, 4)
                stepper("Skin", skins,
                    function() local v = LocalPlayer():GetSkin() return v, (v + 1) .. " / " .. skins end,
                    function(v) send("skin", v) end)
            end
            if #groups > 0 then
                local bar = UI.categoryBar(list, "Bodygroups", "your current model")
                bar:Dock(TOP)
                bar:DockMargin(0, skins > 1 and gap or 0, 0, 4)
                for _, g in ipairs(groups) do
                    stepper(g.name, g.count,
                        function() local v = LocalPlayer():GetBodygroup(g.id) return v, g.options[v] or ("Option " .. v) end,
                        function(v) send("bg", g.id, v) end)
                end
            end

            local reset = UI.button(list, "Reset to default", function() send("reset") end)
            reset:Dock(TOP)
            reset:DockMargin(0, gap, 0, 0)
            reset:SetTall(math.floor(36 * s))

            local note = list:Add("DLabel")
            note:Dock(TOP)
            note:DockMargin(4, gap, 4, 0)
            note:SetFont("RP1942_F4Small")
            note:SetTextColor(C.sub)
            note:SetWrap(true)
            note:SetAutoStretchVertical(true)
            note:SetText("Saved for this model: you'll have the same look next time you wear it.")
        end

        -- Keep the preview matching you, and follow model changes
        page.Think = function()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            if ply:GetModel() ~= shownModel then rebuild() end
            local ent = mp:GetEntity()
            if IsValid(ent) then
                ent:SetSkin(ply:GetSkin())
                for id = 0, ply:GetNumBodyGroups() - 1 do ent:SetBodygroup(id, ply:GetBodygroup(id)) end
            end
        end
        rebuild()
    end,
}
