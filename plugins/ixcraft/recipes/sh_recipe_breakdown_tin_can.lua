RECIPE.name = "Break Down Tin Can"
RECIPE.description = "Salvage useful materials from Tin Can."
RECIPE.model = "models/props_junk/garbage_metalcan001a.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["tin_can"] = 1
}

RECIPE.results = {
	["metal_scrap"] = 1,
}

RECIPE.skillIncrease = 0.05

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