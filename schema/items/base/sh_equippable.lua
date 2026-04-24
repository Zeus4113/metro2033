if (SERVER) then
    util.AddNetworkString("ixEquipContainerClose")
end

ITEM.name = "Base Equippable"
ITEM.description = "A wearable item."
ITEM.category = "Equipment"

ITEM.useSound = "npc/combine_soldier/zipline_clothing1.wav"
ITEM.weight = 0
ITEM.repairType = "equipment"

-- ==============================
-- SLOT SYSTEM
-- ==============================

ITEM.equipSlot = nil -- "outfit", "vest", "helmet"

-- ==============================
-- OUTFIT SUPPORT
-- ==============================

ITEM.outfitModel = nil

-- ==============================
-- ARMOR SUPPORT
-- ==============================

ITEM.damageReduction = 0
ITEM.maxDurability = 0

-- ==============================
-- CONTAINER SUPPORT
-- ==============================

ITEM.invWidth = nil
ITEM.invHeight = nil

-- ==============================
-- RADIATION SUPPORT
-- ==============================

ITEM.radiationProtection = 0   -- 0.0 to 1.0 (percentage reduction)
ITEM.isGasmask = false         -- cosmetic / logic flag
ITEM.filterDrainRate = 0       -- optional future use
ITEM.maxFilterTime = 0

-- ==============================
-- INTERNAL HELPERS
-- ==============================

local function GetEquipment(char)
    return char:GetData("equipment", {
        outfit = nil,
        vest = nil,
        helmet = nil
    })
end

local function SetEquipment(char, equipment)
    char:SetData("equipment", equipment)
end



-- ==============================
-- REGISTER INVENTORY TYPE
-- ==============================

function ITEM:OnRegistered()
    if self.invWidth and self.invHeight then
        ix.inventory.Register(self.uniqueID, self.invWidth, self.invHeight, true)
    end
end

-- ==============================
-- INSTANCE INIT
-- ==============================

function ITEM:OnInstanced(invID, x, y)
    if self.maxDurability and self.maxDurability > 0 then
        if self:GetData("durability") == nil then
            self:SetData("durability", self.maxDurability)
        end
    end

    -- Initialize filter time for gasmasks
    if self.isGasmask and self.maxFilterTime > 0 then
        if self:GetData("filterTime") == nil then
            self:SetData("filterTime", 0)
        end
    end
end

-- ==============================
-- GET CONTAINER INVENTORY
-- ==============================

function ITEM:GetInventory()
    local index = self:GetData("id")
    if index then
        return ix.item.inventories[index]
    end
end

-- ==============================
-- EQUIP
-- ==============================

ITEM.functions.Equip = {
    name = "Equip",
    icon = "icon16/tick.png",
    OnRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end

        local char = client:GetCharacter()
        if not char or not item.equipSlot then return false end

        local equipment = GetEquipment(char)

        if equipment[item.equipSlot] then
            client:Notify("That slot is already occupied.")
            return false
        end

        -- Prevent equipping broken armor
        if item.maxDurability and item.maxDurability > 0 then
            local durability = item:GetData("durability", 0)
            if durability <= 0 then
                client:Notify("This item is broken.")
                return false
            end
        end

        equipment[item.equipSlot] = item:GetID()
        SetEquipment(char, equipment)

        if item.equipSlot == "Outfit" and client.ApplyOutfit then
            client:ApplyOutfit()
            print("apply outfit: " .. item.outfitModel)
        end

        --client:Notify("Equipped.")
		client:EmitSound(item.useSound, 80)
        return false
    end,

    OnCanRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end

        local char = client:GetCharacter()
        if not char or not item.equipSlot then return false end

        -- 🔥 NEW: Must be in main inventory
        local mainInv = char:GetInventory()
        if not mainInv or item.invID ~= mainInv:GetID() then
            return false
        end

        local equipment = char:GetData("equipment", {})
        return equipment[item.equipSlot] ~= item:GetID()
    end
}

-- ==============================
-- UNEQUIP
-- ==============================

