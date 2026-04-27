ITEM.name = "Dweller Stew"
ITEM.model = "models/wick/wrbstalker/anomaly/items/wick_chimera_food.mdl"
ITEM.description = "A hearty stew combining rat meat, mutant meat and mushrooms cooked in purified water."

ITEM.width = 2
ITEM.height = 2
ITEM.weight = 1.0
ITEM.price = 22

ITEM.thirst = 25
ITEM.hunger = 100
ITEM.radiation = 10
ITEM.health = 0

ITEM.duration = 100

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