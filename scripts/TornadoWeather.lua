---@class TornadoWeather
---@version 2.0 (CLIMATE-DRIVEN STORM WEATHER)
---@description Sets the rain / hail / clouds / wind that come with a tornado.
---
--- Classic mode (real-life climate OFF): one of three random supercell profiles (LP / Classic / HP)
---   sets rain, hail, rain turbulence and cloud density. Wind is left as the map's twister weather has it.
--- Real-life mode (TornadoClimate ON with data for the region):
---   rain type / turbulence / clouds: still one of the three supercell profiles (the NOAA files have no rain data)
---   hail: rolled from the region's real chance of hail near tornadoes; stone size from the real size range,
---         bigger stones -> heavier hail fall
---   wind: rolled from the region's real chance of severe wind; gust from the real gust range,
---         turned into a sustained storm wind. Direction is kept: the twister's track follows it.
---
--- Multiplayer: only the server rolls the storm; it sends the result (TornadoWeatherEvent) and clients apply that
--- exact profile, whether the game's weather change reaches them before or after the event.
---
--- The game's weather objects hand out shared RainSettings / CloudSettings tables that belong to the map's
--- weather definition. They are copied before being changed, so a profile only affects this storm and not
--- every later rain of the same type.

TornadoWeather = {}

-- Sustained storm wind as a share of the peak gust (gusts in the NOAA data are peaks).
TornadoWeather.GUST_TO_SUSTAINED = 0.6
-- Hail stone size (cm) that maps to the full hail fall scale of 1.0.
TornadoWeather.HAIL_FULL_SCALE_CM = 8.0
-- Blend time (scaled ms) when a re-spawned tornado swaps the weather without a weather change.
TornadoWeather.RESPAWN_BLEND_MS = 30000
-- Client: how long (real ms) a received profile is kept for the twister weather change that may follow it.
TornadoWeather.RECEIVED_PROFILE_KEEP_MS = 120000

-- The three supercell types (rain / clouds / turbulence; hail is the classic value).
TornadoWeather.PROFILES = {
    {
        name = "LP Supercell (Highly Visible, Low Rain)",
        short = "LP supercell",
        textKey = "tp_supercell_lp",
        rain = function() return math.random() * 0.15 end,      -- Barely any ground wetness
        hail = function() return math.random() * 0.3 end,       -- Light hail
        dropMult = 0.2, turbulence = 0.5, cloudDensity = 0.01,  -- Few drops, calm fall, lighter clouds
    },
    {
        name = "Classic Supercell (Moderate)",
        short = "Classic supercell",
        textKey = "tp_supercell_classic",
        rain = function() return 0.3 + math.random() * 0.3 end,
        hail = function() return 0.4 + math.random() * 0.4 end,
        dropMult = 0.6, turbulence = 1.2, cloudDensity = 0.5,   -- Heavy rain, swirling, darker skies
    },
    {
        name = "HP Supercell (Rain-Wrapped, Zero Visibility)",
        short = "HP supercell",
        textKey = "tp_supercell_hp",
        rain = function() return 0.8 + math.random() * 0.2 end,
        hail = function() return 0.7 + math.random() * 0.3 end,
        dropMult = 1.0, turbulence = 2.5, cloudDensity = 1.0,   -- Max particles, violent, pitch black
    },
}

function TornadoWeather:loadMap(name)
    if TornadoDebug then TornadoDebug:log("WEATHER", "Initializing Visual Weather Randomization...") end

    self.isHooked = false
    self.lastProfile = nil
    self.receivedProfile = nil     -- client: last profile from the server
    self.receivedProfileTime = 0
    self:installHooks()
end

function TornadoWeather:deleteMap()
    -- Managed by Main
end

function TornadoWeather:installHooks()
    if self.isHooked then return end

    -- WeatherObject survives savegame reloads; flag the class so the hook is only added once.
    -- The hook looks up the TornadoWeather global at call time, so it always uses the current one.
    if WeatherObject.tornadoWeatherHooked then
        self.isHooked = true
        return
    end
    WeatherObject.tornadoWeatherHooked = true

    -- Hook into the WeatherObject activation
    WeatherObject.activate = Utils.appendedFunction(WeatherObject.activate, function(weatherObj, weatherInstance, blendDuration, isSavegameInit)
        if weatherObj.weatherType == WeatherType.TWISTER and not isSavegameInit then
            if TornadoWeather then
                -- Real-life track heading first (server): sets the wind direction the profile then builds on.
                local heading = nil
                if g_currentMission:getIsServer() and TornadoClimate ~= nil then
                    heading = TornadoClimate:applyRealHeading(weatherObj)
                end
                TornadoWeather.pendingHeading = heading
                TornadoWeather:applyProfile(blendDuration, false)
            end
        end
    end)

    self.isHooked = true
    if TornadoDebug then TornadoDebug:log("WEATHER", "Weather hooks installed successfully.") end
