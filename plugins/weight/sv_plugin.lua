function ix.weight.CalculateWeight(character)
    local total = 0

    local function AddInventoryWeight(inventory)
        if not inventory then return end

        for _, item in pairs(inventory:GetItems()) do
            local itemWeight = item:GetWeight()

            if itemWeight then
                total = total + itemWeight
            end

            -- If item has a sub-inventory (like vest storage), recurse
            if item.invWidth and isfunction(item.GetInventory) then
                local subInv = item:GetInventory()
                if subInv then
                    AddInventoryWeight(subInv)
                end
            end
        end
    end

    AddInventoryWeight(character:GetInventory())

    return total
end

function ix.weight.Update(character) -- Updates the specified character's current carry weight.
	character:SetData("carry", ix.weight.CalculateWeight(character))
end

function PLUGIN:CharacterLoaded(character) -- This is just a safety net to make sure the carry weight data is up-to-date.
	ix.weight.Update(character)
end

function PLUGIN:CanTransferItem(item, old, inv) -- When a player attempts to take an item out of a container.
	if (inv.owner and item:GetWeight() and (old and old.owner != inv.owner)) then
		local character = ix.char.loaded[inv.owner]

		if (!character:CanCarry(item)) then
			character:GetPlayer():NotifyLocalized("You are carrying too much weight to take that.")
			return false
		end
	end
end
--[[
function PLUGIN:OnItemTransferred(item, old, new)
	if (item:GetWeight()) then
		if (old.owner and !new.owner) then -- Removing item from inventory.
			ix.weight.Update(ix.char.loaded[old.owner])
		elseif (!old.owner and new.owner) then -- Adding item to inventory.
			ix.weight.Update(ix.char.loaded[new.owner])
		end
	end
end
]]
function PLUGIN:OnItemTransferred(item, old, new)
    local weight = item:GetWeight()

    -- If the transferred item has weight OR is a container
    if (weight or item.invWidth) then

        -- Update old owner
        if (old and old.owner) then
            local character = ix.char.loaded[old.owner]
            if (character) then
                character:UpdateWeight()
            end
        end

        -- Update new owner
        if (new and new.owner) then
            local character = ix.char.loaded[new.owner]
            if (character) then
                character:UpdateWeight()
            end
        end
    end
end

function PLUGIN:InventoryItemAdded(old, new, item)
	if (item:GetWeight()) then
		if (!old and new.owner) then -- When an item is directly created in their inventory.
			ix.weight.Update(ix.char.loaded[new.owner])
		end
	end
end

function PLUGIN:CanPlayerTakeItem(client, item)
	local character = client:GetCharacter()

	local itm = item:GetItemTable()

	if (itm:GetWeight()) then
		if (!character:CanCarry(itm)) then
			client:NotifyLocalized("You are carrying too much weight to pick that up.")
			return false
		end
	end
end

function PLUGIN:CanPlayerTradeWithVendor(client, entity, uniqueID, selling)
	if (!selling) then
		local item = ix.item.list[uniqueID]

		if (item:GetWeight() and !client:GetCharacter():CanCarry(item)) then
			client:NotifyLocalized("You are carrying too much weight to buy that.")
			return false
		end
	end
end

function PLUGIN:CharacterVendorTraded(client, entity, uniqueID, selling)
	client:GetCharacter():UpdateWeight()
end
