RECIPE.name = "Craft Operator Outfit"
RECIPE.description = "A rugged outfit assembled from kevlar weave, ballistic plates, and textile patches. Provides good protection while maintaining mobility, making it ideal for operators navigating the dangerous metro environment."
RECIPE.model = "models/hasst/randomguy/jc-bg.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
    ["kevlar_weave"] = 1,
    ["ballistic_plate"] = 2,
	["textile_patch"] = 3,
}

RECIPE.results = {
    ["outfit_operator"] = 1
}

RECIPE.skillIncrease = 1.8

RECIPE.skills = {
    ["Tailoring"] = 18,
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