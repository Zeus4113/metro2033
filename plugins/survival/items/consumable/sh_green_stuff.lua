ITEM.name = "Green Stuff"
ITEM.model = "models/wick/wrbstalker/anomaly/items/dez_stim3.mdl"
ITEM.description = "A powerful injectable stimulant used to rapidly restore health, created using complex medical reagents and chemicals."

ITEM.thirst = 0
ITEM.hunger = 0
ITEM.radiation = -150
ITEM.health = 0

ITEM.duration = 30

ITEM.width = 1
ITEM.height = 1

ITEM.weight = 0.3
ITEM.price = 184

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