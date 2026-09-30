--[[---------------------------------------------------------------------------
1942 DarkRP - Radio (shared: the settings and the stations)

A wireless set (rp1942_radio) that plays internet radio. Press E on it to
tune it: pick a station from the list below or type a stream link. The
sound comes from the radio itself (3D), fading out over `range` units, and
plays on every client near it.

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

LINKS
    Only direct stream links work (they end in the stream, not a web page):
    .mp3 / .aac / .ogg streams, Shoutcast / Icecast mounts. A station's
    "listen" page or a YouTube link won't. http and https both work.
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
    maxUrlLength  = 300,
    price         = 600,     -- if sold in the F4 shop
}

-- The stations in the menu. name / url (a direct stream link).
R.stations = {
    { name = "Radio 1942", url = "https://das-edge13-live365-dal02.cdnstream.com/a21441" },
    { name = "1940s Radio", url = "https://uk3.internet-radio.com/proxy/1940sradio/stream" },
    -- { name = "Another station", url = "http://your.stream.here:8000/stream" },
}

function RP1942.radioSetting(key) return R.settings[key] end

-- Is this a link we'll accept? (a direct http(s) link, nothing else)
function RP1942.radioValidUrl(url)
    if not isstring(url) then return false end
    url = string.Trim(url)
    if #url < 8 or #url > R.settings.maxUrlLength then return false end
    if not (url:find("^https?://") ) then return false end
    if url:find("[%s\"'<>]") then return false end
    return true
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
