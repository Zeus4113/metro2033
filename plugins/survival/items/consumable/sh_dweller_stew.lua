ITEM.name = "Dweller Stew"
ITEM.model = "models/wick/wrbstalker/anomaly/items/wick_chimera_food.mdl"
ITEM.description = "A hearty stew combining rat meat, mutant meat and mushrooms cooked in purified water."

ITEM.thirst = 25
ITEM.hunger = 75
ITEM.radiation = 5
ITEM.health = 0

ITEM.duration = 120

ITEM.width = 2
ITEM.height = 2

ITEM.weight = 1.0
ITEM.price = 15

ITEM.functions.Consume = {
    name = "Eat",
    OnRun = function(item)

        local character = item.player:GetCharacter()
        if not character then return end

        item.player:EmitSound("npc/barnacle/barnacle_crunch2.wav")

        item:HandleConsume(character, item)

        return true
    end
}