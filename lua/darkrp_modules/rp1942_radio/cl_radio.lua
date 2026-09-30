--[[---------------------------------------------------------------------------
1942 DarkRP - Radio (client): the tuning menu (press E on a radio)
---------------------------------------------------------------------------]]
local frame

local function send(radio, url, name, volume)
    net.Start("RP1942_RadioTune")
    net.WriteEntity(radio)
    net.WriteString(url or "")
    net.WriteString(name or "")
    net.WriteFloat(volume or 1)
    net.SendToServer()
end

local function open(radio)
    if IsValid(frame) then frame:Remove() end
    local UI, C = RP1942.F4UI, RP1942.F4UI and RP1942.F4UI.C
    if not UI then return end
    local s = UI.scale()
    local w, h = math.floor(460 * s), math.floor(520 * s)
    local pad = math.floor(12 * s)

    frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    RP1942.F4Panel = frame   -- UI.textEntry hands the keyboard to this panel while typing
    local titleH = math.floor(44 * s)
    frame.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(8, 0, 0, w, titleH, C.titleBar, true, true, false, false)
        surface.SetDrawColor(C.tabActive)
        surface.DrawRect(0, titleH - 2, w, 2)
        draw.SimpleText("RADIO", "RP1942_F4Title", pad, titleH / 2, C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local now = IsValid(radio) and radio:GetStation() or ""
        draw.SimpleText(now ~= "" and ("Now: " .. now) or "Off", "RP1942_F4Small", w - pad, titleH / 2, C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    frame.Think = function(f)
        if not IsValid(radio) or LocalPlayer():GetPos():DistToSqr(radio:GetPos()) > 300 * 300 then f:Remove() end
    end
    frame.OnRemove = function() if RP1942.F4Panel == frame then RP1942.F4Panel = nil end end

    local close = UI.button(frame, "Close", function() frame:Remove() end)
    close:SetSize(math.floor(80 * s), math.floor(28 * s))
    close:SetPos(w - pad - math.floor(80 * s), math.floor((titleH - 28 * s) / 2))

    local body = vgui.Create("DPanel", frame)
    body:SetPos(pad, titleH + pad)
    body:SetSize(w - pad * 2, h - titleH - pad * 2)
    body:SetPaintBackground(false)

    -- Volume knob (the set's own; each player also has rp1942_radio_volume)
    local volLabel = vgui.Create("DLabel", body)
    volLabel:SetFont("RP1942_F4Head")
    volLabel:SetTextColor(C.text)
    volLabel:SetText("Volume")
    volLabel:Dock(TOP)
    volLabel:SetTall(math.floor(26 * s))
    local vol = vgui.Create("DNumSlider", body)
    vol:Dock(TOP)
    vol:SetTall(math.floor(30 * s))
    vol:SetMin(0) vol:SetMax(1) vol:SetDecimals(2)
    vol:SetValue(IsValid(radio) and radio:GetVolume() or 1)
    vol:SetText("")
    vol.Label:SetVisible(false)
    vol.TextArea:SetTextColor(C.text)
    vol.OnValueChanged = function(_, v)
        if not IsValid(radio) or radio:GetURL() == "" then return end
        -- sent a moment after the knob stops moving
        timer.Create("RP1942_RadioVol", 0.4, 1, function()
            if IsValid(radio) then send(radio, radio:GetURL(), radio:GetStation(), v) end
        end)
    end

    -- Custom link
    local linkBar = UI.categoryBar(body, "STREAM LINK", "http(s)://... straight to the stream", C.tab)
    linkBar:Dock(TOP)
    linkBar:DockMargin(0, pad, 0, 4)
    linkBar:SetTall(math.floor(28 * s))
    local entry = UI.textEntry(body, "", function(text)
        send(radio, text, "", vol:GetValue())
    end)
    entry:Dock(TOP)
    entry:SetPlaceholderText("Paste a stream link and press Enter")

    -- Stations
    local bar = UI.categoryBar(body, "STATIONS", nil, C.tab)
    bar:Dock(TOP)
    bar:DockMargin(0, pad, 0, 4)
    bar:SetTall(math.floor(28 * s))
    local list = vgui.Create("DScrollPanel", body)
    list:Dock(FILL)
    UI.styleScroll(list)
    local function stationButton(text, url, name, isCurrent)
        local b = UI.button(list, text, function() send(radio, url, name, vol:GetValue()) end)
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 3)
        b:SetTall(math.floor(32 * s))
        local base = b.Paint
        b.Paint = function(btn, bw, bh)
            base(btn, bw, bh)
            if isCurrent() then
                surface.SetDrawColor(C.gold)
                surface.DrawRect(0, 0, 4, bh)
            end
        end
    end
    stationButton("Off", "", "", function() return IsValid(radio) and radio:GetURL() == "" end)
    for _, st in ipairs(RP1942.Radio.stations) do
        stationButton(st.name, st.url, st.name, function() return IsValid(radio) and radio:GetURL() == st.url end)
    end
end

net.Receive("RP1942_RadioOpen", function()
    local radio = net.ReadEntity()
    if IsValid(radio) then open(radio) end
end)
