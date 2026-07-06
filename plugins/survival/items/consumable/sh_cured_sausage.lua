ITEM.name = "Cured Sausage"
ITEM.description = "A preserved meat sausage made from mutant meat and organs. Lasts longer than fresh cuts."
ITEM.model = "models/props_junk/garbage_metalcan001a.mdl"

ITEM.width = 2
ITEM.height = 1
ITEM.weight = 0.25
ITEM.price = 8

ITEM.thirst = -20
ITEM.hunger = 50
ITEM.radiation = 5
ITEM.health = 0

ITEM.duration = 50

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
