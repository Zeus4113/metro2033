ITEM.name = "Mushroom Tea"
ITEM.model = "models/kek1ch/drink_tea.mdl"
ITEM.description = "A warm drink brewed from cave mushrooms and purified water."

ITEM.width = 1
ITEM.height = 2
ITEM.weight = 0.4
ITEM.price = 5

ITEM.thirst = 25
ITEM.hunger = 0
ITEM.radiation = -40
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