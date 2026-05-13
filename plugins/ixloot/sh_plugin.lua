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

ix.config.Add("toolDurabilityDec", 15, "How much durability required tools lose per lootable interaction.", nil, {
    data = {min = 1, max = 100},
    category = PLUGIN.name
})

-- Respawn times (seconds) per tier
ix.config.Add("lootRespawnTier0",  120, "Respawn time (seconds) for Tier 0 lootables.", nil, { data = {min = 60, max = 1800}, category = PLUGIN.name })
ix.config.Add("lootRespawnTier1",  300, "Respawn time (seconds) for Tier 1 lootables.", nil, { data = {min = 60, max = 1800}, category = PLUGIN.name })
ix.config.Add("lootRespawnTier2",  600, "Respawn time (seconds) for Tier 2 lootables.", nil, { data = {min = 60, max = 1800}, category = PLUGIN.name })
ix.config.Add("lootRespawnTier3",  900, "Respawn time (seconds) for Tier 3 lootables.", nil, { data = {min = 60, max = 1800}, category = PLUGIN.name })
ix.config.Add("lootRespawnTier4", 1800, "Respawn time (seconds) for Tier 4 lootables.", nil, { data = {min = 60, max = 1800}, category = PLUGIN.name })

-- Rare chance percentage per tier: percentage chance (0-100) of rolling a rare item
ix.config.Add("lootRareChanceTier0", 50, "Rare drop chance (%) for Tier 0 lootables.", nil, { data = {min = 0, max = 100}, category = PLUGIN.name })
ix.config.Add("lootRareChanceTier1", 33, "Rare drop chance (%) for Tier 1 lootables.", nil, { data = {min = 0, max = 100}, category = PLUGIN.name })
ix.config.Add("lootRareChanceTier2", 33, "Rare drop chance (%) for Tier 2 lootables.", nil, { data = {min = 0, max = 100}, category = PLUGIN.name })
ix.config.Add("lootRareChanceTier3", 33, "Rare drop chance (%) for Tier 3 lootables.", nil, { data = {min = 0, max = 100}, category = PLUGIN.name })
ix.config.Add("lootRareChanceTier4", 25, "Rare drop chance (%) for Tier 4 lootables.", nil, { data = {min = 0, max = 100}, category = PLUGIN.name })

ix.util.Include("sv_plugin.lua")

PLUGIN.loot = {
    [0] = {
        ["scrap"] = {
            ["common"] = {
                "tin_can",
                "worn_knife",
                "steel_wrench",
                "metal_crowbar",
                "lead_pipe",
                "cast_iron_pot"
            },
            ["rare"] = {
                "broken_radio",
                "antique_clock"
            }
        }
    },
    [1] = {
        ["mechanics"] = {
            ["common"] = {
                "broken_motor",
                "old_cables",
            },
            ["rare"] = {
                "pressure_gauge",
            }
        },
        ["electronics"]= {
            ["common"] = {
                "ruined_psu",
                "power_cord",
            },
            ["rare"] = {
                "9v_battery",
            }
        },
        ["equipment"] = {
            ["common"] = {
                "ruined_jacket",
                "old_boot",
            },
            ["rare"] = {
                "textile_patch"
            }
        },
        ["chemicals"] = {
            ["common"] = {
                "household_cleaner",
                "laundry_detergent",
            },
            ["rare"] = {
                "complex_chemicals"
            }
        },
    },
    [2] = {
        ["mechanics"] = {
            ["common"] = {
                "pressure_gauge",
            },
            ["rare"] = {
                "metal_spring",
            }
        },
        ["electronics"]= {
            ["common"] = {
                "9v_battery",
            },
            ["rare"] = {
                "lcd_screen",
            }
        },
        ["equipment"] = {
            ["common"] = {
                "textile_patch",
            },
            ["rare"] = {
                "ballistic_plate",
            },
        },
        ["chemicals"] = {
            ["common"] = {
                "complex_chemicals"
            },
            ["rare"] = {
                "medical_reagents"
            }
        },
    },
    [3] = {
        ["mechanics"] = {
            ["common"] = {
                "metal_spring",
            },
            ["rare"] = {
                "reciever",
            }
        },
        ["equipment"] = {
            ["common"] = {
                "ballistic_plate",
            },
            ["rare"] = {
                "kevlar_weave",
            },
        },
        ["chemicals"] = {
            ["common"] = {
                "medical_reagents",
            },
            ["rare"] = {
                "syringe",
            }
        },
    },
    [4] = {
        ["military"] = {
            ["common"] = {
                "reciever",
                "kevlar_weave"
            },
            ["rare"] = {
                "akm",
                "g3a3",
                "usp_tactical",
                "mp5a4",
                "sks",
            }
        },
        ["medical"] = {
            ["common"] = {
                "syringe",
                "medkit",
                "anti_radiation_pills",
            },
            ["rare"] = {
                "first_aid_kit",
                "green_stuff"
            }
        },
        ["library"] = {
            ["common"] = {
                "engineers_handbook",
                "tailoring_guide",
                "medical_journal",
            },
            ["rare"] = {
                "civil_documents",
                "military_documents",
            },
        }
    },
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
