--[[-----------------------------------------------------------------------
1942 DarkRP - F4 categories

Category names must match the `category` field in jobs.lua exactly
(case-sensitive). Lower sortOrder = higher in the F4 menu.
---------------------------------------------------------------------------]]
local function jobCategory(name, color, sortOrder)
    DarkRP.createCategory{
        name = name,
        categorises = "jobs",
        startExpanded = true,
        color = color,
        canSee = function(ply) return true end,
        sortOrder = sortOrder,
    }
end

jobCategory("Civilians",     Color(120, 120, 110), 10)
jobCategory("Commercial",    Color(150, 110,  70), 20)
jobCategory("Industry",      Color( 90,  80,  70), 30)
jobCategory("Dealers",       Color( 70,  50,  40), 40)
jobCategory("Resistance",    Color(130,  50,  40), 50)
jobCategory("Wehrmacht",     Color( 93, 101,  82), 60)
jobCategory("Waffen-SS",     Color( 60,  64,  50), 70)
jobCategory("Reich Command", Color( 30,  30,  30), 80)
