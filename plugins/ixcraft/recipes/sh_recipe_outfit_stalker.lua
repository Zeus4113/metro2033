RECIPE.name = "Craft Stalker Outfit"
RECIPE.description = "A rugged outfit assembled from kevlar weave, ballistic plates, and textile patches. Provides good protection while maintaining mobility, making it ideal for stalkers navigating the dangerous metro environment."
RECIPE.model = "models/survivors/sacrifice_sold.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
    ["kevlar_weave"] = 1,
    ["ballistic_plate"] = 2,
	["textile_patch"] = 3,
}

RECIPE.results = {
    ["outfit_stalker"] = 1
}

RECIPE.skillIncrease = 2.1

RECIPE.skills = {
    ["Tailoring"] = 16,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_tailors_table")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a tailoring table." end

    return true
end)