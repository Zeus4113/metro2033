RECIPE.name = "Craft Hansa Guard Uniform"
RECIPE.description = "Assemble a standard Hansa guard uniform for station patrol duty."
RECIPE.model = "models/devcon/mrp/act/player/mercenary.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["textile_patch"] = 1,
	["cloth"] = 2,
}

RECIPE.results = {
	["outfit_hansa_soldier"] = 1,
}

RECIPE.skillIncrease = 0.32

RECIPE.skills = {
	["Tailoring"] = 8,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	if not client or not client:GetCharacter() then return false end
	if client:GetCharacter():GetFaction() ~= FACTION_HANSA then
		return false, "Only Hanseatic League members can craft this uniform."
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
	return client:GetCharacter():GetFaction() == FACTION_HANSA
end)
