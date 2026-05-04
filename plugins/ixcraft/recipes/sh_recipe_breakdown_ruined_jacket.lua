RECIPE.name = "Break Down Ruined Jacket"
RECIPE.description = "Salvage useful materials from Ruined Jacket."
RECIPE.model = "models/kek1ch/novice_outfit.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["ruined_jacket"] = 1
}

RECIPE.results = {
	["cloth"] = 2,
}


RECIPE.skillIncrease = 0.12

RECIPE.skills = {
    ["Tailoring"] = 0,
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