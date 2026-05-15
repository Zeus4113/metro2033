ITEM.name = "Mushroom"
ITEM.description = "Edible cave mushroom commonly farmed in the Metro. Used in food recipes and organic processing."
ITEM.model = "models/avoxgaming/mrp/jake/props/mushroom_2.mdl"

ITEM.width = 2
ITEM.height = 2
ITEM.weight = 1.0
ITEM.price = 16

ITEM.thirst = 0
ITEM.hunger = 25
ITEM.radiation = 50
ITEM.health = 0

ITEM.duration = 60

ITEM.iconCam = {
	pos = Vector(3, 200, 0),
	ang = Angle(-2.07, 269.92, 0),
	fov = 5.26
}


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
