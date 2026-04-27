RECIPE.name = "Craft Green Stuff"
RECIPE.description = "A powerful injectable stimulant used to rapidly restore health, created using complex medical reagents and chemicals."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/dez_stim3.mdl"
RECIPE.category = "Medical"

RECIPE.requirements = {
	["syringe"] = 1,
	["medical_reagents"] = 1,
	["complex_chemicals"] = 1,
}

RECIPE.results = {
    ["green_stuff"] = 1
}

RECIPE.skillIncrease = 1.8

RECIPE.skills = {
    ["Chemistry"] = 18,
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