--[[---------------------------------------------------------------------------
1942 DarkRP - RP1942.Floater: floating world labels (client)

A base class for any 3D2D panel that floats over an entity (dumpsters,
ovens, oil rigs, door locks...). It handles the shared parts:
    position above the entity, facing, scale,
    a distance cutoff (not drawn at all past maxDist),
    a fade-out over the last fadeDist units so it doesn't pop,
    and cleanup if a label's Paint errors.

A label only has to say WHAT to draw:

    local MyLabel = RP1942.Floater:extend{
        offset  = Vector(0, 0, 50),   -- above the entity's origin (world up)
        maxDist = 400,                -- not drawn beyond this (units, ~52 = 1 m)
    }

    function MyLabel:Paint(ent, alpha)
        draw.DrawText("Hello", "DermaLarge", 0, 0, color_white, TEXT_ALIGN_CENTER)
    end

    -- in the entity's cl_init.lua:
    function ENT:Draw()
        self:DrawModel()
        MyLabel:Draw(self)
    end

FIELDS (defaults below, override in extend{} or new{}):
    offset     Vector   position relative to the entity origin
    scale      number   3D2D scale (0.1 = 10 pixels per unit)
    maxDist    number   beyond this distance nothing is drawn
    fadeDist   number   fades out over this many units before maxDist
    billboard  bool     true = always faces the player, false = fixed to the entity

OVERRIDABLE METHODS:
    Paint(ent, alpha)         required: draw at 3D2D origin (0, 0)
    ShouldDraw(ent)           extra condition, e.g. only when a variable is set
    GetDrawPos(ent)           where the panel sits
    GetDrawAngles(ent)        how it is oriented

Classes chain: RP1942.Floater:extend{} -> MyLabel:extend{} -> ...
Use Label:new{ maxDist = 800 } for a one-off variant without a new class.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local Floater = {
    offset    = Vector(0, 0, 50),
    scale     = 0.1,
    maxDist   = 400,
    fadeDist  = 100,
    billboard = true,
}
Floater.__index = Floater

-- Create a subclass. Missing fields and methods fall back to the parent.
function Floater:extend(fields)
    local class = fields or {}
    class.__index = class
    class.super = self
    return setmetatable(class, self)
end

-- Create an instance (optional: classes can be used directly, since a label
-- keeps no per-entity state; the entity is passed in every call).
function Floater:new(fields)
    return setmetatable(fields or {}, self)
end

-- Overridable ----------------------------------------------------------------
function Floater:Paint(ent, alpha)
end

function Floater:ShouldDraw(ent)
    return true
end

function Floater:GetDrawPos(ent)
    return ent:GetPos() + self.offset
end

function Floater:GetDrawAngles(ent)
    if self.billboard then
        return Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
    end

    local ang = ent:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    return ang
end

-- 1 when close, fading to 0 across the last fadeDist units, 0 beyond maxDist
function Floater:GetAlpha(pos)
    local distSqr = LocalPlayer():EyePos():DistToSqr(pos)
    if distSqr >= self.maxDist * self.maxDist then return 0 end   -- cheap early out

    local fadeStart = self.maxDist - self.fadeDist
    if self.fadeDist <= 0 or distSqr <= fadeStart * fadeStart then return 1 end

    return 1 - (math.sqrt(distSqr) - fadeStart) / self.fadeDist
end

-- Not meant to be overridden: the shared drawing sequence ---------------------
function Floater:Draw(ent)
    if not IsValid(ent) or not self:ShouldDraw(ent) then return end

    local pos = self:GetDrawPos(ent)
    local alpha = self:GetAlpha(pos)
    if alpha <= 0 then return end

    cam.Start3D2D(pos, self:GetDrawAngles(ent), self.scale)
        surface.SetAlphaMultiplier(alpha)
        -- Protected so a broken label can't leave the alpha multiplier set or
        -- the 3D2D context open, which would break all rendering after it
        local ok, err = pcall(self.Paint, self, ent, alpha)
        surface.SetAlphaMultiplier(1)
    cam.End3D2D()

    -- Report each distinct error once, not every frame
    if not ok and err ~= self._lastError then
        self._lastError = err
        ErrorNoHalt("[1942] Floater Paint error on " .. tostring(ent) .. ": " .. tostring(err) .. "\n")
    end
end

RP1942.Floater = Floater
