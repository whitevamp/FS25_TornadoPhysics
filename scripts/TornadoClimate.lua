---@class TornadoClimate
---@version 1.0
---@description Optional "real-life climate" mode: rolls each tornado's EF rating and size from
--- NOAA-derived statistics (DB/TornadoClimate.xml, built by tools/build_tornado_climate.py)
--- for the map's region instead of the classic even spread.
---
--- OFF (default): TornadoPhysics:randomizeTornado() keeps its classic roll, unchanged.
--- ON:            1. pick the region (setting, or Auto from the map id / title)
---                2. roll the EF rating from that region's real EF mix
---                3. roll a track width from that EF's real width range (p10 / p50 / p90) and use
---                   where it falls in that range to place the tornado inside the EF's size band.
---                The mod's own radius / map scaling is kept, so gameplay sizes stay as before;
---                only how often each EF rating (and how wide within it) is realistic.
--- If no region data is available (e.g. a non-US map on Auto) the classic roll is used.

TornadoClimate = {}

-- Settings (saved by TornadoSettings, changed via t_set climate / control panel)
TornadoClimate.isEnabled = false
TornadoClimate.regionSetting = "AUTO"   -- "AUTO" or a region id such as "US" / "US_OK"
-- Real-life sub-features (only used while isEnabled):
TornadoClimate.useSeasonality = true    -- tornado timing follows the region's months and hours of day
TornadoClimate.useDirection = true      -- track heading from the region's real directions
TornadoClimate.useOutbreaks = true      -- more tornadoes the same day, with the region's outbreak odds
TornadoClimate.frequency = 1.0          -- multiplier on the map's own overall tornado rate
TornadoClimate.outbreakMax = 3          -- max tornadoes in one outbreak day (including the first)

-- Climate data files, one per country (built by the tools/ scripts). Missing files are skipped.
-- The order is the order of the countries in the region picker.
TornadoClimate.DB_FILES = {
    "DB/TornadoClimate.xml",      -- United States (NOAA SPC)
    "DB/TornadoClimate_CA.xml",   -- Canada (Northern Tornadoes Project)
    "DB/TornadoClimate_AU.xml",   -- Australia (Bureau of Meteorology)
}

-- NOAA reporting thresholds: smallest recorded hail, smallest gust that counts as severe.
TornadoClimate.HAIL_MIN_CM = 1.9
TornadoClimate.SEVERE_GUST_KMH = 93

-- Compass sector -> heading in degrees (0 = north, 90 = east)
TornadoClimate.SECTOR_DEG = { N = 0, NE = 45, E = 90, SE = 135, S = 180, SW = 225, W = 270, NW = 315 }

-- Size band (TornadoPhysics scale) for each EF rating. Must match the EF thresholds in
-- TornadoPhysics:randomizeTornado(): >1.0 EF1, >2.0 EF2, >3.0 EF3, >4.0 EF4, >4.8 EF5.
TornadoClimate.EF_SCALE_BANDS = {
    [0] = { 0.5, 1.0 },
    [1] = { 1.0, 2.0 },
    [2] = { 2.0, 3.0 },
    [3] = { 3.0, 4.0 },
    [4] = { 4.0, 4.8 },
    [5] = { 4.8, 5.0 },
}

