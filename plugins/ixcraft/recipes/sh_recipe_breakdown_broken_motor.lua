RECIPE.name = "Break Down Broken Motor"
RECIPE.description = "Salvage useful materials from Broken Motor."
RECIPE.model = "models/illusion/eftcontainers/engine.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["broken_motor"] = 1
}

RECIPE.results = {
	["mechanical_parts"] = 2,
}

RECIPE.skillIncrease = 0.5

RECIPE.skills = {
    ["Engineering"] = 0,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a workbench." end

    return true
end)