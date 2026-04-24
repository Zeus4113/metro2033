RECIPE.name = "Craft Bandage"
RECIPE.description = "A simple medical dressing crafted from cloth and treated with basic chemical disinfectant"
RECIPE.model = "models/wick/wrbstalker/anomaly/items/wick_dev_bandage.mdl"
RECIPE.category = "Medical"

RECIPE.requirements = {
	["cloth"] = 1,
	["chemicals"] = 1,
}

RECIPE.results = {
    ["bandage"] = 1
}


RECIPE.skillIncrease = 0.5

RECIPE.skills = {
    ["Chemistry"] = 4,
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