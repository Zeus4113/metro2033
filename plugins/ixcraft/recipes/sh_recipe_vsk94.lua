RECIPE.name = "Craft VSK 94"
RECIPE.description = "A suppressed marksman rifle requiring high-quality mechanical parts and weapon components. Favoured for stealth and long-range engagements."
RECIPE.model = "models/weapons/c_vsv.mdl"
RECIPE.category = "Weapon"

RECIPE.requirements = {
	["metal_spring"] = 1,
	["mechanical_parts"] = 3,
	["reciever"] = 1,
}

RECIPE.results = {
    ["vsk94"] = 1
}


RECIPE.skillIncrease = 1.34

RECIPE.skills = {
    ["Engineering"] = 19,
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