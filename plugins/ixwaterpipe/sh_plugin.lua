PLUGIN.name = "Water Pipe"
PLUGIN.author = "metro2033"
PLUGIN.description = "Adds an interactive water pipe entity that provides dirty water."

ix.config.Add("waterPipeFillTime", 3, "Time in seconds to fill a bottle from the pipe.", nil, {
	data = {min = 1, max = 30},
	category = PLUGIN.name
})

ix.config.Add("waterPipeCooldown", 120, "Cooldown in seconds before the pipe can be used again.", nil, {
	data = {min = 10, max = 3600},
	category = PLUGIN.name
})
