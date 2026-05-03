ITEM.name = "Mushroom Vodka"
ITEM.model = "models/fallout 3/vodka.mdl"
ITEM.description = "A crude alcoholic drink distilled from fermented mushrooms and purified water."

ITEM.width = 1
ITEM.height = 2
ITEM.weight = 0.5
ITEM.price = 34

ITEM.thirst = 25
ITEM.hunger = 0
ITEM.radiation = -200
ITEM.health = 0

ITEM.duration = 50


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