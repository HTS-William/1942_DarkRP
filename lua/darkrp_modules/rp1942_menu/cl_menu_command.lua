--[[---------------------------------------------------------------------------
EXAMPLE: one menu shared by several jobs, with an override that still calls
the base class (the "super" call).

jobs.lua (every NCO / Offizier):  menu = "RP1942_CommandMenu",

The same class adapts to whoever opens it: a Wehrmacht NCO sees the
Wehrmacht roster, an SS Offizier sees the SS roster, and the theme follows the
faction automatically.
---------------------------------------------------------------------------]]
local BaseClass = baseclass.Get("RP1942_MenuBase")
local PANEL = {}

function PANEL:GetSubtitle()
    return "Dienstbuch"
end

function PANEL:Populate()
    local branch = self.job.branch

    self:AddSection("Roster")
    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        local job = RPExtraTeams[ply:Team()]
        if job and job.branch == branch then
            self:AddText(ply:Nick() .. "  -  " .. job.name)
            count = count + 1
        end
    end
    if count == 0 then self:AddText("Nobody else is on duty.") end
end

-- Override + super: draw the normal frame, then add a thin rule under the header
function PANEL:Paint(w, h)
    BaseClass.Paint(self, w, h)
    surface.SetDrawColor(self.theme.text.r, self.theme.text.g, self.theme.text.b, 40)
    surface.DrawRect(14, 57, w - 28, 1)
end

vgui.Register("RP1942_CommandMenu", PANEL, "RP1942_MenuBase")
