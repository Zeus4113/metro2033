RECIPE.name = "Break Down Power Cord"
RECIPE.description = "Salvage useful materials from Power Cord."
RECIPE.model = "models/illusion/eftcontainers/powercord.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["power_cord"] = 1
}

RECIPE.results = {
	["wires"] = 1,
}

--[[
RECIPE.skillIncrease = 0.1


RECIPE.skills = {
    ["Engineering"] = 0,
}
]]

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