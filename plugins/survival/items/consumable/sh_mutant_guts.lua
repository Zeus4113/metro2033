ITEM.name = "Mutant Guts"
ITEM.description = "Freshly harvested organs from a mutant. Used in medical and food crafting recipes."
ITEM.model = "models/vj_base/gibs/human/gib3.mdl"

ITEM.width = 2
ITEM.height = 1
ITEM.weight = 0.3
ITEM.price = 3

ITEM.thirst = 0
ITEM.hunger = 20
ITEM.radiation = 60
ITEM.health = 0

ITEM.duration = 30

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
