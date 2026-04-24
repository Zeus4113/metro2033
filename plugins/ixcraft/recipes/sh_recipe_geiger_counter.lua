RECIPE.name = "Craft Geiger Counter"
RECIPE.description = "A handheld radiation detector assembled from sensors, electronics and pressure gauges. Essential for identifying dangerous radiation zones in the tunnels."
RECIPE.model = "models/illusion/eftcontainers/geigercounter.mdl"
RECIPE.category = "Gadget"

RECIPE.requirements = {
	["9v_battery"] = 1,
	["electronics"] = 2,
	["wires"] = 2,
}

RECIPE.results = {
    ["geiger_counter"] = 1
}


RECIPE.skillIncrease = 0.5

RECIPE.skills = {
    ["Engineering"] = 4,
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