--[[-----------------------------------------------------------------------
1942 DarkRP - F4 categories

Category names must match the `category` field in jobs.lua exactly
(case-sensitive). Lower sortOrder = higher in the F4 menu.

canSee hides the WHOLE category (header and jobs) when it returns false.
DarkRP re-evaluates it whenever the F4 menu refreshes, so after changing
job, the branch sections appear/disappear the next time F4 is opened.
Empty categories (e.g. DarkRP's stock "Citizens") are hidden automatically.

canSee is only cosmetic. The real lock is `requires` in jobs.lua, which the
server checks on every job change.
---------------------------------------------------------------------------]]
local function jobCategory(name, color, sortOrder, canSee)
    DarkRP.createCategory{
        name = name,
        categorises = "jobs",
        startExpanded = true,
        color = color,
        canSee = canSee or function() return true end,
        sortOrder = sortOrder,
    }
end

-- Open to everyone
jobCategory("Civilians",  Color(120, 120, 110), 10)
jobCategory("Production", Color(150, 115,  60), 15)   -- Baker, Winemaker, Petroleum Producer, Factory Owner
jobCategory("Resistance", Color(130,  50,  40), 20)
jobCategory("Reich",      Color( 93, 101,  82), 30)   -- every German job, folded like the Resistance

-- Visible to everyone: anyone can run for Führer
jobCategory("Reich Command", Color(120,  20,  20), 70)

-- Staff only, at the very bottom
jobCategory("Staff", Color(40, 110, 160), 1000, function(ply)
    return RP1942.isF4Staff and RP1942.isF4Staff(ply) or false
end)

-- F4 Shop: the producing jobs' machines and supplies (entities.lua)
DarkRP.createCategory{
    name = "Production",
    categorises = "entities",
    startExpanded = true,
    color = Color(160, 120, 60),
    canSee = function() return true end,
    sortOrder = 10,
}

DarkRP.createCategory{
    name = "Printers",
    categorises = "entities",
    startExpanded = true,
    color = Color(90, 130, 70),
    canSee = function() return true end,
    sortOrder = 11,
}

