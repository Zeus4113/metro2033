RECIPE.name = "Craft Hansa Sergeant Uniform"
RECIPE.description = "Construct a heavy Hansa sergeant's uniform with kevlar weave and ballistic plating."
RECIPE.model = "models/devcon/mrp/act/player/ranger_2.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["kevlar_weave"] = 1,
	["ballistic_plate"] = 2,
	["textile_patch"] = 3,
}

RECIPE.results = {
	["outfit_hansa_sergeant"] = 1,
}

RECIPE.skillIncrease = 2.1

RECIPE.skills = {
	["Tailoring"] = 16,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	if not client or not client:GetCharacter() then return false end
	local char = client:GetCharacter()
	if char:GetFaction() ~= FACTION_HANSA then
		return false, "Only Hanseatic League members can craft this uniform."
	end
	if char:GetClass() ~= CLASS_HANSA_SERGEANT then
		return false, "Only Hansa Sergeants can craft this uniform."
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
	return char:GetFaction() == FACTION_HANSA and char:GetClass() == CLASS_HANSA_SERGEANT
end)
