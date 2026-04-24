RECIPE.name = "Craft Bandit Outfit"
RECIPE.description = "A rugged outfit assembled from scavenged leather and cloth. Provides minimal protection but is easy to craft from common materials."
RECIPE.model = "models/devcon/mrp/act/player/bandit_veteran.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["leather"] = 2,
	["cloth"] = 3,
}

RECIPE.results = {
    ["outfit_bandit"] = 1
}


RECIPE.skillIncrease = 1

RECIPE.skills = {
    ["Tailoring"] = 4,
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