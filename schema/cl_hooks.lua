
-- Here is where all of your clientside hooks should go.

-- Disables the crosshair permanently.
function Schema:CharacterLoaded(character)
    self:ExampleFunction("@serverWelcome", character:GetName())
end

hook.Add("Think", "MetroAutoOpenEquipContainers", function()
local menu = ix.gui.menuInventoryContainer
if not IsValid(menu) then return end

local client = LocalPlayer()
local char = client:GetCharacter()
if not char then return end

local equipment = char:GetData("equipment", {})

for slot, itemID in pairs(equipment) do
    local item = ix.item.instances[itemID]

    if item and item.invWidth then
        -- Skip broken containers
        if item.maxDurability and item:GetData("durability", 0) <= 0 then
            continue
        end

        local index = item:GetData("id")
        if not index then continue end

        local inventory = ix.item.inventories[index]
        if not inventory then continue end

        -- Only create panel if it doesn't already exist
        if not IsValid(ix.gui["inv"..index]) then
            local panel = vgui.Create("ixInventory", menu)
            panel:SetInventory(inventory)
            panel:ShowCloseButton(false)
            panel:SetTitle(item:GetName())
            panel:MoveToFront()

            ix.gui["inv"..index] = panel
        end
    end
end
end)

hook.Add("OnCharacterMenuClosed", "MetroResetAutoOpenFlag", function()
ix.gui._metroAutoOpened = nil
end)