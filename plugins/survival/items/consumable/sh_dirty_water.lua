ITEM.name = "Dirty Water"
ITEM.model = "models/kek1ch/dev_drink_water.mdl"
ITEM.description = "Contaminated water gathered from underground sources. Must be purified before safe consumption."

ITEM.thirst = 15
ITEM.hunger = 0
ITEM.radiation = 30
ITEM.health = 0

ITEM.duration = 15

ITEM.width = 1
ITEM.height = 2

ITEM.weight = 1.0
ITEM.price = 4

ITEM.functions.Consume = {
    name = "Drink",
    OnRun = function(item)

        local character = item.player:GetCharacter()
        if not character then return end

        item.player:EmitSound("npc/barnacle/barnacle_gulp1.wav")

        item:HandleConsume(character, item)

        return true
    end
}