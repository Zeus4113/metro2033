RECIPE.name = "Craft Thief Outfit"
RECIPE.description = "A lightweight outfit designed for stealth and agility, crafted from flexible cloth and leather materials."
RECIPE.model = "models/devcon/mrp/act/player/stealth_light.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["leather"] = 2,
	["cloth"] = 3,
}

RECIPE.results = {
    ["outfit_thief"] = 1
}


RECIPE.skillIncrease = 1

RECIPE.skills = {
    ["Tailoring"] = 4,
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