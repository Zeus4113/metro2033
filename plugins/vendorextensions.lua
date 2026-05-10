local PLUGIN = PLUGIN

PLUGIN.name = "Vendor Extensions"
PLUGIN.author = "Barney"
PLUGIN.description = "A centralised place for vendor based plugin hooks."

function PLUGIN:CanPlayerTradeWithVendor(client, entity, uniqueID, isSellingToVendor)
	if not isSellingToVendor then return end
	if not IsValid(client) then return end

	local char = client:GetCharacter()
	if not char then return end

	local inv = char:GetInventory()
	if not inv then return end

	local hasSellable = false
	local blockEquip = false
	local blockFull = false

	for _, item in pairs(inv:GetItems(true)) do
		if item.uniqueID ~= uniqueID then continue end

		local equipped = item:GetData("equip")
		local isFull = false

		if item.invWidth then
			local containerID = item:GetData("id")
			if containerID then
				local containerInv = ix.item.inventories[containerID]
				if containerInv and next(containerInv:GetItems()) then
					isFull = true
				end

				if not isFull then
					for _, inst in pairs(ix.item.instances) do
						if inst.invID == containerID then
							isFull = true
							break
						end
					end
				end
			end
		end

		if not equipped and not isFull then
			hasSellable = true
		elseif equipped then
			blockEquip = true
		else
			blockFull = true
		end
	end

	if not hasSellable then
		if blockFull then
			client:Notify("You cannot sell a bag that still has items inside.")
			return false
		end
		if blockEquip then
			client:Notify("You cannot sell an equipped item.")
			return false
		end
	end

	return true
end
