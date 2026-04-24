RECIPE.name = "Craft Plate Carrier"
RECIPE.description = "An improvised protective vest constructed from scrap metal plates stitched between layers of cloth and leather."
RECIPE.model = "models/hardbass/stalker_neytral_rukzak_7_platecarrier.mdl"
RECIPE.category = "Vest"

RECIPE.requirements = {
	["leather"] = 2,
	["cloth"] = 2,
	["metal_scrap"] = 3,
}

RECIPE.results = {
    ["vest_plate_carrier"] = 1
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