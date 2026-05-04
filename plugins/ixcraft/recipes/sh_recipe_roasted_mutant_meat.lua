RECIPE.name = "Craft Roasted Mutant Meat"
RECIPE.description = "Cooked mutant meat prepared over heat to make it safe for consumption."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/wick_meat_flesh_cooked.mdl"
RECIPE.category = "Food & Drink"

RECIPE.requirements = {
	["mutant_meat"] = 1,
}

RECIPE.results = {
    ["roasted_mutant_meat"] = 1
}


RECIPE.skillIncrease = 0.06

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