if (SERVER) then
    util.AddNetworkString("ixEquipContainerClose")
    util.AddNetworkString("ixEquipContainerOpen")
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

local function FindItemInSlot(char, slot)
    local inv = char:GetInventory()
    if not inv then return nil end
    for _, it in pairs(inv:GetItems()) do
        if it:GetData("equip") and it.equipSlot == slot then return it end
    end
end

local function FindEquippedGasmask(char)
    local inv = char:GetInventory()
    if not inv then return nil end
    for _, it in pairs(inv:GetItems()) do
        if it:GetData("equip") and it.isGasmask then return it end
    end
end



-- ==============================
-- REGISTER INVENTORY TYPE
-- ==============================

function ITEM:OnRegistered()
    if self.invWidth and self.invHeight then
        ix.inventory.Register(self.uniqueID, self.invWidth, self.invHeight, true)
        -- isBag makes Helix auto-open the sub-inventory panel when the player's inventory opens.
        -- Only set it when a sub-inventory actually exists; otherwise the logging plugin crashes
        -- trying to iterate a nil GetInventory() result.
        self.isBag = true
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
        
        if FindItemInSlot(char, item.equipSlot) then
            client:Notify("That slot is already occupied.")
            return false
        end

        if item.isGasmask and FindEquippedGasmask(char) then
            client:Notify("You already have a gasmask equipped.")
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

        item:SetData("equip", true)
        char:UpdateWeight()

        if item.invWidth then
            local index = item:GetData("id")
            if index then
                net.Start("ixEquipContainerOpen")
                net.WriteUInt(index, 32)
                net.Send(client)
            end
        end

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

        return not item:GetData("equip")
            and not FindItemInSlot(char, item.equipSlot)
            and not (item.isGasmask and FindEquippedGasmask(char))
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

        if not item:GetData("equip") then
            return false
        end

        item:SetData("equip", nil)
        char:UpdateWeight()

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

        return item:GetData("equip", false)
    end
}

-- ==============================
-- VIEW CONTAINER (bags integration)
-- ==============================

ITEM.functions.View = {
    icon = "icon16/briefcase.png",
    OnClick = function(item)
        if not item:GetData("equip") then return false end

        local index = item:GetData("id")
        if not index then return false end

        local panel = ix.gui["inv"..index]
        local inventory = ix.item.inventories[index]
        local parent = IsValid(ix.gui.menuInventoryContainer) and ix.gui.menuInventoryContainer or ix.gui.openedStorage

        if IsValid(panel) then
            panel:Remove()
        end

        if inventory and inventory.slots then
            panel = vgui.Create("ixInventory", IsValid(parent) and parent or nil)
            panel:SetInventory(inventory)
            panel:ShowCloseButton(false)
            panel:SetTitle(item:GetName())

            if parent ~= ix.gui.menuInventoryContainer then
                panel:Center()
            else
                panel:MoveToFront()
            end

            ix.gui["inv"..index] = panel
        end

        return false
    end,
    OnCanRun = function()
        return false
    end
}

-- ==============================
-- PREVENT NESTED CONTAINERS
-- ==============================

