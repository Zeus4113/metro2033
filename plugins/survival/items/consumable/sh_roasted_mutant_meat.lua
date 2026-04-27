ITEM.name = "Roasted Mutant Meat"
ITEM.model = "models/wick/wrbstalker/anomaly/items/wick_meat_flesh_cooked.mdl"
ITEM.description = "Cooked mutant meat prepared over heat to make it safe for consumption."

ITEM.width = 2
ITEM.height = 2
ITEM.weight = 1.5
ITEM.price = 6

ITEM.thirst = 0
ITEM.hunger = 66
ITEM.radiation = 20
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