PLUGIN.name = "Mushroom Gathering"
PLUGIN.author = "metro2033"
PLUGIN.description = "Adds gatherable mushroom entities that grow over time."

ix.config.Add("mushroomGrowthTime", 300, "Time in seconds for a mushroom to fully grow.", nil, {
	data = {min = 30, max = 3600},
	category = PLUGIN.name
})

ix.config.Add("mushroomGrowthVariance", 20, "Random variance in growth time (+/- %).", nil, {
	data = {min = 0, max = 100},
	category = PLUGIN.name
})

ix.config.Add("mushroomDoubleChance", 20, "Chance (%) that a new mushroom growth cycle yields 2 on pick.", nil, {
	data = {min = 0, max = 100},
	category = PLUGIN.name
})

ix.config.Add("mushroomBrewingTime", 300, "Time in seconds to brew mushroom vodka in the brewing barrel.", nil, {
	data = {min = 30, max = 3600},
	category = PLUGIN.name
})

PLUGIN.brewIngredients = {
	{ id = "purified_water", count = 3 },
	{ id = "mushroom",       count = 6 },
}

PLUGIN.brewSkillReq = 6

ix.util.Include("sv_plugin.lua")

