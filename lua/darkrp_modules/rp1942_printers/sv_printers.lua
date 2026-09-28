--[[---------------------------------------------------------------------------
1942 DarkRP - money printers (server): who may keep which printer
---------------------------------------------------------------------------]]

-- Printers a player owns, of one class
local function owned(ply, class)
    local list = {}
    for _, ent in ipairs(ents.FindByClass(class)) do
        if ent.Getowning_ent and ent:Getowning_ent() == ply then list[#list + 1] = ent end
    end
    return list
end

-- Joining the Reich (or becoming the Banker) loses your illegal printers;
-- leaving the Banker job loses the Banking Printers
hook.Add("OnPlayerChangedTeam", "RP1942_Printers", function(ply, oldTeam, newTeam)
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        if not RP1942.canOwnIllegalPrinter(ply) then
            local list = owned(ply, "rp1942_printer_illegal")
            for _, p in ipairs(list) do p:Remove() end
            if #list > 0 then DarkRP.notify(ply, 1, 6, "Your illegal printers were dismantled: you can't keep them in this job.") end
        end
        if not (TEAM_BANKER and ply:Team() == TEAM_BANKER) then
            local list = owned(ply, "rp1942_printer_bank")
            for _, p in ipairs(list) do p:Remove() end
            if #list > 0 then DarkRP.notify(ply, 1, 6, "Your Banking Printers were returned to the Reichsbank.") end
        end
    end)
end)

-- Printers can't be pocketed (it would cool them instantly)
hook.Add("canPocket", "RP1942_Printers", function(_, ent)
    if IsValid(ent) and (ent:GetClass() == "rp1942_printer_bank" or ent:GetClass() == "rp1942_printer_illegal") then
        return false, "Printers are too heavy to pocket."
    end
end)
