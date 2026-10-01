--[[---------------------------------------------------------------------------
1942 DarkRP - padlocks (client): the lock's menu (Shift+E) and !doorlocks
---------------------------------------------------------------------------]]
local frame

local FACTION_NAMES = { reich = "the Reich", resistance = "the Resistance", civilian = "the civilians" }

local function edit(lock, action, arg)
    net.Start("RP1942_PadlockEdit")
    net.WriteEntity(lock)
    net.WriteString(action)
    net.WriteString(arg or "")
    net.SendToServer()
end

local function openMenu(d)
    local UI = RP1942.F4UI
    if not UI then return end
    local C = UI.C
    local s = UI.scale()
    local oldX, oldY
    if IsValid(frame) then oldX, oldY = frame:GetPos() frame:Remove() end

    local w, h = math.floor(440 * s), math.floor(560 * s)
    local pad = math.floor(12 * s)
    local titleH = math.floor(44 * s)
    frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    if oldX then frame:SetPos(oldX, oldY) else frame:Center() end
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    local title = d.lock:GetStaff() and "STAFF PADLOCK" or "PADLOCK"
    local sub = d.lock:GetStaff() and (d.saved and "saved on this map" or "not saved: !savelock") or d.lock:GetOwnerName()
    frame.Paint = function(_, fw, fh)
        draw.RoundedBox(8, 0, 0, fw, fh, C.bg)
        draw.RoundedBoxEx(8, 0, 0, fw, titleH, C.titleBar, true, true, false, false)
        surface.SetDrawColor(C.tabActive)
        surface.DrawRect(0, titleH - 2, fw, 2)
        draw.SimpleText(title, "RP1942_F4Title", pad, titleH / 2, C.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(sub, "RP1942_F4Small", fw - pad - math.floor(86 * s), titleH / 2, C.sub, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    frame.Think = function(f)
        if not IsValid(d.lock) or LocalPlayer():GetPos():DistToSqr(d.lock:GetPos()) > 400 * 400 then f:Remove() end
    end
    local close = UI.button(frame, "Close", function() frame:Remove() end)
    close:SetSize(math.floor(76 * s), math.floor(28 * s))
    close:SetPos(w - pad - close:GetWide(), math.floor((titleH - close:GetTall()) / 2))

    local body = vgui.Create("DScrollPanel", frame)
    body:SetPos(pad, titleH + pad)
    body:SetSize(w - pad * 2, h - titleH - pad * 2)
    UI.styleScroll(body)

    local function bar(text, right)
        local b = UI.categoryBar(body, text, right, C.tab)
        b:Dock(TOP)
        b:DockMargin(0, pad, 0, 4)
        b:SetTall(math.floor(28 * s))
    end
    local function toggle(label, on, fn)
        local b = UI.button(body, (on and "[x]  " or "[  ]  ") .. label, fn)
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 3)
        b:SetTall(math.floor(30 * s))
    end

    local intro = vgui.Create("DLabel", body)
    intro:Dock(TOP)
    intro:SetWrap(true)
    intro:SetAutoStretchVertical(true)
    intro:SetFont("RP1942_F4Body")
    intro:SetTextColor(C.sub)
    intro:SetText(d.lock:GetStaff()
        and "Nobody owns this lock. It opens for the groups and players ticked below. Lockpicks and rams work on it."
        or "You can always open your own door. Everyone else needs to be let in below; anyone else who presses E knocks.")

    -- Groups: the owner gets "my faction" / "my job"; staff get every group
    bar("WHO ELSE CAN OPEN IT")
    if d.isStaff then
        for _, g in ipairs(RP1942.padlockGroups()) do
            toggle("Anyone in " .. g.name, d.groups[g.id], function() edit(d.lock, "group", g.id) end)
        end
    elseif d.allowFaction and d.ownerFaction ~= "" then
        toggle("Anyone in " .. (FACTION_NAMES[d.ownerFaction] or d.ownerFaction), d.groups[d.ownerFaction], function() edit(d.lock, "group", d.ownerFaction) end)
    end
    -- jobs already on it (staff can see and untick them), and the owner's own job
    local shownJob = {}
    for cmd in pairs(d.jobs) do
        local job = RP1942.getJobByCommand(cmd)
        shownJob[cmd] = true
        toggle("Anyone working as " .. (job and job.name or cmd), true, function() edit(d.lock, "job", cmd) end)
    end
    if d.allowJob and d.ownerJob ~= "" and not shownJob[d.ownerJob] and (d.isOwner or d.isStaff) then
        toggle("Anyone working as " .. d.ownerJobName, false, function() edit(d.lock, "job", d.ownerJob) end)
    end

    -- Named players
    bar("PLAYERS", #d.players .. " / " .. d.maxAccess)
    for _, p in ipairs(d.players) do
        local row = UI.button(body, p.name .. "     (remove)", function() edit(d.lock, "removeplayer", p.sid) end)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 3)
        row:SetTall(math.floor(30 * s))
    end
    local add = UI.button(body, "+  Add a player", function()
        local menu = DermaMenu()
        local listed, any = {}, false
        for _, p in ipairs(d.players) do listed[p.sid] = true end
        for _, ply in ipairs(player.GetAll()) do
            local sid = ply:SteamID()
            if ply ~= d.lock:GetLockOwner() and not listed[sid] then
                any = true
                menu:AddOption(ply:Nick(), function() edit(d.lock, "addplayer", sid) end)
            end
        end
        if not any then menu:AddOption("Nobody else to add") end
        menu:Open()
    end, function() return #d.players < d.maxAccess end)
    add:Dock(TOP)
    add:SetTall(math.floor(30 * s))

    -- Remove the padlock
    bar("PADLOCK")
    local removing = false
    local rm = UI.button(body, function() return removing and "Click again to remove it" or "Remove the padlock" end, function()
        if not removing then removing = true return end
        edit(d.lock, "remove")
        frame:Remove()
    end)
    rm:Dock(TOP)
    rm:SetTall(math.floor(30 * s))
end

net.Receive("RP1942_PadlockMenu", function()
    local d = { lock = net.ReadEntity() }
    d.isOwner, d.isStaff = net.ReadBool(), net.ReadBool()
    d.allowFaction, d.allowJob = net.ReadBool(), net.ReadBool()
    d.maxAccess = net.ReadUInt(8)
    d.ownerFaction, d.ownerJob, d.ownerJobName = net.ReadString(), net.ReadString(), net.ReadString()
    d.saved = net.ReadBool()
    d.players = {}
    for i = 1, net.ReadUInt(8) do d.players[i] = { sid = net.ReadString(), name = net.ReadString() } end
    table.sort(d.players, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    d.groups = {}
    for _ = 1, net.ReadUInt(8) do d.groups[net.ReadString()] = true end
    d.jobs = {}
    for _ = 1, net.ReadUInt(8) do d.jobs[net.ReadString()] = true end
    if IsValid(d.lock) then openMenu(d) end
end)

--[[ !doorlocks: every lock, marked on screen for a minute -------------------]]
local markers, markersUntil = {}, 0
net.Receive("RP1942_PadlockMarkers", function()
    markers = {}
    for i = 1, net.ReadUInt(8) do markers[i] = { pos = net.ReadVector(), text = net.ReadString() } end
    markersUntil = CurTime() + 60
end)

hook.Add("HUDPaint", "RP1942_PadlockMarkers", function()
    if CurTime() > markersUntil or #markers == 0 then return end
    local eye = LocalPlayer():EyePos()
    for _, m in ipairs(markers) do
        local sp = m.pos:ToScreen()
        if sp.visible then
            local dist = math.floor(eye:Distance(m.pos) / 52.5)
            draw.RoundedBox(4, sp.x - 5, sp.y - 5, 10, 10, Color(201, 168, 92))
            draw.SimpleTextOutlined(m.text .. "  ·  " .. dist .. " m", "DermaDefaultBold", sp.x, sp.y - 10,
                Color(236, 228, 212), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 220))
        end
    end
end)
