--[[---------------------------------------------------------------------------
1942 DarkRP - generic explosions (server)

One function any system can call to make an explosion:

    RP1942.explode(pos)                          -- defaults
    RP1942.explode(pos, { damage = 200, radius = 350, attacker = ply })
    RP1942.explode(pos, { damage = 0, shake = false })   -- effect only, harmless

OPTIONS (all optional):
    damage     number   damage at the centre, falls off with distance   (default 120)
    radius     number   blast radius in units (~52 units = 1 metre)     (default 250)
    attacker   Entity   who gets the kill credit                        (default world)
    inflictor  Entity   what did the damage                             (default attacker)
    effect     string   util.Effect name, false = none                  (default "Explosion")
    sound      string   extra sound to play, false = none               (default none;
                        the "Explosion" effect already makes its own sound)
    shake      bool     shake nearby screens                            (default true)
    scorch     bool     scorch decal on the ground below                (default true)

HOOKS (for other systems to react, e.g. door locks or the pain system):
    RP1942_PreExplosion(pos, opts)   return false to cancel the explosion
    RP1942_PostExplosion(pos, opts)  after damage has been applied

Admin test: rp1942_test_explosion [damage] [radius]  (superadmin, at your crosshair)
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local DEFAULTS = {
    damage = 120,
    radius = 250,
    effect = "Explosion",
    sound  = false,
    shake  = true,
    scorch = true,
}

function RP1942.explode(pos, opts)
    if not isvector(pos) then
        ErrorNoHalt("[1942] RP1942.explode needs a position (Vector), got " .. type(pos) .. "\n")
        return false
    end

    opts = opts or {}
    for k, v in pairs(DEFAULTS) do
        if opts[k] == nil then opts[k] = v end
    end

    if hook.Run("RP1942_PreExplosion", pos, opts) == false then return false end

    -- Visuals and sound (sent to every client near the blast by the engine)
    if opts.effect then
        local ed = EffectData()
        ed:SetOrigin(pos)
        util.Effect(opts.effect, ed, true, true)
    end

    if opts.sound then
        sound.Play(opts.sound, pos, 140, math.random(95, 105))
    end

    if opts.shake then
        -- amplitude, frequency, duration, radius (felt a bit beyond the blast)
        util.ScreenShake(pos, 8, 120, 1, opts.radius * 3)
    end

    if opts.scorch then
        util.Decal("Scorch", pos + Vector(0, 0, 8), pos - Vector(0, 0, 64))
    end

    -- Damage (falls off with distance, blocked by walls; engine behaviour)
    if opts.damage > 0 then
        local attacker = IsValid(opts.attacker) and opts.attacker or game.GetWorld()
        local inflictor = IsValid(opts.inflictor) and opts.inflictor or attacker
        util.BlastDamage(inflictor, attacker, pos, opts.radius, opts.damage)
    end

    hook.Run("RP1942_PostExplosion", pos, opts)
    return true
end

--[[---------------------------------------------------------------------------
Admin test command
---------------------------------------------------------------------------]]
concommand.Add("rp1942_test_explosion", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if not IsValid(ply) then
        print("[1942] Run this in-game; it explodes where you are aiming.")
        return
    end

    local tr = ply:GetEyeTrace()
    RP1942.explode(tr.HitPos, {
        damage   = tonumber(args[1]),
        radius   = tonumber(args[2]),
        attacker = ply,
    })
end)
