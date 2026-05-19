local PLUGIN = PLUGIN

PLUGIN.name        = "Weather Spawner"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Auto-spawns a gWeather entity on server start."

ix.config.Add("defaultWeather", "gw_t1_lightsnow", "gWeather entity classname to spawn on server start. Leave empty to disable.", nil, {
    category = PLUGIN.name
})

if not SERVER then return end

function PLUGIN:InitPostEntity()
    if not gWeatherInstalled then return end

    local class = ix.config.Get("defaultWeather", "gw_t1_lightsnow")
    if class == "" then return end

    if IsValid(gWeather.CurrentWeather) then return end

    local ent = ents.Create(class)
    if not IsValid(ent) then
        ErrorNoHalt("[WeatherSpawner] Failed to create entity '" .. class .. "' — is the classname correct?\n")
        return
    end

    ent:SetPos(Vector(0, 0, 0))
    ent:Spawn()
    ent:Activate()
end
