RECIPE.name = "Craft Hansa Officer Coat"
RECIPE.description = "Tailor the distinctive trench coat of a Hansa officer."
RECIPE.model = "models/devcon/mrp/act/player/trenchcoat_brown.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["textile_patch"] = 1,
	["cloth"] = 2,
}

RECIPE.results = {
	["outfit_hansa_officer"] = 1,
}

RECIPE.skillIncrease = 0.32

RECIPE.skills = {
	["Tailoring"] = 8,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	if not client or not client:GetCharacter() then return false end
	local char = client:GetCharacter()
	if char:GetFaction() ~= FACTION_HANSA then
		return false, "Only Hanseatic League members can craft this uniform."
	end
	if char:GetClass() ~= CLASS_HANSA_OFFICER then
		return false, "Only Hansa Officers can craft this uniform."
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
	return char:GetFaction() == FACTION_HANSA and char:GetClass() == CLASS_HANSA_OFFICER
end)
