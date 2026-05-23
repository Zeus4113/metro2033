RECIPE.name = "Craft Reich Guard Uniform"
RECIPE.description = "Construct a heavy Fourth Reich sergeant's uniform with kevlar weave and ballistic plating."
RECIPE.model = "models/devcon/mrp/act/player/reich_guard.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["kevlar_weave"] = 1,
	["ballistic_plate"] = 2,
	["textile_patch"] = 3,
}

RECIPE.results = {
	["outfit_reich_sergeant"] = 1,
}

RECIPE.skillIncrease = 2.1

RECIPE.skills = {
	["Tailoring"] = 16,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	if not client or not client:GetCharacter() then return false end
	local char = client:GetCharacter()
	if char:GetFaction() ~= FACTION_FOURTH_REICH then
		return false, "Only Fourth Reich soldiers can craft this uniform."
	end
	if char:GetClass() ~= CLASS_REICH_SERGEANT then
		return false, "Only Reich Sergeants can craft this uniform."
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
	local char = client:GetCharacter()
	return char:GetFaction() == FACTION_FOURTH_REICH and char:GetClass() == CLASS_REICH_SERGEANT
end)
