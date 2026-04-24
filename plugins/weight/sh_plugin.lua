PLUGIN.name = "Weight"
PLUGIN.author = "Vex"
PLUGIN.description = "Allows for weight to be added to items."

ix.weight = ix.weight or {}

ix.config.Add("maxWeight", 30, "The maximum weight in Kilograms someone can carry in their inventory.", nil, {
	data = {min = 1, max = 100},
	category = "Weight"
})

ix.config.Add("maxOverWeight", 20, "The maximum amount of weight in Kilograms they can go over their weight limit, this should be less than maxWeight to prevent issues.", nil, {
	data = {min = 1, max = 100},
	category = "Weight"
})

ix.util.Include("sh_meta.lua")
ix.util.Include("sv_plugin.lua")

function ix.weight.WeightString(weight, imperial)
	if (imperial) then
		if (weight < 0.453592) then -- Filthy imperial system; Why do I allow their backwards thinking?
			return math.Round(weight * 35.274, 2).." oz"
		else
			return math.Round(weight * 2.20462, 2).." lbs"
		end
	else
		if (weight < 1) then -- The superior units of measurement.
			return math.Round(weight * 1000, 2).." g"
		else
			return math.Round(weight, 2).." kg"
		end
	end
end

function ix.weight.BaseWeight(character)
	local base = ix.config.Get("maxWeight", 30)
    local strength = character:GetAttribute("strength", 0)
	return base + (strength * ix.config.Get("strengthCarryPerPoint", 1.5))
end

function ix.weight.CanCarry(weight, carry, character) -- Calculate if you are able to carry something.
	local max = ix.weight.BaseWeight(character) + ix.config.Get("maxOverWeight", 20)

	return (weight + carry) <= max
end

