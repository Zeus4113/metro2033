RECIPE.name = "Craft Dweller Stew"
RECIPE.description = "A hearty stew combining rat meat, mutant meat and mushrooms cooked in purified water."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/wick_chimera_food.mdl"
RECIPE.category = "Food & Drink"

RECIPE.requirements = {
	["mutant_meat"] = 1,
	["organics"] = 2,
}

RECIPE.tools = {
	"cast_iron_pot",
}

RECIPE.results = {
    ["dweller_stew"] = 1
}

RECIPE.skillIncrease = 0.22

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