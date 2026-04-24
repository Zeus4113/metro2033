RECIPE.name = "Craft Tactical Helmet"
RECIPE.description = "A reinforced combat helmet incorporating ballistic fibers and armor plates. Designed to withstand gunfire and shrapnel."
RECIPE.model = "models/hardbass/stalker_neytral_rukzak_7blackhelem.mdl"
RECIPE.category = "Helmet"

RECIPE.requirements = {
	["leather"] = 2,
	["kevlar_weave"] = 1,
	["metal_scrap"] = 2,
}

RECIPE.results = {
    ["helmet_tactical"] = 1
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