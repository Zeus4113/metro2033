local CHAR = ix.meta.character


-- Initialize equipment table
function CHAR:GetEquipment()
    return self:GetData("equipment", {
        outfit = nil,
        vest = nil,
        helmet = nil
    })
end

function CHAR:GetEquippedMask()
    local equipment = self:GetEquipment()

    for _, itemID in pairs(equipment) do
        local item = ix.item.instances[itemID]
        if item and item.isGasmask then
            return item
        end
    end
end

function CHAR:GetDamageResistance()
    local equipment = self:GetEquipment()
    if not equipment then return 0 end

    local totalDamageReduction = 0

    for _, itemID in pairs(equipment) do
        local item = ix.item.instances[itemID]
        if not item then continue end

        if item.damageReduction then
            totalDamageReduction = totalDamageReduction + item.damageReduction
        end
    end

    return math.Round(totalDamageReduction * 100)
end

function CHAR:GetRadiationResistance()
    local equipment = self:GetEquipment()
    if not equipment then return 0 end

    local totalRadiationResistance = 0

    for _, itemID in pairs(equipment) do
        local item = ix.item.instances[itemID]
        if not item then continue end

        if item.radiationProtection then
            if not item.isGasmask then
                totalRadiationResistance = totalRadiationResistance + item.radiationProtection
            elseif item.isGasmask and item:GetData("filterTime", 0) > 0 then
                totalRadiationResistance = totalRadiationResistance + item.radiationProtection
            end
        end
    end

    return math.Round(totalRadiationResistance * 100)
end

function CHAR:SetEquipmentSlot(slot, itemID)
    local equipment = self:GetEquipment()
    equipment[slot] = itemID
    self:SetData("equipment", equipment)
end

function CHAR:GetEquipmentItemID(slot)
    local equipment = self:GetEquipment()
    return equipment[slot]
end

function CHAR:HasGasmaskEquipped()
    local equipment = self:GetData("equipment", {})

    for _, itemID in pairs(equipment) do
        local item = ix.item.instances[itemID]

        if item and item.isGasmask then
            if not item.maxDurability or item:GetData("durability", 0) > 0 then
                return true
            end
        end
    end

    return false
end