local PLUGIN = PLUGIN

PLUGIN.name = "Survival"
PLUGIN.author = "BarneytheBandit"
PLUGIN.description = "Survial stats for characters"

ix.config.Add("DrainTick", 60, "Duration in seconds between drain ticks.", nil, {
	data = {min = 1, max = 300},
	category = "Survival"
})

ix.config.Add("HungerDrain", 1, "Hunger lost per tick.", nil, {
	data = {min = 0, max = 100, decimals = 2},
	category = "Survival"
})

ix.config.Add("ThirstDrain", 1.5, "Thirst lost per tick.", nil, {
	data = {min = 0, max = 100, decimals = 2},
	category = "Survival"
})

ix.config.Add("StarvationDamage", 2, "Damage applied to player when they are starving.", nil, {
	data = {min = 0, max = 10},
	category = "Survival"
})

ix.config.Add("DehydrationDamage", 3, "Damage applied to player when they are dehydrated.", nil, {
	data = {min = 0, max = 10},
	category = "Survival"
})

ix.command.Add("CharSetHunger", {
	description = "Set a character's hunger.",
	superAdminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.number
	},
	OnRun = function(self, client, target, amount)
		target:SetHunger(amount)
		client:Notify("Set " .. target:GetName() .. "'s hunger to " .. amount .. ".")
	end
})

ix.command.Add("CharSetThirst", {
	description = "Set a character's thirst.",
	superAdminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.number
	},
	OnRun = function(self, client, target, amount)
		target:SetThirst(amount)
		client:Notify("Set " .. target:GetName() .. "'s thirst to " .. amount .. ".")
	end
})

ix.char.RegisterVar("Hunger", {
    field = "hunger",
    fieldType = ix.type.number,
    default = 100
})

ix.char.RegisterVar("Thirst", {
    field = "thirst",
    fieldType = ix.type.number,
    default = 100
})

ix.char.RegisterVar("StaminaMultiplier", {
	field = "staminaMultiplier",
	fieldType = ix.type.number,
	default = 1
})

ix.util.Include("sv_plugin.lua")