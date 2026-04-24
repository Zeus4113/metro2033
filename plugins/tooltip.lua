local PLUGIN = PLUGIN or {}

PLUGIN.name = "Tooltip"
PLUGIN.author = "Kai"
PLUGIN.description = "A single place to deal with all tooltip changes."
--[[
if CLIENT then
	function PLUGIN:PopulateItemTooltip(tooltip, item)

		local weight = item:GetWeight()

		if weight then
			local row = tooltip:AddRow("weight")
				row:SetText("Weight: " .. ix.weight.WeightString(weight, ix.option.Get("imperial", false)))
				row:SetBackgroundColor(Color(125, 125, 125))
				row:SizeToContents()
		end

		if (item.maxDurability) then
			local panel = tooltip:AddRow("durability")
			local maxDurability = item.maxDurability or ix.config.Get("maxValueDurability", 100)
			local durability = math.Clamp(math.floor(item:GetData("durability", maxDurability)), 0, maxDurability)
			durability = math.max(0, math.floor((durability / maxDurability) * 100))

			panel:SetText("Durability: " .. durability .. "%")
			panel:SetBackgroundColor(Color(125, 125, 125))
			panel:SizeToContents()
		end
	end
end
]]