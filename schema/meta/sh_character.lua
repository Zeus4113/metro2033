local CHAR = ix.meta.character

function CHAR:GetEquipment()
    local result = {}
    local inv = self:GetInventory()
    if not inv then return result end
    for _, item in pairs(inv:GetItems()) do
        if item:GetData("equip") and item.equipSlot then
            result[item.equipSlot] = item:GetID()
        end
    end
    return result
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
    if itemID then
        local item = ix.item.instances[itemID]
        if item then item:SetData("equip", true) end
    else
        local inv = self:GetInventory()
        if not inv then return end
        for _, item in pairs(inv:GetItems()) do
            if item.equipSlot == slot and item:GetData("equip") then
                item:SetData("equip", nil)
                break
            end
        end
    end
end

function CHAR:GetEquipmentItemID(slot)
    local inv = self:GetInventory()
    if not inv then return nil end
    for _, item in pairs(inv:GetItems()) do
        if item.equipSlot == slot and item:GetData("equip") then
            return item:GetID()
        end
    end
end

function CHAR:HasGasmaskEquipped()
    local inv = self:GetInventory()
    if not inv then return false end

    for _, item in pairs(inv:GetItems()) do
        if item.isGasmask and item:GetData("equip") then
            if not item.maxDurability or item:GetData("durability", 0) > 0 then
                return true
            end
        end
    end

    return false
end
