RECIPE.name = "Craft Merchant's Backpack"
RECIPE.description = "A large storage pack capable of carrying significant amounts of goods and crafting materials, commonly used by traders."
RECIPE.model = "models/kek1ch/sumka4.mdl"
RECIPE.category = "Backpack"

RECIPE.requirements = {
	["textile_patch"] = 2,
	["cloth"] = 3,
    ["kevlar_weave"] = 1
}

RECIPE.results = {
    ["backpack_merchants"] = 1
}


RECIPE.skillIncrease = 2

RECIPE.skills = {
    ["Tailoring"] = 20,
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