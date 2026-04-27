ITEM.name = "Skill Book"
ITEM.description = "A book that contains knowledge about a specific skill. It can be used to learn or improve that skill."
ITEM.model = "models/props_lab/binderredlabel.mdl"
ITEM.category = "Books"

ITEM.skill = nil -- The skill that this book teaches or improves. This should be set in derived items.
ITEM.skillIncrease = 0 -- The amount by which this book increases the skill level. This should be set in derived items.

ITEM.functions.Read = {
    name = "Equip",
    icon = "icon16/tick.png",
    OnRun = function(item)
        local character = item.player:GetCharacter()
        if not character then return false end

        -- Check if the player already has the skill
        local currentLevel = character:GetAttribute(item.skill) or 0

        -- Increase the skill level
        character:SetAttribute(item.skill, currentLevel + item.skillIncrease)

        item.player:ChatPrint("You have read the " .. item.name .. " and increased your " .. item.skill .. " skill by " .. item.skillIncrease .. ".")

        return true
    end,

    OnCanSee = function(item)
        if item.skill == nil then return false end
        return true
    end
}

