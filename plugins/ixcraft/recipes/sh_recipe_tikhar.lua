RECIPE.name = "Craft Tikhar"
RECIPE.description = "A handmade pneumatic rifle powered by compressed air. Built from mechanical components and pressure systems scavenged from old technology."
RECIPE.model = "models/weapons/c_tikhar.mdl"
RECIPE.category = "Weapon"

RECIPE.requirements = {
	["pressure_gauge"] = 1,
	["mechanical_parts"] = 2,
	["lead_pipe"] = 1,
}

RECIPE.results = {
    ["tikhar"] = 1
}


RECIPE.skillIncrease = 0.39

RECIPE.skills = {
    ["Engineering"] = 7
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