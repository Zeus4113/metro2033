RECIPE.name = "Craft Medkit"
RECIPE.description = "A compact medical kit containing chemical treatments and organic reagents used for emergency care."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/wick_dev_aptechka_low.mdl"
RECIPE.category = "Medical"

RECIPE.requirements = {
	["organics"] = 1,
	["chemicals"] = 1,
	["medical_reagents"] = 1,
}

RECIPE.results = {
    ["medkit"] = 1
}


RECIPE.skillIncrease = 1

RECIPE.skills = {
    ["Chemistry"] = 8,
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