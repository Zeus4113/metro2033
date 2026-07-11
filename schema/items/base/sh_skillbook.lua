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

        -- Craft skills live in ix.skill (dynamic cap); anything else is a plain attribute.
        local isSkill = ix.skill and ix.skill.IsValid(item.skill)

        local currentLevel = isSkill and ix.skill.Get(character, item.skill)
            or (character:GetAttribute(item.skill, 0) or 0)

        local ceiling = isSkill and ix.skill.GetCap(character, item.skill) or 20

        if currentLevel >= ceiling then
            item.player:Notify("Your " .. item.skill .. " skill cannot be improved any further right now.")
            return false
        end

        -- Increase the skill level (AddXP clamps to the current cap for craft skills).
        if isSkill then
            ix.skill.AddXP(character, item.skill, item.skillIncrease)
        else
            character:SetAttrib(item.skill, math.min(currentLevel + item.skillIncrease, 20))
        end

        local newLevel = isSkill and math.floor(ix.skill.Get(character, item.skill))
            or character:GetAttribute(item.skill, 0)

        item.player:Notify("You have read the " .. item.name .. " and your " .. item.skill .. " skill has increased to " .. newLevel .. ".")

        return true
    end,

    OnCanRun = function(item)
        if not item.skill then return false end
        return true
    end
}

