RECIPE.name = "Craft Makeshift Helmet"
RECIPE.description = "A crude protective helmet assembled from scrap metal, leather and cloth padding. Offers basic head protection using easily salvaged materials."
RECIPE.model = "models/hardbass/helem_hq.mdl"
RECIPE.category = "Helmet"

RECIPE.requirements = {
	["wires"] = 2,
	["cloth"] = 3,
	["textile_patch"] = 1,
}

RECIPE.results = {
    ["helmet_makeshift"] = 1
}


RECIPE.skillIncrease = 0.54

RECIPE.skills = {
    ["Tailoring"] = 7,
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