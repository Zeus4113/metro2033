RECIPE.name = "Craft Carrier Rig"
RECIPE.description = "A strung together carrier rig made from layers of cloth and leather."
RECIPE.model = "models/hardbass/stalker_sv_nauchniyrazgryz.mdl"
RECIPE.category = "Vest"

RECIPE.requirements = {
	["leather"] = 2,
	["cloth"] = 1,
}

RECIPE.results = {
    ["vest_carrier_rig"] = 1
}


RECIPE.skillIncrease = 0.24

RECIPE.skills = {
    ["Tailoring"] = 5,
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