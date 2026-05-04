RECIPE.name = "Break Down Ruined PSU"
RECIPE.description = "Salvage useful materials from Ruined PSU."
RECIPE.model = "models/illusion/eftcontainers/powersupplyunit.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["ruined_psu"] = 1
}

RECIPE.results = {
	["electronics"] = 2,
}

RECIPE.skillIncrease = 0.16

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

    if not nearStation then return false, "You need to be near a engineering bench." end

    return true
end)