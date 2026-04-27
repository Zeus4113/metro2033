
function Schema:OnCharacterCreated(client, character)
    --[[
    local data = character:GetData("skillAllocation", {})

    for attrib, value in pairs(data) do
        character:SetAttrib(attrib, value)
    end
    ]]
    local inv = character:GetInventory()

    if inv then inv:Add("flashlight") end

end


-- Armor durability

local ARMOR_DEBUG = false

hook.Add("EntityTakeDamage", "metroArmorDurabilitySystem", function(ent, dmgInfo)
    if not ent:IsPlayer() then return end

    local char = ent:GetCharacter()
    if not char then return end

    if dmgInfo:IsDamageType(DMG_RADIATION) then return end

    local inventory = char:GetInventory()
    if not inventory then return end

    local equipment = char:GetData("equipment", {})
    local damage = dmgInfo:GetDamage()
    local originalDamage = damage
    local totalReduction = 0

    if ARMOR_DEBUG then
        print("---- ARMOR DEBUG ----")
        print("Incoming Damage:", damage)
    end

    for slot, itemID in pairs(equipment) do
        if itemID then
            local item = inventory:GetItemByID(itemID)

            if item and item.damageReduction and item.damageReduction > 0 then
                local durability = item:GetData("durability", 0)

                if durability > 0 then
                    totalReduction = totalReduction + item.damageReduction

                    if ARMOR_DEBUG then
                        print(string.format(
                            "[%s] %s | Reduction: %.2f | Durability: %.2f",
                            slot,
                            item.name,
                            item.damageReduction,
                            durability
                        ))
                    end
                elseif ARMOR_DEBUG then
                    print(string.format(
                        "[%s] %s is broken (Durability 0)",
                        slot,
                        item.name
                    ))
                end
            end
        end
    end

    if totalReduction <= 0 then
        if ARMOR_DEBUG then
            print("No active armor. Full damage applied.")
            print("---------------------")
        end
        return
    end

    totalReduction = math.min(totalReduction, 0.8)
    local absorbed = damage * totalReduction
    local finalDamage = damage - absorbed

    if ARMOR_DEBUG then
        print("Total Reduction:", totalReduction)
        print("Absorbed Damage:", absorbed)
        print("Final Damage:", finalDamage)
    end

    -- Durability loss distribution
    for slot, itemID in pairs(equipment) do
        if itemID then
            local item = inventory:GetItemByID(itemID)

            if item then
                local durability = item:GetData("durability", 0)

                if durability > 0 then
                    local portion = damage * ix.config.Get("decDurabilityEquipment", 0.1)
                    --(item.damageReduction / totalReduction)
                    local newDurability = math.max(durability - portion, 0)

                    item:SetData("durability", newDurability)

                    if ARMOR_DEBUG then
                        print(string.format(
                            "[%s] %s durability reduced by %.2f → %.2f",
                            slot,
                            item.name,
                            portion,
                            newDurability
                        ))
                    end

                    -- Break handling
                    if newDurability <= 0 then
                        local equipmentTable = char:GetData("equipment", {})
                        equipmentTable[slot] = nil
                        char:SetData("equipment", equipmentTable)

                        if slot == "Outfit" then
                            ent:ApplyOutfit()
                        end

                        ent:Notify(item.name .. " has broken and was unequipped!")

                        if ARMOR_DEBUG then
                            print(item.name .. " BROKE.")
                        end
                    end
                end
            end
        end
    end

    -- Apply reduced damage
    dmgInfo:SetDamage(finalDamage)

    if ARMOR_DEBUG then
        print("Final Damage Applied:", finalDamage)

        timer.Simple(0, function()
            if IsValid(ent) then
                print("Post-damage Health:", ent:Health())
                print("---------------------")
            end
        end)
    end
end)


-- Check outfit on player loaded
hook.Add("PlayerLoadedCharacter", "MetroApplyOutfitOnLoad", function(ply, char)
    timer.Simple(0, function()
        if IsValid(ply) then
            ply:ApplyOutfit()
        end
    end)
end)

-- unequip on death

hook.Add("PlayerDeath", "MetroForceUnequipOnDeath", function(victim)
    if not IsValid(victim) then return end

    local char = victim:GetCharacter()
    if not char then return end

    local equipment = char:GetData("equipment", {})
    if not equipment then return end

    -- Clear all slots
    equipment.Outfit = nil
    equipment.Vest = nil
    equipment.Helmet = nil
    equipment.Backpack = nil

    char:SetData("equipment", equipment)

    -- Revert model safely
    if victim.ApplyOutfit then
        victim:ApplyOutfit()
    end
end)
