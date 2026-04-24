RECIPE.name = "Craft AKM"
RECIPE.description = "A rugged assault rifle assembled from reinforced mechanical parts and durable materials. A costly weapon to craft but extremely reliable."
RECIPE.model = "models/weapons/w_rif_ak47.mdl"
RECIPE.category = "Weapon"

RECIPE.requirements = {
	["metal_spring"] = 2,
	["mechanical_parts"] = 3,
	["lead_pipe"] = 1,
}

RECIPE.results = {
    ["akm"] = 1
}


RECIPE.skillIncrease = 2

RECIPE.skills = {
    ["Engineering"] = 12,
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