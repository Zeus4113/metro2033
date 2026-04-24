RECIPE.name = "Craft Revolver"
RECIPE.description = "A sturdy sidearm built around a simple mechanical firing system. Requires fewer components than automatic weapons, making it easier to craft."
RECIPE.model = "models/weapons/c_metrorevolver.mdl"
RECIPE.category = "Weapon"

RECIPE.requirements = {
	["metal_spring"] = 1,
	["mechanical_parts"] = 2,
	["lead_pipe"] = 1,
}

RECIPE.results = {
    ["revolver"] = 1
}


RECIPE.skillIncrease = 1.5

RECIPE.skills = {
    ["Engineering"] = 10,
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