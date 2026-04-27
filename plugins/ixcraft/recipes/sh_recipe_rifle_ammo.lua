RECIPE.name = "Craft Rifle Ammo"
RECIPE.description = "Military-grade rifle cartridges manufactured using larger amounts of scrap metal and propellant. A staple for automatic rifles and combat weapons."
RECIPE.model = "models/kek1ch/ammo_545x39_ap.mdl"
RECIPE.category = "Ammo"

RECIPE.requirements = {
	["metal_scrap"] = 3,
	["chemicals"] = 2,
}

RECIPE.results = {
    ["rifle_ammo"] = 1
}


RECIPE.skillIncrease = 0.35

RECIPE.skills = {
    ["Engineering"] = 8,
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