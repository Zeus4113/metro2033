RECIPE.name = "Disassemble G3A3"
RECIPE.description = "Strip down a military G3A3 into recoverable components."
RECIPE.model = "models/weapons/arccw/c_ur_g3.mdl"
RECIPE.category = "Disassemble"

RECIPE.requirements = {
	["g3a3"] = 1,
}

RECIPE.results = {
	["reciever"] = 1,
	["metal_spring"] = 2,
}

RECIPE.skillIncrease = 0.06

RECIPE.skills = {
	["Engineering"] = 10,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	if not client or not client:GetCharacter() then return false end
	local nearStation = false
	for _, v in pairs(ents.FindByClass("ix_station_engineering_bench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			nearStation = true
		end
	end
	if not nearStation then return false, "You need to be near an engineering bench." end
	return true
end)
