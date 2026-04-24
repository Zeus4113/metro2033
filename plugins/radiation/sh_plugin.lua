PLUGIN.name = "Radiation"
PLUGIN.author = "Metro"
PLUGIN.description = "Radiation system with command-based zones."

ix.util.Include("sh_meta.lua")
ix.util.Include("sv_plugin.lua")

ix.config.Add("radiationMax", 100, "Maximum radiation level.", nil, {
    data = {min = 1, max = 1000},
    category = "Radiation"
})

ix.config.Add("noGasmaskRadiationThreshold", 10, "Radiation gain per tick before damage begins if no gasmask.", nil, {
    data = {min = 0, max = 1000},
    category = "Radiation"
})

ix.config.Add("radiationThreshold", 60, "Radiation level before damage begins regardless of equipment.", nil, {
    data = {min = 0, max = 1000},
    category = "Radiation"
})

ix.config.Add("noGasmaskRadiationDamage", 5, "Damage per second after threshold if no gasmask.", nil, {
    data = {min = 0, max = 100},
    category = "Radiation"
})

ix.config.Add("radiationDamage", 2, "Damage per second after threshold.", nil, {
    data = {min = 0, max = 100, decimals = 2},
    category = "Radiation"
})

ix.config.Add("radiationDecay", 0.5, "Radiation decay per second outside zones.", nil, {
    data = {min = 0, max = 10, decimals = 2},
    category = "Radiation"
})

ix.char.RegisterVar("filterTime", {
    field = "filter_time",
    fieldType = ix.type.number,
    default = 0
})

ix.char.RegisterVar("filterActive", {
    field = "filter_active",
    fieldType = ix.type.bool,
    default = false
})

function GetEquippedItem(char, slot)
    local equipment = char:GetData("equipment", {})
    local itemID = equipment[slot]

    if itemID then
        return ix.item.instances[itemID]
    end
end