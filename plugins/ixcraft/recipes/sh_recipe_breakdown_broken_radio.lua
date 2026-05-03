RECIPE.name = "Break Down Broken Radio"
RECIPE.description = "Break down a broken radio for parts."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/dez_radio.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["broken_radio"] = 1
}

RECIPE.results = {
	["electronics"] = 2,
}

RECIPE.skillIncrease = 0.2

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