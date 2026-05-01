ITEM.name = "Consumable Base"
ITEM.model = "models/props_junk/PopCan01a.mdl"
ITEM.description = "Some consumable item."
ITEM.category = "Consumable"

ITEM.thirst = 0
ITEM.hunger = 0
ITEM.radiation = 0
ITEM.health = 0

ITEM.duration = 0

ITEM.weight = 1

ITEM.functions.Consume = {
	name = "Consume",
    OnRun = function(item)

        local character = item.player:GetCharacter()
        if not character then return end

        item:HandleConsume(character, item)

        return true
    end
}

function ITEM:HandleConsume(character, item)

    if item then
        item.weight = 0
        if IsValid(item.player) then
            if character then
                character:UpdateWeight()
            end
        end
    end

    for i = 1, self.duration do
        timer.Simple(i, function()
            
            if not character:GetPlayer():Alive() then return end

            if self.thirst and self.thirst ~= 0 then
                local thirst = character:GetThirst()
                character:SetThirst(math.Clamp(thirst + (self.thirst/self.duration), 0, 100))
                --print("New thirst: " .. character:GetThirst())
            end

            if self.hunger and self.hunger ~= 0 then
                local hunger = character:GetHunger()
                character:SetHunger(math.Clamp(hunger + (self.hunger/self.duration), 0, 100))
                --print("New hunger: " .. character:GetHunger())
            end

            if self.radiation and self.radiation ~= 0 then
                local radiation = character:GetRadiation()
                character:SetRadiation(math.Clamp(radiation + (self.radiation/self.duration), 0, ix.config.Get("radiationMax")))
                --print("New radiation: " .. character:GetRadiation())
            end

            if self.health and self.health ~= 0 then
                local health = character:GetPlayer():Health()
                character:GetPlayer():SetHealth(math.Clamp(health + (self.health/self.duration), 0, character:GetPlayer():GetMaxHealth()))
                --print("New health: " .. character:GetPlayer():Health())
            end

        end )
    end
end

if CLIENT then
    function ITEM:PopulateTooltip(tooltip)
        local client = LocalPlayer()
        local char = client:GetCharacter()

        -- Helper to add simple row
        local function AddLine(id, text, color)
            local row = tooltip:AddRow(id)
            row:SetText(text)
            row:SetTextColor(color or color_white)
            row:SizeToContents()
        end

        if self.hunger or self.thirst then

            local divider = tooltip:AddRow("divider")
            divider:SetText("────────────")
            divider:SetTextColor(Color(80, 80, 80))
            divider:SizeToContents()

            if self.hunger and self.hunger ~= 0 then
                AddLine("hunger", "Nutrition: " .. self.hunger)
            end

            if self.thirst and self.thirst ~= 0 then
                AddLine("thirst", "Hydration: " .. self.thirst)
            end

            if self.radiation and self.radiation ~= 0 then
                AddLine("radiation", "Radiation: " .. self.radiation .. " rads")
            end

            if self.health and self.health ~= 0 then
                AddLine("health", "Health: " .. self.health .. " hp")
            end

            if self.duration and self.duration ~= 0 then
                AddLine("duration", "Duration: " .. self.duration .. " seconds")
            end

            if self:GetWeight() then
                AddLine("weight", "Weight: " .. ix.weight.WeightString(self:GetWeight()))
            end
        end

    end
end