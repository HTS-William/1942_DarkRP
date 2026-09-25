--[[---------------------------------------------------------------------------
1942 DarkRP - F4 Commands tab (client)

    Money             give / drop money, write a cheque
    Actions           roleplay name, drop weapon, player info, doors, prop owner
    Citizen options   custom job title

Everything runs DarkRP's normal chat commands (or only reads what you can
already see), so all of DarkRP's own checks still apply.
---------------------------------------------------------------------------]]
RP1942.F4Tabs = RP1942.F4Tabs or {}

local function UI() return RP1942.F4UI end

-- Ask for an amount of money, then run fn(amount)
local function askAmount(title, fn)
    Derma_StringRequest(title, "How much?", "", function(text)
        local n = tonumber(text)
        if n and n > 0 then fn(tostring(math.floor(n))) end
    end)
end

local function say(...)
    chat.AddText(UI().C.gold, "[1942] ", UI().C.text, ...)
end

-- Cheque: pick who it's for, then how much
local function writeCheque()
    local menu = DermaMenu()
    local count = 0
    for _, p in ipairs(player.GetAll()) do
        if p ~= LocalPlayer() then
            count = count + 1
            menu:AddOption(p:Nick(), function()
                askAmount("Cheque for " .. p:Nick(), function(amount)
                    UI().command("cheque", tostring(p:UserID()), amount)   -- user id: safe with spaces in names
                end)
            end)
        end
    end
    if count == 0 then menu:AddOption("Nobody else is online"):SetEnabled(false) end
    menu:Open()
end

-- Info on the player you're looking at, printed to your console
local function playerInfo()
    local p = LocalPlayer():GetEyeTrace().Entity
    if not (IsValid(p) and p:IsPlayer()) then return say("Look at a player first.") end

    local faction = RP1942.getFaction and RP1942.getFaction(p)
    local names = RP1942.Config and RP1942.Config.FactionNames or {}
    local wanted = p:getDarkRPVar("wanted") and ("yes - " .. tostring(p:getDarkRPVar("wantedReason") or "")) or "no"
    local rows = {
        { "Name", p:Nick() },
        { "Job", p:getDarkRPVar("job") or team.GetName(p:Team()) },
        { "Faction", faction and (names[faction] or faction) or "-" },
        { "SteamID", p:SteamID() },
        { "SteamID64", p:SteamID64() or "-" },
        { "Wanted", wanted },
    }
    MsgC(UI().C.gold, "\n========== Player info ==========\n")
    for _, r in ipairs(rows) do MsgC(UI().C.sub, string.format("%-10s ", r[1]), UI().C.text, r[2], "\n") end
    MsgC(UI().C.gold, "=================================\n")
    say("Info on ", p:Nick(), " printed to your console (~).")
end

-- Who owns the prop you're looking at
local function propOwner()
    local e = LocalPlayer():GetEyeTrace().Entity
    if not IsValid(e) or e:IsPlayer() then return say("Look at a prop first.") end
    local owner = e.CPPIGetOwner and e:CPPIGetOwner()
    if IsValid(owner) and owner:IsPlayer() then
        say("That belongs to ", owner:Nick(), ".")
    else
        say("That doesn't belong to anyone (it's part of the map, or its owner left).")
    end
end

-- One section: { title, color key, rows }. A row is either a button
-- { "Label", fn, closeMenu } or a text box { entry = { label, value(), onEnter } }.
local SECTIONS = {
    { "Money", "category", {
        { "Give money to the player you're looking at", function() askAmount("Give money", function(a) UI().command("give", a) end) end },
        { "Drop money", function() askAmount("Drop money", function(a) UI().command("dropmoney", a) end) end },
        { "Write a cheque", writeCheque },
    }},
    { "Actions", "category", {
        { entry = { "Change your roleplay name (be realistic!) - press Enter to apply",
                    function() return LocalPlayer():Nick() end,
                    function(text) UI().command("rpname", text) end } },
        { "Drop current weapon", function() UI().command("drop") end, true },
        { "Get player info (appears in console)", playerInfo },
        { "Sell all of your doors", function()
            Derma_Query("Sell every door you own?", "Sell all doors", "Sell them", function() UI().command("unownalldoors") end, "Cancel")
        end },
        { "Get prop owner", propOwner },
    }},
    { "Citizen options", "categoryAlt", {
        { entry = { function()
                        -- Undercover jobs: the server keeps it silent (rp1942_core/sv_disguise.lua)
                        if RP1942.canDisguise and RP1942.canDisguise(LocalPlayer()) then
                            return "Set your cover title (silent: nobody is told) - press Enter to apply"
                        end
                        return "Set a custom job title - press Enter to apply"
                    end,
                    function()
                        local job = RPExtraTeams[LocalPlayer():Team()]
                        return LocalPlayer():getDarkRPVar("job") or (job and job.name) or ""
                    end,
                    function(text) UI().command("job", text) end } },
    }},
}

RP1942.F4Tabs.commands = {
    name = "Commands",
    icon = "icon16/cog.png",
    build = function(page)
        local ui = UI()
        local C = ui.C
        local s = ui.scale()
        local gap = math.floor(8 * s)

        local list = vgui.Create("DScrollPanel", page)
        list:Dock(FILL)
        ui.styleScroll(list)
        list.Paint = function(_, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
        list:GetCanvas():DockPadding(gap, gap, gap, gap)

        for _, section in ipairs(SECTIONS) do
            local bar = ui.categoryBar(list, section[1], nil, C[section[2]])
            bar:Dock(TOP)
            bar:DockMargin(0, 0, 0, 4)

            for _, row in ipairs(section[3]) do
                if row.entry then
                    local label = list:Add("DLabel")
                    label:Dock(TOP)
                    label:DockMargin(4, 4, 0, 2)
                    label:SetFont("RP1942_F4Small")
                    label:SetTextColor(C.sub)
                    label:SetText(isfunction(row.entry[1]) and row.entry[1]() or row.entry[1])
                    label:SizeToContentsY()

                    local box = ui.textEntry(list, row.entry[2](), row.entry[3])
                    box:Dock(TOP)
                    box:DockMargin(0, 0, 0, 4)
                else
                    local btn = list:Add("DButton")
                    btn:Dock(TOP)
                    btn:DockMargin(0, 0, 0, 4)
                    btn:SetTall(math.floor(34 * s))
                    btn:SetText("")
                    btn.hover = 0
                    btn.DoClick = function()
                        surface.PlaySound("ui/buttonclick.wav")
                        if row[3] then RP1942.closeF4() end
                        row[2]()
                    end
                    btn.Paint = function(b, w, h)
                        b.hover = Lerp(FrameTime() * 12, b.hover, b:IsHovered() and 1 or 0)
                        draw.RoundedBox(4, 0, 0, w, h, ui.mix(C.card, C.cardHover, b.hover))
                        surface.SetDrawColor(C.gold.r, C.gold.g, C.gold.b, 255 * b.hover)
                        surface.DrawRect(0, h - 2, w, 2)
                        draw.SimpleText(row[1], "RP1942_F4Body", w / 2, h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end

            local spacer = list:Add("Panel")
            spacer:Dock(TOP)
            spacer:SetTall(gap * 2)
        end
    end,
}
