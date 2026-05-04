RECIPE.name = "Craft Magnum Ammo"
RECIPE.description = "Heavy revolver rounds requiring more refined materials and propellant. Harder to craft, but far more powerful than standard pistol ammunition."
RECIPE.model = "models/kek1ch/ammo_50_ae.mdl"
RECIPE.category = "Ammo"

RECIPE.requirements = {
	["metal_scrap"] = 2,
	["chemicals"] = 3,
}

RECIPE.results = {
    ["magnum_ammo"] = 1
}


RECIPE.skillIncrease = 0.29

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