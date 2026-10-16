---@class TornadoHazards
---@version 1.2
---@description Optional natural hazards that the crop insurance needs as perils (OFF by default).
--- Phase 1: drought. Phase 2: flood. Phase 3: field fire (see docs/INSURANCE_DESIGN.md 15.2).
---
--- Soil water (one value for the whole map, 0..1) is updated every in-game hour from the game's own weather:
--- rain (and a little snow) fills it, warm dry hours drain it; below 5 C nothing dries out. When it stays under
--- DROUGHT_LEVEL for DROUGHT_DAYS in-game days a drought starts. Every drought day each growing field gets
--- patchy crop damage through the game's own disaster function (FSDensityMapUtil.updateDisasterArea, the same
--- one hail uses), growing a little each day up to a cap; rain ends it. Rice paddies are spared, grass is hit
--- half as hard. Only when the game's "Disaster destruction" setting is enabled.
--- Flood: heavy rain for FLOOD_HOURS on soaked soil floods the lowest-lying growing fields of the map - a patchy
--- damage circle at each field's lowest point (water pools there). Rice is spared.
--- Field fire: during a drought, on hot dry afternoons, a ripe dry field can catch fire. The fire starts at a spot
--- inside the field and burns a growing circle (kept inside the field) until it burns out or rain puts it out;
--- the burnt crop is destroyed. Visuals / map marker: TornadoFieldFireFX (synced with TornadoFieldFireEvent).
--- "Only damage owned fields" (off by default) skips fields no farm owns.
--- Every field hit is logged (day, field, farm, share) for the insurance module and saved with the savegame.
---
--- Server only (the engine syncs the crop changes); messages go to all players, damage reports to the farm.
--- Switched off while FS25_RealisticWeather is installed (it has its own drought; both would double the loss).

TornadoHazards = {}

-- Settings (saved by TornadoSettings, synced by TornadoSync, changed via t_set hazards / control panel)
TornadoHazards.isEnabled = false
TornadoHazards.droughtEnabled = true
TornadoHazards.intensity = 1.0     -- crop damage multiplier; 1.0 = mild
TornadoHazards.frequency = 1.0     -- how fast the soil dries out (more / longer dry spells)
TornadoHazards.floodEnabled = true
TornadoHazards.fireEnabled = true
TornadoHazards.ownedOnly = false   -- true: fields no farm owns are never damaged

TornadoHazards.FILE = "TornadoHazards.xml"
TornadoHazards.REALISTIC_WEATHER_MOD = "FS25_RealisticWeather"

-- Soil water balance (per in-game hour). Tuned so a week of hot dry weather empties a normal soil.
TornadoHazards.WATER_START = 0.6
TornadoHazards.RAIN_GAIN = 0.04         -- per hour of full rain
TornadoHazards.SNOW_GAIN_FACTOR = 0.3   -- snow counts less (it melts later)
TornadoHazards.EVAP_BASE = 0.0010       -- per hour at 5 C
TornadoHazards.EVAP_PER_DEGREE = 0.00018 -- extra per hour and degree above 5 C (25 C: ~0.0046 / h)
TornadoHazards.NO_DRYING_BELOW_C = 5

-- Drought thresholds (soil water) and timing (in-game days).
TornadoHazards.DRY_SPELL_LEVEL = 0.30   -- warning
TornadoHazards.DRY_SPELL_RESET = 0.40   -- warning can fire again after recovering above this
TornadoHazards.DROUGHT_LEVEL = 0.20
TornadoHazards.DROUGHT_END_LEVEL = 0.35
TornadoHazards.DROUGHT_DAYS = 2

-- Crop damage per drought day: share grows by DAILY_STEP up to MAX_SHARE (both x intensity), turned into the
-- disaster function's perlin threshold (higher = fewer patches). PERLIN_PER_SHARE needs in-game calibration.
TornadoHazards.DAILY_STEP = 0.03
TornadoHazards.MAX_SHARE = 0.15
TornadoHazards.MAX_SHARE_LIMIT = 0.9
TornadoHazards.PERLIN_PER_SHARE = 10000
TornadoHazards.GRASS_FACTOR = 0.5
TornadoHazards.SPARED_FRUITS = { RICE = true, RICELONGGRAIN = true }
TornadoHazards.HALF_FRUITS = { GRASS = true, MEADOW = true }

-- Flood: heavy rain on soaked soil. Fields whose lowest point is among the lowest FLOOD_LOW_SHARE of all fields
-- get a damage circle there (radius from the field size), FLOOD_LOCAL_SHARE x intensity heavy inside the circle.
TornadoHazards.FLOOD_SOAKED = 0.85
TornadoHazards.HEAVY_RAIN = 0.6
TornadoHazards.FLOOD_HOURS = 3
TornadoHazards.FLOOD_COOLDOWN_DAYS = 2
TornadoHazards.FLOOD_LOW_SHARE = 0.2
TornadoHazards.FLOOD_LOCAL_SHARE = 0.5
TornadoHazards.FLOOD_RADIUS_FACTOR = 0.3
TornadoHazards.FLOOD_MIN_RADIUS = 12
TornadoHazards.FLOOD_MAX_RADIUS = 70
TornadoHazards.FLOOD_GRID_STEPS = 7       -- 7 x 7 height samples inside each field outline
TornadoHazards.FLOOD_SPARED_FRUITS = { RICE = true, RICELONGGRAIN = true }

