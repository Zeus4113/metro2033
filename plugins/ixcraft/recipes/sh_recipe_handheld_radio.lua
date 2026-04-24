RECIPE.name = "Craft Handheld Radio"
RECIPE.description = "A portable communication device crafted from salvaged electronics, wiring and a small display. Allows long-distance contact between stations and patrols."
RECIPE.model = "models/radio/w_radio.mdl"
RECIPE.category = "Gadget"

RECIPE.requirements = {
	["lcd_screen"] = 1,
	["9v_battery"] = 1,
	["electronics"] = 2,
}

RECIPE.results = {
    ["handheld_radio"] = 1
}


RECIPE.skillIncrease = 1

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