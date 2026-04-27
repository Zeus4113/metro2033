RECIPE.name = "Break Down Old Cables"
RECIPE.description = "Salvage useful materials from Old Cables."
RECIPE.model = "models/illusion/eftcontainers/militarycable.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["old_cables"] = 1
}

RECIPE.results = {
	["wires"] = 3,
}

RECIPE.skillIncrease = 0.15

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