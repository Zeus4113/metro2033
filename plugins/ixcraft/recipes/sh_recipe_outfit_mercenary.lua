RECIPE.name = "Craft Mercenary Outfit"
RECIPE.description = "A rugged outfit assembled from ballistic plates and textile patches. Provides moderate protection and is suitable for combat scenarios."
RECIPE.model = "models/hasst/randomguy/l_1.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
    ["ballistic_plate"] = 1,
	["textile_patch"] = 2,
	["cloth"] = 3,
}

RECIPE.results = {
    ["outfit_mercenary"] = 1
}

RECIPE.skillIncrease = 0.98

RECIPE.skills = {
    ["Tailoring"] = 12,
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