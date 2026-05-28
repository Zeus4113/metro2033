ITEM.name = "Purified Water"
ITEM.model = "models/kek1ch/dev_drink_stalker.mdl"
ITEM.description = "Water that has been boiled and filtered to remove harmful contaminants."

ITEM.width = 1
ITEM.height = 2
ITEM.weight = 0.5
ITEM.price = 3

ITEM.thirst = 33
ITEM.hunger = 0
ITEM.radiation = 0
ITEM.health = 0

ITEM.duration = 33


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