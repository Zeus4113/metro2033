ITEM.name = "Lurker Meat"
ITEM.model = "models/fallout 3/human_meat.mdl"
ITEM.description = "Small cuts of meat taken from lurkers. Commonly used in simple survival meals."

ITEM.width = 2
ITEM.height = 1
ITEM.weight = 1.0
ITEM.price = 3

ITEM.thirst = 0
ITEM.hunger = 33
ITEM.radiation = 50
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