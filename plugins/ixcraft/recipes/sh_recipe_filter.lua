RECIPE.name = "Craft Filter"
RECIPE.description = "A common item in the metro, used by scavengers and stalkers alike. Made from a mix of mechanical parts and chemical compounds."
RECIPE.model = "models/teebeutel/metro/objects/gasmask_filter.mdl"
RECIPE.category = "Gadget"

RECIPE.requirements = {
	["cloth"] = 1,
	["chemicals"] = 1
}

RECIPE.results = {
    ["filter"] = 1
}


RECIPE.skillIncrease = 0.1

RECIPE.skills = {
    ["Engineering"] = 1,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_engineering_bench")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a engineering bench." end

    return true
end)