-- Field fire: only during a drought, FIRE_HOURS of the day, at FIRE_MIN_TEMP or warmer and without rain. Per hour
-- FIRE_CHANCE_PER_HOUR x frequency that one ripe dry field catches fire (one fire at a time).
TornadoHazards.FIRE_MIN_TEMP = 25
TornadoHazards.FIRE_FIRST_HOUR = 10
TornadoHazards.FIRE_LAST_HOUR = 19
TornadoHazards.FIRE_CHANCE_PER_HOUR = 0.04
TornadoHazards.FIRE_START_RADIUS = 4
TornadoHazards.FIRE_MIN_RADIUS = 10        -- a start spot needs at least this much room to the field edge
TornadoHazards.FIRE_MAX_RADIUS = 80
TornadoHazards.FIRE_SPREAD_MPS = 0.05      -- metres per game second (80 m in ~27 game minutes)
TornadoHazards.FIRE_BURN_INTERVAL_MS = 1000
TornadoHazards.FIRE_RAIN_OUT = 0.3         -- rain this strong puts the fire out
-- Crops that do not burn like a dry grain field.
TornadoHazards.FIRE_EXCLUDED_FRUITS = { RICE = true, RICELONGGRAIN = true, POTATO = true, SUGARBEET = true,
    REDBEET = true, CARROT = true, PARSNIP = true, SPINACH = true, GREENBEAN = true, GRASS = true, MEADOW = true,
    SUGARCANE = true, GRAPE = true, OLIVE = true, POPLAR = true }

TornadoHazards.MAX_EVENTS = 300

TornadoHazards.EVENT_DROUGHT = "DROUGHT"
TornadoHazards.EVENT_FLOOD = "FLOOD"
TornadoHazards.EVENT_FIRE = "FIRE"

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

function TornadoHazards:loadMap()
    self.water = self.WATER_START
    self.dryDays = 0
    self.droughtDay = 0          -- 0 = no drought, else the day number of the running drought
    self.dryWarned = false
    self.events = {}             -- { kind, day, fieldId, farmId, share }
    self.lastDamage = nil        -- { day, fields, share } of the last damage pass (status)
    self.floodHours = 0          -- consecutive hours of heavy rain on soaked soil
    self.floodCooldownUntil = 0  -- no new flood before this day
    self.lastFlood = nil         -- { day, fields }
    self.lowPoints = nil         -- fieldId -> { x, z, y } lowest point of each field (built on first flood)
    self.fire = nil              -- the burning fire: { id, field, fieldId, farmId, x, z, radius, maxRadius, speed, burnTimer }
    self.nextFireId = 1

    if isServer() then
        self:loadState()
        if g_messageCenter ~= nil then
            g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
            g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
        end
    end
    if TornadoDebug then
        TornadoDebug:info("HAZARDS", string.format("V1.1 loaded (enabled %s, soil water %.0f %%%s)", tostring(self.isEnabled),
            self.water * 100, self:isHandledByRealisticWeather() and ", off: RealisticWeather installed" or ""))
    end
end

function TornadoHazards:deleteMap()
    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end
    self.fire = nil
end

-- =========================================================================
-- STATE
-- =========================================================================

function TornadoHazards:isHandledByRealisticWeather()
    return g_modIsLoaded ~= nil and g_modIsLoaded[self.REALISTIC_WEATHER_MOD] == true
end

--- Module running at all (the soil water is needed by both drought and flood).
function TornadoHazards:isActive()
    return self.isEnabled and (self.droughtEnabled or self.floodEnabled or self.fireEnabled)
        and not self:isHandledByRealisticWeather() and isServer()
end

function TornadoHazards:isFireActive()
    return self:isActive() and self.fireEnabled
end

function TornadoHazards:isDroughtActive()
    return self:isActive() and self.droughtEnabled
end

function TornadoHazards:isFloodActive()
    return self:isActive() and self.floodEnabled
end

local function getFieldOwner(field)
    local farmId = field.getOwner ~= nil and field:getOwner() or nil
    return farmId or 0
end

--- Whether a field may be damaged at all ("Only damage owned fields" skips fields nobody owns).
function TornadoHazards:isFieldAffected(field)
    if not self.ownedOnly then
        return true
    end
    local noOwner = FarmlandManager ~= nil and FarmlandManager.NO_OWNER_FARM_ID or 0
    return getFieldOwner(field) ~= noOwner
end

--- True when the game's "Disaster destruction" setting lets weather destroy crops.
function TornadoHazards:canDestroyCrops()
    local info = g_currentMission ~= nil and g_currentMission.missionInfo or nil
    if info == nil or DisasterDestructionState == nil then
        return false
    end
    return info.disasterDestructionState == DisasterDestructionState.ENABLED
end

local function getWeather()
    local environment = g_currentMission ~= nil and g_currentMission.environment or nil
    return environment ~= nil and environment.weather or nil
end

local function getDay()
    local environment = g_currentMission ~= nil and g_currentMission.environment or nil
    return environment ~= nil and environment.currentMonotonicDay or 0
end

