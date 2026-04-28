RECIPE.name = "Craft Gasmask"
RECIPE.description = "A vital piece of survival gear assembled from cloth, leather and mechanical filter components. Protects the wearer from toxic air and radioactive dust."
RECIPE.model = "models/weapons/metro2033/w_gasmask.mdl"
RECIPE.category = "Helmet"

RECIPE.requirements = {
	["wire"] = 1,
	["cloth"] = 2,
}

RECIPE.results = {
    ["helmet_gasmask"] = 1
}


RECIPE.skillIncrease = 0.3

RECIPE.skills = {
    ["Tailoring"] = 3,
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