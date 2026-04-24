RECIPE.name = "Craft Shotgun Ammo"
RECIPE.description = "Packed shells filled with metal shot. Simple to assemble but resource-heavy, consuming large quantities of scrap and chemicals."
RECIPE.model = "models/kek1ch/ammo_12x76_zhekan.mdl"
RECIPE.category = "Ammo"

RECIPE.requirements = {
	["metal_scrap"] = 3,
	["chemicals"] = 3,
}

RECIPE.results = {
    ["shotgun_ammo"] = 1
}


RECIPE.skillIncrease = 0.35

RECIPE.skills = {
    ["Engineering"] = 12,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_engineering_bench")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a engineering bench." end

    return true
end)