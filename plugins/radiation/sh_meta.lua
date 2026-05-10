local CHAR = ix.meta.character

function CHAR:GetRadiation()
    return self:GetData("radiation", 0)
end

function CHAR:SetRadiation(amount)
    local max = ix.config.Get("radiationMax", 100)
    self:SetData("radiation", math.Clamp(amount, 0, max))
end

function CHAR:AddRadiation(amount)
    self:SetRadiation(self:GetRadiation() + amount)
end

function CHAR:GetRadiationProtection()
    local protection = 0
    local equipment = self:GetEquipment()

    for _, itemID in pairs(equipment) do
        local item = ix.item.instances[itemID]

        if item and item.radiationProtection then
            
            if not item.maxDurability or item:GetData("durability", 0) > 0 then

                if not item.isGasmask then
                    protection = protection + item.radiationProtection
                elseif item.isGasmask and item:GetData("filterTime", 0) > 0 then
                    protection = protection + item.radiationProtection
                end
            end
        end
    end

    return math.Clamp(protection, 0, 1)
end