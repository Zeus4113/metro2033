RECIPE.name = "Craft Helsing"
RECIPE.description = "A pneumatic crossbow designed to launch steel bolts with deadly force. Requires precision mechanical components and pressure regulators to function properly."
RECIPE.model = "models/weapons/c_helsing.mdl"
RECIPE.category = "Weapon"

RECIPE.requirements = {
	["pressure_gauge"] = 1,
	["mechanical_parts"] = 2,
	["lead_pipe"] = 1,
}

RECIPE.results = {
    ["helsing"] = 1
}


RECIPE.skillIncrease = 0.9

RECIPE.skills = {
    ["Engineering"] = 9,
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