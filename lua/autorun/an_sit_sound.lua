--============================================================
-- SitAnywhere Sitting Sound
-- Plays thesittingsoundeffect.ogg when player sits down
--============================================================

if SERVER then
    AddCSLuaFile()

    resource.AddFile("sound/rp1942_sit/thesittingsoundeffect.ogg")
end

if CLIENT then

    hook.Add("OnEntityCreated", "AN_SitAnywhere_PlaySitSound", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            if ent:GetClass() ~= "prop_vehicle_prisoner_pod" then return end

            local ply = LocalPlayer()
            if not IsValid(ply) then return end

            timer.Simple(0.1, function()
                if not IsValid(ent) or not IsValid(ply) then return end

                if ply:GetVehicle() == ent then
                    surface.PlaySound("rp1942_sit/thesittingsoundeffect.ogg")
                end
            end)
        end)
    end)

end
