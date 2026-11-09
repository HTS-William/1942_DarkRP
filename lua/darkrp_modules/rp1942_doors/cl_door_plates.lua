--[[---------------------------------------------------------------------------
42Bros - who owns a door, shown on the door itself (client)

A box on both faces of every ownable door, at about chest height, instead of
DarkRP's text in the middle of the screen when you look at a door:

    Owned By: Anna Weber        a player's door (plain black box)
    Owned By: Reich             a faction door (!factiondoor), in the
                                faction's colour (sh_doors.lua: color)
    For Sale: $30               nobody owns it yet
    F2 to buy

A door title set with /title shows as a small line above "Owned By".
Doors that can't be owned get nothing, so the map's own doors stay as they
are. Vehicles keep DarkRP's normal text.

It reads the door's DarkRP data every frame, so buying, selling, /title and
faction changes show straight away. Nothing new is saved or sent.
---------------------------------------------------------------------------]]
local CFG = {
    drawWithin   = 420,   -- units: drawn up to here (about 8 m)...
    fadeFrom     = 300,   -- ...fading out from here
    rescan       = 0.5,   -- seconds between looks for doors nearby
    playerAlpha  = 0.6,   -- the box's opacity on a player's door (0-1)
    factionAlpha = 0.7,   -- and on a faction door
    height       = 56,    -- units above the bottom of the door
    surfaceGap   = 0.6,   -- how far off the door's surface, so it never sinks in
    maxScale     = 0.075, -- size of the text on the door (units per pixel)
}

surface.CreateFont("RP1942_DoorPlate",      { font = "Roboto", extended = true, size = 48, weight = 600 })
surface.CreateFont("RP1942_DoorPlateSmall", { font = "Roboto", extended = true, size = 32, weight = 500 })

local DOOR_CLASSES = { prop_door_rotating = true, func_door = true, func_door_rotating = true }

local WHITE, GREY = Color(255, 255, 255), Color(205, 205, 205)

-- "Owned By: Reich" -> the group's colour from RP1942.FactionDoors
local groupColor = {}
local function colorForGroup(name)
    if groupColor[name] == nil then
        groupColor[name] = false
        for _, g in ipairs((RP1942.FactionDoors and RP1942.FactionDoors.groups) or {}) do
            if g.name == name and g.color then groupColor[name] = g.color break end
        end
    end
    return groupColor[name] or nil
end