-- =========================================================================
-- WATER BALANCE (every in-game hour)
-- =========================================================================

function TornadoHazards:onHourChanged()
    if not self:isActive() then
        return
    end
    local weather = getWeather()
    if weather == nil then
        return
    end
    local rain = weather.getRainFallScale ~= nil and weather:getRainFallScale() or 0
    local snow = weather.getSnowFallScale ~= nil and weather:getSnowFallScale() or 0
    local temperature = weather.getCurrentTemperature ~= nil and weather:getCurrentTemperature() or 15

    local gain = ((rain or 0) + (snow or 0) * self.SNOW_GAIN_FACTOR) * self.RAIN_GAIN
    local loss = 0
    if temperature >= self.NO_DRYING_BELOW_C then
        loss = (self.EVAP_BASE + (temperature - self.NO_DRYING_BELOW_C) * self.EVAP_PER_DEGREE) * self.frequency
    end
    self.water = math.max(0, math.min(1, self.water + gain - loss))

    -- Flood: hours of heavy rain on soaked soil in a row.
    if self.floodEnabled then
        if (rain or 0) >= self.HEAVY_RAIN and self.water >= self.FLOOD_SOAKED then
            self.floodHours = self.floodHours + 1
        elseif (rain or 0) < self.HEAVY_RAIN * 0.5 then
            self.floodHours = 0
        end
        if self.floodHours >= self.FLOOD_HOURS and getDay() >= self.floodCooldownUntil then
            self:triggerFlood()
        end
    end

    -- Field fire: hot dry afternoons during a drought.
    if self.fireEnabled and self.fire == nil and self.droughtDay > 0 and (rain or 0) <= 0
        and temperature >= self.FIRE_MIN_TEMP then
        local hour = g_currentMission.environment.currentHour or 12
        if hour >= self.FIRE_FIRST_HOUR and hour <= self.FIRE_LAST_HOUR
            and math.random() < self.FIRE_CHANCE_PER_HOUR * self.frequency then
            self:startRandomFire()
        end
    end

    -- Dry-spell warning once per dry period (drought only).
    if not self.droughtEnabled then
        return
    end
    if not self.dryWarned and self.droughtDay == 0 and self.water < self.DRY_SPELL_LEVEL then
        self.dryWarned = true
        self:sendMessage("tp_msg_dry_spell", { TornadoText.num(math.floor(self.water * 100 + 0.5)) }, TornadoSync and TornadoSync.MSG_INFO)
    elseif self.dryWarned and self.water > self.DRY_SPELL_RESET then
        self.dryWarned = false
    end
end

-- =========================================================================
-- DROUGHT (every in-game day)
-- =========================================================================

function TornadoHazards:onDayChanged()
    if not self:isDroughtActive() then
        return
    end
    if self.water < self.DROUGHT_LEVEL then
        self.dryDays = self.dryDays + 1
    else
        self.dryDays = 0
    end

    if self.droughtDay > 0 then
        if self.water > self.DROUGHT_END_LEVEL then
            self:endDrought()
            return
        end
        self.droughtDay = self.droughtDay + 1
        self:applyDroughtDamage()
    elseif self.dryDays >= self.DROUGHT_DAYS then
        self:startDrought()
    end
end

function TornadoHazards:startDrought()
    self.droughtDay = 1
    self:sendMessage("tp_msg_drought_start", {}, TornadoSync and TornadoSync.MSG_CRITICAL)
    if TornadoDebug then
        TornadoDebug:info("HAZARDS", string.format("Drought started (soil water %.0f %%, %d dry days).", self.water * 100, self.dryDays))
    end
    self:applyDroughtDamage()
end

function TornadoHazards:endDrought()
    if TornadoDebug then
        TornadoDebug:info("HAZARDS", string.format("Drought ended after %d days (soil water %.0f %%).", self.droughtDay, self.water * 100))
    end
    self.droughtDay = 0
    self.dryDays = 0
    self:sendMessage("tp_msg_drought_end", {}, TornadoSync and TornadoSync.MSG_INFO)
end

--- Share of a growing field the drought takes on the current drought day (before the grass factor).
function TornadoHazards:getDroughtShare()
    local maxShare = math.min(self.MAX_SHARE_LIMIT, self.MAX_SHARE * self.intensity)
    return math.min(maxShare, self.DAILY_STEP * self.intensity * math.max(1, self.droughtDay))
end

local function shareToPerlin(share)
    return math.floor(math.max(0, 10000 - share * TornadoHazards.PERLIN_PER_SHARE) + 0.5)
end

