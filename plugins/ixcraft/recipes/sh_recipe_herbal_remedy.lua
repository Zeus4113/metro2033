RECIPE.name = "Craft Herbal Remedy"
RECIPE.description = "A basic medicinal concoction made from a mixture of herbs and chemicals, used to alleviate pain and minor injuries."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/dez_item_yad.mdl"
RECIPE.category = "Medical"

RECIPE.requirements = {
	["organics"] = 1,
	["chemicals"] = 1,
}

RECIPE.results = {
    ["herbal_remedy"] = 1
}


RECIPE.skillIncrease = 0.17

RECIPE.skills = {
    ["Chemistry"] = 3,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_chemistry_set")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a chemistry set." end

    return true
end)