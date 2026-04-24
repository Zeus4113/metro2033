ITEM.name = "Painkillers"
ITEM.model = "models/wick/wrbstalker/anomaly/items/dez_drug_sleeping_pills.mdl"
ITEM.description = "A small dose of chemical medication used to suppress pain and keep wounded survivors functional."

ITEM.thirst = 0
ITEM.hunger = 0
ITEM.radiation = 0
ITEM.health = 50

ITEM.duration = 50

ITEM.width = 1
ITEM.height = 1

ITEM.weight = 0.1
ITEM.price = 21

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