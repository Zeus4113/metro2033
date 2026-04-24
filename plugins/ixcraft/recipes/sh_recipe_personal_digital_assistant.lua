RECIPE.name = "Craft Personal Digital Assistant"
RECIPE.description = "A small handheld computer constructed using advanced electronic components and display technology. Useful for storing information and monitoring systems."
RECIPE.model = "models/spec45as/stalker/items/pda.mdl"
RECIPE.category = "Gadget"

RECIPE.requirements = {
	["lcd_screen"] = 1,
	["electronics"] = 3,
	["9v_battery"] = 2,
}

RECIPE.results = {
    ["personal_digital_assistant"] = 1
}


RECIPE.skillIncrease = 1

RECIPE.skills = {
    ["Engineering"] = 16,
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