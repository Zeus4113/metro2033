RECIPE.name = "Craft Traveler's Pack"
RECIPE.description = "A medium-sized backpack designed for long trips between stations. Crafted from durable cloth and reinforced leather."
RECIPE.model = "models/kek1ch/sumka3.mdl"
RECIPE.category = "Backpack"

RECIPE.requirements = {
	["leather"] = 4,
	["cloth"] = 2,
}

RECIPE.results = {
    ["backpack_travelers"] = 1
}


RECIPE.skillIncrease = 1.5

RECIPE.skills = {
    ["Tailoring"] = 8,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_tailors_table")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a tailoring table." end

    return true
end)