end

--- Kept for older callers: a fresh profile, as on a weather activation.
function TornadoWeather:applyRandomProfile()
    self:applyProfile(nil, false)
end

-- =========================================================================
-- PROFILE
-- =========================================================================

--- Builds and applies the storm weather.
--- @param blendDuration number|nil  blend time handed over by the weather change (scaled ms)
--- @param isRespawn boolean          true when a new tornado spawns without a weather change
--- @param preset table|nil           profile to apply instead of rolling one (multiplayer client)
function TornadoWeather:applyProfile(blendDuration, isRespawn, preset)
    if not g_currentMission or not g_currentMission.environment or not g_currentMission.environment.weather then
        return
    end
    local weatherSys = g_currentMission.environment.weather
    if weatherSys.rainUpdater == nil or weatherSys.rainUpdater.targetRain == nil then
        return
    end

    local isClient = not g_currentMission:getIsServer()
    if isClient and preset == nil then
        -- The weather change reached this client: use the server's profile if it already arrived,
        -- otherwise TornadoWeatherEvent applies it when it does.
        if self.receivedProfile ~= nil and g_time - self.receivedProfileTime < self.RECEIVED_PROFILE_KEEP_MS then
            preset = self.receivedProfile
        else
            return
        end
    end

    local profile = preset or self:rollProfile()
    if preset == nil then
        profile.headingDeg = self.pendingHeading
        self.pendingHeading = nil
    end
    -- Fill in the fixed values of the supercell type (only the index travels over the network).
    local supercell = self.PROFILES[profile.index] or self.PROFILES[1]
    profile.name = supercell.name
    profile.short = supercell.short
    profile.textKey = supercell.textKey
    profile.dropMult = supercell.dropMult
    profile.turbulence = supercell.turbulence
    profile.cloudDensity = supercell.cloudDensity

    local blend = blendDuration
    if isRespawn or blend == nil then
        blend = self.RESPAWN_BLEND_MS
    end

    self:applyRain(weatherSys.rainUpdater, profile, blend, isRespawn)
    self:applyClouds(weatherSys.cloudUpdater, profile, blend, isRespawn)
    -- A given profile (server's storm on a client, or a savegame restore on the server) also carries the
    -- heading; a freshly rolled one already had it set by TornadoClimate:applyRealHeading().
    local applyHeading = preset ~= nil and profile.headingDeg ~= nil
    if weatherSys.windUpdater ~= nil and (profile.windMps ~= nil or applyHeading) then
        local wind = weatherSys.windUpdater
        local dirX, dirZ = wind.targetDirX, wind.targetDirZ
        if applyHeading and TornadoClimate ~= nil then
            dirX, dirZ = TornadoClimate.headingToDirection(profile.headingDeg)
        end
        wind:setTargetValues(dirX, dirZ, profile.windMps or wind.targetVelocity, wind.targetCirrusSpeedFactor, blend)
    end

    self.lastProfile = profile
    self:logProfile(profile)

    -- Server: every player gets this exact storm.
    if not isClient and TornadoSync ~= nil then
        TornadoSync:sendWeather(profile)
    end
end

--- Server: a new random storm profile (classic supercell, plus real-life hail / wind when climate mode is on).
function TornadoWeather:rollProfile()
    local index = math.random(1, #self.PROFILES)
    local supercell = self.PROFILES[index]
    local profile = {
        index = index,
        rain = supercell.rain(),
        hail = supercell.hail(),
        windMps = nil,   -- nil = leave the wind as it is (classic)
    }

    -- Real-life climate: hail and wind from the region's NOAA statistics.
    local climate = TornadoClimate ~= nil and TornadoClimate:rollWeather() or nil
    if climate ~= nil then
        profile.region = climate.region.name
        profile.hailCm = climate.hailCm
        profile.hail = climate.hailCm ~= nil and math.min(1, math.max(0.15, climate.hailCm / self.HAIL_FULL_SCALE_CM)) or 0
        profile.gustKmh = climate.gustKmh
        profile.severeWind = climate.severeWind
        profile.windMps = math.min(WindUpdater.MAX_SPEED, (climate.gustKmh * self.GUST_TO_SUSTAINED) / 3.6)
    end
    return profile
end

--- Client: the server's storm profile (TornadoWeatherEvent). Applied now, blending from the current
--- weather, and kept for a twister weather change that may still arrive (applyProfile picks it up then).
function TornadoWeather:applyReceivedProfile(profile)
    self.receivedProfile = profile
    self.receivedProfileTime = g_time
    self:applyProfile(nil, true, profile)
end

--- Rain / hail: changes a private copy of the target rain.
function TornadoWeather:applyRain(rainUpdater, profile, blend, isRespawn)
    local rain = RainSettings.new()
    rain:copyAttributes(rainUpdater.targetRain)
    rain.rainfallScale = profile.rain
    rain.hailfallScale = profile.hail
    rain.maxDropsMultiplier = profile.dropMult
    rain.turbulence = profile.turbulence

    local rainType = rain.typeId ~= nil and rainUpdater.types[rain.typeId] or nil

    if isRespawn then
        -- No weather change is running: blend from what is falling right now.
        local current = RainSettings.new()
        current:copyAttributes(rainType ~= nil and rainType.values or rainUpdater.targetRain)
        rainUpdater.lastRain = current
        rainUpdater.alpha = 0
        rainUpdater.duration = math.max(1, blend)
    end

    -- Swap the target only, so a weather blend that is already running keeps its start point.
    rainUpdater.targetRain = rain
    rainUpdater.isDirty = true

    -- Values the updater does not blend when the rain type changes are taken from its type table.
    if rainType ~= nil then
        rainType.values.maxDropsMultiplier = profile.dropMult
        rainType.values.turbulence = profile.turbulence
    end
end

--- Cloud darkness: changes a private copy of the target clouds.
function TornadoWeather:applyClouds(cloudUpdater, profile, blend, isRespawn)
    if cloudUpdater == nil or cloudUpdater.targetClouds == nil then
        return
    end

    local clouds = CloudSettings.new()
    clouds:copyAttributes(cloudUpdater.targetClouds)
    clouds.densityScale = profile.cloudDensity

    if isRespawn and cloudUpdater.currentClouds ~= nil then
        local current = CloudSettings.new()
        current:copyAttributes(cloudUpdater.currentClouds)
        cloudUpdater.lastClouds = current
        cloudUpdater.alpha = 0
        cloudUpdater.duration = math.max(1, blend)
    end

    cloudUpdater.targetClouds = clouds
    cloudUpdater.isDirty = true
end

function TornadoWeather:logProfile(profile)
    if TornadoDebug == nil then
        return
    end
    if profile.region ~= nil then
        TornadoDebug:info("WEATHER", string.format("Real-life storm (%s): %s | Hail: %s | Gusts: %.0f km/h%s | Wind: %.0f km/h | Rain: %.2f",
            profile.region, profile.name,
            profile.hailCm ~= nil and string.format("%.1f cm (scale %.2f)", profile.hailCm, profile.hail) or "none",
            profile.gustKmh, profile.severeWind and " (severe)" or "", profile.windMps * 3.6, profile.rain))
    else
        TornadoDebug:log("WEATHER", string.format("Deployed %s [Rain: %.2f | Hail: %.2f | Drops: %.1f | Turb: %.1f | Clouds: %.2f]",
            profile.name, profile.rain, profile.hail, profile.dropMult, profile.turbulence, profile.cloudDensity))
    end
end

--- Second line of the ESC map overlay, e.g. "Storm: HP supercell  Hail: 5.3cm  Gusts: 128km/h".
--- Real hail size and gusts only exist in real-life mode; classic mode shows the storm type.
function TornadoWeather:getMapLineText()
    local p = self.lastProfile
    local moving = TornadoText.direction(TornadoPhysics ~= nil and TornadoPhysics.trackLabel or nil)
    local movingText = moving ~= nil and TornadoText.format("tp_map_moving", moving) or nil
    if p == nil then
        return movingText
    end
    local parts = { TornadoText.format("tp_map_storm", p.textKey ~= nil and TornadoText.get(p.textKey) or p.short) }
    if p.region ~= nil then
        table.insert(parts, TornadoText.format("tp_map_hail",
            p.hailCm ~= nil and string.format("%.1f cm", p.hailCm) or TornadoText.get("tp_none")))
        table.insert(parts, TornadoText.format("tp_map_gusts", math.floor((p.gustKmh or 0) + 0.5)))
    end
    if movingText ~= nil then
        table.insert(parts, movingText)
    end
    return table.concat(parts, "  ")
end

--- One-line summary for t_set climate status / the control panel.
function TornadoWeather:getLastProfileText()
    local p = self.lastProfile
    if p == nil then
        return "none yet"
    end
    if p.region == nil then
        return p.name
    end
    return string.format("%s, hail %s, gusts %.0f km/h", p.name,
        p.hailCm ~= nil and string.format("%.1f cm", p.hailCm) or "none", p.gustKmh)
end
