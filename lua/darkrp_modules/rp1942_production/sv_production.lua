--[[---------------------------------------------------------------------------
1942 DarkRP - production (server): goods, selling, the economy nudge, markets

    RP1942.spawnGood(goodId, pos, ang)  -> a good lying at pos
    RP1942.sellGoods(ply, goodIds)      -> pays ply for a list of good ids at market price
    RP1942.nudgeEconomy(points)         -> push the economy bar (fractions add up)
---------------------------------------------------------------------------]]
local CFG = RP1942.Production
util.AddNetworkString("RP1942_Drunk")
util.AddNetworkString("RP1942_PanelPress")
util.AddNetworkString("RP1942_PocketGoods")

--[[---------------------------------------------------------------------------
Panel buttons (look + E). The client says which entity and which button; the
entity's ENT:OnPanelPress(ply, id) does the rest and checks what it needs.
Here: it must be close, alive, and not spamming.
---------------------------------------------------------------------------]]
net.Receive("RP1942_PanelPress", function(_, ply)
    local ent, id = net.ReadEntity(), net.ReadString()
    if not (IsValid(ply) and ply:Alive() and IsValid(ent) and ent.OnPanelPress) then return end
    if #id > 40 then return end
    local now = CurTime()
    if (ply.RP1942_NextPanel or 0) > now then return end
    ply.RP1942_NextPanel = now + 0.25
    local reach = (CFG.useDistance or 120) + 60   -- a little slack for lag and big props
    if ply:EyePos():DistToSqr(ent:WorldSpaceCenter()) > reach * reach then return end
    ent:OnPanelPress(ply, id)
end)

--[[---------------------------------------------------------------------------
Machine power (ovens, derricks, factory lines). Switching off pauses the
machine: its clocks stop where they are (ENT:Now() returns the moment it was
switched off). Switching on moves the listed timestamps on by however long
it was off, so it carries on as if nothing happened.
The entity needs NetworkVars "Off" (Bool) and "PausedAt" (Float).
Returns true if it changed.
---------------------------------------------------------------------------]]
function RP1942.setMachinePower(ent, on, fields)
    if on == not ent:GetOff() then return false end
    local now = CurTime()
    if on then
        local d = now - ent:GetPausedAt()
        for _, f in ipairs(fields or {}) do
            local v = ent["Get" .. f](ent)
            if v and v > 0 then ent["Set" .. f](ent, v + d) end
        end
        ent:SetPausedAt(0)
        ent:SetOff(false)
    else
        ent:SetPausedAt(now)
        ent:SetOff(true)
    end
    return true
end

--[[---------------------------------------------------------------------------
Goods
---------------------------------------------------------------------------]]
function RP1942.spawnGood(goodId, pos, ang, quality)
    if not RP1942.Goods[goodId] then return end
    local ent = ents.Create("rp1942_good")
    if not IsValid(ent) then return end
    ent:SetGood(goodId)
    ent:SetQuality(math.Clamp(quality or 2, 1, 3))
    ent:SetPos(pos)
    ent:SetAngles(ang or Angle(0, math.random(0, 359), 0))
    ent:Spawn()

    if (CFG.goodsLifetime or 0) > 0 then
        ent.RP1942_Expires = CurTime() + CFG.goodsLifetime
    end
    return ent
end

--[[---------------------------------------------------------------------------
Hand goods to a player: into their pocket while there's room, the rest put
down at dropPos (e.g. on top of the oven). Returns pocketed, dropped.
---------------------------------------------------------------------------]]
function RP1942.giveGoods(ply, goodId, quality, count, dropPos)
    local pocketed, dropped = 0, 0
    for i = 1, count do
        local ent = RP1942.spawnGood(goodId, dropPos + Vector((i - 2) * 6, 0, i * 4), nil, quality)
        if IsValid(ent) then
            ent.RP1942_Holder = ply
            if RP1942.pocketOrLeave and RP1942.pocketOrLeave(ply, ent) then
                pocketed = pocketed + 1
            else
                dropped = dropped + 1
            end
        end
    end
    return pocketed, dropped
end

-- Remember who last had their hands on a good: that's who a market pays
local function holder(ply, ent)
    if RP1942.goodOf(ent) and IsValid(ply) and ply:IsPlayer() then
        ent.RP1942_Holder = ply
        ent.RP1942_Expires = CFG.goodsLifetime > 0 and (CurTime() + CFG.goodsLifetime) or nil
    end
end
hook.Add("GravGunOnPickedUp", "RP1942_GoodsHolder", holder)
hook.Add("PhysgunPickup", "RP1942_GoodsHolder", function(ply, ent) holder(ply, ent) end)   -- no return: doesn't change who may pick up
hook.Add("OnPlayerPhysicsPickup", "RP1942_GoodsHolder", holder)
hook.Add("onPocketItemDropped", "RP1942_GoodsHolder", function(ply, ent) holder(ply, ent) end)

