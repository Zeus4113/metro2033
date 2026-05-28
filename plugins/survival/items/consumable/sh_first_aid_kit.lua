ITEM.name = "First Aid Kit"
ITEM.model = "models/wick/wrbstalker/anomaly/items/dez_item_aptechka.mdl"
ITEM.description = "A more advanced medical kit containing multiple treatments and chemical reagents for serious injuries."

ITEM.width = 1
ITEM.height = 1
ITEM.weight = 0.5
ITEM.price = 105

ITEM.thirst = 0
ITEM.hunger = 0
ITEM.radiation = 0
ITEM.health = 100

ITEM.duration = 25

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