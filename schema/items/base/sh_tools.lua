ITEM.name = "Base Tool Item"
ITEM.description = "Base class for tools used in crafting and scavenging."
ITEM.category = "Tools"
ITEM.weight = 1

-- Shows the tool's condition in its tooltip, but only for tools that actually
-- wear out (those with a maxDurability). Crafting-only tools omit it.
function ITEM:PopulateTooltip(tooltip)
	if not self.maxDurability then return end

	local current = self:GetData("durability", self.maxDurability)
	local pct     = math.Round(math.Clamp(current / self.maxDurability, 0, 1) * 100)

	local row = tooltip:AddRowAfter("description", "condition")
	row:SetText("Condition: " .. pct .. "%")
	row:SetBackgroundColor(Color(150, 120, 40))
	row:SizeToContents()
end
