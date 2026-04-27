RECIPE.name = "Craft Reinforced Vest"
RECIPE.description = "A heavily armored vest featuring additional ballistic layers and hardened plating, offering strong protection against high-caliber rounds."
RECIPE.model = "models/hardbass/neutral_bact_razgruz.mdl"
RECIPE.category = "Vest"

RECIPE.requirements = {
	["leather"] = 3,
	["textile_patch"] = 2,
	["ballistic_plate"] = 1,
}

RECIPE.results = {
    ["vest_reinforced"] = 1
}


RECIPE.skillIncrease = 1.5

RECIPE.skills = {
    ["Tailoring"] = 13,
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