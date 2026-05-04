RECIPE.name = "Craft Lurker Skewer"
RECIPE.description = "A simple cooked meal made by roasting lurker meat over an open flame."
RECIPE.model = "models/clutter/iguanaonastick.mdl"
RECIPE.category = "Food & Drink"

RECIPE.requirements = {
	["lurker_meat"] = 1,
}

RECIPE.results = {
    ["lurker_skewer"] = 1
}


RECIPE.skillIncrease = 0.03

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