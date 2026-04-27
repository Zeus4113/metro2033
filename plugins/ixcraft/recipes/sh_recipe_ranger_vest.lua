RECIPE.name = "Craft Ranger Vest"
RECIPE.description = "A pre-war special forces armored vest modified and maintained at a high degree to insure the best defence in the tunnles"
RECIPE.model = "models/hardbass/stalker_bandit_2_b_razgryz.mdl"
RECIPE.category = "Vest"

RECIPE.requirements = {
	["textile_patch"] = 3,
	["kevlar_weave"] = 1,
	["ballistic_plate"] = 2,
}

RECIPE.results = {
    ["ranger_vest"] = 1
}


RECIPE.skillIncrease = 1.7

RECIPE.skills = {
    ["Tailoring"] = 17,
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