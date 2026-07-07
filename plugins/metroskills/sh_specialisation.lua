--[[
    Craft-skill specialisation.

    During character creation a player must pick ONE craft skill (Chemistry, Engineering or
    Tailoring) to specialise in. The chosen skill can level up to 20; the other two craft skills
    cap at 10 (see plugins/metroskills/attributes/sh_*.lua). The choice is permanent -- no respec
    path is exposed anywhere in-game.

    Non-craft skills (Survival, Strength, Agility, Endurance) are unaffected and keep their own
    maxValue.
]]

local CRAFT_SKILLS = {
    chemistry = "Chemistry",
    engineering = "Engineering",
    tailoring = "Tailoring"
}

-- Effective skill cap for a character: the specialised craft skill -> 20, everything else uses
-- its own attribute maxValue (10 for the other craft skills, unchanged for non-craft skills).
function ix.attributes.GetMax(character, key)
    local attribute = ix.attributes.list[key]
    local base = (attribute and attribute.maxValue) or ix.config.Get("maxAttributes", 100)

    if (character and CRAFT_SKILLS[key]) then
        local spec = character.GetSpecialisation and character:GetSpecialisation() or ""

        if (spec ~= "" and string.lower(spec) == key) then
            return 20
        end
    end

    return base
end

ix.char.RegisterVar("specialisation", {
    field = "specialisation",
    fieldType = ix.type.string,
    default = "",
    index = 4.5, -- render just below the attribute bars in the "attributes" creation step
    category = "attributes",
    isLocal = true,

    OnDisplay = function(self, container, payload)
        if (payload.specialisation == nil) then
            payload.specialisation = ""
        end

        local panel = container:Add("Panel")
        panel:Dock(TOP)

        local buttons = {}
        local totalHeight = 0

        for key, name in SortedPairsByValue(CRAFT_SKILLS) do
            local button = panel:Add("ixMenuSelectionButton")
            button:SetText(name:utf8upper())
            button:SizeToContents()
            button:Dock(TOP)
            button:DockMargin(0, 0, 0, 4)
            button:SetButtonList(buttons)
            button.specialisation = key
            button.OnSelected = function(this)
                payload:Set("specialisation", this.specialisation)
            end

            if (payload.specialisation == key) then
                button:SetSelected(true)
            end

            totalHeight = totalHeight + button:GetTall() + 4
        end

        panel:SetTall(totalHeight)

        return panel
    end,

    -- Required + valid. Runs client-side (VerifyProgression) and server-side (creation receiver).
    OnValidate = function(self, value, payload, client)
        if (!isstring(value) or !CRAFT_SKILLS[value]) then
            return false, "specNotChosen"
        end
    end
})
