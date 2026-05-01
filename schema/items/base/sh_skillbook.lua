ITEM.name = "Skill Book"
ITEM.description = "A book that contains knowledge about a specific skill. It can be used to learn or improve that skill."
ITEM.model = "models/props_lab/binderredlabel.mdl"
ITEM.category = "Books"

ITEM.skill = nil -- The skill that this book teaches or improves. This should be set in derived items.
ITEM.skillIncrease = 0 -- The amount by which this book increases the skill level. This should be set in derived items.

ITEM.functions.Read = {
    name = "Read",
    icon = "icon16/book.png",
    OnRun = function(item)
        local character = item.player:GetCharacter()
        if not character then return false end

        -- Check if the player already has the skill
        local currentLevel = character:GetAttribute(item.skill, 0) or 0

        if currentLevel >= 20 then
            item.player:Notify("Your " .. item.skill .. " skill is already at the maximum level.")
            return false
        end
        
        -- Increase the skill level
        character:SetAttrib(item.skill, math.min(currentLevel + item.skillIncrease, 20))

        item.player:Notify("You have read the " .. item.name .. " and your " .. item.skill .. " skill has increased to " .. character:GetAttribute(item.skill, 0) .. ".")

        return true
    end,

    OnCanRun = function(item)
        if not item.skill then return false end
        return true
    end
}