function TornadoClimate:loadMap(modDir)
    self.regions = {}        -- id -> { id, name, parent, efMix = {[0..5] = share}, width = {[ef] = {p10,p50,p90}} }
    self.regionOrder = {}    -- ids: each country, then its states / provinces by name
    self.lastRoll = nil

    local loadedFiles = 0
    for fileIndex, file in ipairs(self.DB_FILES) do
        local path = Utils.getFilename(file, modDir)
        if fileExists(path) and self:loadDataFile(path, fileIndex) then
            loadedFiles = loadedFiles + 1
        end
    end
    if loadedFiles == 0 then
        print("TORNADO CLIMATE: no climate data found in DB/ - real-life climate mode unavailable.")
        return
    end

    -- Country by country (file order), the country-wide region first, then its sub-regions by name.
    table.sort(self.regionOrder, function(a, b)
        local ra, rb = self.regions[a], self.regions[b]
        if ra.fileIndex ~= rb.fileIndex then return ra.fileIndex < rb.fileIndex end
        if (ra.parent == nil) ~= (rb.parent == nil) then return ra.parent == nil end
        return ra.name < rb.name
    end)

    if TornadoDebug then
        TornadoDebug:info("CLIMATE", string.format("V1.1 Loaded %d regions from %d climate file(s) (mode %s)",
            #self.regionOrder, loadedFiles, self.isEnabled and "ON" or "OFF"))
    end

    self:installHooks()
end

--- Reads one climate XML file; returns true when it could be opened.
function TornadoClimate:loadDataFile(path, fileIndex)
    local xmlId = loadXMLFile("TornadoClimate", path)
    if xmlId == nil or xmlId == 0 then
        print("TORNADO CLIMATE: could not open " .. path)
        return false
    end

    local i = 0
    while true do
        local key = string.format("TornadoClimate.region(%d)", i)
        local id = getXMLString(xmlId, key .. "#id")
        if id == nil then break end

        local region = {
            id = id,
            name = getXMLString(xmlId, key .. "#name") or id,
            parent = getXMLString(xmlId, key .. "#parent"),
            fileIndex = fileIndex,
            efMix = {},
            width = {},
            hail = nil,   -- { chance, p50, p90, max } hail size in cm
            wind = nil,   -- { chance, p50, p90, max } gust in km/h
            months = {},  -- [1..12] share of tornadoes
            hours = {},   -- [0..23] share of tornadoes (CST)
            direction = nil, -- { meanDeg, consistency, sectors = { {deg, share}, ... } }
            outbreak = nil,  -- { dayShare, perDayP50, perDayP90, perDayMax }
        }

        local j = 0
        while true do
            local mKey = string.format("%s.months.month(%d)", key, j)
            local month = getXMLInt(xmlId, mKey .. "#m")
            if month == nil then break end
            region.months[month] = getXMLFloat(xmlId, mKey .. "#weight") or 0
            j = j + 1
        end

        j = 0
        while true do
            local hKey = string.format("%s.hours.hour(%d)", key, j)
            local hour = getXMLInt(xmlId, hKey .. "#h")
            if hour == nil then break end
            region.hours[hour] = getXMLFloat(xmlId, hKey .. "#weight") or 0
            j = j + 1
        end

        local meanDeg = getXMLFloat(xmlId, key .. ".direction#meanDeg")
        if meanDeg ~= nil then
            region.direction = { meanDeg = meanDeg, consistency = getXMLFloat(xmlId, key .. ".direction#consistency") or 0, sectors = {} }
            j = 0
            while true do
                local dKey = string.format("%s.direction.toward(%d)", key, j)
                local sector = getXMLString(xmlId, dKey .. "#sector")
                if sector == nil then break end
                local deg = TornadoClimate.SECTOR_DEG[sector]
                if deg ~= nil then
                    table.insert(region.direction.sectors, { deg = deg, share = getXMLFloat(xmlId, dKey .. "#share") or 0 })
                end
                j = j + 1
            end
        end

        local dayShare = getXMLFloat(xmlId, key .. ".outbreak#dayShare")
        if dayShare ~= nil then
            region.outbreak = {
                dayShare = dayShare,
                perDayP50 = getXMLFloat(xmlId, key .. ".outbreak#perDayP50") or 1,
                perDayP90 = getXMLFloat(xmlId, key .. ".outbreak#perDayP90") or 2,
                perDayMax = getXMLFloat(xmlId, key .. ".outbreak#perDayMax") or 3,
            }
        end

        j = 0
        while true do
            local efKey = string.format("%s.efMix.ef(%d)", key, j)
            local rating = getXMLInt(xmlId, efKey .. "#rating")
            if rating == nil then break end
            region.efMix[rating] = getXMLFloat(xmlId, efKey .. "#share") or 0
            j = j + 1
        end

        j = 0
        while true do
            local wKey = string.format("%s.pathWidth.ef(%d)", key, j)
            local rating = getXMLInt(xmlId, wKey .. "#rating")
            if rating == nil then break end
            region.width[rating] = {
                p10 = getXMLFloat(xmlId, wKey .. "#p10"),
                p50 = getXMLFloat(xmlId, wKey .. "#p50"),
                p90 = getXMLFloat(xmlId, wKey .. "#p90"),
            }
            j = j + 1
        end

        local hailChance = getXMLFloat(xmlId, key .. ".hail#chance")
        if hailChance ~= nil then
            region.hail = {
                chance = hailChance,
                p50 = getXMLFloat(xmlId, key .. ".hail#sizeP50Cm"),
                p90 = getXMLFloat(xmlId, key .. ".hail#sizeP90Cm"),
                max = getXMLFloat(xmlId, key .. ".hail#sizeMaxCm"),
            }
        end
        local windChance = getXMLFloat(xmlId, key .. ".wind#chance")
        if windChance ~= nil then
            region.wind = {
                chance = windChance,
                p50 = getXMLFloat(xmlId, key .. ".wind#gustP50Kmh"),
                p90 = getXMLFloat(xmlId, key .. ".wind#gustP90Kmh"),
                max = getXMLFloat(xmlId, key .. ".wind#gustMaxKmh"),
            }
        end

        if self.regions[id] == nil then
            self.regionOrder[#self.regionOrder + 1] = id
        end
        self.regions[id] = region
        i = i + 1
    end
    delete(xmlId)
    return true
end

--- Region block or the parent region's when this one has none (direction / outbreak / months / hours).
function TornadoClimate:getRegionData(region, key)
    local value = region[key]
    local isEmpty = value == nil or (type(value) == "table" and next(value) == nil)
    if isEmpty and region.parent ~= nil and self.regions[region.parent] ~= nil then
        return self.regions[region.parent][key]
    end
    return value
end

function TornadoClimate:deleteMap()
    self.regions = {}
    self.regionOrder = {}
    self.lastRoll = nil
end

-- =========================================================================
-- REGION
-- =========================================================================

function TornadoClimate:hasData()
    return self.regionOrder ~= nil and #self.regionOrder > 0
end

--- Region picked automatically from the map: a state / province / country name in the map's title or id
--- -> that region (longest name wins), base US map -> "US", otherwise nil (no data for this region yet).
function TornadoClimate:detectRegion()
    if g_currentMission == nil or g_currentMission.missionInfo == nil then
        return nil
    end
    local info = g_currentMission.missionInfo
    local mapId = info.mapId or ""

    local title = info.mapTitle or ""
    if g_mapManager ~= nil and g_mapManager.getMapById ~= nil then
        local map = g_mapManager:getMapById(mapId)
        if map ~= nil and map.title ~= nil then
            title = title .. " " .. map.title
        end
    end
    local haystack = string.lower(title .. " " .. mapId)

    -- Longest matching name wins: "West Virginia" beats "Virginia", "Arkansas" beats "Kansas",
    -- "Western Australia" beats "Australia", "Ontario" beats "Canada".
    local bestId, bestLength = nil, 0
    for _, id in ipairs(self.regionOrder) do
        local name = string.lower(self.regions[id].name)
        if id ~= "US" and #name > bestLength and string.find(haystack, name, 1, true) ~= nil then
            bestId, bestLength = id, #name
        end
    end
    if bestId ~= nil then
        return bestId
    end

    if mapId == "MapUS" and self.regions["US"] ~= nil then
        return "US"
    end
    return nil
end

--- The region in use: the manual setting if it exists in the data, else Auto detection.
function TornadoClimate:getActiveRegion()
    if not self:hasData() then
        return nil
    end
    if self.regionSetting ~= "AUTO" and self.regions[self.regionSetting] ~= nil then
        return self.regions[self.regionSetting]
    end
    local detected = self:detectRegion()
    return detected ~= nil and self.regions[detected] or nil
end

--- Region setting, accepting an id ("US_OK", "CAN_ON", "AUS_NSW"), a name ("Oklahoma", "Ontario") or "auto".
--- A bare code is tried as a US state first ("CA" = California, "WA" = Washington), then any country.
function TornadoClimate:setRegion(value)
    if value == nil then
        return false
    end
    local wanted = string.upper(tostring(value))
    if wanted == "AUTO" then
        self.regionSetting = "AUTO"
        return true
    end
    local candidates = { wanted, "US_" .. wanted }
    for _, candidate in ipairs(candidates) do
        if self.regions[candidate] ~= nil then
            self.regionSetting = candidate
            return true
        end
    end
    for _, id in ipairs(self.regionOrder) do
        if string.upper(self.regions[id].name) == wanted then
            self.regionSetting = id
            return true
        end
    end
    for _, id in ipairs(self.regionOrder) do
        if string.sub(id, -(#wanted + 1)) == "_" .. wanted then
            self.regionSetting = id
            return true
        end
    end
    return false
end

function TornadoClimate:getRegionLabel(id)
    if id == "AUTO" then
        -- Always what Auto would detect for this map, independent of a manual pick.
        local detected = self:hasData() and self:detectRegion() or nil
        return TornadoText.format("tp_auto", detected ~= nil and self.regions[detected].name or TornadoText.get("tp_auto_none"))
    end
    local region = self.regions ~= nil and self.regions[id] or nil
    return region ~= nil and region.name or tostring(id)
end

-- =========================================================================
-- ROLLING
-- =========================================================================

--- A region's block (e.g. "hail"), or the parent region's when this one has none / no sizes.
function TornadoClimate:getBlock(region, key)
    local block = region[key]
    if (block == nil or block.p50 == nil) and region.parent ~= nil and self.regions[region.parent] ~= nil then
        return self.regions[region.parent][key]
    end
    return block
end

--- Value drawn from p50 / p90 / max: 50% between 0.6 x p50 and p50, 40% p50-p90, 10% p90-max.
function TornadoClimate.sampleFromPercentiles(block)
    local r = math.random()
    if r < 0.5 then
        return block.p50 * (0.6 + 0.8 * r)
    elseif r < 0.9 then
        return block.p50 + (block.p90 - block.p50) * ((r - 0.5) / 0.4)
    end
    local top = math.max(block.max or block.p90, block.p90)
    return block.p90 + (top - block.p90) * ((r - 0.9) / 0.1)
end

--- Storm weather for a tornado in the active region, or nil when real-life mode can't be used.
--- Returns { region, hailCm (nil = no hail), gustKmh, severeWind }.
function TornadoClimate:rollWeather()
    if not self.isEnabled then
        return nil
    end
    local region = self:getActiveRegion()
    if region == nil then
        return nil
    end

    local result = { region = region }

    -- NOAA only records hail from 0.75 in (1.9 cm) and severe gusts from 50 kt (93 km/h); the sampler's
    -- low tail (0.6 x median) can fall under that, so floor it at the reporting thresholds.
    local hail = self:getBlock(region, "hail")
    if hail ~= nil and hail.p50 ~= nil and hail.p90 ~= nil and math.random() < (hail.chance or 0) then
        result.hailCm = math.max(self.HAIL_MIN_CM, self.sampleFromPercentiles(hail))
    end

    local wind = self:getBlock(region, "wind")
    if wind ~= nil and wind.p50 ~= nil and wind.p90 ~= nil and math.random() < (wind.chance or 0) then
        result.gustKmh = math.max(self.SEVERE_GUST_KMH, self.sampleFromPercentiles(wind))
        result.severeWind = true
    else
        -- No severe-wind report: ordinary strong storm inflow, below the 93 km/h severe threshold.
        result.gustKmh = 50 + math.random() * 40
        result.severeWind = false
    end

    return result
end

--- EF rating drawn from the region's EF mix; falls back to the parent region's mix if empty.
function TornadoClimate:rollEF(region)
    local mix = region.efMix
    local total = 0
    for ef = 0, 5 do total = total + (mix[ef] or 0) end
    if total <= 0 and region.parent ~= nil and self.regions[region.parent] ~= nil then
        return self:rollEF(self.regions[region.parent])
    end
    if total <= 0 then
        return nil
    end

    local roll = math.random() * total
    for ef = 0, 5 do
        roll = roll - (mix[ef] or 0)
        if roll <= 0 then
            return ef
        end
    end
    return 5
end

--- Position 0..1 inside the EF size band, from a realistic track width for that EF.
--- Width is drawn piecewise: 10% below p10, 40% p10-p50, 40% p50-p90, 10% above p90.
function TornadoClimate:rollBandPosition(region, ef)
    local w = region.width[ef]
    if (w == nil or w.p10 == nil) and region.parent ~= nil and self.regions[region.parent] ~= nil then
        w = self.regions[region.parent].width[ef]
    end
    if w == nil or w.p10 == nil or w.p50 == nil or w.p90 == nil or w.p90 <= w.p10 then
        return math.random(), nil
    end

    local r = math.random()
    local width
    if r < 0.1 then
        width = w.p10 * (0.5 + r * 5)                         -- 0.5 x p10 .. p10
    elseif r < 0.5 then
        width = w.p10 + (w.p50 - w.p10) * ((r - 0.1) / 0.4)
    elseif r < 0.9 then
        width = w.p50 + (w.p90 - w.p50) * ((r - 0.5) / 0.4)
    else
        width = w.p90 * (1 + (r - 0.9) * 5)                   -- p90 .. 1.5 x p90
    end

    local position = (width - w.p10 * 0.5) / (w.p90 * 1.5 - w.p10 * 0.5)
    return math.max(0, math.min(1, position)), width
end

--- Scale for TornadoPhysics:randomizeTornado(), or nil to keep the classic roll.
function TornadoClimate:rollScale()
    if not self.isEnabled then
        return nil
    end
    local region = self:getActiveRegion()
    if region == nil then
        if TornadoDebug then TornadoDebug:log("CLIMATE", "No climate data for this map region - classic roll used.") end
        return nil
    end

    local ef = self:rollEF(region)
    if ef == nil then
        return nil
    end
    local band = self.EF_SCALE_BANDS[ef]
    local position, width = self:rollBandPosition(region, ef)

    -- Stay just inside the band so TornadoPhysics derives the same EF from the scale.
    local inset = (band[2] - band[1]) * 0.02
    local scale = band[1] + inset + (band[2] - band[1] - 2 * inset) * position

    self.lastRoll = { region = region.id, regionName = region.name, ef = ef, width = width, scale = scale }
    if TornadoDebug then
        TornadoDebug:info("CLIMATE", string.format("Real-life roll: %s EF-%d (real width %s) -> scale %.2f",
            region.name, ef, width ~= nil and string.format("%.0fm", width) or "n/a", scale))
    end
    return scale
end


-- =========================================================================
-- SEASONALITY / TIME OF DAY
-- The map's weather decides how often twisters come up (its per-season weights). In real-life mode the
-- map's average rate is kept (times the frequency setting) but redistributed over the year and the day
-- by the region's real month and hour shares. Hooked into Weather:createRandomWeatherInstance (server).
-- =========================================================================

--- Calendar month (1..12) of an in-game day. Period 1 = March; southern-hemisphere maps are 6 months on.
function TornadoClimate:getMonthOfDay(day)
    local environment = g_currentMission.environment
    local period = environment:getPeriodFromDay(day)
    local month = period + 2
    if environment.daylight ~= nil and environment.daylight.latitude ~= nil and environment.daylight.latitude < 0 then
        month = month + 6
    end
    return (month - 1) % 12 + 1
end

--- 1.0 = average; 2.0 = twice the average share of tornadoes in this month / hour.
function TornadoClimate:getTimingFactor(region, month, hour)
    local months = self:getRegionData(region, "months")
    local hours = self:getRegionData(region, "hours")
    local monthFactor = (months ~= nil and months[month] ~= nil) and months[month] * 12 or 1
    local hourFactor = (hours ~= nil and hours[hour] ~= nil) and hours[hour] * 24 or 1
    return monthFactor * hourFactor
end

--- The map's average twister share per forecast slot over the year (0 when the map has no twisters).
function TornadoClimate:getMapTwisterRate(weather)
    local total, seasons = 0, 0
    for season, list in pairs(weather.weightedWeatherObjects) do
        seasons = seasons + 1
        local twister = weather:getWeatherObjectBySeasonAndType(season, WeatherType.TWISTER)
        if twister ~= nil and #list > 0 then
            local count = 0
            for _, index in ipairs(list) do
                if index == twister.index then count = count + 1 end
            end
            total = total + count / #list
        end
    end
    return seasons > 0 and total / seasons or 0
end

--- Replaces a freshly rolled forecast slot so twisters follow real seasonality / time of day.
function TornadoClimate:adjustForecastInstance(weather, superFunc, instance, season, startDay, startDayTime, firstWeather)
    if not (self.isEnabled and self.useSeasonality) or g_currentMission == nil or not g_currentMission:getIsServer() then
        return instance
    end
    local region = self:getActiveRegion()
    local twister = weather:getWeatherObjectBySeasonAndType(season, WeatherType.TWISTER)
    if region == nil or twister == nil or not twister:getIsAvailable() then
        return instance
    end
    local baseRate = self:getMapTwisterRate(weather)
    if baseRate <= 0 then
        return instance
    end

    local hour = math.floor((startDayTime or 0) / 3600000) % 24
    local chance = math.min(0.5, baseRate * self.frequency * self:getTimingFactor(region, self:getMonthOfDay(startDay), hour))
    local current = weather:getWeatherObjectByIndex(season, instance.objectIndex)
    local isTwister = current ~= nil and current.weatherType == WeatherType.TWISTER

    if math.random() < chance then
        if isTwister then
            return instance
        end
        local variationIndex = twister:getRandomVariationIndex()
        local variation = twister:getVariationByIndex(variationIndex)
        local duration = MathUtil.hoursToMs(math.max(1, math.random(variation.minHours, variation.maxHours)))
        if TornadoDebug then
            TornadoDebug:log("CLIMATE", string.format("Forecast: twister placed on day %d %02d:00 (chance %.1f%%)", startDay, hour, chance * 100))
        end
        return WeatherInstance.createInstance(twister.index, variationIndex, startDay, math.floor(startDayTime), duration, season)
    end

    -- Not a tornado slot: re-roll the game's pick until it is something else.
    local tries = 0
    while isTwister and tries < 10 do
        instance = superFunc(weather, season, startDay, startDayTime, firstWeather)
        current = weather:getWeatherObjectByIndex(season, instance.objectIndex)
        isTwister = current ~= nil and current.weatherType == WeatherType.TWISTER
        tries = tries + 1
    end
    return instance
end

-- =========================================================================
-- DIRECTION
-- =========================================================================

--- Track heading in degrees (0 = N, 90 = E) from the region's real track directions, or nil.
function TornadoClimate:rollHeading(region)
    local direction = self:getRegionData(region, "direction")
    if direction == nil or direction.sectors == nil or #direction.sectors == 0 then
        return nil
    end
    local total = 0
    for _, sector in ipairs(direction.sectors) do total = total + sector.share end
    if total <= 0 then
        return nil
    end
    local roll = math.random() * total
    for _, sector in ipairs(direction.sectors) do
        roll = roll - sector.share
        if roll <= 0 then
            return (sector.deg + (math.random() * 45 - 22.5)) % 360
        end
    end
    return direction.meanDeg
end

--- World direction (x, z) of a compass heading. North is -Z on FS maps.
function TornadoClimate.headingToDirection(headingDeg)
    local rad = math.rad(headingDeg)
    return math.sin(rad), -math.cos(rad)
end

--- Compass label of a world direction (x, z).
function TornadoClimate.directionToLabel(dirX, dirZ)
    if dirX == nil or dirZ == nil or (math.abs(dirX) < 0.0001 and math.abs(dirZ) < 0.0001) then
        return nil
    end
    local heading = (math.deg(math.atan2(dirX, -dirZ)) + 360) % 360
    local labels = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    return labels[math.floor(((heading + 22.5) % 360) / 45) + 1]
end

--- Server, twister weather activation: real-life heading for the wind (the twister follows the wind)
--- and a start point on the upwind side so the track crosses the map. Returns the heading or nil.
function TornadoClimate:applyRealHeading(weatherObject)
    if not (self.isEnabled and self.useDirection) or self.consoleSpawnActive then
        return nil
    end
    local region = self:getActiveRegion()
    local heading = region ~= nil and self:rollHeading(region) or nil
    if heading == nil then
        return nil
    end

    local dirX, dirZ = self.headingToDirection(heading)
    local half = g_currentMission.terrainSize * 0.5
    local offset = (math.random() - 0.5) * half          -- sideways, so tracks do not all cross the centre
    weatherObject.twisterStartPosX = -dirX * half * 0.85 + (-dirZ) * offset
    weatherObject.twisterStartPosZ = -dirZ * half * 0.85 + dirX * offset

    local wind = g_currentMission.environment.weather.windUpdater
    wind:setTargetValues(dirX, dirZ, wind.targetVelocity, wind.targetCirrusSpeedFactor, math.max(1, wind.duration or 1))

    if TornadoDebug then
        TornadoDebug:info("CLIMATE", string.format("Real-life track heading %.0f deg (%s)", heading, self.directionToLabel(dirX, dirZ) or "?"))
    end
    return heading
end

-- =========================================================================
-- HOOKS (server; the hooked classes survive savegame reloads, so flag them)
-- =========================================================================

function TornadoClimate:installHooks()
    if Weather == nil or Weather.tornadoClimateHooked then
        return
    end
    Weather.tornadoClimateHooked = true

    Weather.createRandomWeatherInstance = Utils.overwrittenFunction(Weather.createRandomWeatherInstance,
        function(weather, superFunc, season, startDay, startDayTime, firstWeather)
            local instance = superFunc(weather, season, startDay, startDayTime, firstWeather)
            if TornadoClimate ~= nil and not firstWeather and instance ~= nil then
                instance = TornadoClimate:adjustForecastInstance(weather, superFunc, instance, season, startDay, startDayTime, firstWeather)
            end
            return instance
        end)

    -- gsWeatherTwisterSpawn places the twister at the player and aims it the player's way: leave that alone.
    Weather.consoleCommandWeatherTwisterSpawn = Utils.overwrittenFunction(Weather.consoleCommandWeatherTwisterSpawn,
        function(weather, superFunc, ...)
            if TornadoClimate ~= nil then TornadoClimate.consoleSpawnActive = true end
            local result = superFunc(weather, ...)
            if TornadoClimate ~= nil then TornadoClimate.consoleSpawnActive = false end
            return result
        end)
end
