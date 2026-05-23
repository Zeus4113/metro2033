RECIPE.name = "Craft Reich Veteran Uniform"
RECIPE.description = "Reinforce a Reich uniform with ballistic plating for battle-hardened veterans."
RECIPE.model = "models/devcon/mrp/act/player/reich_nco.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["ballistic_plate"] = 1,
	["textile_patch"] = 2,
	["cloth"] = 3,
}

RECIPE.results = {
	["outfit_reich_veteran"] = 1,
}

RECIPE.skillIncrease = 0.98

RECIPE.skills = {
	["Tailoring"] = 12,
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
