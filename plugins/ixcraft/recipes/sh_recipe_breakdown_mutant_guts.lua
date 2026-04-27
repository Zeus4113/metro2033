RECIPE.name = "Break Down Mutant Guts"
RECIPE.description = "Salvage useful materials from Mutant Guts."
RECIPE.model = "models/vj_base/gibs/human/gib3.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["mutant_guts"] = 1
}

RECIPE.results = {
	["organics"] = 2,
}


RECIPE.skillIncrease = 0.2

RECIPE.skills = {
    ["Chemistry"] = 0,
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