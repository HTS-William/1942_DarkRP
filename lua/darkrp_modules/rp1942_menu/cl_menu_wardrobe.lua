--[[---------------------------------------------------------------------------
F3 menu for undercover jobs: the wardrobe.
jobs.lua (Gestapo Agent, Resistance Operative):  menu = "RP1942_WardrobeMenu",
Colours follow the job's faction (Reich / Resistance), like every job menu.
Server side of the buttons: rp1942_core/sv_disguise.lua ("model" handler).

The models offered: this job's list in RP1942.Config.Disguise.models, or every
civilian job's models when it's empty (RP1942.disguiseModels in sh_commands.lua).
---------------------------------------------------------------------------]]
local PANEL = {}

function PANEL:GetSubtitle()
    return "Wardrobe"
end

function PANEL:Populate()
    local theme = self.theme
    local lp = LocalPlayer()

    self:AddSection("Cover")
    self:AddText("You appear to everyone as: " .. (lp:getDarkRPVar("job") or "?") .. ".")
    self:AddText("Change it with \"Set a custom job title\" in the F4 Commands tab. For you it's silent: nobody is told. Type your real job name there to reveal yourself.")

    self:AddSection("Disguise")
    self:AddText("Click a model to wear it. It stays on through respawns until you change job.")

    local grid = self.content:Add("DIconLayout")
    grid:Dock(TOP)
    grid:DockMargin(0, 2, 0, 8)
    grid:SetSpaceX(6)
    grid:SetSpaceY(6)

    local size = math.Clamp(math.floor(ScrH() * 0.075), 64, 110)
    for _, model in ipairs(RP1942.disguiseModels(LocalPlayer())) do
        local icon = grid:Add("SpawnIcon")
        icon:SetSize(size, size)
        icon:SetModel(model)
        icon:SetTooltip(string.match(model, "([^/]+)%.mdl$") or model)
        icon.OpenMenu = function() end   -- no spawn-menu right-click options here
        icon.DoClick = function()
            surface.PlaySound("ui/buttonclick.wav")
            self:Request("model", model)
        end
        icon.PaintOver = function(_, w, h)
            if string.lower(LocalPlayer():GetModel() or "") == string.lower(model) then
                surface.SetDrawColor(theme.accentHover)
                surface.DrawOutlinedRect(0, 0, w, h, 3)
            end
        end
    end

    self:AddButton("Standard issue (your job's normal model)", function()
        self:Request("model", "")
    end)
end

vgui.Register("RP1942_WardrobeMenu", PANEL, "RP1942_MenuBase")
