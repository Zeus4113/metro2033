RECIPE.name = "Craft Reich Officer Uniform"
RECIPE.description = "Tailor the formal combat uniform of a Fourth Reich officer."
RECIPE.model = "models/devcon/mrp/act/player/reich_offizier_jake.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["textile_patch"] = 1,
	["cloth"] = 2,
}

RECIPE.results = {
	["outfit_reich_officer"] = 1,
}

RECIPE.skillIncrease = 0.32

RECIPE.skills = {
	["Tailoring"] = 8,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	if not client or not client:GetCharacter() then return false end
	local char = client:GetCharacter()
	if char:GetFaction() ~= FACTION_FOURTH_REICH then
		return false, "Only Fourth Reich soldiers can craft this uniform."
	end
	if char:GetClass() ~= CLASS_REICH_OFFICER then
		return false, "Only Reich Officers can craft this uniform."
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
	return char:GetFaction() == FACTION_FOURTH_REICH and char:GetClass() == CLASS_REICH_OFFICER
end)