ITEM.functions.Unequip = {
    name = "Unequip",
	icon = "icon16/cross.png",
    OnRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end

        local char = client:GetCharacter()
        if not char or not item.equipSlot then return false end

        local equipment = GetEquipment(char)

        if equipment[item.equipSlot] ~= item:GetID() then
            return false
        end

        equipment[item.equipSlot] = nil
        SetEquipment(char, equipment)

        if item.equipSlot == "Outfit" and client.ApplyOutfit then
            client:ApplyOutfit()
        end

        -- Close container if open
        if item.invWidth then
            local index = item:GetData("id")
            if index then
                net.Start("ixEquipContainerClose")
                    net.WriteUInt(index, 32)
                net.Send(client)
            end
        end

        --client:Notify("Unequipped.")
        client:EmitSound(item.useSound, 80)
        return false
    end,

    OnCanRun = function(item)
        local client = item.player
        if not IsValid(client) then return false end
        local char = client:GetCharacter()
        if not char or not item.equipSlot then return false end

        local equipment = GetEquipment(char)
        return equipment[item.equipSlot] == item:GetID()
    end
}

-- ==============================
-- PREVENT NESTED CONTAINERS
-- ==============================

hook.Add("CanTransferItem", "MetroPreventNestedEquipContainers", function(item, oldInv, newInv)
    -- Allow dropping (newInv == nil)
    if not newInv then return end

    if newInv:GetID() == 0 then return true end

    local owner = item:GetOwner()
    local char = IsValid(owner) and owner:GetCharacter()

    -- 🔥 1️⃣ Prevent moving equipped equippables
    if char and item.equipSlot then
        local equipment = char:GetData("equipment", {})

        if equipment[item.equipSlot] == item:GetID() then
            owner:Notify("You cannot move an equipped item.")
            return false
        end
    end

    -- 🔥 2️⃣ Prevent nesting equip containers
    if newInv.vars and newInv.vars.isEquipContainer then
        if item.invWidth then
            owner:Notify("You cannot place containers inside other containers.")
            return false
        end
    end
end)

-- ==============================
-- CLEANUP ON REMOVAL
-- ==============================

function ITEM:OnRemoved()
    local owner = self:GetOwner()
    local char = IsValid(owner) and owner:GetCharacter()

    -- ==============================
    -- UNEQUIP SAFELY
    -- ==============================
    if char and self.equipSlot then
        local equipment = char:GetData("equipment", {})

        if equipment[self.equipSlot] == self:GetID() then
            equipment[self.equipSlot] = nil
            char:SetData("equipment", equipment)

            if self.equipSlot == "Outfit" and owner.ApplyOutfit then
                owner:ApplyOutfit()
            end
        end
    end

    -- ==============================
    -- HANDLE CONTAINER CLEANUP
    -- ==============================
    if not self.invWidth then return end

    local index = self:GetData("id")
    if not index then return end

    -- Close UI if it's open
    if IsValid(owner) then
        net.Start("ixEquipContainerClose")
            net.WriteUInt(index, 32)
        net.Send(owner)
    end

    -- Remove from in-memory inventories (CRITICAL)
    local inventory = ix.item.inventories[index]
    if inventory then
        -- Optional: clear receivers to prevent weird syncing
        inventory.receivers = {}

        ix.item.inventories[index] = nil
    end

    -- ==============================
    -- DATABASE CLEANUP
    -- ==============================
    local query = mysql:Delete("ix_items")
        query:Where("inventory_id", index)
    query:Execute()

    query = mysql:Delete("ix_inventories")
        query:Where("inventory_id", index)
    query:Execute()
end

function ITEM:OnSendData()
    if not self.invWidth then return end

    local index = self:GetData("id")

    if index then
        local inventory = ix.item.inventories[index]

        if inventory then
            inventory.vars.isEquipContainer = self.uniqueID
            inventory:Sync(self.player)
            inventory:AddReceiver(self.player)
        else
            local owner = self.player:GetCharacter():GetID()

            ix.inventory.Restore(index, self.invWidth, self.invHeight, function(inv)
                inv.vars.isEquipContainer = self.uniqueID
                inv:SetOwner(owner, true)

                for client, character in ix.util.GetCharacters() do
                    if character:GetID() == inv.owner then
                        inv:AddReceiver(client)
                        break
                    end
                end
            end)
        end
    else
        ix.inventory.New(self.player:GetCharacter():GetID(), self.uniqueID, function(inv)
            inv.vars.isEquipContainer = self.uniqueID
            inv:SetOwner(self.player:GetCharacter():GetID(), true)

            self:SetData("id", inv:GetID())

            inv:AddReceiver(self.player)
        end)
    end
