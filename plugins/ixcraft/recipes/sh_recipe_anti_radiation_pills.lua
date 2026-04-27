RECIPE.name = "Craft Anti Radiation Pills"
RECIPE.description = "Specialized medication designed to reduce radiation poisoning using refined chemical compounds."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/wick_dev_antirad.mdl"
RECIPE.category = "Medical"

RECIPE.requirements = {
	["complex_chemicals"] = 1,
	["chemicals"] = 2,
}

RECIPE.results = {
    ["anti_radiation_pills"] = 1
}


RECIPE.skillIncrease = 1.2

RECIPE.skills = {
    ["Chemistry"] = 12,
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