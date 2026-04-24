RECIPE.name = "Craft Pistol Ammo"
RECIPE.description = "Standard sidearm cartridges assembled from recycled metal casings and chemical propellant. Cheap to manufacture and commonly crafted by Metro gunsmiths."
RECIPE.model = "models/kek1ch/ammo_9x18_fmj.mdl"
RECIPE.category = "Ammo"

RECIPE.requirements = {
	["metal_scrap"] = 1,
	["chemicals"] = 1,
}

RECIPE.results = {
    ["pistol_ammo"] = 1
}


RECIPE.skillIncrease = 0.35

RECIPE.skills = {
    ["Engineering"] = 4,
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