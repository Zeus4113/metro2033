RECIPE.name = "Craft Mushroom Vodka"
RECIPE.description = "A crude alcoholic drink distilled from fermented mushrooms and purified water."
RECIPE.model = "models/fallout 3/vodka.mdl"
RECIPE.category = "Food & Drink"

RECIPE.requirements = {
	["mushroom"] = 1,
	["purified_water"] = 1,
    ["organics"] = 2
}

RECIPE.results = {
    ["mushroom_vodka"] = 1
}


RECIPE.skillIncrease = 0.5

RECIPE.skills = {
    ["Chemistry"] = 0,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_cooking_station")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a cooking station." end

    return true
end)