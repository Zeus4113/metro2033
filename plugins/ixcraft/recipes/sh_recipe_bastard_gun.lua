RECIPE.name = "Craft Bastard Gun"
RECIPE.description = "A crude automatic firearm cobbled together from scavenged machine parts. Easy to manufacture but infamous for its poor reliability."
RECIPE.model = "models/weapons/c_bastardgun.mdl"
RECIPE.category = "Weapon"

RECIPE.requirements = {
	["metal_spring"] = 1,
	["mechanical_parts"] = 3,
	["lead_pipe"] = 1,
}

RECIPE.results = {
    ["bastard"] = 1
}


RECIPE.skillIncrease = 1.5

RECIPE.skills = {
    ["Engineering"] = 8,
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