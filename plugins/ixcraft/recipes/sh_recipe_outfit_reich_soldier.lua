RECIPE.name = "Craft Reich Soldier Uniform"
RECIPE.description = "Assemble a standard Fourth Reich combat uniform for enlisted soldiers."
RECIPE.model = "models/devcon/mrp/act/player/reich_enlisted.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["textile_patch"] = 1,
	["cloth"] = 2,
}

RECIPE.results = {
	["outfit_reich_soldier"] = 1,
}

RECIPE.skillIncrease = 0.32

RECIPE.skills = {
	["Tailoring"] = 8,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	if not client or not client:GetCharacter() then return false end
	if client:GetCharacter():GetFaction() ~= FACTION_FOURTH_REICH then
		return false, "Only Fourth Reich soldiers can craft this uniform."
	end
	local nearStation = false
	for _, v in pairs(ents.FindByClass("ix_station_tailors_table")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			nearStation = true
		end
	end
	if not nearStation then return false, "You need to be near a tailoring table." end
	return true
end)

RECIPE:PostHook("OnCanSee", function(recipeTable, client)
	if not client or not client:GetCharacter() then return false end
	return client:GetCharacter():GetFaction() == FACTION_FOURTH_REICH
end)
