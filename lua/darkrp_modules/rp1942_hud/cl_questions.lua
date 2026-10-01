--[[---------------------------------------------------------------------------
1942 DarkRP - DarkRP's yes / no questions in our style (client)

DarkRP asks players things with a little grey Derma box: above all the
lottery ("There is a lottery! Participate for RM250?"), and anything else
that uses DarkRP.createQuestion. This draws them as our own cards instead,
down the left side of the screen, newest at the bottom:

    LOTTERY                                   0:24
    The Führer has started a lottery. A ticket costs RM 250.
    Everyone who buys one is in the draw; the winner takes the whole pot.
    [ BUY A TICKET ]  [ NO THANKS ]
    ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░  (time left)
    F3 frees the cursor

Answering still goes through DarkRP ("ans <id> 1/2"), so its rules (paying,
the draw, the winner) are untouched. Unanswered questions close by
themselves when their time is up, as before.
---------------------------------------------------------------------------]]
RP1942.screenFont("RP1942_QTitle",  0.018, 800, { min = 15 })
RP1942.screenFont("RP1942_QText",   0.016, 500, { min = 13 })
RP1942.screenFont("RP1942_QSmall",  0.013, 500, { min = 12 })

local open, order = {}, {}   -- id -> card; cards in the order they came

local function scale() return math.Clamp(ScrH() / 1080, 0.75, 1.5) end

local function relayout()
    local s = scale()
    local y = math.floor(ScrH() * 0.28)
    for i = #order, 1, -1 do
        if not IsValid(order[i]) then table.remove(order, i) end
    end
    for _, card in ipairs(order) do
        card:SetPos(math.floor(16 * s), y)
        y = y + card:GetTall() + math.floor(8 * s)
    end
end

local function close(id)
    local card = open[id]
    open[id] = nil
    if IsValid(card) then card:Remove() end
    relayout()
end

local function answer(id, yes)
    RunConsoleCommand("ans", id, yes and "1" or "2")
    close(id)
end

-- What the card says: the lottery gets its own wording, anything else is shown as asked
local function describe(question, id)
    question = DarkRP.deLocalise and DarkRP.deLocalise(question) or question
    if string.StartWith(id, "lottery") then
        local price = string.match(question, "for%s+(.-)%?%s*$") or ""
        return "LOTTERY",
            "The Führer has started a lottery." .. (price ~= "" and (" A ticket costs " .. price .. ".") or "")
                .. " Everyone who buys one is in the draw; the winner takes the whole pot.",
            "BUY A TICKET", "NO THANKS"
    end
    return "A QUESTION", question, "YES", "NO"
end

local function show(question, id, seconds)
    if open[id] then close(id) end
    if not seconds or seconds <= 0 then seconds = 100 end
    local C = RP1942.col
    local s = scale()
    local w = math.floor(360 * s)
    local pad = math.floor(12 * s)
    local title, text, yesText, noText = describe(question, id)
    local started, deadline = CurTime(), CurTime() + seconds

    local card = vgui.Create("DPanel")
    card:SetWide(w)
    card:SetMouseInputEnabled(true)
    card:SetKeyboardInputEnabled(false)
    card:DockPadding(pad, math.floor(40 * s), pad, pad)

    local body = vgui.Create("DLabel", card)
    body:Dock(TOP)
    body:SetFont("RP1942_QText")
    body:SetTextColor(C("text"))
    body:SetWrap(true)
    body:SetAutoStretchVertical(true)
    body:SetText(text)

    local row = vgui.Create("Panel", card)
    row:Dock(TOP)
    row:DockMargin(0, pad, 0, 0)
    row:SetTall(math.floor(32 * s))
    local UI = RP1942.F4UI
    local function button(label, yes)
        local b = UI and UI.button(row, label, function() answer(id, yes) end) or vgui.Create("DButton", row)
        if not UI then
            b:SetText(label)
            b.DoClick = function() surface.PlaySound("ui/buttonclick.wav") answer(id, yes) end
        end
        b:Dock(LEFT)
        b:DockMargin(0, 0, math.floor(8 * s), 0)
        b:SetWide(math.floor((w - pad * 2 - 8 * s) / 2))
        return b
    end
    button(yesText, true)
    button(noText, false)

    local hint = vgui.Create("DLabel", card)
    hint:Dock(TOP)
    hint:DockMargin(0, math.floor(6 * s), 0, 0)
    hint:SetFont("RP1942_QSmall")
    hint:SetTextColor(C("sub"))
    hint:SetText("F3 frees the cursor to click")
    hint:SizeToContentsY()

    card.Paint = function(_, cw, ch)
        local left = math.max(deadline - CurTime(), 0)
        draw.RoundedBox(6, 0, 0, cw, ch, C("bg"))
        draw.RoundedBoxEx(6, 0, 0, cw, math.floor(32 * s), C("titleBar"), true, true, false, false)
        surface.SetDrawColor(C("tabActive"))
        surface.DrawRect(0, math.floor(32 * s) - 2, cw, 2)
        draw.SimpleText(title, "RP1942_QTitle", pad, math.floor(16 * s), C("gold"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%d:%02d", math.floor(left / 60), math.ceil(left) % 60), "RP1942_QText", cw - pad, math.floor(16 * s),
            C("sub"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        -- time left, along the bottom edge
        local frac = math.Clamp(left / seconds, 0, 1)
        draw.RoundedBox(2, pad, ch - math.floor(5 * s), cw - pad * 2, math.max(2, math.floor(3 * s)), C("well"))
        draw.RoundedBox(2, pad, ch - math.floor(5 * s), math.floor((cw - pad * 2) * frac), math.max(2, math.floor(3 * s)), C("gold"))
    end
    card.Think = function(self)
        if CurTime() >= deadline then close(id) end
    end
    -- height follows the wrapped text
    card.PerformLayout = function(self)
        self:SizeToChildren(false, true)
        self:SetTall(self:GetTall() + pad)
        relayout()
    end

    open[id] = card
    order[#order + 1] = card
    LocalPlayer():EmitSound("Town.d1_town_02_elevbell1", 100, 100)
    relayout()
end

-- Take over DarkRP's question messages (same names: this module loads after DarkRP's)
usermessage.Hook("DoQuestion", function(msg)
    if not IsValid(LocalPlayer()) then return end
    local question, id, seconds = msg:ReadString(), msg:ReadString(), msg:ReadFloat()
    show(question, id, seconds)
end)

usermessage.Hook("KillQuestionVGUI", function(msg)
    close(msg:ReadString())
end)
