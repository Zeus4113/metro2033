ITEM.name = "Roasted Mutant Meat"
ITEM.model = "models/wick/wrbstalker/anomaly/items/wick_meat_flesh_cooked.mdl"
ITEM.description = "Cooked mutant meat prepared over heat to make it safe for consumption."

ITEM.thirst = 0
ITEM.hunger = 40
ITEM.radiation = 15
ITEM.health = 0

ITEM.duration = 60

ITEM.width = 2
ITEM.height = 2

ITEM.weight = 1.5
ITEM.price = 7

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