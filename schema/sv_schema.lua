
-- Here is where all of your serverside functions should go.

-- Block base PM/Reply commands — PDA is the only allowed private messaging method.
hook.Add("InitializedSchema", "BlockBasePM", function()
	ix.command.list["pm"] = nil
	ix.command.list["reply"] = nil
end)

-- Example server function that will slap the given player.
function Schema:SlapPlayer(client)
	if (IsValid(client) and client:IsPlayer()) then
		client:SetVelocity(Vector(math.random(-50, 50), math.random(-50, 50), math.random(0, 20)))
		client:TakeDamage(math.random(5, 10))
	end
end

function Schema:InitializedConfig()
    ix.config.Set("maxAttributes", 450)
end

function Schema:CanPlayerTradeWithVendor(client, entity, uniqueID, isSellingToVendor)
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

	return true
end