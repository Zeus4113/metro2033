RECIPE.name = "Craft Purified Water"
RECIPE.description = "Water that has been boiled and filtered to remove harmful contaminants."
RECIPE.model = "models/kek1ch/dev_drink_stalker.mdl"
RECIPE.category = "Food & Drink"

RECIPE.requirements = {
	["dirty_water"] = 2,
}

RECIPE.results = {
    ["purified_water"] = 1
}


RECIPE.skillIncrease = 0.25

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