---@class TornadoOutbreak
---@version 1.0
---@description Real-life climate mode: tornado outbreaks. When a tornado touches down, the region's real share of
--- outbreak days (NOAA: days with 10+ tornadoes nationally) decides whether more tornadoes follow the same day.
--- The count follows the region's tornadoes-per-day data, capped by the "max per outbreak" setting.
--- Follow-ups arrive 30-120 in-game minutes after the previous one ends, until the cap, midnight or 22:00.
--- Each follow-up is real twister weather (same path as a natural tornado: storm weather, real heading,
--- warning, siren, multiplayer sync). Server only.

TornadoOutbreak = {}

TornadoOutbreak.MIN_DELAY_MINUTES = 30
TornadoOutbreak.MAX_DELAY_MINUTES = 120
TornadoOutbreak.LAST_START_HOUR = 22      -- no new follow-ups after 22:00 (the storm day is over)

function TornadoOutbreak:loadMap()
    self:reset()
end

function TornadoOutbreak:deleteMap()
    self:reset()
end

function TornadoOutbreak:reset()
    self.isActive = false
    self.total = 0
    self.remaining = 0
    self.day = nil
    self.nextSpawnAt = nil
end

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

--- In-game time in minutes since day 0 (monotonic, does not wrap at midnight).
local function gameMinutes()
    local environment = g_currentMission.environment
    return environment.currentMonotonicDay * 1440 + environment.dayTime / 60000
end

-- =========================================================================
-- EVENTS FROM TornadoPhysics
-- =========================================================================

--- A new tornado touched down (not a size re-roll). May start an outbreak day.
function TornadoOutbreak:onTouchdown()
    if self.isActive or not isServer() then
        return  -- follow-ups of a running outbreak do not start another one
    end
    local climate = TornadoClimate
    if climate == nil or not (climate.isEnabled and climate.useOutbreaks) then
        return
    end
    local region = climate:getActiveRegion()
    local data = region ~= nil and climate:getRegionData(region, "outbreak") or nil
    if data == nil or math.random() >= (data.dayShare or 0) then
        return
    end

    -- Typical size of a busy day in this region, capped by the setting.
    local typical = math.max(2, (data.perDayP90 or 2) * (0.5 + math.random()))
    local total = math.max(2, math.min(climate.outbreakMax or 3, math.floor(typical + 0.5)))
    if total < 2 then
        return
    end

    self.isActive = true
    self.total = total
    self.remaining = total - 1
    self.day = g_currentMission.environment.currentMonotonicDay
    self.nextSpawnAt = nil

    if TornadoDebug then
        TornadoDebug:info("OUTBREAK", string.format("Outbreak day in %s: up to %d more tornadoes possible today.",
            region.name, self.remaining))
    end
    if TornadoSync ~= nil then
        if self.remaining == 1 then
            TornadoSync:sendMessage("tp_msg_outbreak_one", { TornadoText.str(region.name) }, TornadoSync.MSG_CRITICAL)
        else
            TornadoSync:sendMessage("tp_msg_outbreak", { TornadoText.str(region.name), TornadoText.num(self.remaining) },
                TornadoSync.MSG_CRITICAL)
        end
    end
end

--- The current tornado is gone: schedule the next one of the outbreak.
function TornadoOutbreak:onTornadoEnded()
    if not self.isActive or not isServer() then
        return
    end
    if self.remaining <= 0 then
        self:finish("all tornadoes of the outbreak are done")
        return
    end
    local delay = math.random(self.MIN_DELAY_MINUTES, self.MAX_DELAY_MINUTES)
    self.nextSpawnAt = gameMinutes() + delay
    if TornadoDebug then
        TornadoDebug:log("OUTBREAK", string.format("Next tornado in about %d in-game minutes (%d left).", delay, self.remaining))
    end
end

function TornadoOutbreak:finish(reason)
    if TornadoDebug then TornadoDebug:info("OUTBREAK", "Outbreak over: " .. reason) end
    self:reset()
end

-- =========================================================================
-- MAIN LOOP
-- =========================================================================

function TornadoOutbreak:update(dt)
    if not self.isActive or self.nextSpawnAt == nil or not isServer() then
        return
    end
    -- Settings switched off mid-outbreak.
    if TornadoClimate == nil or not (TornadoClimate.isEnabled and TornadoClimate.useOutbreaks) then
        self:finish("outbreaks switched off")
        return
    end

    local environment = g_currentMission.environment
    if environment.currentMonotonicDay ~= self.day or environment.dayTime / 3600000 >= self.LAST_START_HOUR then
        self:finish("the storm day is over")
        return
    end
    if gameMinutes() < self.nextSpawnAt then
        return
    end
    -- Never stack on a tornado that is still on the ground.
    if TornadoPhysics ~= nil and TornadoPhysics.tornadoNode ~= nil and entityExists(TornadoPhysics.tornadoNode) then
        return
    end

    self.nextSpawnAt = nil
    if self:spawnFollowUp() then
        self.remaining = self.remaining - 1
    else
        self:finish("this map has no twister weather right now")
    end
end

--- Starts twister weather now, the same way the game's own gsWeatherTwisterSpawn does (but with a natural
--- start point and heading). Rebuilding the forecast also re-sends it to every multiplayer client.
function TornadoOutbreak:spawnFollowUp()
    local environment = g_currentMission.environment
    local weather = environment.weather
    if weather == nil or weather.twister == nil then
        return false
    end
    local twister = weather:getWeatherObjectBySeasonAndType(environment.currentSeason, WeatherType.TWISTER)
    if twister == nil or not twister:getIsAvailable() then
        return false
    end

    local current = weather.forecastItems[1]
    local currentObject = current ~= nil and weather:getWeatherObjectByIndex(current.season, current.objectIndex) or nil

    local variationIndex = twister:getRandomVariationIndex()
    local variation = twister:getVariationByIndex(variationIndex)
    local duration = MathUtil.hoursToMs(math.max(1, math.random(variation.minHours, variation.maxHours)))
    local instance = WeatherInstance.createInstance(twister.index, variationIndex,
        environment.currentMonotonicDay, math.floor(environment.dayTime), duration, environment.currentSeason)

    weather.forecastItems = { instance }
    weather:fillWeatherForecast(true)
    if currentObject ~= nil then
        currentObject:deactivate(1)
        currentObject:update(9999999)
    end
    weather:init()

    if TornadoDebug then
        TornadoDebug:info("OUTBREAK", string.format("Outbreak tornado %d of %d is forming.", self.total - self.remaining + 1, self.total))
    end
    return true
end

--- One-line state for t_set climate status.
function TornadoOutbreak:getStatusText()
    if not self.isActive then
        return "none"
    end
    return string.format("%d of %d done, %d left", self.total - self.remaining, self.total, self.remaining)
end
