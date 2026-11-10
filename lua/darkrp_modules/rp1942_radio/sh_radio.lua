--[[---------------------------------------------------------------------------
42Bros - Radio (shared: the settings and the stations)

A wireless set (rp1942_radio) that plays internet radio. Press E on it to
tune it to one of the stations listed below (R.stations): only those. Nobody
can type in their own link, so every listener only ever connects to a
station you chose (a player's own link would show them the IP address of
everyone near the radio). The sound comes from the radio itself (3D),
fading out over `range` units, and plays on every client near it.

WHO MAY TUNE IT
    * whoever owns it (bought it from the F4 shop, or spawned it)
    * staff (ulx prodspawn, or superadmins without ULX)
    * anyone, if it has no owner (placed with !prodspawn and saved), or if
      `anyoneCanTune` is on

TWO KINDS OF RADIO
    rp1942_radio      the fixed wireless set staff place with !prodspawn
                      (frozen; !saveprod keeps it and its station)
    Radio Set good    the factory's "very rare" product (rp1942_good, radio):
                      a working radio too. E tunes it, Shift+E carries it.
                      Sold at the market like any good, pocketed, or bought
                      in the F4 shop, where it always costs more than the
                      market pays for it (sh_f4_shop.lua: markup).

ADDING A STATION
    Add a line to R.stations. Only direct stream links work (they end in the
    stream, not a web page): .mp3 / .aac / .ogg streams, Shoutcast / Icecast
    mounts. A station's "listen" page or a YouTube link won't. http and https
    both work. Players see the station's name, never its link.
    Every player's own volume: rp1942_radio_volume 0-1 (console), and
    rp1942_radio 0 turns radios off for that player.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Radio = RP1942.Radio or {}
local R = RP1942.Radio

R.settings = {
    model         = "models/props_lab/citizenradio.mdl",
    range         = 900,     -- units: how far the radio is heard (~52 units = 1 m)
    nearRange     = 150,     -- full volume this close; fades out to `range`
    anyoneCanTune = false,   -- true: anyone can change any radio
    perPlayer     = 1,       -- radios one player may have (in the world, pocket and inventory)
    -- (its price in the F4 shop: rp1942_f4/sh_f4_shop.lua, "Radio Set")
}

-- The stations in the menu. name / url (a direct stream link).
R.stations = {
    { name = "Radio 1942", url = "https://das-edge13-live365-dal02.cdnstream.com/a21441" },
    { name = "1940s Radio", url = "https://uk3.internet-radio.com/proxy/1940sradio/stream" },
    -- { name = "Another station", url = "http://your.stream.here:8000/stream" },
}

function RP1942.radioSetting(key) return R.settings[key] end

-- The station with this link, or nil: the only links a radio will play
function RP1942.radioStation(url)
    if not isstring(url) then return nil end
    for i, st in ipairs(R.stations) do
        if st.url == url then return st, i end
    end
end

-- Is this a link we'll accept? Only the stations above.
function RP1942.radioValidUrl(url)
    return RP1942.radioStation(url) ~= nil
end

-- Any entity that's a radio: the wireless set, or the factory's Radio Set good
function RP1942.isRadio(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    return class == "rp1942_radio" or (class == "rp1942_good" and ent.IsRadio and ent:IsRadio())
end

function RP1942.radioCanTune(ply, radio)
    if not IsValid(ply) or not IsValid(radio) then return false end
    if R.settings.anyoneCanTune then return true end
    if radio:GetClass() == "rp1942_good" then return true end   -- a Radio Set good: whoever has it in hand
    if radio.RP1942_SaveId or radio.RP1942_ProdSpawnedBy then return true end   -- placed by staff: a public set
    local owner = radio.RP1942_ShopOwner
    if not IsValid(owner) and radio.CPPIGetOwner then owner = radio:CPPIGetOwner() end
    if not IsValid(owner) and radio.Getowning_ent then owner = radio:Getowning_ent() end
    if not IsValid(owner) then return true end   -- nobody's: a public set
    if owner == ply then return true end
    if RP1942.staffCan then return RP1942.staffCan(ply, "ulx prodspawn", function(p) return p:IsSuperAdmin() end) end
    return ply:IsSuperAdmin()
end
