RECIPE.name = "Craft Dosimeter"
RECIPE.description = "A compact radiation monitor worn by stalkers to track cumulative exposure over time. Requires precision electronics and power sources to build."
RECIPE.model = "models/kek1ch/dev_decoder.mdl"
RECIPE.category = "Gadget"

RECIPE.requirements = {
	["9v_battery"] = 1,
	["electronics"] = 2,
	["wires"] = 2,
}

RECIPE.results = {
    ["dosimeter"] = 1
}


RECIPE.skillIncrease = 0.5

RECIPE.skills = {
    ["Engineering"] = 6,
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