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
jobCategory("Resistance", Color(130,  50,  40), 20)
jobCategory("Reich",      Color( 93, 101,  82), 30)   -- every German job, folded like the Resistance

-- Visible to everyone: anyone can run for Führer
jobCategory("Reich Command", Color(120,  20,  20), 70)
