--[[---------------------------------------------------------------------------
1942 DarkRP - F4 menu (shared config)

Replaces DarkRP's F4 menu. DarkRP's own F4 module stays loaded underneath (so
nothing that expects it breaks); it just never opens.

Files:
    sh_f4.lua           this config: colours, tabs
    cl_f4.lua           the window, tab bar, opening/closing with F4
    cl_f4_jobs.lua      Jobs: grid of cards with idle models + detail panel
    cl_f4_shop.lua      Shop: DarkRP entities, weapons and ammo (no shipments)
    cl_f4_commands.lua  Commands: money, name, drop weapon, doors, ...
    cl_f4_pages.lua     one tab per text page in sh_f4_pages.lua (Rules, ...)
    sh_f4_pages.lua     the text of those pages            <- fill in
    sh_f4_shop.lua      items sold in the Shop tab           <- add items
    sh_f4_shop_core.lua / sv_f4_shop.lua   the shop's logic
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

RP1942.F4Config = {
    title    = "1942",          -- gold part of the title
    subtitle = "Options",       -- the rest

    -- Tabs, left to right. Remove a name to hide that tab.
    -- "pages" = every page in sh_f4_pages.lua, each as its own tab.
    tabs = { "commands", "jobs", "shop", "pages" },

    -- Jobs tab
    showLockedJobs = true,      -- show jobs you can't take (dimmed, with the reason)
    jobColumns     = 3,

    --[[-----------------------------------------------------------------------
    Colours. Color(red, green, blue, alpha), each 0-255.
    -----------------------------------------------------------------------]]
    colors = {
        bg          = Color(20, 19, 17, 248),   -- window
        titleBar    = Color(14, 13, 12),        -- top strip
        panel       = Color(28, 26, 23),        -- behind lists and details
        card        = Color(38, 35, 31),        -- job / item cards
        cardHover   = Color(52, 48, 42),
        cardSelected= Color(64, 52, 36),
        category    = Color(84, 18, 18),        -- category bars
        categoryAlt = Color(38, 72, 30),        -- green bars (Citizen options)
        entry       = Color(14, 13, 12),        -- text boxes
        tab         = Color(34, 32, 29),
        tabHover    = Color(48, 45, 40),
        tabActive   = Color(112, 22, 22),
        gold        = Color(201, 168, 92),      -- accents, current job
        text        = Color(236, 228, 212),
        sub         = Color(160, 152, 136),
        available   = Color(140, 200, 110),     -- job names you can take
        unavailable = Color(215, 85, 70),       -- locked / full / can't afford
        button      = Color(128, 26, 24),
        buttonHover = Color(156, 36, 32),
        disabled    = Color(52, 49, 45),
    },
}
