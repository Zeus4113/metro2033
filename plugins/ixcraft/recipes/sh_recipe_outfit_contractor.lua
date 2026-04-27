RECIPE.name = "Craft Contractor Outfit"
RECIPE.description = "A rugged outfit assembled from textile patches and cloth. Provides minimal protection but is easy to craft from common materials."
RECIPE.model = "models/catnike/port/driga/stalker_neutral2d.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["textile_patch"] = 1,
	["cloth"] = 2,
}

RECIPE.results = {
    ["outfit_contractor"] = 1
}

RECIPE.skillIncrease = 0.8

RECIPE.skills = {
    ["Tailoring"] = 8,
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_tailors_table")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a tailoring table." end

    return true
end)