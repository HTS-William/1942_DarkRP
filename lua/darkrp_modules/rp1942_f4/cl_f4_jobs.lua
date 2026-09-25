--[[---------------------------------------------------------------------------
1942 DarkRP - F4 Jobs tab (client)

    ┌ Category ───────────────────────────┐ ┌─────────────────────┐
    │ [card] [card] [card]                │ │   (idle model)      │
    │ [card] [card]                       │ │ Job name            │
    ├ Category ───────────────────────────┤ │ description, info   │
    │ [card] [card] [card]                │ │ [ Become job ]      │
    └─────────────────────────────────────┘ └─────────────────────┘

Card name colours: green = you can take it, red = you can't (locked or
full), gold = your current job. Which categories show follows DarkRP's
category canSee (the faction hop system). Everything is checked again by
DarkRP on the server when you press the button.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local IDLE_SEQUENCES = { "idle_all_01", "idle_all_02", "idle_subtle", "idle" }

--[[---------------------------------------------------------------------------
Can the local player take this job? Returns state, reason.
    "current" | "available" | "full" | "locked"
Mirrors DarkRP's own checks, in the same order.
---------------------------------------------------------------------------]]
local function slotLimit(job)
    if not job.max or job.max == 0 then return nil end
    if job.max < 1 then return math.max(1, math.ceil(player.GetCount() * job.max)) end
    return job.max
end

local function jobState(job)
    local lp = LocalPlayer()
    if lp:Team() == job.team then return "current", nil end

    local admin = job.admin or 0
    if admin == 1 and not lp:IsAdmin() then return "locked", "Only admins can take this job." end
    if admin >= 2 and not lp:IsSuperAdmin() then return "locked", "Only superadmins can take this job." end

    if job.NeedToChangeFrom then
        local from = istable(job.NeedToChangeFrom) and job.NeedToChangeFrom or { job.NeedToChangeFrom }
        if not table.HasValue(from, lp:Team()) then
            local names = {}
            for _, t in ipairs(from) do names[#names + 1] = team.GetName(t) end
            return "locked", "You must be " .. table.concat(names, " or ") .. " first."
        end
    end

    if job.customCheck and not job.customCheck(lp) then
        local msg = job.CustomCheckFailMsg
        if isfunction(msg) then msg = msg(lp, job) end
        return "locked", (msg and msg ~= "") and msg or "You can't take this job right now."
    end

    local limit = slotLimit(job)
    if limit and team.NumPlayers(job.team) >= limit then
        if TEAM_FUHRER and job.team == TEAM_FUHRER then return "full", "The office is occupied." end
        return "full", "Every slot is taken."
    end
    return "available", nil
end

-- What the big button says and does
local function jobAction(job)
    local UI = RP1942.F4UI
    if TEAM_FUHRER and job.team == TEAM_FUHRER and RP1942.openElection then
        -- The server turns this into the election ballot
        return "Stand for election", function() UI.command(job.command) end
    end
    if job.quietJoin then
        -- The server does this silently, with a civilian cover (rp1942_core/sv_disguise.lua)
        return "Report for duty (quietly)", function() UI.command(job.command) end
    end
    if job.vote or (job.RequiresVote and job.RequiresVote(LocalPlayer(), job.team)) then
        return "Call a vote for " .. job.name, function() UI.command("vote" .. job.command) end
    end
    return "Become " .. job.name, function() UI.command(job.command) end
end

local function jobModels(job)
    return istable(job.model) and job.model or { job.model }
end

-- The model the player would get: their saved pick if it's one of this job's models
local function preferredModel(job)
    local models = jobModels(job)
    local pref = DarkRP.getPreferredJobModel and DarkRP.getPreferredJobModel(job.team)
    if pref and table.HasValue(models, pref) then return pref end
    return models[1]
end

--[[---------------------------------------------------------------------------
Full-body framing. The camera's FOV in Garry's Mod is the horizontal angle
for a 4:3 view, so the vertical angle is smaller than it looks - fixed camera
numbers cut the head and feet off. Instead, work out how far back the camera
must be for the model's real height (and width, for narrow panels) to fit.
---------------------------------------------------------------------------]]
local MARGIN = 1.10   -- 10% breathing room around the model

local function frameWholeModel(mp)
    local ent = mp:GetEntity()
    if not IsValid(ent) then return end

    local mins, maxs = ent:GetModelBounds()
    local height = maxs.z - mins.z
    if height < 40 or height > 110 then   -- odd bounds: assume a standard player
        mins, maxs, height = Vector(-16, -16, 0), Vector(16, 16, 72), 72
    end
    local center = (mins + maxs) * 0.5
    local width = math.max(maxs.x - mins.x, maxs.y - mins.y)

    local vHalf = math.atan(math.tan(math.rad(mp:GetFOV()) / 2) * 0.75)
    local w, h = mp:GetWide(), mp:GetTall()
    local aspect = (w > 0 and h > 0) and (w / h) or (4 / 3)
    local hHalf = math.atan(math.tan(vHalf) * aspect)

    local dist = math.max(height * MARGIN / 2 / math.tan(vHalf), width * MARGIN / 2 / math.tan(hHalf))
    local dir = Vector(1, 0.22, 0.06):GetNormalized()   -- slightly to the side and above
    mp:SetCamPos(center + dir * dist)
    mp:SetLookAt(center)
end

--[[---------------------------------------------------------------------------
Idle model: a DModelPanel that plays the standing idle animation instead of
spinning. bust = framed on head and shoulders (cards); otherwise full body.
---------------------------------------------------------------------------]]
local function makeModelPanel(parent, model, bust)
    local mp = vgui.Create("DModelPanel", parent)
    mp:SetMouseInputEnabled(false)
    mp.LayoutEntity = function(self) self:RunAnimation() end

    function mp:SetJobModel(mdl)
        self:SetModel(mdl or "models/player/kleiner.mdl")
        local ent = self:GetEntity()
        if not IsValid(ent) then return end
        for _, name in ipairs(IDLE_SEQUENCES) do
            local seq = ent:LookupSequence(name)
            if seq and seq > 0 then ent:ResetSequence(seq) break end
        end
        ent:SetAngles(Angle(0, 0, 0))   -- player models face +X: towards the camera
        ent:SetupBones()

        if bust then
            local bone = ent:LookupBone("ValveBiped.Bip01_Head1")
            local head = bone and ent:GetBonePosition(bone)
            if not head or head:IsZero() then head = Vector(0, 0, 64) end
            self:SetFOV(28)
            self:SetCamPos(head + Vector(60, 14, 0))
            self:SetLookAt(head + Vector(0, 0, -8))
        else
            self:SetFOV(30)
            frameWholeModel(self)
        end
    end

    mp:SetJobModel(model)
    return mp
end

--[[---------------------------------------------------------------------------
The tab
---------------------------------------------------------------------------]]
RP1942.F4Tabs.jobs = {
    name = "Jobs",
    icon = "icon16/group.png",
    build = function(page)
        local UI = RP1942.F4UI
        local C = UI.C
        local CFG = RP1942.F4Config
        local s = UI.scale()
        local gap = math.floor(8 * s)
        local cols = CFG.jobColumns or 3

        local selected   -- the job shown in the detail panel
        local detail = vgui.Create("DPanel", page)
        detail:Dock(RIGHT)
        detail:DockMargin(gap, 0, 0, 0)

        local list = vgui.Create("DScrollPanel", page)
        list:Dock(FILL)
        UI.styleScroll(list)
        list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        list:GetCanvas():DockPadding(gap, gap, gap, gap)

        page.PerformLayout = function(_, w) detail:SetWide(math.floor(w * 0.36)) end

        ------------------------------------------------------------------ detail
        detail.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        detail:DockPadding(gap * 2, gap, gap * 2, gap * 2)

        local model = makeModelPanel(detail, nil, false)
        model:Dock(TOP)
        model:SetTall(math.floor(ScrH() * 0.30))
        model:SetMouseInputEnabled(true)

        -- Arrows to pick between a job's models (only when it has several)
        local modelIndex = 1
        local function arrow(dir)
            local b = vgui.Create("DButton", model)
            b:SetText("")
            b:SetSize(math.floor(28 * s), math.floor(40 * s))
            b.Paint = function(btn, w, h)
                local models = selected and jobModels(selected) or {}
                if #models < 2 then return end
                draw.RoundedBox(4, 0, 0, w, h, btn:IsHovered() and C.tabHover or Color(0, 0, 0, 110))
                draw.SimpleText(dir < 0 and "<" or ">", "RP1942_F4Head", w / 2, h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            b.DoClick = function()
                local models = selected and jobModels(selected) or {}
                if #models < 2 then return end
                modelIndex = (modelIndex - 1 + dir) % #models + 1
                model:SetJobModel(models[modelIndex])
                if DarkRP.setPreferredJobModel then DarkRP.setPreferredJobModel(selected.team, models[modelIndex]) end
                surface.PlaySound("ui/buttonclick.wav")
            end
            return b
        end
        local left, right = arrow(-1), arrow(1)
        model.PerformLayout = function(self, w, h)
            left:SetPos(0, (h - left:GetTall()) / 2)
            right:SetPos(w - right:GetWide(), (h - right:GetTall()) / 2)
            frameWholeModel(self)
        end

        local actionLabel, actionFn = "", function() end
        local state, reason = "available", nil
        local action = UI.button(detail, function() return actionLabel end, function()
            actionFn()
            RP1942.closeF4()
        end, function() return selected and state == "available" end)
        action:Dock(BOTTOM)
        action:SetTall(math.floor(44 * s))

        local info = vgui.Create("DScrollPanel", detail)
        info:Dock(FILL)
        info:DockMargin(0, gap, 0, gap)
        UI.styleScroll(info)

        local function addLabel(text, font, color, marginTop)
            local l = info:Add("DLabel")
            l:Dock(TOP)
            l:DockMargin(0, marginTop or 0, 6, 0)
            l:SetFont(font)
            l:SetTextColor(color)
            l:SetText(text)
            l:SetWrap(true)
            l:SetAutoStretchVertical(true)
            return l
        end

        local function refreshAction()
            if not selected then return end
            state, reason = jobState(selected)
            actionLabel, actionFn = jobAction(selected)
            if state == "current" then actionLabel = "This is your job"
            elseif state == "full" and TEAM_FUHRER and selected.team == TEAM_FUHRER then actionLabel = "Office occupied"
            elseif state == "full" then actionLabel = "No slots free"
            elseif state == "locked" then actionLabel = "Locked" end
        end

        local function showJob(job)
            selected = job
            modelIndex = 1
            local models = jobModels(job)
            local pref = preferredModel(job)
            for i, m in ipairs(models) do if m == pref then modelIndex = i end end
            model:SetJobModel(pref)
            refreshAction()

            info:Clear()
            local nameCol = state == "current" and C.gold or state == "available" and C.available or C.unavailable
            addLabel(job.name, "RP1942_F4Big", nameCol)

            local tags = {}
            if job.vip then tags[#tags + 1] = "VIP" end
            if job.whitelisted then tags[#tags + 1] = "WHITELISTED" end
            if TEAM_FUHRER and job.team == TEAM_FUHRER then tags[#tags + 1] = "ELECTED" end
            if job.quietJoin then tags[#tags + 1] = "UNDERCOVER" end
            if job.vote then tags[#tags + 1] = "VOTE" end
            if #tags > 0 then addLabel(table.concat(tags, "  ·  "), "RP1942_F4Small", C.gold, 2) end

            if reason then addLabel(reason, "RP1942_F4Body", C.unavailable, gap) end
            addLabel(job.description or "", "RP1942_F4Body", C.text, gap)

            local limit = slotLimit(job)
            local rows = {
                { "Salary", DarkRP.formatMoney(job.salary or 0) },
                { "Slots", team.NumPlayers(job.team) .. " / " .. (limit or "unlimited") },
            }
            local factions = RP1942.Config and RP1942.Config.FactionNames
            if job.faction and factions and factions[job.faction] then
                local f = factions[job.faction]
                rows[#rows + 1] = { "Faction", f:sub(1, 1):upper() .. f:sub(2) }
            end
            local weps = {}
            for _, class in ipairs(job.weapons or {}) do
                local w = weapons.Get(class)
                weps[#weps + 1] = w and w.PrintName and w.PrintName ~= "" and language.GetPhrase(w.PrintName) or class
            end
            rows[#rows + 1] = { "Weapons", #weps > 0 and table.concat(weps, ", ") or "None" }
            for i, r in ipairs(rows) do
                addLabel(r[1], "RP1942_F4Small", C.sub, i == 1 and gap * 2 or gap)
                addLabel(r[2], "RP1942_F4Body", C.text)
            end
        end

        -- Keep the button and reason current (someone takes the last slot, etc.)
        local nextCheck = 0
        detail.Think = function()
            if not selected or RealTime() < nextCheck then return end
            nextCheck = RealTime() + 0.5
            local beforeState, beforeReason = state, reason
            refreshAction()
            if state ~= beforeState or reason ~= beforeReason then showJob(selected) end
        end

        ------------------------------------------------------------------ cards
        local function addCard(grid, job)
            local card = vgui.Create("DButton", grid)
            card:SetText("")
            card.hover = 0
            card.DoClick = function()
                surface.PlaySound("ui/buttonclick.wav")
                showJob(job)
            end

            local mp = makeModelPanel(card, preferredModel(job), true)
            mp:Dock(FILL)
            mp:DockMargin(2, 2, 2, 2)

            local cstate, nextState = "available", 0
            card.Think = function()
                if RealTime() < nextState then return end
                nextState = RealTime() + 0.5
                cstate = jobState(job)
            end

            card.Paint = function(c, w, h)
                c.hover = Lerp(FrameTime() * 12, c.hover, c:IsHovered() and 1 or 0)
                local bg = selected == job and C.cardSelected or UI.mix(C.card, C.cardHover, c.hover)
                draw.RoundedBox(4, 0, 0, w, h, bg)
            end

            card.PaintOver = function(c, w, h)
                -- Dim jobs you can't take
                if cstate == "locked" or cstate == "full" then
                    draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 90))
                end
                -- Name bar along the bottom, sized to its two lines of text
                surface.SetFont("RP1942_F4Head");  local _, nameH = surface.GetTextSize("Ag")
                surface.SetFont("RP1942_F4Small"); local _, slotH = surface.GetTextSize("Ag")
                local barH = nameH + slotH + 8
                draw.RoundedBoxEx(4, 0, h - barH, w, barH, Color(0, 0, 0, 175), false, false, true, true)
                local nameCol = cstate == "current" and C.gold or cstate == "available" and C.available or C.unavailable
                draw.SimpleText(UI.fit(job.name, "RP1942_F4Head", w - 12), "RP1942_F4Head", 7, h - barH + 3, nameCol)

                local limit = slotLimit(job)
                local slots = team.NumPlayers(job.team) .. (limit and (" / " .. limit) or "")
                if job.vip then slots = slots .. "  ·  VIP" end
                draw.SimpleText(slots, "RP1942_F4Small", 7, h - 4, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

                if selected == job then
                    surface.SetDrawColor(C.gold)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                end
                if cstate == "current" then
                    surface.SetFont("RP1942_F4Small")
                    local tw, th = surface.GetTextSize("CURRENT")
                    local bw, bh, m = tw + 12, th + 4, 6
                    draw.RoundedBox(3, w - bw - m, m, bw, bh, C.gold)
                    draw.SimpleText("CURRENT", "RP1942_F4Small", w - m - bw / 2, m + bh / 2, C.titleBar, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
            return card
        end

        -- A category: bar + grid of cards, `cols` across
        local firstJob
        local function addCategory(cat)
            if cat.canSee and not cat.canSee(LocalPlayer()) then return end

            local jobs = {}
            for _, job in ipairs(cat.members or {}) do
                if CFG.showLockedJobs or jobState(job) ~= "locked" then jobs[#jobs + 1] = job end
            end
            if #jobs == 0 then return end

            local bar = UI.categoryBar(list, cat.name, #jobs .. (#jobs == 1 and " job" or " jobs"))
            bar:Dock(TOP)
            bar:DockMargin(0, 0, 0, gap)

            local grid = list:Add("Panel")
            grid:Dock(TOP)
            grid:DockMargin(0, 0, 0, gap * 2)
            for _, job in ipairs(jobs) do
                addCard(grid, job)
                firstJob = firstJob or job
            end
            grid.PerformLayout = function(g, w)
                local cw = math.floor((w - gap * (cols - 1)) / cols)
                local ch = math.floor(cw * 1.08)
                for i, child in ipairs(g:GetChildren()) do
                    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
                    child:SetPos(col * (cw + gap), row * (ch + gap))
                    child:SetSize(cw, ch)
                end
                local rows = math.ceil(#g:GetChildren() / cols)
                local tall = rows * ch + (rows - 1) * gap
                if g:GetTall() ~= tall then g:SetTall(tall) end
            end
        end
        for _, cat in ipairs(DarkRP.getCategories().jobs or {}) do addCategory(cat) end

        -- Start on your current job
        local current = RPExtraTeams[LocalPlayer():Team()]
        showJob(current or firstJob or RPExtraTeams[1])
    end,
}
