
-- Here is where all of your shared hooks should go.

-- Disable entity driving.
function Schema:CanDrive(client, entity)
	return false
end

hook.Add("PlayerLoadedCharacter", "FixUnequippedBags", function(client, char)

    for _, item in pairs(char:GetInventory():GetItems()) do

        if (item.isBag and item:GetData("id")) then

            local inv = ix.item.inventories[item:GetData("id")]

            if (inv and not item:GetData("equip")) then
                inv:RemoveReceiver(client)
            end
        end
    end
end)

-- Disable auto-open bags permanently
hook.Add("InitializedOptions", "DisableOpenBagsOption", function()

    local opt = ix.option.stored and ix.option.stored.openBags
    if (!opt) then return end

    -- Force default OFF
    opt.default = false

    -- Hide from settings menu
    opt.hidden = true
end)


-- Prevent players changing it
hook.Add("CanPlayerModifyOption", "BlockOpenBagsChange", function(client, key)

    if (key == "openBags") then
        return false
    end
end)