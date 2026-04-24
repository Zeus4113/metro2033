local INVENTORY = ix.meta.inventory

function INVENTORY:HasItemDeep(uniqueID, amount)
    amount = amount or 1
    local total = 0

    local function countInventory(inv)
        for _, item in pairs(inv:GetItems()) do
            if item.uniqueID == uniqueID then
                total = total + (item:GetQuantity() or 1)

                if total >= amount then
                    return true
                end
            end

            -- Check nested inventories (bags)
            if item.invID then
                local subInv = ix.item.inventories[item.invID]
                if subInv then
                    if countInventory(subInv) then
                        return true
                    end
                end
            end
        end
    end

    return countInventory(self) or false
end

function INVENTORY:GetItemsByUniqueIDDeep(uniqueID)
    local results = {}
    local visited = {}

    local function scan(inv)
        if visited[inv] then return end
        visited[inv] = true

        for _, item in pairs(inv:GetItems()) do
            if item.uniqueID == uniqueID then
                table.insert(results, item)
            end

            -- Check sub-inventories (bags)
            if item.invID then
                local subInv = ix.item.inventories[item.invID]
                if subInv then
                    scan(subInv)
                end
            end
        end
    end

    scan(self)

    return results
end

function INVENTORY:GetItemCountDeep(uniqueID)
    local count = 0
    local visited = {}

    local function scan(inv)
        if visited[inv] then return end
        visited[inv] = true

        for _, item in pairs(inv:GetItems()) do
            if item.uniqueID == uniqueID then
                count = count + (item:GetQuantity() or 1)
            end

            -- Scan nested inventories
            if item.invID then
                local subInv = ix.item.inventories[item.invID]
                if subInv then
                    scan(subInv)
                end
            end
        end
    end

    scan(self)

    return count
end

local INVENTORY = ix.meta.inventory

function INVENTORY:GetItemsDeep(visited, includeEquipment)
    local results = {}
    visited = visited or {}

    -- Prevent infinite loops
    if visited[self] then return results end
    visited[self] = true

    -- Get base items (DO NOT call overridden GetItems here)
    local items = self:GetItems()

    for _, item in pairs(items) do
        results[#results + 1] = item

        -- Traverse container inventories
        if item.invID then
            local subInv = ix.item.inventories[item.invID]

            if subInv then
                local subItems = subInv:GetItemsDeep(visited, includeEquipment)

                for _, subItem in ipairs(subItems) do
                    results[#results + 1] = subItem
                end
            end
        end
    end

    -- Include equipped containers if requested
    if includeEquipment then
        local owner = self.GetOwner and self:GetOwner()

        if IsValid(owner) then
            local char = owner:GetCharacter()

            if char and char.GetEquipment then
                for _, item in pairs(char:GetEquipment() or {}) do
                    if item.invID then
                        local subInv = ix.item.inventories[item.invID]

                        if subInv and not visited[subInv] then
                            local subItems = subInv:GetItemsDeep(visited, includeEquipment)

                            for _, subItem in ipairs(subItems) do
                                results[#results + 1] = subItem
                            end
                        end
                    end
                end
            end
        end
    end

    return results
end