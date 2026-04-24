ITEM.name = "Medkit"
ITEM.model = "models/wick/wrbstalker/anomaly/items/wick_dev_aptechka_low.mdl"
ITEM.description = "A compact medical kit containing chemical treatments and organic reagents used for emergency care."

ITEM.thirst = 0
ITEM.hunger = 0
ITEM.radiation = 0
ITEM.health = 60

ITEM.duration = 30

ITEM.width = 1
ITEM.height = 1

ITEM.weight = 1.0
ITEM.price = 37

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