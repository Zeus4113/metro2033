local PLUGIN = PLUGIN

PLUGIN.name        = "Weather Spawner"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Auto-spawns a gWeather entity on server start."

ix.config.Add("defaultWeather", "gw_t1_lightsnow", "gWeather entity classname to spawn on server start. Leave empty to disable.", nil, {
    category = PLUGIN.name
})

if not SERVER then return end

local function SpawnWeather()
    if not gWeatherInstalled then
        print("[WeatherSpawner] ABORT: gWeatherInstalled is nil — addon may not be loaded")
        return
    end
    print("[WeatherSpawner] gWeather version: " .. tostring(gWeatherVersion))

    local class = ix.config.Get("defaultWeather", "gw_t1_lightsnow")
    print("[WeatherSpawner] defaultWeather config value: '" .. tostring(class) .. "'")
    if class == "" then
        print("[WeatherSpawner] ABORT: defaultWeather is empty, spawning disabled")
        return
    end

    if IsValid(gWeather.CurrentWeather) then
        print("[WeatherSpawner] ABORT: weather already active (" .. tostring(gWeather.CurrentWeather:GetClass()) .. ")")
        return
    end

    print("[WeatherSpawner] Creating entity: " .. class)
    local ent = ents.Create(class)
    if not IsValid(ent) then
        ErrorNoHalt("[WeatherSpawner] ABORT: Failed to create entity '" .. class .. "' — is the classname correct?\n")
        return
    end

    ent:SetPos(Vector(0, 0, 0))
    ent:Spawn()
    ent:Activate()
    print("[WeatherSpawner] Spawned " .. class .. " successfully (EntIndex " .. tostring(ent:EntIndex()) .. ")")
end

function PLUGIN:PlayerLoadedCharacter(_, _)
    -- Spawn weather on the first character load. gWeather broadcasts setup net
    -- messages (fog, sky, atmosphere) during entity Initialize — they must reach
    -- at least one connected client, so we defer until a player is present.
    SpawnWeather()
end
