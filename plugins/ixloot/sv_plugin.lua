local PLUGIN = PLUGIN

-- messy but idc.
function PLUGIN:SearchLootContainer(ent, client)
    if not ent.lootType then return end

    -- cooldown
    if ent.nextLootTime and ent.nextLootTime > CurTime() then
        client:Notify("There is nothing in the container.")
        return
    end


    if ent.requiredTools then

        local toolAmount = 0
        local inv = client:GetCharacter():GetInventory()

        for v, k in pairs(ent.requiredTools) do
            local item = inv:HasItem(k)
            if item then   
                if item.maxDurability and item:GetData("durability", item.maxDurability) > 0 then
                    toolAmount = toolAmount + 1 
                elseif not item.maxDurability then
                    toolAmount = toolAmount + 1
                end
            end
        end

        if toolAmount < table.Count(ent.requiredTools) then
            client:Notify("You do not have the required tools to open this.")
            return
        end

    end

    client:Freeze(true)

    if(ent.searchSounds) then
        client:EmitSound(table.Random(ent.searchSounds), 40)
    end

    client:SetAction(ent.searchText or "Searching..." , ent.searchTime or 5, function()

        if not IsValid(client) then return end

        local char = client:GetCharacter()
        if not char then client:Freeze(false) return end

        local inventory = char:GetInventory()
        if not inventory then client:Freeze(false) return end

        if ent.requiredTools then
            for k, v in pairs(ent.requiredTools) do
                local item = inventory:HasItem(v)
                if not item then continue end
                if not item.maxDurability then continue end

                item:SetData("durability", item:GetData("durability", item.maxDurability) - ix.config.Get("toolDurabilityDec", 15))

                if item:GetData("durability", item.maxDurability) <= 0 then
                    if item.Unequip then
                        item:Unequip(client)
                    end

                    local size = math.max(1, (item.width or 1) * (item.height or 1))
                    item:Remove()
                    inventory:Add("metal_scrap", size)
                    client:Notify(item.name .. " has broken.")
                end
            end
        end
        
        client:Freeze(false)

        local itemID
        local plugin = ix.plugin.Get("ixloot")

        if ent.lootTier and ent.lootType and math.random(1, 100) <= ix.config.Get("lootRareChanceTier" .. (ent.lootTier or 0), 10) then
            itemID = table.Random(plugin.loot[ent.lootTier][ent.lootType]["rare"])
        else
            itemID = table.Random(plugin.loot[ent.lootTier][ent.lootType]["common"])
        end


        local success = inventory:Add(itemID)

        local itemName = ix.item.Get(itemID).name

        if success then
            client:Notify("You found " .. itemName .. ".")
        else
            -- spawn item on ground
            local forward = client:GetForward() * 40
            local pos = client:GetPos() + forward + Vector(0,0,20)

            ix.item.Spawn(itemID, pos)

            client:Notify("You found " .. itemName .. ", but your inventory is full.")
        end

    end)

    local baseTime    = ix.config.Get("lootRespawnTier" .. (ent.lootTier or 0), 180)
    local maxPlayers  = ix.config.Get("lootScaleMaxPlayers", 32)
    local maxMult     = ix.config.Get("lootScaleMultiplier", 2.0)
    local playerCount = math.max(1, #player.GetAll())
    local scale       = maxMult - (maxMult - 1) * math.Clamp(playerCount / maxPlayers, 0, 1)
    ent.nextLootTime  = CurTime() + (baseTime * scale)
end

function Schema:SpawnRandomLoot(position, rareItem)
    local randomLootItem = table.Random(PLUGIN.randomLoot.common)

    if (rareItem == true) then
        randomLootItem = table.Random(PLUGIN.randomLoot.rare)
    end

    ix.item.Spawn(randomLootItem, position)
end
