--[[
	   ______                    __   __                   
	  / ____/___ ___  ____  ____/ /  / /   ___  ____ ______
	 / / __/ __ `__ \/ __ \/ __  /  / /   / _ \/ __ `/ ___/
	/ /_/ / / / / / / /_/ / /_/ /  / /___/  __/ /_/ (__  ) 
	\____/_/ /_/ /_/\____/\__,_/  /_____/\___/\__, /____/  
	                                         /____/        
	@Valkyrie, @blackops7799
]]--
    
if (SERVER) then
    AddCSLuaFile("sh_legs.lua")
end

if (CLIENT) then
    hook.Add("ShouldDisableLegs", "GML::Support::Prone", function()
        if (!LocalPlayer().IsProne) then
            return
        end

        if (LocalPlayer():IsProne()) then
            return true
        end
    end)

    hook.Add("ShouldDisableLegs", "GML::Support::MorphMod", function()
        if (!pk_pills) then
            return
        end

        if (pk_pills.getMappedEnt(LocalPlayer())) then
            return true
        end
    end)

	hook.Add("ShouldDisableLegs", "GML::Support::VWallrun", function()
        if (VWallrunning) then
            return true
        end
    end)
    
    hook.Add("ShouldDisableLegs", "GML::Support::Mantle", function()
        if (inmantle) then
            return true
        end
	end)
end

-- 1942 DarkRP: keep the legs dressed like the player. Gmod Legs copies the
-- model, bodygroups and skin only when it (re)builds the legs, so changing
-- bodygroups in the F4 Appearance tab (or a wardrobe/skin change that keeps
-- the same model) left the old legs on. Checked ten times a second.
if (CLIENT) then
    local nextCheck = 0
    hook.Add("Think", "GML::Support::RP1942Appearance", function()
        local now = RealTime()
        if now < nextCheck then return end
        nextCheck = now + 0.1

        local legs = g_Legs
        local ply = LocalPlayer()
        if not (legs and IsValid(ply)) then return end
        local ent = legs.LegEnt
        if not IsValid(ent) then return end

        -- A different model: let Gmod Legs rebuild them (it re-applies everything)
        local want = ply.GetLegModel and ply:GetLegModel() or ply:GetModel()
        if string.lower(want or "") ~= string.lower(ent:GetModel() or "") then
            if legs.SetUp then legs:SetUp() end
            return
        end

        -- Same model: copy over what can change on it
        for id = 0, ply:GetNumBodyGroups() - 1 do
            local v = ply:GetBodygroup(id)
            if ent:GetBodygroup(id) ~= v then ent:SetBodygroup(id, v) end
        end
        if ent:GetSkin() ~= ply:GetSkin() then ent:SetSkin(ply:GetSkin()) end
        if ent:GetMaterial() ~= ply:GetMaterial() then ent:SetMaterial(ply:GetMaterial()) end
        for i = 0, #(ply:GetMaterials() or {}) - 1 do
            local sm = ply:GetSubMaterial(i)
            if ent:GetSubMaterial(i) ~= sm then ent:SetSubMaterial(i, sm) end
        end
    end)
end
