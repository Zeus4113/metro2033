RECIPE.name = "Craft Painkillers"
RECIPE.description = "A small dose of chemical medication used to suppress pain and keep wounded survivors functional."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/dez_drug_sleeping_pills.mdl"
RECIPE.category = "Medical"

RECIPE.requirements = {
	["organics"] = 1,
	["chemicals"] = 2,
}

RECIPE.results = {
    ["painkillers"] = 1
}


RECIPE.skillIncrease = 0.75

RECIPE.skills = {
    ["Chemistry"] = 6,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_chemistry_set")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a chemistry set." end

    return true
end)