hook.Add("CanTransferItem", "MetroPreventNestedEquipContainers", function(item, old, newInv)
    -- Allow dropping (newInv == nil)
    if not newInv then return end

    if newInv:GetID() == 0 then return true end

    -- Derive the acting player from the source inventory's owner — this is
    -- reliable even when item.player hasn't been set (e.g. newly created items).
    local char = old and old.owner and ix.char.loaded[old.owner]
    local client = char and IsValid(char:GetPlayer()) and char:GetPlayer()

    -- Fallback to item.player for server-side operations where old has no owner.
    if not client then
        client = IsValid(item.player) and item.player
        char = client and client:GetCharacter()
    end

    -- Prevent moving equipped items
    if char and item:GetData("equip", false) then
        if client then client:Notify("You cannot move an equipped item.") end
        return false
    end

    -- World containers set vars.isBag = true (so other bags can't nest inside them).
    -- Explicitly allow any item into world containers so Helix's nested-bag check never fires.
    if newInv.vars and newInv.vars.isContainer then
        return true
    end

    -- Prevent nesting equip containers inside other equip containers (player-initiated only)
    if client and newInv.vars and newInv.vars.isEquipContainer and item.invWidth then
        client:Notify("You cannot place containers inside other containers.")
        return false
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
    if char and self.equipSlot and self:GetData("equip") then
        char:UpdateWeight()
        if self.equipSlot == "Outfit" and owner.ApplyOutfit then
            owner:ApplyOutfit()
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

    -- Remove from in-memory inventories
    local inventory = ix.item.inventories[index]
    if inventory then
        for _, invItem in pairs(inventory:GetItems()) do
            ix.item.instances[invItem:GetID()] = nil
        end

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

if SERVER then
    function ITEM:OnTransferred(oldInv, newInv)
        if not self.invWidth then return end

        local subInv = self:GetInventory()
        if not subInv then return end

        -- Purge all current receivers (container viewers, old owner, etc.)
        for _, ply in pairs(table.Copy(subInv:GetReceivers())) do
            subInv:RemoveReceiver(ply)
        end

        -- Add the new owner as the only receiver
        if newInv and newInv.owner then
            local char = ix.char.loaded[newInv.owner]
            if char then
                local ply = char:GetPlayer()
                if IsValid(ply) then
                    subInv:AddReceiver(ply)
                end
            end
        end
    end
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
            local char = IsValid(self.player) and self.player:GetCharacter()
            local charInv = char and char:GetInventory()
            -- Only claim ownership when the item is actually in this player's own inventory,
            -- not when they're merely viewing it through a container someone else owns.
            local itemBelongsToPlayer = charInv and (self.invID == charInv:GetID())

            ix.inventory.Restore(index, self.invWidth, self.invHeight, function(inv)
                inv.vars.isEquipContainer = self.uniqueID

                if itemBelongsToPlayer then
                    inv:SetOwner(char:GetID(), true)
                end

                for client, character in ix.util.GetCharacters() do
                    if character:GetID() == inv.owner then
                        inv:AddReceiver(client)
                        break
                    end
                end

                if IsValid(self.player) and not itemBelongsToPlayer then
                    inv:AddReceiver(self.player)
                    inv:Sync(self.player)
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

ITEM.postHooks.drop = function(item)
    local client = item.player
    if not IsValid(client) then return end

    local char = client:GetCharacter()
    if not char then return end

    -- Unequip if needed
    if item.equipSlot and item:GetData("equip") then
        item:SetData("equip", nil)

        if item.equipSlot == "Outfit" and client.ApplyOutfit then
            client:ApplyOutfit()
        end
    end

    -- Close container UI if open and disown sub-inventory
    if item.invWidth then
        local index = item:GetData("id")
        if index then
            net.Start("ixEquipContainerClose")
                net.WriteUInt(index, 32)
            net.Send(client)

            -- Release DB ownership so character loading won't pull this sub-inventory
            -- back as a character inventory while the item is lying in the world.
            local query = mysql:Update("ix_inventories")
                query:Update("character_id", 0)
                query:Where("inventory_id", index)
            query:Execute()

            local subInv = ix.item.inventories[index]
            if subInv then
                subInv.owner = nil
                subInv:RemoveReceiver(client)
            end
        end
    end

    -- Recalculate weight after dropping container
    char:UpdateWeight()
end

if CLIENT then
    net.Receive("ixEquipContainerClose", function()
        local index = net.ReadUInt(32)
        local panel = ix.gui["inv" .. index]

        if IsValid(panel) then
            panel:Close()
        end
    end)

    net.Receive("ixEquipContainerOpen", function()
        local index = net.ReadUInt(32)

        local char = LocalPlayer():GetCharacter()
        if not char then return end

        local inv = char:GetInventory()
        if not inv then return end

        for _, item in pairs(inv:GetItems()) do
            if item:GetData("id") == index and item.functions and item.functions.View then
                item.functions.View.OnClick(item)
                return
            end
        end
    end)

    -- Items with maxDurability get PaintOver replaced by the durability plugin.
    -- This base version handles equippables that have no durability tracking.
    function ITEM:PaintOver(item, w)
        if not item.equipSlot or not item:GetData("equip") then return end

        local label = string.upper(item.equipSlot)

        surface.SetFont("DermaDefaultBold")
        local textW, textH = surface.GetTextSize(label)

        local padding = 6
        local boxW = textW + padding * 2
        local boxH = textH + 4

        draw.RoundedBox(4, w - boxW - 4, 4, boxW, boxH, Color(20, 120, 20, 220))
        draw.SimpleText(label, "DermaDefaultBold", w - boxW / 2 - 4, 4 + boxH / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function ITEM:PopulateTooltip(tooltip)
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

        if self.extraCarryWeight and self.extraCarryWeight > 0 then
            AddLine("carry", "Extra Carry Weight: " .. ix.weight.WeightString(self.extraCarryWeight))
        end
    end
end