-- Goods left lying around too long disappear (checked every 30 s, cheap)
timer.Create("RP1942_GoodsLifetime", 30, 0, function()
    local now = CurTime()
    for _, ent in ipairs(ents.FindByClass("rp1942_good")) do
        if ent.RP1942_Expires and ent.RP1942_Expires < now and not ent:IsPlayerHolding() then
            ent:Remove()
        end
    end
end)

--[[---------------------------------------------------------------------------
The goods in a player's pocket, as "good|quality" = count. DarkRP only tells
the client each pocket item's model, so the market board gets this summary
from us whenever the pocket changes.
---------------------------------------------------------------------------]]
local function pocketGoods(ply)
    local list = {}
    for index, item in pairs(ply.darkRPPocket or {}) do
        local id = item.Class == "rp1942_good" and item.DT and item.DT.Good
        if id and RP1942.Goods[id] then
            list[#list + 1] = { index = index, id = id, q = math.Clamp(tonumber(item.DT.Quality) or 2, 1, 3) }
        end
    end
    return list
end

local function sendPocketGoods(ply)
    if not IsValid(ply) then return end
    local counts = {}
    for _, g in ipairs(pocketGoods(ply)) do
        local key = g.id .. "|" .. g.q
        counts[key] = (counts[key] or 0) + 1
    end
    net.Start("RP1942_PocketGoods")
    net.WriteTable(counts)
    net.Send(ply)
end
local function pocketChanged(ply) timer.Simple(0, function() sendPocketGoods(ply) end) end
hook.Add("onPocketItemAdded", "RP1942_PocketGoods", pocketChanged)
hook.Add("onPocketItemRemoved", "RP1942_PocketGoods", pocketChanged)
hook.Add("PlayerInitialSpawn", "RP1942_PocketGoods", function(ply) timer.Simple(5, function() sendPocketGoods(ply) end) end)

--[[---------------------------------------------------------------------------
The economy nudge. Only MARKET sales call this; private sales between
players don't touch the economy.
---------------------------------------------------------------------------]]
local pending = 0

function RP1942.nudgeEconomy(points)
    if not RP1942.addEconomy then return end
    pending = pending + (points or 0)
    local whole = math.floor(pending)
    if whole >= 1 then
        pending = pending - whole
        RP1942.addEconomy(whole, "market sales")
    end
end

--[[---------------------------------------------------------------------------
Demand: every demandEvery seconds one good is "in demand" (sells for more),
and the market's trend arrows start again from the economy at that moment.
---------------------------------------------------------------------------]]
local function pickDemand()
    local ids, current = table.GetKeys(RP1942.Goods), RP1942.goodInDemand()
    if #ids > 1 then table.RemoveByValue(ids, current) end
    SetGlobal2String("RP1942_Demand", ids[math.random(#ids)] or "")
    SetGlobal2Int("RP1942_EconSnapshot", RP1942.getEconomy and RP1942.getEconomy() or 0)
end
hook.Add("InitPostEntity", "RP1942_MarketDemand", function()
    pickDemand()
    timer.Create("RP1942_MarketDemand", math.max(CFG.market.demandEvery or 3600, 60), 0, pickDemand)
end)

--[[---------------------------------------------------------------------------
Selling at a market. items = { { id = "bread", q = 2 }, ... }
(plain good ids are accepted too, as 2-star goods)
---------------------------------------------------------------------------]]
function RP1942.sellGoods(ply, items)
    if not IsValid(ply) or #items == 0 then return 0 end

    local gross, points, counts, order = 0, 0, {}, {}
    for _, item in ipairs(items) do
        if isstring(item) then item = { id = item, q = 2 } end
        local good = RP1942.Goods[item.id]
        if good then
            gross = gross + RP1942.marketPrice(item.id, item.q)
            points = points + (good.economy or 0)
            local key = item.id .. "|" .. item.q
            if not counts[key] then order[#order + 1] = { key = key, id = item.id, q = item.q } end
            counts[key] = (counts[key] or 0) + 1
        end
    end
    if gross <= 0 then return 0 end

    local net, tax = gross, 0
    if RP1942.applyTax then net, tax = RP1942.applyTax(ply, gross, "goods_sale") end
    ply:addMoney(net)
    RP1942.nudgeEconomy(points)

    local parts = {}
    for _, o in ipairs(order) do
        parts[#parts + 1] = counts[o.key] .. "x " .. RP1942.qualityName(o.q) .. " " .. RP1942.Goods[o.id].name
    end
    DarkRP.notify(ply, 0, 5, "Sold " .. table.concat(parts, ", ") .. " for " .. DarkRP.formatMoney(net)
        .. (tax > 0 and (" (" .. DarkRP.formatMoney(tax) .. " tax)") or "") .. ".")
    hook.Run("RP1942_GoodsSold", ply, items, net, tax)
    return net
end

-- A good pushed into a market: sold for whoever last held it
function RP1942.sellGoodEntity(ent)
    local id = RP1942.goodOf(ent)
    if not id or ent.RP1942_Sold then return end
    local ply = ent.RP1942_Holder
    if not IsValid(ply) then return end   -- nobody to pay: leave it
    ent.RP1942_Sold = true
    local q = ent:GetQuality()
    ent:Remove()
    RP1942.sellGoods(ply, { { id = id, q = q } })
end

-- Sell goods from a player's pocket: all of them, or only one good (and quality)
function RP1942.sellPocketGoods(ply, onlyId, onlyQ)
    local items = {}
    for _, g in ipairs(pocketGoods(ply)) do
        if (not onlyId or g.id == onlyId) and (not onlyQ or g.q == onlyQ) then
            items[#items + 1] = { id = g.id, q = g.q }
            ply:removePocketItem(g.index)
        end
    end
    if #items == 0 then
        DarkRP.notify(ply, 1, 5, "You have no goods like that in your pocket. Pocket goods first, or push them into the market.")
        return
    end
    RP1942.sellGoods(ply, items)
end

--[[---------------------------------------------------------------------------
Markets: placed in game with !addmarket, saved per map in
data/rp1942/markets_<map>.json
---------------------------------------------------------------------------]]
local SAVE_DIR = "rp1942"
local function saveFile() return SAVE_DIR .. "/markets_" .. game.GetMap() .. ".json" end
local function loadSaved()
    local raw = file.Read(saveFile(), "DATA")
    return raw and util.JSONToTable(raw) or {}
end
local function writeSaved(list)
    file.CreateDir(SAVE_DIR)
    file.Write(saveFile(), util.TableToJSON(list, true))
end

local function spawnMarket(pos, yaw, saveId)
    local m = ents.Create("rp1942_market")
    if not IsValid(m) then return end
    m:SetPos(pos)
    m:SetAngles(Angle(0, yaw, 0))
    m:Spawn()
    m.saveId = saveId
    local phys = m:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    return m
end

local function spawnSavedMarkets()
    for id, v in pairs(loadSaved()) do
        spawnMarket(Vector(v.x, v.y, v.z), v.yaw, id)
    end
end
hook.Add("InitPostEntity", "RP1942_Markets", spawnSavedMarkets)
hook.Add("PostCleanupMap", "RP1942_Markets", spawnSavedMarkets)

local function allowed(ply, access)
    if RP1942.staffCan(ply, access, CFG.market.adminCheck) then return true end
    DarkRP.notify(ply, 1, 4, "You aren't allowed to place markets.")
    return false
end

RP1942.defineStaffCommand("addmarket", function(ply)
    if not allowed(ply, "ulx addmarket") then return "" end
    local tr = ply:GetEyeTrace()
    if not tr.Hit or tr.HitPos:Distance(ply:EyePos()) > 400 then
        DarkRP.notify(ply, 1, 4, "Look at the floor where the market should go.")
        return ""
    end
    local yaw = ply:EyeAngles().y + 180   -- facing you
    local m = spawnMarket(tr.HitPos + Vector(0, 0, 4), yaw)
    if not IsValid(m) then return "" end
    m:DropToFloor()

    local list = loadSaved()
    local id = tostring(os.time()) .. "_" .. math.random(1000, 9999)
    local pos = m:GetPos()
    list[id] = { x = pos.x, y = pos.y, z = pos.z, yaw = yaw }
    writeSaved(list)
    m.saveId = id
    DarkRP.notify(ply, 0, 5, "Market placed and saved for this map.")
    ServerLog(string.format("[1942] %s placed a market at %s\n", ply:Nick(), tostring(pos)))
    return ""
end)

RP1942.defineStaffCommand("removemarket", function(ply)
    if not allowed(ply, "ulx removemarket") then return "" end
    local tr = ply:GetEyeTrace()
    local m = tr.Entity
    if not IsValid(m) or m:GetClass() ~= "rp1942_market" or tr.HitPos:Distance(ply:EyePos()) > 400 then
        DarkRP.notify(ply, 1, 4, "Look at a market to remove it.")
        return ""
    end
    if m.saveId then
        local list = loadSaved()
        list[m.saveId] = nil
        writeSaved(list)
    end
    ServerLog(string.format("[1942] %s removed a market at %s\n", ply:Nick(), tostring(m:GetPos())))
    m:Remove()
    DarkRP.notify(ply, 0, 5, "Market removed.")
    return ""
end)

-- Warn once at startup about models that aren't installed
hook.Add("InitPostEntity", "RP1942_ProductionCheck", function()
    local function check(model, what)
        if model and not util.IsValidModel(model) then
            MsgC(Color(255, 180, 60), "[1942] Production: the " .. what .. " model '" .. model .. "' isn't installed; it will show as an error model.\n")
        end
    end
    for id, g in pairs(RP1942.Goods) do
        for _, m in ipairs(istable(g.model) and g.model or { g.model }) do check(m, id) end
    end
    check(CFG.oven.model, "oven"); check(CFG.flour.model, "flour"); check(CFG.wine.model, "wine barrel"); check(CFG.market.model, "market")
    check(CFG.oil.model, "oil derrick"); check(CFG.factory.model, "factory")
    if #table.GetKeys(loadSaved()) == 0 then
        MsgC(Color(255, 180, 60), "[1942] Production: no markets on this map yet. Place some with !addmarket.\n")
    end
end)
