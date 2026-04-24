RECIPE.name = "Break Down Household Cleaner"
RECIPE.description = "Salvage useful materials from Household Cleaner."
RECIPE.model = "models/props_junk/garbage_plasticbottle001a.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["household_cleaner"] = 1
}

RECIPE.results = {
	["chemicals"] = 1,
}


RECIPE.skillIncrease = 0.25

RECIPE.skills = {
    ["Chemistry"] = 0,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_chemistry_set")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a chemistry set." end

    return true
end)