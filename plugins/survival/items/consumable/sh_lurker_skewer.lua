ITEM.name = "Lurker Skewer"
ITEM.model = "models/clutter/iguanaonastick.mdl"
ITEM.description = "A simple cooked meal made by roasting lurker meat over an open flame."

ITEM.width = 2
ITEM.height = 1
ITEM.weight = 0.5
ITEM.price = 3

ITEM.thirst = 0
ITEM.hunger = 33
ITEM.radiation = 10
ITEM.health = 0

ITEM.duration = 33

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