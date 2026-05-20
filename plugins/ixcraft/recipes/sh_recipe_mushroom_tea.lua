RECIPE.name = "Craft Mushroom Tea"
RECIPE.description = "A warm drink brewed from cave mushrooms and purified water."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/dez_drink_tea.mdl"
RECIPE.category = "Food & Drink"

RECIPE.requirements = {
    ["mushroom"] = 1,
	["purified_water"] = 1,
}

RECIPE.results = {
    ["mushroom_tea"] = 1
}


RECIPE.skillIncrease = 0.13

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