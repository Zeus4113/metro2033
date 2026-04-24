RECIPE.name = "Craft Reinforced Helmet"
RECIPE.description = "A heavily armored helmet built with multiple layers of ballistic fiber and armor plating, offering superior protection at the cost of heavier materials."
RECIPE.model = "models/z-o-m-b-i-e/metro_ll/equipment/m_ll_helmet_lynx_01.mdl"
RECIPE.category = "Helmet"

RECIPE.requirements = {
	["leather"] = 2,
	["kevlar_weave"] = 2,
	["ballistic_plate"] = 2,
}

RECIPE.results = {
    ["helmet_reinforced"] = 1
}


RECIPE.skillIncrease = 2.5

RECIPE.skills = {
    ["Tailoring"] = 16,
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