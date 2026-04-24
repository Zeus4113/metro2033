local PLUGIN = PLUGIN

PLUGIN.name = "Lootable Containers"
PLUGIN.description = "Allows you to loot certin crates to obtain loot items."
PLUGIN.author = "Riggs"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2026 Riggs

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- i dont even wanna begin rewriting this plugin or optimizing it
-- this shit is a mess

-- doubled the items in the table so that they are more common than anything else. If you get what I mean.

ix.util.Include("sv_plugin.lua")


PLUGIN.lootTable = {
    ["general"] = {
        "tin_can",
        "lead_pipe",
        "cast_iron_pot",
        "dirty_water",
    },
    ["equipment"] = {
        "ruined_jacket",
        "old_boot",
        "dirty_water",
    },
    ["electrical"] = {
        "power_cord",
        "old_cables",
        "ruined_psu"
    },
    ["industrial"] = {
        "metal_scrap",
        "mechanical_parts",
        "broken_motor"
    },
    ["medical"] = {
        "purified_water",
        "bandage",
        "painkillers"
    },
    ["tools"] = {
        "steel_wrench",
        "worn_knife",
        "metal_crowbar"
    },
    ["hazmat"] = {
        "purified_water",
        "filter",
        "anti_radiation_pills"
    },
    ["military"] = {
         "tikhar",
         "helsing",
         "helmet_makeshift",
         "vest_carrier_rig"
    },
    ["farm"] = {
        "mushroom",
    },
    ["corpse"] = {
        "filter",
        "anti_radiation_pills",
        "medkit",
    }
}

PLUGIN.rareLootTable = {
    ["general"] = {
        "antique_clock",
        "broken_transmitter",
        "household_cleaner",
        "laundry_detergent"
    },
    ["equipment"] = {
        "kevlar_weave",
        "kevlar_weave",
        "ballistic_plate",
    },
    ["electrical"] = {
        "9v_battery",
        "9v_battery",
        "lcd_screen"
    },
    ["industrial"] = {
        "pressure_gauge",
        "pressure_gauge",
        "metal_spring"
    },
    ["medical"] = {
        "syringe",
        "syringe",
        "medical_reagents",
    },
    ["tools"] = {
        "revolver",
        "key"
    },
    ["hazmat"] = {
        "helmet_gasmask"
    },
    ["military"] = {
         "helmet_ranger",
         "vest_tactical",
         "bastard",
         "revolver",
         "backpack_travelers"
    },
    ["farm"] = {
        "mushroom"
    },
    ["corpse"] = {
        "revolver",
        "bastard",
        "vest_plate_carrier",
    }
}

PLUGIN.rareChance = {
    ["general"] = 4,
    ["electrical"] = 3,
    ["industrial"] = 3,
    ["equipment"] = 3,
    ["medical"] = 3,
    ["military"] = 4,
    ["tools"] = 100,
    ["hazmat"] = 10,
    ["farm"] = 0,
    ["corpse"] = 20,

}


if ( CLIENT ) then
    function PLUGIN:PopulateEntityInfo(ent, tooltip)
        local client = LocalPlayer()
        local entClass = ent:GetClass()

        if not ( entClass:find("ix_loot") ) then
            return false
        end

        if not (ent.displayName) then return false end

        local title = tooltip:AddRow("loot")
        title:SetText(ent.displayName)
        title:SetImportant()
        title:SizeToContents()

        if ent.requiredTools then
            local toolString = ""

            for k, v in pairs(ent.requiredTools) do
                if toolString == "" then
                    toolString = toolString .. "Required Tools: " .. ix.item.list[v].name
                else
                    toolString = toolString .. ", " .. ix.item.list[v].name
                end
            end

            local tools = tooltip:AddRow("tools")
            tools:SetText(toolString)
            tools:SetBackgroundColor(Color(157, 194, 120))
            tools:SizeToContents()
        end

        if not (ent.description) then return false end

        local description = tooltip:AddRow("desc")
        description:SetText(ent.description)
        description:SizeToContents()
    end
end