--- One drought day of crop damage on every growing field. Returns the number of fields hit.
function TornadoHazards:applyDroughtDamage()
    if not self:canDestroyCrops() then
        if TornadoDebug then
            TornadoDebug:info("HAZARDS", "Drought day without crop damage: the game's disaster destruction setting is not enabled.")
        end
        return 0
    end
    local weather = getWeather()
    if weather ~= nil and weather.getCurrentMinMaxTemperatures ~= nil then
        local _, maxTemperature = weather:getCurrentMinMaxTemperatures()
        if maxTemperature ~= nil and maxTemperature < self.NO_DRYING_BELOW_C then
            return 0   -- too cold for crops to dry out
        end
    end
    if g_fieldManager == nil or g_fieldManager.getFields == nil or FSDensityMapUtil == nil
        or FSDensityMapUtil.updateDisasterArea == nil then
        return 0
    end

    local share = self:getDroughtShare()
    local day = getDay()
    local perFarm = {}
    local numFields = 0
    for _, field in pairs(g_fieldManager:getFields()) do
        local fruitName = self:getGrowingFruitName(field)
        if fruitName ~= nil and not self.SPARED_FRUITS[fruitName] and self:isFieldAffected(field) then
            local fieldShare = self.HALF_FRUITS[fruitName] and share * self.GRASS_FACTOR or share
            local polygon = field.getDensityMapPolygon ~= nil and field:getDensityMapPolygon() or nil
            if polygon ~= nil then
                FSDensityMapUtil.updateDisasterArea(polygon, shareToPerlin(fieldShare))
                numFields = numFields + 1
                local farmId = getFieldOwner(field)
                self:logEvent(self.EVENT_DROUGHT, day, field:getId(), farmId, fieldShare)
                if farmId ~= nil and farmId ~= 0 then
                    perFarm[farmId] = (perFarm[farmId] or 0) + 1
                end
            end
        end
    end

    self.lastDamage = { day = day, fields = numFields, share = share }
    for farmId, count in pairs(perFarm) do
        self:sendMessage("tp_msg_drought_damage", { TornadoText.num(count) }, TornadoSync and TornadoSync.MSG_INFO, farmId)
    end
    if TornadoDebug then
        TornadoDebug:info("HAZARDS", string.format("Drought day %d: %d growing fields hit, share up to %.0f %% (perlin %d).",
            self.droughtDay, numFields, share * 100, shareToPerlin(share)))
    end
    return numFields
end

--- Fruit type name of the crop growing on a field, nil when nothing grows there.
function TornadoHazards:getGrowingFruitName(field)
    local state = field.getFieldState ~= nil and field:getFieldState() or nil
    if state == nil or not state.isValid or state.fruitTypeIndex == nil or state.fruitTypeIndex == FruitType.UNKNOWN then
        return nil
    end
    if (state.growthState or 0) <= 0 then
        return nil
    end
    local fruitType = g_fruitTypeManager ~= nil and g_fruitTypeManager:getFruitTypeByIndex(state.fruitTypeIndex) or nil
    return fruitType ~= nil and fruitType.name or nil
end

-- =========================================================================
-- FLOOD
-- =========================================================================

--- Lowest point of a field: its outline points and centre, sampled on the terrain. Cached per field.
function TornadoHazards:getFieldLowPoint(field)
    self.lowPoints = self.lowPoints or {}
    local id = field.getId ~= nil and field:getId() or nil
    if id ~= nil and self.lowPoints[id] ~= nil then
        return self.lowPoints[id]
    end
    if g_terrainNode == nil or getTerrainHeightAtWorldPos == nil then
        return nil
    end
    local best = nil
    local centreY = nil
    local function sample(x, z)
        if x == nil or z == nil then return end
        local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
        if y ~= nil and (best == nil or y < best.y) then
            best = { x = x, z = z, y = y }
        end
        return y
    end
    if field.getCenterOfFieldWorldPosition ~= nil then
        centreY = sample(field:getCenterOfFieldWorldPosition())
    end

    -- A grid inside the field outline (not the outline itself: corners often sit on raised edges / tracks).
    local outline = {}
    local points = field.getPolygonPoints ~= nil and field:getPolygonPoints() or nil
    for _, node in ipairs(points or {}) do
        if node ~= nil and node ~= 0 then
            local x, _, z = getWorldTranslation(node)
            if x ~= nil then
                table.insert(outline, { x = x, z = z })
            end
        end
    end
    if #outline >= 3 then
        local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
        for _, p in ipairs(outline) do
            minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
            minZ, maxZ = math.min(minZ, p.z), math.max(maxZ, p.z)
        end
        local steps = self.FLOOD_GRID_STEPS
        for i = 1, steps do
            for j = 1, steps do
                local x = minX + (maxX - minX) * (i - 0.5) / steps
                local z = minZ + (maxZ - minZ) * (j - 0.5) / steps
                if self:isInsideOutline(outline, x, z) then
                    sample(x, z)
                end
            end
        end
    end
    if best ~= nil then
        best.belowCentre = centreY ~= nil and (centreY - best.y) or 0
    end
    if id ~= nil and best ~= nil then
        self.lowPoints[id] = best
    end
    return best
end

--- Point-in-polygon (even-odd rule) on the x / z plane.
function TornadoHazards:isInsideOutline(outline, x, z)
    local inside = false
    local j = #outline
    for i = 1, #outline do
        local a, b = outline[i], outline[j]
        if ((a.z > z) ~= (b.z > z)) and (x < (b.x - a.x) * (z - a.z) / (b.z - a.z) + a.x) then
            inside = not inside
        end
        j = i
    end
    return inside
end