if (CLIENT) then
	ix.option.Add("imperial", ix.type.bool, false, {
		category = "Weight"
	})

	hook.Add("CreateMenuButtons", "ixInventory", function(tabs)
        if (hook.Run("CanPlayerViewInventory") == false) then
            return
        end

        tabs["inv"] = {
            bDefault = true,
            Create = function(info, container)

                local canvas = container:Add("DTileLayout")
                local canvasLayout = canvas.PerformLayout
                canvas.PerformLayout = nil
                canvas:SetBorder(0)
                canvas:SetSpaceX(2)
                canvas:SetSpaceY(2)
                canvas:Dock(FILL)

                ix.gui.menuInventoryContainer = canvas

                local panel = canvas:Add("ixInventory")
                panel:SetPos(0, 0)
                panel:SetDraggable(false)
                panel:SetSizable(false)
                panel:SetTitle(nil)
                panel.bNoBackgroundBlur = true
                panel.childPanels = {}

                local inventory = LocalPlayer():GetCharacter():GetInventory()

                if (inventory) then
                    panel:SetInventory(inventory)
                end

                ix.gui.inv1 = panel

                if (ix.option.Get("openBags", true)) then
                    for _, v in pairs(inventory:GetItems()) do
                        if (!v.isBag) then
                            continue
                        end

                        v.functions.View.OnClick(v)
                    end
                end

                local character = LocalPlayer():GetCharacter()
                local carry = character:GetData("carry", 0)
                local color = ix.config.Get("color")
                local maxWeight = ix.config.Get("maxWeight", 30) + (character:GetAttribute("strength", 0) * ix.config.Get("strengthCarryPerPoint", 0))

                local w, h = panel:GetSize()

                -- increased height for new panels
                panel:SetTall(h + 84)

                w = w - 10

                ------------------------------------------------
                -- Weight Bar
                ------------------------------------------------

                local weight = panel:Add("DPanel")
                weight:SetPos(5, h - 4)
                weight:SetSize(w, 24)

                weight.Paint = function(self, w, h)
                    surface.SetDrawColor(35, 35, 35, 85)
                    surface.DrawRect(1, 1, w, h)

                    surface.SetDrawColor(0, 0, 0, 250)
                    surface.DrawOutlinedRect(0, 0, w, h)
                end

                local bar = weight:Add("DPanel")
                bar:SetSize(w, 24)

                bar.Paint = function(self)
                    surface.SetDrawColor(color)
                    surface.DrawRect(4, 4, math.min(((w - 8) / maxWeight) * carry, w - 8), 16)
                end

                local barO = weight:Add("DPanel")
                barO:SetSize(w, 24)

                barO.Paint = function(self)
                    surface.SetDrawColor(Color(205, 50, 50))

                    if (carry > maxWeight) then
                        surface.DrawRect(4, 4, math.min(((w - 8) / maxWeight) * (carry - maxWeight), w - 8), 16)
                    end
                end

                local barT = weight:Add("DLabel")
                barT:SetSize(w, 24)
                barT:SetContentAlignment(5)

                barT.Think = function()
                    carry = character:GetData("carry", 0)

                    if (ix.option.Get("imperial", false)) then
                        barT:SetText(math.Round(carry * 2.20462, 2).." lbs / "..math.Round(maxWeight * 2.20462, 2).." lbs")
                    else
                        barT:SetText(math.Round(carry, 2).." kg / "..maxWeight.." kg")
                    end
                end

                ------------------------------------------------
                -- Resistance Panel
                ------------------------------------------------

                local resistPanel = panel:Add("DPanel")
                resistPanel:SetPos(5, h + 28)
                resistPanel:SetSize(w, 52)

                resistPanel.Paint = function() end

                ------------------------------------------------
                -- Damage Resistance
                ------------------------------------------------

                local dmgBar = resistPanel:Add("DPanel")
                dmgBar:SetPos(0, 0)
                dmgBar:SetSize(w, 24)

                dmgBar.Paint = function(self, w2, h2)
                    surface.SetDrawColor(35, 35, 35, 85)
                    surface.DrawRect(1, 1, w2, h2)

                    surface.SetDrawColor(0, 0, 0, 250)
                    surface.DrawOutlinedRect(0, 0, w2, h2)
                end

                local dmgFill = dmgBar:Add("DPanel")
                dmgFill:SetSize(w, 24)

                dmgFill.Paint = function(self, w2, h2)
                    local char = LocalPlayer():GetCharacter()
                    if not char then return end

                    local resist = char:GetDamageResistance() or 0

                    surface.SetDrawColor(75, 118, 128)
                    surface.DrawRect(4, 4, math.min((w2 - 8) * (resist / 100), w2 - 8), 16)
                end

                local dmgText = dmgBar:Add("DLabel")
                dmgText:SetSize(w, 24)
                dmgText:SetContentAlignment(5)

                dmgText.Think = function(self)
                    local char = LocalPlayer():GetCharacter()
                    if char then
                        self:SetText("Damage Resistance: "..char:GetDamageResistance().."%")
                    end
                end

                ------------------------------------------------
                -- Radiation Resistance
                ------------------------------------------------

                local radBar = resistPanel:Add("DPanel")
                radBar:SetPos(0, 28)
                radBar:SetSize(w, 24)

                radBar.Paint = function(self, w2, h2)
                    surface.SetDrawColor(35, 35, 35, 85)
                    surface.DrawRect(1, 1, w2, h2)

                    surface.SetDrawColor(0, 0, 0, 250)
                    surface.DrawOutlinedRect(0, 0, w2, h2)
                end

                local radFill = radBar:Add("DPanel")
                radFill:SetSize(w, 24)

                radFill.Paint = function(self, w2, h2)
                    local char = LocalPlayer():GetCharacter()
                    if not char then return end

                    local resist = char:GetRadiationResistance() or 0

                    surface.SetDrawColor(87, 128, 75)
                    surface.DrawRect(4, 4, math.min((w2 - 8) * (resist / 100), w2 - 8), 16)
                end

                local radText = radBar:Add("DLabel")
                radText:SetSize(w, 24)
                radText:SetContentAlignment(5)

                radText.Think = function(self)
                    local char = LocalPlayer():GetCharacter()
                    if char then
                        self:SetText("Radiation Resistance: "..char:GetRadiationResistance().."%")
                    end
                end

                ------------------------------------------------

                canvas.PerformLayout = canvasLayout
                canvas:Layout()
            end
        }
    end)
end
