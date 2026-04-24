RECIPE.name = "Craft Tactical Vest"
RECIPE.description = "A combat vest reinforced with kevlar fibers and ballistic plates. Designed to provide reliable protection during firefights."
RECIPE.model = "models/hardbass/stalker_bandit_2_b_razgryz.mdl"
RECIPE.category = "Vest"

RECIPE.requirements = {
	["cloth"] = 2,
	["kevlar_weave"] = 1,
	["ballistic_plate"] = 1,
}

RECIPE.results = {
    ["vest_tactical"] = 1
}


RECIPE.skillIncrease = 2.0

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