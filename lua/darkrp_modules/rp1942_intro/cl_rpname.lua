--[[---------------------------------------------------------------------------
1942 DarkRP - roleplay name registration (client)

When the intro has faded (cl_intro.lua fires RP1942_IntroFinished), a player
who hasn't got a proper roleplay name yet is asked for one: a first and a
last name. It's set with DarkRP's own /rpname, so DarkRP still checks it
(length, characters, not taken) and saves it. Players who already have a
"First Last" name that isn't their Steam name aren't asked again.
The name is what will go on their papers (a future papers system).

    /register       open the form again (chat)
    rp1942_rpname   the same, in console
---------------------------------------------------------------------------]]
local FIRST = {
    "Hans", "Karl", "Friedrich", "Otto", "Wilhelm", "Heinrich", "Ernst", "Walter", "Paul", "Kurt", "Josef", "Franz",
    "Anna", "Greta", "Marta", "Elise", "Hedwig", "Ilse", "Frieda", "Irene",
    "Jan", "Tadeusz", "Piotr", "Andrzej", "Marek", "Zofia", "Halina", "Irena", "Krystyna", "Wanda",
}
local LAST = {
    "Richter", "Becker", "Hoffmann", "Schulz", "Wagner", "Keller", "Brandt", "Vogel", "Krause", "Neumann", "Lehmann", "Hartmann",
    "Kowalski", "Nowak", "Wisniewski", "Kaminski", "Lewandowski", "Zielinski", "Szymanski", "Wozniak", "Dabrowski", "Kozlowski",
}

-- Has this player got a proper roleplay name yet?
local function needsName()
    local lp = LocalPlayer()
    if not IsValid(lp) then return false end
    local rp = lp:getDarkRPVar("rpname") or lp:Nick()
    local steam = lp.SteamName and lp:SteamName() or ""
    if rp == steam then return true end
    return not string.find(rp, "^%S+ %S+$")   -- not "First Last"
end

-- One part of the name: 2-14 characters, letters (any alphabet), - and ' inside
local function checkPart(text, what)
    if #text < 2 then return what .. " is too short." end
    if utf8.len(text) and utf8.len(text) > 14 then return what .. " is too long (14 letters at most)." end
    local stripped = string.gsub(text, "[%-']", "")
    if string.find(stripped, "[%d%s%p]") then return what .. " can only have letters (and - or ')." end
    return nil
end

-- "hans" -> "Hans" (plain letters only; others are left as typed)
local function capital(text)
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

local form

