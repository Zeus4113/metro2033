RECIPE.name = "Craft Novice Stalker Outfit"
RECIPE.description = "Entry-level protective gear designed for inexperienced surface explorers venturing into dangerous zones."
RECIPE.model = "models/devcon/mrp/act/player/stalker_novice.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["leather"] = 2,
	["cloth"] = 1,
	["kevlar_weave"] = 2,
}

RECIPE.results = {
    ["outfit_novice_stalker"] = 1
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