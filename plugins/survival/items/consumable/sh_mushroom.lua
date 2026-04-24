ITEM.name = "Mushrooms"
ITEM.description = "Edible cave mushrooms commonly farmed in the Metro. Used in food recipes and organic processing."

ITEM.category = "Junk"
ITEM.weight = 1.0
ITEM.price = 2

ITEM.thirst = 0
ITEM.hunger = 10
ITEM.radiation = 30
ITEM.health = 0

ITEM.duration = 20

ITEM.model = "models/avoxgaming/mrp/jake/props/mushroom_1.mdl"
ITEM.width = 2
ITEM.height = 2
ITEM.iconCam = {
	pos = Vector(0, 200, 0),
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
