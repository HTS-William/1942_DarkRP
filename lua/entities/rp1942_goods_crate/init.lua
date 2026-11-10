AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.CrateModel = "models/Items/item_item_crate.mdl"

function ENT:Initialize()
    self:SetModel(self.CrateModel)
    if self:GetQuality() < 1 then self:SetQuality(2) end
    if self:GetCount() < 1 then self:SetCount(1) end
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(30)   -- light enough to pocket (DarkRP: up to 100) and carry with Shift + E
        phys:Wake()
    end
end

-- The owner, if they're still on the server (otherwise it's free to take)
function ENT:OwnerOnline()
    local id = self:GetOwnerID()
    if id == "" then return nil end
    local owner = player.GetBySteamID(id)
    if IsValid(owner) then return owner end
    self:SetOwnerID("")
    self:SetOwnerName("")
end

-- One fewer in the crate. A crate never holds just one: the last one left
-- turns back into a plain good where the crate was.
function ENT:TakeFromCrate()
    local n = self:GetCount() - 1
    if n >= 2 then
        self:SetCount(n)
        return
    end
    self.RP1942_Stacked = true   -- (nothing merges into it from here on)
    if n == 1 then
        local good = RP1942.spawnGood(self:GetGood(), self:GetPos() + Vector(0, 0, 8), self:GetAngles(), self:GetQuality())
        if IsValid(good) then
            good:SetOwnerID(self:GetOwnerID())
            good:SetOwnerName(self:GetOwnerName())
            good.RP1942_Holder = self.RP1942_Holder
            good.RP1942_ShopOwner = self.RP1942_ShopOwner
            good.RP1942_Expires = self.RP1942_Expires
        end
    end
    self:Remove()
end

-- A single good of the crate's kind, made for ply (to go into their pocket)
local function oneOut(self, ply)
    local good = RP1942.spawnGood(self:GetGood(), ply:GetPos() + Vector(0, 0, 40), nil, self:GetQuality())
    if not IsValid(good) then return nil end
    good:SetOwnerID(self:GetOwnerID())
    good:SetOwnerName(self:GetOwnerName())
    good.RP1942_Holder = ply
    good.RP1942_ShopOwner = self.RP1942_ShopOwner
    good.RP1942_NoStackUntil = CurTime() + 2   -- (not straight back into a crate)
    return good
end

-- Someone else's food or drink: buy one (the same as rp1942_good's Buy)
function ENT:BuyOne(ply, seller)
    local info = self:GoodInfo()
    local price = self:SalePrice()
    if RP1942.pocketRoom(ply) <= 0 then
        return DarkRP.notify(ply, 1, 4, "Your pocket is full: make room before buying.")
    end
    if price > 0 and not ply:canAfford(price) then
        return DarkRP.notify(ply, 1, 4, info.name .. " costs " .. DarkRP.formatMoney(price) .. ": you can't afford it.")
    end
    local good = oneOut(self, ply)
    if not IsValid(good) then return end
    self:TakeFromCrate()
    ply:addMoney(-price)
    local net, tax = price, 0
    if RP1942.applyTax then net, tax = RP1942.applyTax(seller, price, "goods_sale") end
    seller:addMoney(net)
    good:SetOwnerPlayer(ply)
    if not RP1942.pocketOrLeave(ply, good) then good:SetPos(ply:GetPos() + Vector(0, 0, 40)) end
    local what = RP1942.qualityName(good:GetQuality()) .. " " .. info.name
    DarkRP.notify(ply, 0, 5, "Bought " .. what .. " from " .. seller:Nick() .. " for " .. DarkRP.formatMoney(price) .. ". It's in your pocket.")
    DarkRP.notify(seller, 0, 5, ply:Nick() .. " bought your " .. what .. ": " .. DarkRP.formatMoney(net)
        .. (tax > 0 and (" (" .. DarkRP.formatMoney(tax) .. " tax)") or "") .. ".")
    hook.Run("RP1942_GoodBought", ply, seller, good:GetGood(), good:GetQuality(), price)
end

function ENT:Use(ply)
    if not (IsValid(ply) and ply:IsPlayer()) or self.RP1942_Stacked or self.RP1942_Sold then return end
    local info = self:GoodInfo()
    if not info then return end

    -- someone else's food or drink: E buys one
    if info.eat and not self:IsOwnedBy(ply) then
        local seller = self:OwnerOnline()
        if seller then return self:BuyOne(ply, seller) end
    end
    -- Shift + E: carry the crate
    if ply:KeyDown(IN_SPEED) then
        self.RP1942_Holder = ply
        ply:PickupObject(self)
        return
    end

    -- E: one into your pocket
    if RP1942.pocketRoom(ply) <= 0 then
        return DarkRP.notify(ply, 1, 4, "Your pocket is full.")
    end
    local good = oneOut(self, ply)
    if not IsValid(good) then return end
    if info.eat and self:GetOwnerID() == "" then good:SetOwnerPlayer(ply) end
    local left = self:GetCount() - 1
    self:TakeFromCrate()
    if not RP1942.pocketOrLeave(ply, good) then good:SetPos(ply:GetPos() + Vector(0, 0, 40)) end
    DarkRP.notify(ply, 0, 3, "Took " .. RP1942.qualityName(good:GetQuality()) .. " " .. info.name .. " (" .. left .. " left).")
end

-- Pushed into a market: everything in it is sold. Into another crate or a
-- good of the same kind: merged (a tick later, never inside the physics callback).
function ENT:PhysicsCollide(data)
    local other = data.HitEntity
    if not IsValid(other) or self.RP1942_Sold or self.RP1942_Stacked then return end
    local class = other:GetClass()
    if class == "rp1942_market" then
        timer.Simple(0, function()
            if IsValid(self) and RP1942.sellGoodEntity then RP1942.sellGoodEntity(self) end
        end)
    elseif class == "rp1942_good" or class == "rp1942_goods_crate" then
        timer.Simple(0, function() if RP1942.stackGoods then RP1942.stackGoods(self, other) end end)
    end
end