local function open()
    if IsValid(form) then return end
    local UI = RP1942.F4UI
    if not UI then return end
    local C, s = UI.C, UI.scale()

    form = vgui.Create("EditablePanel")
    form:SetSize(math.floor(560 * s), math.floor(330 * s))
    form:Center()
    form:MakePopup()
    form:SetAlpha(0)
    form:AlphaTo(255, 0.4)

    local titleH = math.floor(46 * s)
    local pad = math.floor(18 * s)
    local status, statusCol = "", C.sub
    local waitingFor, waitUntil

    form.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(8, 0, 0, w, titleH, C.titleBar, true, true, false, false)
        surface.SetDrawColor(C.tabActive)
        surface.DrawRect(0, titleH - 2, w, 2)
        draw.SimpleText("MELDEAMT", "RP1942_F4Title", pad, titleH / 2, C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetFont("RP1942_F4Title")
        local tw = surface.GetTextSize("MELDEAMT ")
        draw.SimpleText("·  Registration", "RP1942_F4Title", pad + tw, titleH / 2, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(status, "RP1942_F4Small", pad, h - math.floor(64 * s), statusCol)
    end

    local intro = vgui.Create("DLabel", form)
    intro:SetPos(pad, titleH + pad)
    intro:SetSize(form:GetWide() - pad * 2, math.floor(48 * s))
    intro:SetFont("RP1942_F4Body")
    intro:SetTextColor(C.text)
    intro:SetWrap(true)
    intro:SetText("Before you go out, register with the authorities. Choose a first and last name that fits 1942: "
        .. "it's the name everyone will know you by, and the one on your papers.")

    local fieldY = titleH + pad + math.floor(62 * s)
    local fieldW = math.floor((form:GetWide() - pad * 3) / 2)

    local function field(x, label, placeholder)
        local l = vgui.Create("DLabel", form)
        l:SetPos(x, fieldY)
        l:SetFont("RP1942_F4Small")
        l:SetTextColor(C.sub)
        l:SetText(label)
        l:SizeToContents()

        local e = vgui.Create("DTextEntry", form)
        e:SetPos(x, fieldY + math.floor(20 * s))
        e:SetSize(fieldW, math.floor(38 * s))
        e:SetFont("RP1942_F4Head")
        e:SetTextColor(C.text)
        e:SetCursorColor(C.gold)
        e:SetPaintBackground(false)
        e:SetUpdateOnType(true)
        e.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, C.entry)
            surface.SetDrawColor(self:HasFocus() and C.gold or C.tabHover)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            self:DrawTextEntryText(C.text, Color(C.gold.r, C.gold.g, C.gold.b, 90), C.gold)
            if self:GetValue() == "" then
                draw.SimpleText(placeholder, "RP1942_F4Head", 8, h / 2, Color(C.sub.r, C.sub.g, C.sub.b, 110), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
        return e
    end
    local first = field(pad, "FIRST NAME  (VORNAME)", "e.g. Hans")
    local last = field(pad * 2 + fieldW, "LAST NAME  (NACHNAME)", "e.g. Richter")
    first:RequestFocus()

    -- The name as it will be registered, under the fields
    local preview = vgui.Create("DPanel", form)
    preview:SetPos(pad, fieldY + math.floor(68 * s))
    preview:SetSize(form:GetWide() - pad * 2, math.floor(30 * s))
    preview.Paint = function(_, w, h)
        local f, l = capital(string.Trim(first:GetValue())), capital(string.Trim(last:GetValue()))
        local name = (f ~= "" or l ~= "") and (f .. " " .. l) or "..."
        draw.SimpleText("You will be known as:", "RP1942_F4Small", 0, h / 2, C.sub, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetFont("RP1942_F4Small")
        local tw = surface.GetTextSize("You will be known as:  ")
        draw.SimpleText(name, "RP1942_F4Head", tw, h / 2, C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local function submit()
        local f, l = capital(string.Trim(first:GetValue())), capital(string.Trim(last:GetValue()))
        local err = checkPart(f, "The first name") or checkPart(l, "The last name")
        if err then
            status, statusCol = err, C.unavailable
            surface.PlaySound("buttons/button10.wav")
            return
        end
        local name = f .. " " .. l
        status, statusCol = "Registering...", C.sub
        waitingFor, waitUntil = name, RealTime() + 3
        RunConsoleCommand("darkrp", "rpname", name)
    end
    first.OnEnter = function() last:RequestFocus() end
    last.OnEnter = submit

    local bw, bh = math.floor(150 * s), math.floor(40 * s)
    local register = UI.button(form, "Register", submit)
    register:SetSize(bw, bh)
    register:SetPos(form:GetWide() - bw - pad, form:GetTall() - bh - pad)

    local random = UI.button(form, "Random name", function()
        first:SetValue(FIRST[math.random(#FIRST)])
        last:SetValue(LAST[math.random(#LAST)])
        status = ""
    end)
    random:SetSize(bw, bh)
    random:SetPos(form:GetWide() - bw * 2 - pad - math.floor(10 * s), form:GetTall() - bh - pad)

    -- Wait for DarkRP to accept it (it sets the rpname) or not
    form.Think = function()
        if not waitingFor then return end
        if LocalPlayer():getDarkRPVar("rpname") == waitingFor then
            surface.PlaySound("buttons/button14.wav")
            notification.AddLegacy("Registered as " .. waitingFor .. ".", NOTIFY_GENERIC, 5)
            waitingFor = nil
            form:AlphaTo(0, 0.3, 0, function() if IsValid(form) then form:Remove() end end)
        elseif RealTime() > waitUntil then
            waitingFor = nil
            status, statusCol = "That name couldn't be registered (taken, or not allowed). Try another.", C.unavailable
        end
    end
end

hook.Add("RP1942_IntroFinished", "RP1942_RPName", function()
    timer.Simple(0.5, function()
        if needsName() then open() end
    end)
end)

concommand.Add("rp1942_rpname", open)
net.Receive("RP1942_OpenRPName", open)   -- /register