--- Height below which a field counts as "low" (the FLOOD_LOW_SHARE quantile of all fields' lowest points).
function TornadoHazards:getFloodHeightLimit()
    local heights = {}
    for _, field in pairs(g_fieldManager:getFields()) do
        local low = self:getFieldLowPoint(field)
        if low ~= nil then
            table.insert(heights, low.y)
        end
    end
    if #heights == 0 then
        return nil
    end
    table.sort(heights)
    local index = math.max(1, math.ceil(#heights * self.FLOOD_LOW_SHARE))
    return heights[index]
end

--- Floods the lowest-lying growing fields. Returns the number of fields hit.
function TornadoHazards:triggerFlood()
    self.floodHours = 0
    self.floodCooldownUntil = getDay() + self.FLOOD_COOLDOWN_DAYS
    if not self:canDestroyCrops() then
        if TornadoDebug then
            TornadoDebug:info("HAZARDS", "Flood without crop damage: the game's disaster destruction setting is not enabled.")
        end
        return 0
    end
    if g_fieldManager == nil or g_fieldManager.getFields == nil or FSDensityMapUtil == nil
        or FSDensityMapUtil.updateDisasterArea == nil or DensityMapCircle == nil then
        return 0
    end
    local limit = self:getFloodHeightLimit()
    if limit == nil then
        return 0
    end

    local localShare = math.min(0.95, self.FLOOD_LOCAL_SHARE * self.intensity)
    local perlin = shareToPerlin(localShare)
    local circle = DensityMapCircle.new()
    local day = getDay()
    local perFarm = {}
    local numFields = 0
    for _, field in pairs(g_fieldManager:getFields()) do
        local fruitName = self:getGrowingFruitName(field)
        local low = fruitName ~= nil and not self.FLOOD_SPARED_FRUITS[fruitName] and self:isFieldAffected(field)
            and self:getFieldLowPoint(field) or nil
        if low ~= nil and low.y <= limit then
            local areaHa = field.getAreaHa ~= nil and field:getAreaHa() or 1
            local sideM = math.sqrt(math.max(areaHa, 0.01) * 10000)
            local radius = math.max(self.FLOOD_MIN_RADIUS, math.min(self.FLOOD_MAX_RADIUS, sideM * self.FLOOD_RADIUS_FACTOR))
            circle:updateFromWorldPosition(low.x, low.z, radius, 12)
            FSDensityMapUtil.updateDisasterArea(circle, perlin)
            numFields = numFields + 1
            if TornadoDebug then
                TornadoDebug:info("HAZARDS", string.format("  Flood field %s: circle at (%.0f, %.0f), radius %.0f m, %.1f m below the field centre.",
                    tostring(field:getId()), low.x, low.z, radius, low.belowCentre or 0))
            end
            -- Share of the whole field: the circle (at most the field) times the share inside it.
            local fieldShare = localShare * math.min(1, (math.pi * radius * radius) / (math.max(areaHa, 0.01) * 10000))
            local farmId = getFieldOwner(field)
            self:logEvent(self.EVENT_FLOOD, day, field:getId(), farmId, fieldShare)
            if farmId ~= 0 then
                perFarm[farmId] = (perFarm[farmId] or 0) + 1
            end
        end
    end

    self.lastFlood = { day = day, fields = numFields }
    if numFields > 0 then
        self:sendMessage("tp_msg_flood", { TornadoText.num(numFields) }, TornadoSync and TornadoSync.MSG_CRITICAL)
        for farmId, count in pairs(perFarm) do
            self:sendMessage("tp_msg_flood_damage", { TornadoText.num(count) }, TornadoSync and TornadoSync.MSG_INFO, farmId)
        end
    end
    if TornadoDebug then
        TornadoDebug:info("HAZARDS", string.format("Flood: %d low-lying growing fields hit (height limit %.1f m, share %.0f %% inside the circle, perlin %d).",
            numFields, limit, localShare * 100, perlin))
    end
    return numFields
end

-- =========================================================================
-- FIELD FIRE
-- =========================================================================

--- Fruit type and field state of the crop growing on a field (nil when nothing grows there).
function TornadoHazards:getFieldFruit(field)
    local state = field.getFieldState ~= nil and field:getFieldState() or nil
    if state == nil or not state.isValid or state.fruitTypeIndex == nil or state.fruitTypeIndex == FruitType.UNKNOWN then
        return nil, nil
    end
    local fruitType = g_fruitTypeManager ~= nil and g_fruitTypeManager:getFruitTypeByIndex(state.fruitTypeIndex) or nil
    return fruitType, state
end

--- A field can burn: a ripe (harvest-ready) crop that burns like a dry grain field.
function TornadoHazards:canFieldBurn(field, anyGrowingCrop)
    if not self:isFieldAffected(field) then
        return false
    end
    local fruitType, state = self:getFieldFruit(field)
    if fruitType == nil or state == nil or self.FIRE_EXCLUDED_FRUITS[fruitType.name] or (state.growthState or 0) <= 0 then
        return false
    end
    if anyGrowingCrop then
        return true
    end
    local minState = fruitType.minHarvestingGrowthState or 0
    local maxState = fruitType.maxHarvestingGrowthState or 0
    return minState > 0 and state.growthState >= minState and state.growthState <= maxState
end

--- Field outline as { {x, z} ... } (world positions of its polygon points).
function TornadoHazards:getFieldOutline(field)
    local outline = {}
    local points = field.getPolygonPoints ~= nil and field:getPolygonPoints() or nil
    for _, node in ipairs(points or {}) do
        if node ~= nil and node ~= 0 then
            local x, _, z = getWorldTranslation(node)
            if x ~= nil then
                table.insert(outline, { x = x, z = z })
            end
        end
    end
    return outline
end

local function distanceToSegment(px, pz, a, b)
    local dx, dz = b.x - a.x, b.z - a.z
    local lengthSq = dx * dx + dz * dz
    local t = lengthSq > 0 and math.max(0, math.min(1, ((px - a.x) * dx + (pz - a.z) * dz) / lengthSq)) or 0
    local cx, cz = a.x + t * dx - px, a.z + t * dz - pz
    return math.sqrt(cx * cx + cz * cz)
end

--- Random start spot inside the field with room to burn: returns x, z, maxRadius (or nil).
function TornadoHazards:pickFireStart(field)
    local outline = self:getFieldOutline(field)
    if #outline < 3 then
        return nil
    end
    local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
    for _, p in ipairs(outline) do
        minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
        minZ, maxZ = math.min(minZ, p.z), math.max(maxZ, p.z)
    end
    local spots = {}
    local steps = self.FLOOD_GRID_STEPS
    for i = 1, steps do
        for j = 1, steps do
            local x = minX + (maxX - minX) * (i - 0.5) / steps
            local z = minZ + (maxZ - minZ) * (j - 0.5) / steps
            if self:isInsideOutline(outline, x, z) then
                local room = math.huge
                local k = #outline
                for m = 1, #outline do
                    room = math.min(room, distanceToSegment(x, z, outline[m], outline[k]))
                    k = m
                end
                if room >= self.FIRE_MIN_RADIUS then
                    table.insert(spots, { x = x, z = z, room = room })
                end
            end
        end
    end
    if #spots == 0 then
        return nil
    end
    local spot = spots[math.random(1, #spots)]
    return spot.x, spot.z, math.min(self.FIRE_MAX_RADIUS, spot.room)
end

--- Sets a random ripe dry field on fire. Returns true when a fire started.
function TornadoHazards:startRandomFire()
    if g_fieldManager == nil or g_fieldManager.getFields == nil then
        return false
    end
    local candidates = {}
    for _, field in pairs(g_fieldManager:getFields()) do
        if self:canFieldBurn(field, false) then
            table.insert(candidates, field)
        end
    end
    while #candidates > 0 do
        local index = math.random(1, #candidates)
        if self:startFireOnField(candidates[index]) then
            return true
        end
        table.remove(candidates, index)
    end
    return false
end

--- Starts a fire on this field (no checks on weather). Returns true when it started.
function TornadoHazards:startFireOnField(field)
    if self.fire ~= nil then
        return false
    end
    local x, z, maxRadius = self:pickFireStart(field)
    if x == nil then
        return false
    end
    local fire = {
        id = self.nextFireId,
        field = field,
        fieldId = field:getId() or 0,
        farmId = getFieldOwner(field),
        x = x, z = z,
        radius = self.FIRE_START_RADIUS,
        maxRadius = maxRadius,
        speed = self.FIRE_SPREAD_MPS,
        burnTimer = 0,
        circle = DensityMapCircle ~= nil and DensityMapCircle.new() or nil,
    }
    self.nextFireId = (self.nextFireId % 60000) + 1
    self.fire = fire

    local data = self:getFireData(fire)
    if TornadoFieldFireFX ~= nil then
        TornadoFieldFireFX:start(data)
    end
    if TornadoSync ~= nil and TornadoSync.broadcast ~= nil and TornadoFieldFireEvent ~= nil then
        TornadoSync:broadcast(TornadoFieldFireEvent.new(TornadoFieldFireEvent.START, data))
    end
    self:sendMessage("tp_msg_field_fire", { TornadoText.str(tostring(fire.fieldId)) }, TornadoSync and TornadoSync.MSG_CRITICAL)
    if TornadoDebug then
        TornadoDebug:info("HAZARDS", string.format("Field fire on field %s at (%.0f, %.0f), can grow to %.0f m.",
            tostring(fire.fieldId), x, z, maxRadius))
    end
    return true
end

--- The network / visuals view of a fire (current radius, so joining players see it at its present size).
function TornadoHazards:getFireData(fire)
    return { id = fire.id, fieldId = fire.fieldId, x = fire.x, z = fire.z, radius = fire.radius,
        maxRadius = fire.maxRadius, speed = fire.speed }
end

--- Ends the fire: logs the burnt share for the insurance and tells everyone why it ended.
function TornadoHazards:stopFire(reason)
    local fire = self.fire
    if fire == nil then
        return
    end
    self.fire = nil
    local areaHa = fire.field ~= nil and fire.field.getAreaHa ~= nil and fire.field:getAreaHa() or 1
    local share = math.min(1, (math.pi * fire.radius * fire.radius) / (math.max(areaHa, 0.01) * 10000))
    self:logEvent(self.EVENT_FIRE, getDay(), fire.fieldId, fire.farmId, share)

    if TornadoFieldFireFX ~= nil then
        TornadoFieldFireFX:stop(fire.id)
    end
    if TornadoSync ~= nil and TornadoSync.broadcast ~= nil and TornadoFieldFireEvent ~= nil then
        TornadoSync:broadcast(TornadoFieldFireEvent.new(TornadoFieldFireEvent.STOP, { id = fire.id }))
    end
    local key = reason == "rain" and "tp_msg_fire_out_rain" or "tp_msg_fire_out"
    self:sendMessage(key, { TornadoText.str(tostring(fire.fieldId)) }, TornadoSync and TornadoSync.MSG_INFO)
    if TornadoDebug then
        TornadoDebug:info("HAZARDS", string.format("Field fire on field %s ended (%s): radius %.0f m, about %.0f %% of the field burnt.",
            tostring(fire.fieldId), tostring(reason), fire.radius, share * 100))
    end
end

--- Every frame on the server: grow the fire, burn the crop inside it, rain puts it out.
function TornadoHazards:update(dt)
    local fire = self.fire
    if fire == nil or not isServer() then
        return
    end
    if not self:isFireActive() then
        self:stopFire("off")
        return
    end
    local weather = getWeather()
    local rain = weather ~= nil and weather.getRainFallScale ~= nil and weather:getRainFallScale() or 0
    if (rain or 0) >= self.FIRE_RAIN_OUT then
        self:stopFire("rain")
        return
    end
    local timeScale = (g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.timeScale) or 1
    fire.radius = math.min(fire.maxRadius, fire.radius + fire.speed * dt / 1000 * timeScale)

    fire.burnTimer = fire.burnTimer + dt
    local burntOut = fire.radius >= fire.maxRadius
    if fire.burnTimer >= self.FIRE_BURN_INTERVAL_MS or burntOut then
        fire.burnTimer = 0
        if fire.circle ~= nil and self:canDestroyCrops() and FSDensityMapUtil ~= nil
            and FSDensityMapUtil.updateDisasterArea ~= nil then
            fire.circle:updateFromWorldPosition(fire.x, fire.z, fire.radius, 16)
            FSDensityMapUtil.updateDisasterArea(fire.circle, 0)
        end
    end
    if burntOut then
        self:stopFire("out")
    end
end

function TornadoHazards:logEvent(kind, day, fieldId, farmId, share)
    table.insert(self.events, { kind = kind, day = day, fieldId = fieldId or 0, farmId = farmId or 0, share = share or 0 })
    while #self.events > self.MAX_EVENTS do
        table.remove(self.events, 1)
    end
end

function TornadoHazards:sendMessage(key, params, kind, farmId)
    if TornadoSync ~= nil and TornadoSync.sendMessage ~= nil then
        TornadoSync:sendMessage(key, params, kind, farmId)
    end
end

-- =========================================================================
-- SAVEGAME (TornadoHazards.xml next to the other Tornado files)
-- =========================================================================

function TornadoHazards:getPath()
    if TornadoDestruction == nil or TornadoDestruction._resolveSavegamePath == nil then
        return nil
    end
    local dir = TornadoDestruction:_resolveSavegamePath()
    return dir ~= nil and (dir .. self.FILE) or nil
end

function TornadoHazards:loadState()
    local path = self:getPath()
    if path == nil or not fileExists(path) then
        return
    end
    local xmlId = loadXMLFile("TornadoHazards", path)
    if xmlId == nil or xmlId == 0 then
        return
    end
    self.water = getXMLFloat(xmlId, "TornadoHazards.drought#water") or self.water
    self.dryDays = getXMLInt(xmlId, "TornadoHazards.drought#dryDays") or 0
    self.droughtDay = getXMLInt(xmlId, "TornadoHazards.drought#day") or 0
    self.dryWarned = getXMLBool(xmlId, "TornadoHazards.drought#warned") == true
    self.floodHours = getXMLInt(xmlId, "TornadoHazards.flood#hours") or 0
    self.floodCooldownUntil = getXMLInt(xmlId, "TornadoHazards.flood#cooldownUntil") or 0
    local i = 0
    while true do
        local key = string.format("TornadoHazards.events.event(%d)", i)
        local kind = getXMLString(xmlId, key .. "#kind")
        if kind == nil then break end
        table.insert(self.events, {
            kind = kind,
            day = getXMLInt(xmlId, key .. "#day") or 0,
            fieldId = getXMLInt(xmlId, key .. "#field") or 0,
            farmId = getXMLInt(xmlId, key .. "#farm") or 0,
            share = getXMLFloat(xmlId, key .. "#share") or 0,
        })
        i = i + 1
    end
    delete(xmlId)
end

function TornadoHazards:save()
    if not isServer() then
        return
    end
    local path = self:getPath()
    if path == nil then
        return
    end
    local xmlId = createXMLFile("TornadoHazards", path, "TornadoHazards")
    if xmlId == nil or xmlId == 0 then
        return
    end
    setXMLFloat(xmlId, "TornadoHazards.drought#water", self.water or self.WATER_START)
    setXMLInt(xmlId, "TornadoHazards.drought#dryDays", self.dryDays or 0)
    setXMLInt(xmlId, "TornadoHazards.drought#day", self.droughtDay or 0)
    setXMLBool(xmlId, "TornadoHazards.drought#warned", self.dryWarned == true)
    setXMLInt(xmlId, "TornadoHazards.flood#hours", self.floodHours or 0)
    setXMLInt(xmlId, "TornadoHazards.flood#cooldownUntil", self.floodCooldownUntil or 0)
    for i, event in ipairs(self.events or {}) do
        local key = string.format("TornadoHazards.events.event(%d)", i - 1)
        setXMLString(xmlId, key .. "#kind", event.kind)
        setXMLInt(xmlId, key .. "#day", event.day)
        setXMLInt(xmlId, key .. "#field", event.fieldId)
        setXMLInt(xmlId, key .. "#farm", event.farmId)
        setXMLFloat(xmlId, key .. "#share", event.share)
    end
    saveXMLFile(xmlId)
    delete(xmlId)
end

-- =========================================================================
-- STATUS / DEV CONSOLE
-- =========================================================================

function TornadoHazards:getStatusText()
    if self:isHandledByRealisticWeather() then
        return "Hazards: OFF - FS25_RealisticWeather is installed and handles drought and floods."
    end
    local drought = self.droughtDay > 0 and string.format("day %d (share %.0f %%)", self.droughtDay, self:getDroughtShare() * 100) or "none"
    local flood = self.lastFlood ~= nil and string.format("day %d, %d fields", self.lastFlood.day, self.lastFlood.fields) or "none"
    local fire = self.fire ~= nil and string.format("field %s, radius %.0f / %.0f m", tostring(self.fire.fieldId), self.fire.radius,
        self.fire.maxRadius) or "none"
    return string.format("Hazards: Enabled = %s | Drought = %s | Flood = %s | Fire = %s | Owned fields only = %s | Soil water = %.0f %% | Dry days = %d | Drought now = %s | Heavy-rain hours = %d | Last flood = %s | Burning = %s | Intensity = x%.2f | Frequency = x%.2f | Crop damage = %s | Events logged = %d",
        tostring(self.isEnabled), tostring(self.droughtEnabled), tostring(self.floodEnabled), tostring(self.fireEnabled),
        tostring(self.ownedOnly), (self.water or 0) * 100, self.dryDays or 0, drought, self.floodHours or 0, flood, fire,
        self.intensity, self.frequency,
        self:canDestroyCrops() and "on" or "off (game disaster setting)", #(self.events or {}))
end

--- t_dev hazards <water <0-100> | drought | damage | end | flood | fire [field] | fireout | log | status>
function TornadoHazards:consoleCommand(sub, value)
    if not isServer() then
        return "Hazards: dev commands run on the host / server only."
    end
    if sub == "water" then
        local percent = tonumber(value)
        if percent == nil then return "Usage: t_dev hazards water <0-100>" end
        self.water = math.max(0, math.min(1, percent / 100))
        return string.format("Hazards: soil water set to %.0f %%.", self.water * 100)
    elseif sub == "drought" then
        self.water = math.min(self.water, self.DROUGHT_LEVEL * 0.5)
        self.dryDays = self.DROUGHT_DAYS
        if self.droughtDay == 0 then
            self:startDrought()
        end
        return "Hazards: drought forced. " .. self:getStatusText()
    elseif sub == "damage" then
        if self.droughtDay == 0 then
            self.droughtDay = 1
        else
            self.droughtDay = self.droughtDay + 1
        end
        local fields = self:applyDroughtDamage()
        return string.format("Hazards: drought day %d applied to %d growing fields (share %.0f %%).", self.droughtDay, fields,
            self:getDroughtShare() * 100)
    elseif sub == "end" then
        self.water = self.WATER_START
        if self.droughtDay > 0 then
            self:endDrought()
        end
        return "Hazards: drought ended, soil water reset."
    elseif sub == "flood" then
        self.water = math.max(self.water, self.FLOOD_SOAKED)
        local fields = self:triggerFlood()
        return string.format("Hazards: flood forced - %d low-lying growing fields hit.", fields)
    elseif sub == "fire" then
        if self.fire ~= nil then
            return "Hazards: a fire is already burning on field " .. tostring(self.fire.fieldId) .. "."
        end
        local wanted = tonumber(value)
        if g_fieldManager ~= nil then
            local candidates = {}
            for _, field in pairs(g_fieldManager:getFields()) do
                if (wanted == nil or field:getId() == wanted) and self:canFieldBurn(field, true) then
                    table.insert(candidates, field)
                end
            end
            while #candidates > 0 do
                local index = math.random(1, #candidates)
                if self:startFireOnField(candidates[index]) then
                    return string.format("Hazards: fire started on field %s.", tostring(self.fire.fieldId))
                end
                table.remove(candidates, index)
            end
        end
        return "Hazards: no field found that can burn" .. (wanted ~= nil and (" (field " .. tostring(wanted) .. ")") or "") ..
            " - it needs a growing grain-type crop and room inside the field."
    elseif sub == "fireout" then
        if self.fire == nil then return "Hazards: no fire burning." end
        self:stopFire("rain")
        return "Hazards: fire put out."
    elseif sub == "log" then
        print("---------------- HAZARD EVENTS (last 20) ----------------")
        local first = math.max(1, #self.events - 19)
        for i = first, #self.events do
            local e = self.events[i]
            print(string.format("  day %d  %-8s field %3d  farm %d  share %.0f %%", e.day, e.kind, e.fieldId, e.farmId, e.share * 100))
        end
        print("---------------------------------------------------------")
        return string.format("Hazards: %d events logged.", #self.events)
    end
    return self:getStatusText()
end
