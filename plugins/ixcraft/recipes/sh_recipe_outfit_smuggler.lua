RECIPE.name = "Craft Smuggler Outfit"
RECIPE.description = "A rugged outfit assembled from scavenged leather and cloth. Provides minimal protection but is easy to craft from common materials."
RECIPE.model = "models/player/axelnoir/resident_evil_4/bio4/em/em18/merchanto_pm.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["leather"] = 1,
	["cloth"] = 2,
}

RECIPE.results = {
    ["outfit_smuggler"] = 1
}

RECIPE.skillIncrease = 0.2

RECIPE.skills = {
    ["Tailoring"] = 2,
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