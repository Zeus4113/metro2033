ITEM.name = "Medkit"
ITEM.model = "models/wick/wrbstalker/anomaly/items/wick_dev_aptechka_low.mdl"
ITEM.description = "A compact medical kit containing chemical treatments and organic reagents for emergency care."

ITEM.width = 1
ITEM.height = 1
ITEM.weight = 0.3
ITEM.price = 23

ITEM.thirst = 0
ITEM.hunger = 0
ITEM.radiation = 0
ITEM.health = 75

ITEM.duration = 25


ITEM.functions.Consume = {
    name = "Use",
    OnRun = function(item)

        local character = item.player:GetCharacter()
        if not character then return end

        item.player:EmitSound("interface/medkit/medkit_use_1.mp3")

        item:HandleConsume(character, item)

        return true
    end
}