RECIPE.name = "Craft Ranger Helmet"
RECIPE.description = "A durable helmet used by experienced stalkers. Combines mechanical fittings and reinforced materials for better protection in hazardous environments."
RECIPE.model = "models/maver1k_xvii/metro_digger_helmet.mdl"
RECIPE.category = "Helmet"

RECIPE.requirements = {
	["leather"] = 2,
	["kevlar_weave"] = 1,
	["ballistic_plate"] = 1,
}

RECIPE.results = {
    ["helmet_ranger"] = 1
}


RECIPE.skillIncrease = 2

RECIPE.skills = {
    ["Tailoring"] = 12,
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