end

ITEM.postHooks.drop = function(item, result)
    local client = item.player
    if not IsValid(client) then return end

    local char = client:GetCharacter()
    if not char then return end

    local equipment = char:GetData("equipment", {})

    -- Unequip if needed
    if item.equipSlot and equipment[item.equipSlot] == item:GetID() then
        equipment[item.equipSlot] = nil
        char:SetData("equipment", equipment)

        if item.equipSlot == "Outfit" and client.ApplyOutfit then
            client:ApplyOutfit()
        end
    end

    -- Close container UI if open
    if item.invWidth then
        local index = item:GetData("id")
        if index then
            net.Start("ixEquipContainerClose")
                net.WriteUInt(index, 32)
            net.Send(client)
        end
    end

    -- Recalculate weight after dropping container
    if IsValid(client) then
        local char = client:GetCharacter()
        if char then
            char:UpdateWeight()
        end
    end
end

if CLIENT then
    net.Receive("ixEquipContainerClose", function()
        local index = net.ReadUInt(32)
        local panel = ix.gui["inv" .. index]

        if IsValid(panel) then
            panel:Close()
        end
    end)

    function ITEM:PopulateTooltip(tooltip)
        local client = LocalPlayer()
        local char = client:GetCharacter()

        local equipment = char and char:GetData("equipment", {})
        local isEquipped = equipment and self.equipSlot
            and equipment[self.equipSlot] == self:GetID()

        -- Helper to add simple row
        local function AddLine(id, text, color)
            local row = tooltip:AddRow(id)
            row:SetText(text)
            row:SetTextColor(color or color_white)
            row:SizeToContents()
        end

        -- Divider line
        local divider = tooltip:AddRow("divider")
        divider:SetText("────────────")
        divider:SetTextColor(Color(80, 80, 80))
        divider:SizeToContents()


        if self.isGasmask then
            if self:GetData("filterTime") then
                AddLine("gasmask", "Filter Time: " .. math.Round(self:GetData("filterTime")))
            end
        end

        -- ARMOR REDUCTION
        if self.damageReduction and self.damageReduction > 0 then
            local percent = math.Round(self.damageReduction * 100)
            AddLine("armor", "Damage Reduction: " .. percent .. "%")
        end

        if self.radiationProtection and self.radiationProtection > 0 then
            local percent = math.Round(self.radiationProtection * 100)
            AddLine("rad", "Radiation Protection: " .. percent .. "%")
        end

        -- STORAGE
        if self.invWidth and self.invHeight then
            local slots = self.invWidth * self.invHeight
            AddLine("storage", "Storage: " .. self.invWidth .. "x" .. self.invHeight .. " (" .. slots .. " slots)")
        end

        --[[
        -- SLOT
        if self.equipSlot then
            AddLine("slot", "Slot: " .. self.equipSlot)
        end

        -- DURABILITY
        if self.maxDurability and self.maxDurability > 0 then
            local durability = math.Round(self:GetData("durability", self.maxDurability))

            local color = color_white
            if durability <= 0 then
                color = Color(200, 60, 60)
            elseif durability < (self.maxDurability * 0.25) then
                color = Color(220, 150, 50)
            end

            AddLine("durability", "Durability: " .. durability .. " / " .. self.maxDurability, color)
        end
        
        -- WEIGHT
        if self:GetWeight() then
            AddLine("weight", "Weight: " .. ix.weight.WeightString(self:GetWeight()))
        end

        -- Equipped State
        if isEquipped then
            AddLine("equipped", "Equipped", Color(80, 200, 120))
        end
        ]]
    end
end