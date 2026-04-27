ITEM.name = "Mutant Meat"
ITEM.model = "models/fallout 3/meat.mdl"
ITEM.description = "Raw meat harvested from mutated creatures. Unsafe to eat without proper cooking or preparation."

ITEM.width = 2
ITEM.height = 2
ITEM.weight = 2.0
ITEM.price = 6

ITEM.thirst = 0
ITEM.hunger = 66
ITEM.radiation = 100
ITEM.health = 0

ITEM.duration = 66 


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