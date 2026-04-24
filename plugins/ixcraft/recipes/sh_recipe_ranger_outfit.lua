RECIPE.name = "Craft Ranger Outfit"
RECIPE.description = "A hardened combat suit crafted using stronger ballistic materials, typically worn by experienced stalkers."
RECIPE.model = "models/devcon/mrp/act/player/ranger_2.mdl"
RECIPE.category = "Outfit"

RECIPE.requirements = {
	["leather"] = 3,
	["kevlar_weave"] = 3,
	["ballistic_plate"] = 1,
}

RECIPE.results = {
    ["outfit_ranger"] = 1
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