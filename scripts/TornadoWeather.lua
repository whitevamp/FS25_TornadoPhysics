---@class TornadoWeather
---@version 1.1 (DYNAMIC VISUAL PRECIPITATION)
---@description Randomizes mechanical and visual precipitation profiles during a tornado.

TornadoWeather = {}

function TornadoWeather:loadMap(name)
    if TornadoDebug then TornadoDebug:log("WEATHER", "Initializing Visual Weather Randomization...") end
    
    self.isHooked = false
    self:installHooks()
end

function TornadoWeather:deleteMap()
    -- Managed by Main
end

function TornadoWeather:installHooks()
    if self.isHooked then return end

    -- Hook into the WeatherObject activation
    WeatherObject.activate = Utils.appendedFunction(WeatherObject.activate, function(weatherObj, weatherInstance, blendDuration, isSavegameInit)
        if weatherObj.weatherType == WeatherType.TWISTER and not isSavegameInit then
            if TornadoWeather then
                TornadoWeather:applyRandomProfile()
            end
        end
    end)
    
    self.isHooked = true
    if TornadoDebug then TornadoDebug:log("WEATHER", "Weather hooks installed successfully.") end
end

function TornadoWeather:applyRandomProfile()
    if not g_currentMission or not g_currentMission.environment or not g_currentMission.environment.weather then
        return
    end

    local weatherSys = g_currentMission.environment.weather
    local rainUpdater = weatherSys.rainUpdater
    local cloudUpdater = weatherSys.cloudUpdater

    if not rainUpdater or not rainUpdater.targetRain then 
        return 
    end

    -- Generate a random profile: 1 = LP (Dry), 2 = Classic (Mixed), 3 = HP (Torrential)
    local stormType = math.random(1, 3)
    local profileName = ""
    
    -- Variables we are going to tweak
    local rScale, hScale, dropMult, turbulence, cloudDensity

    if stormType == 1 then
        profileName = "LP Supercell (Highly Visible, Low Rain)"
        rScale       = math.random() * 0.15  -- Barely any ground wetness
        hScale       = math.random() * 0.3   -- Light hail
        dropMult     = 0.2                   -- Very few visual raindrops
        turbulence   = 0.5                   -- Calm rain fall
        cloudDensity = 0.01                  -- Lighter clouds
        
    elseif stormType == 2 then
        profileName = "Classic Supercell (Moderate)"
        rScale       = 0.3 + (math.random() * 0.3)
        hScale       = 0.4 + (math.random() * 0.4)
        dropMult     = 0.6                   -- Standard heavy rain visuals
        turbulence   = 1.2                   -- Swirling rain
        cloudDensity = 0.5                   -- Darker skies
        
    else
        profileName = "HP Supercell (Rain-Wrapped, Zero Visibility)"
        rScale       = 0.8 + (math.random() * 0.2)
        hScale       = 0.7 + (math.random() * 0.3)
        dropMult     = 1.0                   -- MAX visual rain particles
        turbulence   = 2.5                   -- Violent, chaotic rain movement
        cloudDensity = 1.0                   -- Pitch black / maximum cloud thickness
    end

    -- 1. Apply to the targetRain (interpolated over the blend duration)
    rainUpdater.targetRain.rainfallScale = rScale
    rainUpdater.targetRain.hailfallScale = hScale
    rainUpdater.targetRain.maxDropsMultiplier = dropMult
    rainUpdater.targetRain.turbulence = turbulence

    -- 2. Apply to the targetClouds (Darkens the ambient lighting)
    if cloudUpdater and cloudUpdater.targetClouds then
        cloudUpdater.targetClouds.densityScale = cloudDensity
    end

    -- 3. Override active values instantly so the visual particle emitters update NOW
    local activeType = rainUpdater.targetRain.typeId
    if activeType and rainUpdater.types[activeType] then
        local values = rainUpdater.types[activeType].values
        values.rainfallScale = rScale
        values.hailfallScale = hScale
        values.maxDropsMultiplier = dropMult
        values.turbulence = turbulence
    end

    if TornadoDebug then 
        TornadoDebug:log("WEATHER", string.format("Deployed %s [Rain: %.2f | Drops: %.1f | Turb: %.1f | Clouds: %.2f]", 
            profileName, rScale, dropMult, turbulence, cloudDensity)) 
    end
end