RECIPE.name = "Craft Scavengers Pouch"
RECIPE.description = "A small leather pouch stitched from salvaged cloth and hide. Used by scavengers to carry extra supplies and crafting materials."
RECIPE.model = "models/kek1ch/sumka1.mdl"
RECIPE.category = "Backpack"

RECIPE.requirements = {
	["leather"] = 1,
	["cloth"] = 2,
}

RECIPE.results = {
    ["backpack_scavengers"] = 1
}


RECIPE.skillIncrease = 0.21

RECIPE.skills = {
    ["Tailoring"] = 3,
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