-- What the box says, or nil for no box
local function plateFor(door)
    local title = door:getKeysTitle()
    if title == "" then title = nil end

    local owner = door:getDoorOwner()
    if IsValid(owner) then
        return { title = title, line = "Owned By: " .. owner:Nick() }
    end

    local group = door:getKeysDoorGroup()
    if group then
        return { title = title, line = "Owned By: " .. group, color = colorForGroup(group) }
    end

    local teams = door:getKeysDoorTeams()
    if teams then
        local names, color = {}, nil
        for teamNr, on in pairs(teams) do
            local job = on and RPExtraTeams[teamNr]
            if job then
                names[#names + 1] = job.name
                color = color or job.color
            end
        end
        table.sort(names)
        if #names > 2 then names = { names[1], names[2] .. " +" .. (#names - 2) } end
        if #names > 0 then
            return { title = title, line = "Owned By: " .. table.concat(names, ", "), color = color }
        end
    end

    if door:getKeysNonOwnable() then return nil end

    local cost = GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.doorcost or 0
    return { title = title, line = cost > 0 and ("For Sale: " .. DarkRP.formatMoney(cost)) or "For Sale", sub = "F2 to buy" }
end

--[[---------------------------------------------------------------------------
Where the box goes: the door's thinnest axis is its thickness, the axis
closest to straight up is its height, the one left is its width. Worked out
once per model and kept.
---------------------------------------------------------------------------]]
local shapes = {}
local function shapeOf(door)
    local key = (door:GetModel() or "") .. "|" .. door:GetClass()
    if shapes[key] then return shapes[key] end
    local mins, maxs = door:OBBMins(), door:OBBMaxs()
    local size = maxs - mins
    if size.x <= 0 or size.y <= 0 or size.z <= 0 then return nil end

    -- local axis closest to the door's up (doors are upright: their local z, unless the map says otherwise)
    local up = 3
    local axes = { door:GetForward(), -door:GetRight(), door:GetUp() }
    local best = -1
    for i = 1, 3 do
        local d = math.abs(axes[i].z)
        if d > best then best, up = d, i end
    end
    local others = {}
    for i = 1, 3 do if i ~= up then others[#others + 1] = i end end
    local sz = { size.x, size.y, size.z }
    local thin, wide = others[1], others[2]
    if sz[thin] > sz[wide] then thin, wide = wide, thin end

    local s = { mins = mins, maxs = maxs, thin = thin, wide = wide, up = up, width = sz[wide], height = sz[up] }
    shapes[key] = s
    return s
end

local function axisSet(v, i, value)
    if i == 1 then v.x = value elseif i == 2 then v.y = value else v.z = value end
end
local function axisGet(v, i)
    if i == 1 then return v.x elseif i == 2 then return v.y end
    return v.z
end

-- The two faces: { pos, normal } in the world, front and back
local function facesOf(door, s)
    local center = (s.mins + s.maxs) * 0.5
    local h = math.min(CFG.height, s.height * 0.6)
    -- "up" may run either way along its axis: measure from whichever end is lower in the world
    local lowEnd, highEnd = Vector(center), Vector(center)
    axisSet(lowEnd, s.up, axisGet(s.mins, s.up))
    axisSet(highEnd, s.up, axisGet(s.maxs, s.up))
    local bottomIsMin = door:LocalToWorld(lowEnd).z <= door:LocalToWorld(highEnd).z
    axisSet(center, s.up, bottomIsMin and (axisGet(s.mins, s.up) + h) or (axisGet(s.maxs, s.up) - h))

    local worldCenter = door:LocalToWorld(center)
    local faces = {}
    for _, side in ipairs({ axisGet(s.maxs, s.thin) + CFG.surfaceGap, axisGet(s.mins, s.thin) - CFG.surfaceGap }) do
        local p = Vector(center)
        axisSet(p, s.thin, side)
        local wp = door:LocalToWorld(p)
        local n = wp - worldCenter
        if n:LengthSqr() > 0 then
            n:Normalize()
            faces[#faces + 1] = { pos = wp, normal = n }
        end
    end
    return faces
end

--[[---------------------------------------------------------------------------
Drawing
---------------------------------------------------------------------------]]
local doors = {}
local nextScan = 0

local function scan()
    local lp = LocalPlayer()
    doors = {}
    for _, e in ipairs(ents.FindInSphere(lp:EyePos(), CFG.drawWithin + 60)) do
        if IsValid(e) and DOOR_CLASSES[e:GetClass()] and e.isKeysOwnable and e:isKeysOwnable() then
            doors[#doors + 1] = e
        end
    end
end

local PAD_X, PAD_Y, GAP = 28, 16, 6

-- Width of the box in pixels (its widest line plus padding)
local function boxWidth(plate)
    surface.SetFont("RP1942_DoorPlate")
    local w = surface.GetTextSize(plate.line)
    surface.SetFont("RP1942_DoorPlateSmall")
    if plate.title then w = math.max(w, (surface.GetTextSize(plate.title))) end
    if plate.sub then w = math.max(w, (surface.GetTextSize(plate.sub))) end
    return w + PAD_X * 2
end

local function drawBox(plate, alpha)
    surface.SetFont("RP1942_DoorPlate")
    local lw, lh = surface.GetTextSize(plate.line)
    local tw, th, sw, shh = 0, 0, 0, 0
    if plate.title then
        surface.SetFont("RP1942_DoorPlateSmall")
        tw, th = surface.GetTextSize(plate.title)
    end
    if plate.sub then
        surface.SetFont("RP1942_DoorPlateSmall")
        sw, shh = surface.GetTextSize(plate.sub)
    end
    local padX, padY, gap = PAD_X, PAD_Y, GAP
    local w = math.max(lw, tw, sw) + padX * 2
    local h = lh + padY * 2 + (plate.title and (th + gap) or 0) + (plate.sub and (shh + gap) or 0)
    local x, y = -w / 2, -h / 2

    local c = plate.color or color_black
    local a = (plate.color and CFG.factionAlpha or CFG.playerAlpha) * 255 * alpha
    draw.RoundedBox(6, x, y, w, h, Color(c.r, c.g, c.b, a))

    local ty = y + padY
    if plate.title then
        draw.SimpleText(plate.title, "RP1942_DoorPlateSmall", 0, ty, Color(GREY.r, GREY.g, GREY.b, 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        ty = ty + th + gap
    end
    draw.SimpleText(plate.line, "RP1942_DoorPlate", 0, ty, Color(WHITE.r, WHITE.g, WHITE.b, 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    ty = ty + lh + gap
    if plate.sub then
        draw.SimpleText(plate.sub, "RP1942_DoorPlateSmall", 0, ty, Color(GREY.r, GREY.g, GREY.b, 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

hook.Add("PostDrawTranslucentRenderables", "RP1942_DoorPlates", function(depth, sky)
    if depth or sky then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local now = RealTime()
    if now >= nextScan then
        nextScan = now + CFG.rescan
        scan()
    end

    local eye = EyePos()
    for _, door in ipairs(doors) do
        if IsValid(door) and not door:IsDormant() then
            local plate = plateFor(door)
            local s = plate and shapeOf(door)
            if s then
                for _, face in ipairs(facesOf(door, s)) do
                    local toEye = eye - face.pos
                    local dist = toEye:Length()
                    -- only the face turned towards you, and only near enough
                    if dist < CFG.drawWithin and toEye:Dot(face.normal) > 0 then
                        local alpha = 1
                        if dist > CFG.fadeFrom then alpha = 1 - (dist - CFG.fadeFrom) / (CFG.drawWithin - CFG.fadeFrom) end
                        -- the box faces out of the door, upright, reading left to right
                        -- (the same angle the padlock's text uses to face the viewer)
                        local ang = Angle(0, face.normal:Angle().y + 90, 90)
                        -- shrink a long name to fit the door's width
                        local scale = math.min(CFG.maxScale, (s.width * 0.9) / boxWidth(plate))
                        cam.Start3D2D(face.pos, ang, scale)
                            drawBox(plate, alpha)
                        cam.End3D2D()
                    end
                end
            end
        end
    end
end)

-- DarkRP's own look-at text is replaced on doors (vehicles keep it)
hook.Add("HUDDrawDoorData", "RP1942_DoorPlates", function(ent)
    if IsValid(ent) and DOOR_CLASSES[ent:GetClass()] then return true end
end)
