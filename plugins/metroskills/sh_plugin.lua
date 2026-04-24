PLUGIN.name = "Metro Attributes"
PLUGIN.author = "Metro Schema"
PLUGIN.description = "Handles gameplay effects from attributes."

ix.config.Add("strengthMultiplier", 0.3, "The strength multiplier scale", nil, {
	data = {min = 0, max = 1.0, decimals = 1},
	category = "attributes"
})

ix.config.Add("strengthCarryPerPoint", 1.5, "Carry weight gained per strength.", nil, {
    data = {min = 0, max = 10, decimals = 1},
    category = "attributes"
})

ix.config.Add("enduranceHealthPerPoint", 2, "Health gained per endurance.", nil, {
    data = {min = 0, max = 10},
    category = "attributes"
})

ix.config.Add("enduranceStaminaPerPoint", 2, "Stamina gained per endurance.", nil, {
    data = {min = 0, max = 10},
    category = "attributes"
})

ix.config.Add("enduranceStaminaLoseModifier", 0.02, "Stamina loss modifier per endurance.", nil, {
    data = {min = 0, max = 1, decimals = 2},
    category = "attributes"
})

ix.config.Add("agilityRunSpeed", 2, "Run speed gained per agility.", nil, {
    data = {min = 0, max = 10},
    category = "attributes"
})

ix.config.Add("agilityStaminaRegenModifier", 0.02, "Stamina regeneration modifier per agility.", nil, {
    data = {min = 0, max = 1, decimals = 2},
    category = "attributes"
})

ix.config.Add("survivalRadResist", 0.03, "Radiation reduction per survival.", nil, {
    data = {min = 0, max = 1, decimals = 2},
    category = "attributes"
})

ix.config.Add("survivalHungerResist", 0.03, "Hunger drain resistance per survival.", nil, {
    data = {min= 0, max = 1, decimals = 2},
    category = "attributes"
})

ix.config.Add("survivalThirstResist", 0.03, "Thirst drain resistance per survival.", nil, {
    data = {min= 0, max = 1, decimals = 2},
    category = "attributes"
})

ix.config.Add("scavengingLootChance", 0.03, "Loot chance per scavenging.", nil, {
    data = {min = 0, max = 1, decimals = 2},
    category = "attributes"
})

ix.config.Add("cookingFarmChance", 0.03, "Gathering chance per cooking.", nil, {
    data = {min = 0, max = 1, decimals = 2},
    category = "attributes"
})

ix.config.Add("characterCreationPoints", 40, "Number of points a player can use during character creation.", nil, {
    data = {min = 0, max = 180},
    category = "attributes"
})

function PLUGIN:GetDefaultAttributePoints(client, count)
    return ix.config.Get("characterCreationPoints", 20)
end

if not SERVER then return end

function PLUGIN:GetPlayerPunchDamage(client, damage, context)
    local char = client:GetCharacter()
    if not char then return end

    local strength = char:GetAttribute("strength", 0)

    context.damage = context.damage + strength * 0.4
end

function PLUGIN:AdjustPlayerSpeed(client, speed)

    local char = client:GetCharacter()
    if not char then return end

    local agility = char:GetAttribute("agility", 0)

    speed.run = speed.run + agility * ix.config.Get("agilityRunSpeed", 2)
    speed.walk = speed.walk + agility
end

function PLUGIN:AdjustStaminaOffset(client, offset)
    local char = client:GetCharacter()
    if not char then return offset end

    if offset > 0 then
        local agility = char:GetAttribute("agility", 0)
        offset = (offset + (agility * ix.config.Get("agilityStaminaRegenModifier"))) * char:GetStaminaMultiplier()
        return offset
    elseif offset < 0 then
        local endurance = char:GetAttribute("endurance", 0)
        offset = (offset + (endurance * ix.config.Get("enduranceStaminaLoseModifier"))) * char:GetStaminaMultiplier()
        return offset
    end

    return offset
end

function PLUGIN:PlayerThrowPunch(client, trace)
	if (client:GetCharacter() and IsValid(trace.Entity) and trace.Entity:IsPlayer()) then
		client:GetCharacter():UpdateAttrib("strength", 0.001)
	end
end