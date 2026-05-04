RECIPE.name = "Break Down Mushrooms"
RECIPE.description = "Salvage useful materials from Mushrooms."
RECIPE.model = "models/avoxgaming/mrp/jake/props/mushroom_2.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["mushroom"] = 1
}

RECIPE.results = {
	["organics"] = 3,
}

RECIPE.skillIncrease = 0.24

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