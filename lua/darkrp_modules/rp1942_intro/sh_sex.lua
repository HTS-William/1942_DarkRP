--[[---------------------------------------------------------------------------
1942 DarkRP - men's and women's models that fit the name (shared)

A job with both men's and women's models (the civilians, the Resistance...)
gives you one that fits you:
    1. what you ticked on the Meldeamt form (Herr / Frau, /register), or
    2. if you never did: a guess from your first name (Anna, Greta, Zofia...
       and most names ending in -a or -e are women's; everything else men's)
An outfit you picked yourself in F4 (under a job) is kept if it's the right
kind; switching Herr / Frau on the form changes it to one that is.

Which models are women's: any whose path contains "female", plus any listed
in FEMALE_MODELS below.

    RP1942.nameSex(firstName)  -> "f" / "m"
    RP1942.playerSex(ply)      -> "f" / "m"
    RP1942.modelSex(path)      -> "f" / "m"
Server: sv_sex.lua. The form: cl_rpname.lua.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

local FEMALE_MODELS = {   -- women's models whose path doesn't say "female"
    -- ["models/player/alyx.mdl"] = true,
}

local FEMALE_NAMES = {}
for n in string.gmatch([[anna greta marta martha elise hedwig ilse frieda irene zofia halina irena krystyna wanda
    maria marie gertrud erika ursula helga hildegard margarete margot liesel lieselotte kathe käthe eva emma lotte
    inge charlotte elisabeth johanna sophie clara klara luise ruth edith agnes berta bertha rosa paula ida lina
    gisela renate brigitte ingrid irmgard waltraud elfriede hannelore annemarie helene magda magdalena rosemarie
    edeltraud dora gerda herta hertha marlene trude traudl ella else elsa minna olga vera nina lena leni hanna
    hannah greta ruth agata agnieszka jadwiga barbara katarzyna elzbieta stanislawa danuta teresa janina
    alicja ewa beata dorota grazyna lucyna maja mila lilly lily sarah rachel rebecca miriam esther judith]], "%S+") do
    FEMALE_NAMES[n] = true
end
-- Men's names that end the way women's usually do
local MALE_EXCEPTIONS = {}
for n in string.gmatch([[uwe ole kuba bonifacy jona luca andrea nikola sascha mischa jascha kosta ilja sasha
    andre rene jose mike steve dave george joe luke kyle pete jake shane wayne lee jesse duane ville tore moshe]], "%S+") do
    MALE_EXCEPTIONS[n] = true
end

function RP1942.nameSex(first)
    first = string.lower(string.Trim(tostring(first or "")))
    if first == "" then return "m" end
    if FEMALE_NAMES[first] then return "f" end
    if MALE_EXCEPTIONS[first] then return "m" end
    local last = string.sub(first, -1)
    return (last == "a" or last == "e") and "f" or "m"
end

function RP1942.modelSex(path)
    path = string.lower(tostring(path or ""))
    if FEMALE_MODELS[path] or string.find(path, "female", 1, true) then return "f" end
    return "m"
end

-- What a player is: ticked on the form, or guessed from the first name
function RP1942.playerSex(ply)
    if not IsValid(ply) then return "m" end
    local set = ply:GetNW2String("RP1942_Sex", "")
    if set == "f" or set == "m" then return set end
    local name = ply.getDarkRPVar and ply:getDarkRPVar("rpname") or ply:Nick()
    return RP1942.nameSex(string.match(name or "", "^(%S+)") or "")
end

-- This job's models for a sex (nil when the job has none of that sex)
function RP1942.jobModelsFor(job, sex)
    if not (job and istable(job.model)) then return nil end
    local list = {}
    for _, m in ipairs(job.model) do
        if RP1942.modelSex(m) == sex then list[#list + 1] = m end
    end
    return #list > 0 and list or nil
end
