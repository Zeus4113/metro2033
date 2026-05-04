RECIPE.name = "Craft Duplet"
RECIPE.description = "A double-barrel shotgun designed for brutal close-range combat. Its simple design makes it easier to maintain and craft than more complex firearms."
RECIPE.model = "models/weapons/c_duplet.mdl"
RECIPE.category = "Weapon"

RECIPE.requirements = {
	["metal_spring"] = 1,
	["mechanical_parts"] = 3,
	["lead_pipe"] = 2,
}

RECIPE.results = {
    ["duplet"] = 1
}


RECIPE.skillIncrease = 0.7

RECIPE.skills = {
    ["Engineering"] = 15,
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