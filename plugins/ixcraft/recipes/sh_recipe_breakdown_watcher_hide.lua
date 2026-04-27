RECIPE.name = "Break Down Watcher Hide"
RECIPE.description = "Salvage useful materials from Watcher Hide."
RECIPE.model = "models/wick/wrbstalker/anomaly/items/wick_hide_bloodsucker.mdl"
RECIPE.category = "Junk"

RECIPE.requirements = {
    ["watcher_hide"] = 1
}

RECIPE.results = {
	["leather"] = 4,
}


RECIPE.skillIncrease = 0.5

RECIPE.skills = {
    ["Tailoring"] = 0,
}


RECIPE:PostHook("OnCanCraft", function(recipeTable, client)

    if not client or not client:GetCharacter() then return false end

    local nearStation = false

    for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
        if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
            nearStation = true
        end
    end

    if not nearStation then return false, "You need to be near a workbench." end

    return true
end)