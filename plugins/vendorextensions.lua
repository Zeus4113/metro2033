local PLUGIN = PLUGIN

PLUGIN.name = "Vendor Extensions"
PLUGIN.author = "Barney"
PLUGIN.description = "A centralised place for vendor based plugin hooks."

function PLUGIN:CanPlayerTradeWithVendor(client, entity, uniqueID, isSellingToVendor)

	if not isSellingToVendor then return end

	if not IsValid(client) then return end
	
	local char = client:GetCharacter()

	if not char then return end

	local equipment = char:GetEquipment()

	local item = ix.item.list[uniqueID]

	if item.equipSlot and equipment[item.equipSlot] == item:GetID() then
		client:Notify("You cannot sell an equipped item.")
		return false
	end

	if item.slot and item:GetData("equip", false) then
		client:Notify("You cannot sell an equipped item.")
		return false
	end

	return true
end