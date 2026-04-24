ITEM.name = "Bandage"
ITEM.model = "models/wick/wrbstalker/anomaly/items/wick_dev_bandage.mdl"
ITEM.description = "A simple medical dressing crafted from cloth and treated with basic chemical disinfectant"

ITEM.thirst = 0
ITEM.hunger = 0
ITEM.radiation = 0
ITEM.health = 10

ITEM.duration = 5

ITEM.width = 1
ITEM.height = 1

ITEM.weight = 0.2
ITEM.price = 16

ITEM.functions.Consume = {
    name = "Use",
    OnRun = function(item)

        local character = item.player:GetCharacter()
        if not character then return end

        item.player:EmitSound("items/medshot4.wav")

        item:HandleConsume(character, item)

        return true
    end
}