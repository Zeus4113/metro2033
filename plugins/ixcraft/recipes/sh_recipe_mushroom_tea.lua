RECIPE.name = "Brew Mushroom Tea"
RECIPE.description = "Mushrooms steeped in purified water over a fire, brewed in a kettle to make a warm, restorative tea."
RECIPE.model = "models/kek1ch/drink_tea.mdl"
RECIPE.category = "Food & Drink"

RECIPE.requirements = {
	["mushroom"] = 1,
	["purified_water"] = 1,
}

RECIPE.tools = {
	"kettle",
}

RECIPE.results = {
	["mushroom_tea"] = 1
}

RECIPE.skillIncrease = 0.18

RECIPE.skills = {
	["Chemistry"] = 0,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

	if not client or not client:GetCharacter() then return false end

	local nearStation = false

	for _, v in pairs(ents.FindByClass("ix_station_cooking_station")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			nearStation = true
		end
	end

	if not nearStation then return false, "You need to be near a cooking station." end

	return true
end)
