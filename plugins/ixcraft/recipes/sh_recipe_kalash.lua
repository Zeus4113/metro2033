RECIPE.name = "Craft Kalash"
RECIPE.description = "A rugged assault rifle assembled from reinforced mechanical parts and durable materials. A costly weapon to craft but extremely reliable."
RECIPE.model = "models/weapons/w_rif_ak47.mdl"
RECIPE.category = "Weapon"

RECIPE.requirements = {
	["reciever"] = 1,
	["metal_spring"] = 1,
	["mechanical_parts"] = 3,
}

RECIPE.results = {
    ["kalash"] = 1
}


RECIPE.skillIncrease = 1.34

RECIPE.skills = {
    ["Engineering"] = 17,
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