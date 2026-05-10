
function Schema:OnCharacterCreated(client, character)
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

    local damage = dmgInfo:GetDamage()
    local originalDamage = damage
    local totalReduction = 0

    if ARMOR_DEBUG then
        print("---- ARMOR DEBUG ----")
        print("Incoming Damage:", damage)
    end

    for _, item in pairs(inventory:GetItems()) do
        if item:GetData("equip") and item.damageReduction and item.damageReduction > 0 then
            local durability = item:GetData("durability", 0)

            if durability > 0 then
                totalReduction = totalReduction + item.damageReduction

                if ARMOR_DEBUG then
                    print(string.format(
                        "[%s] %s | Reduction: %.2f | Durability: %.2f",
                        item.equipSlot,
                        item.name,
                        item.damageReduction,
                        durability
                    ))
                end
            elseif ARMOR_DEBUG then
                print(string.format(
                    "[%s] %s is broken (Durability 0)",
                    item.equipSlot,
                    item.name
                ))
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
    for _, item in pairs(inventory:GetItems()) do
        if item:GetData("equip") then
            local durability = item:GetData("durability", 0)

            if durability > 0 then
                local portion = damage * ix.config.Get("decDurabilityEquipment", 0.1)
                local newDurability = math.max(durability - portion, 0)

                item:SetData("durability", newDurability)

                if ARMOR_DEBUG then
                    print(string.format(
                        "[%s] %s durability reduced by %.2f → %.2f",
                        item.equipSlot,
                        item.name,
                        portion,
                        newDurability
                    ))
                end

                -- Break handling
                if newDurability <= 0 then
                    item:SetData("equip", nil)
                    char:UpdateWeight()

                    ent:Notify(item.name .. " has broken and was unequipped!")

                    if item.equipSlot == "Outfit" and ent.ApplyOutfit then
                        ent:ApplyOutfit()
                    end

                    -- Close container if open
                    if item.invWidth then
                        local index = item:GetData("id")
                        if index then
                            net.Start("ixEquipContainerClose")
                                net.WriteUInt(index, 32)
                            net.Send(ent)
                        end
                    end

                    ent:EmitSound(item.useSound, 80)

                    if ARMOR_DEBUG then
                        print(item.name .. " BROKE.")
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

    local inv = char:GetInventory()
    if inv then
        for _, item in pairs(inv:GetItems()) do
            if item:GetData("equip") then
                item:SetData("equip", nil)
            end
        end
    end

    if victim.ApplyOutfit then
        victim:ApplyOutfit()
    end
end)

-- One-time migration: move old char-stored equipment IDs to item flags
hook.Add("PlayerLoadedCharacter", "MetroMigrateEquipmentToItems", function(_, char)
    local old = char:GetData("equipment")
    if not old or not next(old) then return end

    for _, itemID in pairs(old) do
        if not ix.item.instances[itemID] then
            return -- items not loaded yet; abort and retry next login
        end
    end

    for _, itemID in pairs(old) do
        local item = ix.item.instances[itemID]
        if item and not item:GetData("equip") then
            item:SetData("equip", true)
        end
    end

    char:SetData("equipment", nil)
end)
