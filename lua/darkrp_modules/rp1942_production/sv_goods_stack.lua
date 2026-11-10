--[[---------------------------------------------------------------------------
42Bros - goods on the ground merge into crates (rp1942_goods_crate)

Two goods that touch become a crate, a good that touches a crate goes in,
and two crates that touch become one, like DarkRP's shipments. Only when
they're the same thing:

    the same good at the same quality
    the same owner (food and drink with a name on it), and the same F4 shop buyer
    not a Radio Set (each one is a working radio)
    nobody is carrying either of them
    at most CRATE_MAX in one crate

The crate keeps who last held the goods (who a market pays) and the latest
time they'd expire. Called from rp1942_good and rp1942_goods_crate's
PhysicsCollide, a tick after the bump.
---------------------------------------------------------------------------]]
local CRATE_MAX = 20

local function countOf(e) return e:GetClass() == "rp1942_goods_crate" and e:GetCount() or 1 end

function RP1942.canStackGoods(a, b)
    if not (IsValid(a) and IsValid(b)) or a == b then return false end
    for _, e in ipairs({ a, b }) do
        local class = e:GetClass()
        if class ~= "rp1942_good" and class ~= "rp1942_goods_crate" then return false end
        if e.RP1942_Sold or e.RP1942_Stacked or e:IsPlayerHolding() then return false end
        if (e.RP1942_NoStackUntil or 0) > CurTime() then return false end
    end
    if a:GetGood() ~= b:GetGood() or a:GetQuality() ~= b:GetQuality() then return false end
    local good = RP1942.Goods[a:GetGood()]
    if not good or good.radio or good.noStack then return false end
    if a:GetOwnerID() ~= b:GetOwnerID() then return false end
    if a.RP1942_ShopOwner ~= b.RP1942_ShopOwner then return false end
    return countOf(a) + countOf(b) <= CRATE_MAX
end

local function latest(x, y)
    if x and y then return math.max(x, y) end
    return x or y
end

-- Merge b into a (or both into a new crate). Returns the crate, or nil.
function RP1942.stackGoods(a, b)
    if not RP1942.canStackGoods(a, b) then return nil end
    -- the crate that stays: an existing one (the fuller), or a new one where a is
    if b:GetClass() == "rp1942_goods_crate" and (a:GetClass() ~= "rp1942_goods_crate" or b:GetCount() > a:GetCount()) then
        a, b = b, a
    end
    local total = countOf(a) + countOf(b)
    local holder = IsValid(b.RP1942_Holder) and b.RP1942_Holder or a.RP1942_Holder
    local expires = latest(a.RP1942_Expires, b.RP1942_Expires)
    if (a.RP1942_Expires == nil) ~= (b.RP1942_Expires == nil) then expires = nil end   -- one never expires: neither does the crate

    local crate = a
    if a:GetClass() ~= "rp1942_goods_crate" then
        crate = ents.Create("rp1942_goods_crate")
        if not IsValid(crate) then return nil end
        crate:SetGood(a:GetGood())
        crate:SetQuality(a:GetQuality())
        crate:SetOwnerID(a:GetOwnerID())
        crate:SetOwnerName(a:GetOwnerName())
        crate.RP1942_ShopOwner = a.RP1942_ShopOwner
        crate:SetPos(a:GetPos() + Vector(0, 0, 6))
        crate:SetAngles(Angle(0, a:GetAngles().y, 0))
        crate:SetCount(total)
        crate:Spawn()
        local owner = a.CPPIGetOwner and a:CPPIGetOwner()
        if IsValid(owner) and crate.CPPISetOwner then crate:CPPISetOwner(owner) end
        a.RP1942_Stacked = true
        a:Remove()
    else
        crate:SetCount(total)
    end
    crate.RP1942_Holder = holder
    crate.RP1942_Expires = expires
    b.RP1942_Stacked = true
    b:Remove()
    return crate
end
