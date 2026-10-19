---@class TornadoInsuranceDamage
---@version 1.0 (insurance phase 1)
---@description Storm damage report: which fields lose crop, how much, and to what (docs/INSURANCE_DESIGN.md §4.1,
--- §18 phase 1). Works with the insurance OFF too - it is the claims source of the crop insurance.
---
--- Every crop destruction in the game goes through FSDensityMapUtil.updateDisasterArea(area, perlin): the twister
--- (DensityMapNodePolygon along its path), hail (DensityMapCircle spots) and our own hazards (drought: the whole
--- field polygon, flood / fire: circles). The function is wrapped once (server); each call is measured as a
--- geometry estimate (decided 2026-10-16, no density-map reads):
---   * the area's outline is laid over a 2 m grid per field it touches (cell centres inside area and field);
---   * a cell's destroyed share is 1 - perlin / 10000 (the same rule the hazards are calibrated with);
---   * each field remembers the destroyed share per cell (and a field-wide share for whole-field calls such as
---     drought) for its current crop, so repeated hits (the twister re-applies its areas every frame, drought
---     raises its share every day) only count what is new; the memory resets when the crop changes or is resown;
---   * only fields with a crop in its destroyable growth states count.
--- Hits are grouped into one event per cause and field; an event closes after a quiet time and is written to the
--- damage log { id, cause, day, fieldId, farmId, crop, share }. Tornado / hail events also send each owning farm a
--- report (drought, flood and fire already have their own messages).
--- Cause: our hazards name it (setCause); otherwise a node polygon is the twister, anything else is hail.

TornadoInsuranceDamage = {}

TornadoInsuranceDamage.FILE = "TornadoDamage.xml"
TornadoInsuranceDamage.CELL_SIZE = 2                -- metres (4 m measured a 20 m hail spot ~11 % low)
TornadoInsuranceDamage.MAX_LOG = 500
TornadoInsuranceDamage.MIN_REPORT_SHARE = 0.01      -- events below 1 % of a field are logged quietly, not reported
                                                    -- (game hail leaves 0.1 - 0.6 % specks everywhere)
TornadoInsuranceDamage.MAX_SAMPLES = 40000          -- per call (200 x 200 m at 2 m) - safety cap
TornadoInsuranceDamage.PERLIN_FULL = 10000

TornadoInsuranceDamage.CAUSE_TORNADO = "TORNADO"
TornadoInsuranceDamage.CAUSE_HAIL = "HAIL"
TornadoInsuranceDamage.CAUSE_DROUGHT = "DROUGHT"
TornadoInsuranceDamage.CAUSE_FLOOD = "FLOOD"
TornadoInsuranceDamage.CAUSE_FIRE = "FIRE"

-- Quiet time (game minutes) after which an event is closed, per cause.
-- Tornado: one report per storm - its events stay open while it is on the map and close when it leaves the map,
-- despawns or respawns (onTornadoEnded); the 60 minutes are only a fallback.
TornadoInsuranceDamage.QUIET_MINUTES = { TORNADO = 60, HAIL = 30, DROUGHT = 5, FLOOD = 5, FIRE = 10 }
TornadoInsuranceDamage.REPORTED_CAUSES = { TORNADO = true, HAIL = true }
TornadoInsuranceDamage.CAUSE_KEYS = { TORNADO = "tp_cause_tornado", HAIL = "tp_cause_hail", DROUGHT = "tp_cause_drought",
    FLOOD = "tp_cause_flood", FIRE = "tp_cause_fire" }

local MS_PER_MINUTE = 60 * 1000
local MS_PER_DAY = 24 * 60 * MS_PER_MINUTE

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

local function getEnvironment()
    return g_currentMission ~= nil and g_currentMission.environment or nil
end

local function getDay()
    local environment = getEnvironment()
    return environment ~= nil and environment.currentMonotonicDay or 0
end

local function getAbsoluteMs()
    local environment = getEnvironment()
    if environment == nil then
        return 0
    end
    return (environment.currentMonotonicDay or 0) * MS_PER_DAY + (environment.dayTime or 0)
end

function TornadoInsuranceDamage:loadMap()
    self.fieldGeometry = {}  -- fieldId -> { outline, minX, minZ, maxX, maxZ, numCells } (fields do not move)
    self.memory = {}         -- fieldId -> { fruit, growth, cells = { key -> p }, sumCells, uniform }
    self.events = {}         -- open events: "CAUSE|fieldId" -> { cause, fieldId, farmId, crop, share, lastMs, startDay }
    self.log = {}            -- closed events
    self.nextId = 1
    self.cause = nil         -- cause named by our hazards for the calls in progress
    self.causeField = nil
    if isServer() then
        self:installHook()
        self:loadState()
        if g_messageCenter ~= nil then
            g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
        end
    end
end

function TornadoInsuranceDamage:deleteMap()
    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end
    self.fieldGeometry = {}
    self.memory = {}
    self.events = {}
end

--- Wraps FSDensityMapUtil.updateDisasterArea once (it survives savegame reloads - guard flag on the table).
function TornadoInsuranceDamage:installHook()
    if FSDensityMapUtil == nil or FSDensityMapUtil.updateDisasterArea == nil or FSDensityMapUtil.tornadoDamageHooked then
        return
    end
    FSDensityMapUtil.tornadoDamageHooked = true
    local original = FSDensityMapUtil.updateDisasterArea
    FSDensityMapUtil.updateDisasterArea = function(densityMapArea, perlinPercentage, ...)
        local result = original(densityMapArea, perlinPercentage, ...)
        if TornadoInsuranceDamage ~= nil and TornadoInsuranceDamage.onDisasterArea ~= nil then
            TornadoInsuranceDamage:onDisasterArea(densityMapArea, perlinPercentage)
        end
        return result
    end
end

--- Our hazards name the cause of their calls: setCause(cause) ... setCause(nil). wholeField = the field when the
--- call covers that whole field (drought): measured without sampling.
function TornadoInsuranceDamage:setCause(cause, wholeField)
    self.cause = cause
    self.causeField = wholeField
end

-- =========================================================================
-- GEOMETRY
-- =========================================================================

--- Point-in-polygon (even-odd) on x / z. polygon = { x1, z1, x2, z2, ... }
local function isInside(polygon, x, z)
    local inside = false
    local n = #polygon / 2
    local j = n
    for i = 1, n do
        local xi, zi = polygon[i * 2 - 1], polygon[i * 2]
        local xj, zj = polygon[j * 2 - 1], polygon[j * 2]
        if ((zi > z) ~= (zj > z)) and (x < (xj - xi) * (z - zi) / (zj - zi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end
TornadoInsuranceDamage.isInside = isInside

--- Outline and bounding box of a field (cached). nil when the field has no outline.
function TornadoInsuranceDamage:getFieldGeometry(field)
    local fieldId = field:getId()
    local geometry = self.fieldGeometry[fieldId]
    if geometry ~= nil then
        return geometry or nil
    end
    local outline = {}
    local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
    for _, node in ipairs(field.getPolygonPoints ~= nil and field:getPolygonPoints() or {}) do
        if node ~= nil and node ~= 0 then
            local x, _, z = getWorldTranslation(node)
            if x ~= nil then
                table.insert(outline, x)
                table.insert(outline, z)
                minX, maxX = math.min(minX, x), math.max(maxX, x)
                minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
            end
        end
    end
    if #outline < 6 then
        self.fieldGeometry[fieldId] = false
        return nil
    end
    local areaM2 = (field.getAreaHa ~= nil and field:getAreaHa() or 0) * 10000
    geometry = { outline = outline, minX = minX, minZ = minZ, maxX = maxX, maxZ = maxZ,
        numCells = math.max(1, areaM2 / (self.CELL_SIZE * self.CELL_SIZE)) }
    self.fieldGeometry[fieldId] = geometry
    return geometry
end

--- The area's outline on x / z: { x1, z1, ... } and its bounding box.
local function getAreaPolygon(area)
    if area == nil or area.getVerticesAs3DCoordinates == nil then
        return nil
    end
    local vertices = area:getVerticesAs3DCoordinates(0)
    if vertices == nil or #vertices < 9 then
        return nil
    end
    local polygon = {}
    local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
    for i = 1, #vertices, 3 do
        local x, z = vertices[i], vertices[i + 2]
        table.insert(polygon, x)
        table.insert(polygon, z)
        minX, maxX = math.min(minX, x), math.max(maxX, x)
        minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
    end
    return polygon, minX, minZ, maxX, maxZ
end

-- =========================================================================
-- CROP STATE
-- =========================================================================

--- Fill type name of a crop that the disaster function can destroy now (growth state in its destroyable
--- range), plus the fruit index and growth state. nil when nothing destroyable grows on the field.
function TornadoInsuranceDamage:getDestroyableCrop(field)
    local state = field.getFieldState ~= nil and field:getFieldState() or nil
    if state == nil or not state.isValid or state.fruitTypeIndex == nil or FruitType == nil
        or state.fruitTypeIndex == FruitType.UNKNOWN or g_fruitTypeManager == nil then
        return nil
    end
    local fruitType = g_fruitTypeManager:getFruitTypeByIndex(state.fruitTypeIndex)
    if fruitType == nil or fruitType.minDisasterDestructionState == nil then
        return nil
    end
    local growth = state.growthState or 0
    if growth < fruitType.minDisasterDestructionState or growth > (fruitType.maxDisasterDestructionState or growth) then
        return nil
    end
    local name = g_fruitTypeManager.getFillTypeNameByFruitTypeIndex ~= nil
        and g_fruitTypeManager:getFillTypeNameByFruitTypeIndex(state.fruitTypeIndex) or fruitType.name
    return name, state.fruitTypeIndex, growth
end

--- Per-field memory of what is already destroyed; reset for a new crop (other fruit, or resown = growth went down).
function TornadoInsuranceDamage:getMemory(fieldId, fruit, growth)
    local memory = self.memory[fieldId]
    if memory == nil or memory.fruit ~= fruit or growth < memory.growth then
        memory = { fruit = fruit, growth = growth, cells = {}, sumCells = 0, uniform = 0 }
        self.memory[fieldId] = memory
    end
    memory.growth = growth
    return memory
end

-- =========================================================================
-- MEASURING
-- =========================================================================

--- Damage another mod paints itself (not through updateDisasterArea), e.g. Moisture System withering
--- (TornadoMoisture). area: anything with getVerticesAs3DCoordinates(); share = destroyed share inside it (0 - 1).
function TornadoInsuranceDamage:recordArea(area, share, cause)
    local previousCause, previousField = self.cause, self.causeField
    self.cause, self.causeField = cause, nil
    self:onDisasterArea(area, math.floor((1 - math.max(0, math.min(1, share or 1))) * self.PERLIN_FULL + 0.5))
    self.cause, self.causeField = previousCause, previousField
end

--- Called after every updateDisasterArea (server).
function TornadoInsuranceDamage:onDisasterArea(area, perlinPercentage)
    if not isServer() or g_fieldManager == nil then
        return
    end
    local p = 1 - math.max(0, math.min(self.PERLIN_FULL, tonumber(perlinPercentage) or self.PERLIN_FULL)) / self.PERLIN_FULL
    if p <= 0 then
        return
    end
    local cause = self.cause
    if cause == nil then
        cause = area ~= nil and area.nodes ~= nil and self.CAUSE_TORNADO or self.CAUSE_HAIL
    end

    -- Whole-field call (drought): the field's own polygon - no sampling needed.
    if self.causeField ~= nil then
        self:addUniform(self.causeField, p, cause)
        return
    end

    local polygon, minX, minZ, maxX, maxZ = getAreaPolygon(area)
    if polygon == nil then
        return
    end
    for _, field in pairs(g_fieldManager:getFields()) do
        local geometry = self:getFieldGeometry(field)
        if geometry ~= nil and geometry.maxX >= minX and geometry.minX <= maxX and geometry.maxZ >= minZ and geometry.minZ <= maxZ then
            self:addArea(field, geometry, polygon, math.max(minX, geometry.minX), math.max(minZ, geometry.minZ),
                math.min(maxX, geometry.maxX), math.min(maxZ, geometry.maxZ), p, cause)
        end
    end
end

--- Cells of the field inside the area (cell centres on the field's own 2 m grid).
--- Fields nobody owns are not measured: nobody insures them, and the game's hail touches dozens of them per tick.
local function isOwned(field)
    local farmId = field.getOwner ~= nil and field:getOwner() or 0
    return farmId ~= nil and farmId ~= 0 and (FarmlandManager == nil or farmId ~= FarmlandManager.NO_OWNER_FARM_ID)
end

function TornadoInsuranceDamage:addArea(field, geometry, polygon, x0, z0, x1, z1, p, cause)
    if not isOwned(field) then
        return
    end
    local crop, fruit, growth = self:getDestroyableCrop(field)
    if crop == nil then
        return
    end
    local size = self.CELL_SIZE
    local i0 = math.floor((x0 - geometry.minX) / size)
    local i1 = math.floor((x1 - geometry.minX) / size)
    local k0 = math.floor((z0 - geometry.minZ) / size)
    local k1 = math.floor((z1 - geometry.minZ) / size)
    if (i1 - i0 + 1) * (k1 - k0 + 1) > self.MAX_SAMPLES then
        return
    end
    local memory = self:getMemory(field:getId(), fruit, growth)
    local gained = 0
    for i = i0, i1 do
        local x = geometry.minX + (i + 0.5) * size
        for k = k0, k1 do
            local z = geometry.minZ + (k + 0.5) * size
            if isInside(polygon, x, z) and isInside(geometry.outline, x, z) then
                local key = i * 100000 + k
                local old = memory.cells[key] or 0
                if p > old then
                    -- effective share of a cell = 1 - (1 - uniform) (1 - cell)
                    gained = gained + (p - old) * (1 - memory.uniform)
                    memory.cells[key] = p
                    memory.sumCells = memory.sumCells + (p - old)
                end
            end
        end
    end
    if gained > 0 then
        self:addToEvent(field, crop, cause, gained / geometry.numCells)
    end
end

--- Field-wide share (drought): only the rise over what the field already lost counts.
function TornadoInsuranceDamage:addUniform(field, p, cause)
    if not isOwned(field) then
        return
    end
    local crop, fruit, growth = self:getDestroyableCrop(field)
    if crop == nil then
        return
    end
    local geometry = self:getFieldGeometry(field)
    local numCells = geometry ~= nil and geometry.numCells or 1
    local memory = self:getMemory(field:getId(), fruit, growth)
    if p <= memory.uniform then
        return
    end
    local cellShare = math.min(1, memory.sumCells / numCells)
    local gained = (p - memory.uniform) * (1 - cellShare)
    memory.uniform = p
    if gained > 0 then
        self:addToEvent(field, crop, cause, gained)
    end
end

function TornadoInsuranceDamage:addToEvent(field, crop, cause, share)
    local fieldId = field:getId()
    local key = cause .. "|" .. tostring(fieldId)
    local event = self.events[key]
    if event == nil then
        local farmId = field.getOwner ~= nil and field:getOwner() or 0
        event = { cause = cause, fieldId = fieldId, farmId = farmId or 0, crop = crop, share = 0, startDay = getDay(),
            areaHa = field.getAreaHa ~= nil and field:getAreaHa() or 0 }
        self.events[key] = event
    end
    event.share = math.min(1, event.share + share)
    event.lastMs = getAbsoluteMs()
end

-- =========================================================================
-- CLOSING EVENTS + REPORT
-- =========================================================================

function TornadoInsuranceDamage:onMinuteChanged()
    if next(self.events) == nil then
        return
    end
    if self:hasOpenCause(self.CAUSE_TORNADO) and not self:isTornadoOnMap() then
        self:onTornadoEnded()
    end
    self:closeEvents(false)
end

function TornadoInsuranceDamage:hasOpenCause(cause)
    for _, event in pairs(self.events) do
        if event.cause == cause then
            return true
        end
    end
    return false
end

--- Is a tornado still on the playable map? Gone, or its centre at the mod's own boundary line (TornadoPhysics
--- map boundary minus the geo-fence - the line border safety uses) = the storm is over for every field. The game
--- moves a tornado on far past the edge and despawns it much later (in-game test: 36 real minutes).
function TornadoInsuranceDamage:isTornadoOnMap()
    local node = TornadoPhysics ~= nil and TornadoPhysics.tornadoNode or nil
    if node == nil or node == 0 or not entityExists(node) then
        return false
    end
    local boundary = TornadoPhysics.mapBoundary
    if boundary == nil and g_currentMission ~= nil and g_currentMission.terrainSize ~= nil then
        boundary = g_currentMission.terrainSize * 0.5
    end
    if boundary == nil then
        return true
    end
    local fence = TornadoPhysics.settings ~= nil and tonumber(TornadoPhysics.settings.geo_fence) or 0
    local limit = boundary - math.max(0, fence)
    local x, _, z = getWorldTranslation(node)
    return math.abs(x) < limit and math.abs(z) < limit
end

--- The tornado is over (despawned, or a new one spawned on the twister): report its damage now instead of
--- waiting for the quiet time.
function TornadoInsuranceDamage:onTornadoEnded()
    -- Equipment claims for the vehicles the storm damaged.
    if isServer() and TornadoInsuranceEquipment ~= nil and TornadoInsuranceEquipment.onStormEnded ~= nil then
        TornadoInsuranceEquipment:onStormEnded()
    end
    if isServer() and self.events ~= nil and next(self.events) ~= nil then
        self:closeEvents(true, self.CAUSE_TORNADO)
    end
end

--- Closes quiet events (or all of them - of one cause when given - e.g. before saving) and reports them.
function TornadoInsuranceDamage:closeEvents(all, onlyCause)
    local now = getAbsoluteMs()
    local closed = {}
    for key, event in pairs(self.events) do
        local quiet = (self.QUIET_MINUTES[event.cause] or 10) * MS_PER_MINUTE
        local closeNow = all and (onlyCause == nil or event.cause == onlyCause)
        if closeNow or now - (event.lastMs or now) >= quiet then
            self.events[key] = nil
            table.insert(closed, event)
        end
    end
    if #closed == 0 then
        return
    end
    table.sort(closed, function(a, b)
        if a.fieldId ~= b.fieldId then
            return a.fieldId < b.fieldId
        end
        return a.cause < b.cause
    end)
    local reports = {}   -- "farm|cause" -> { farmId, cause, fields, ha, worstField, worstShare }
    for _, event in ipairs(closed) do
        local entry = { id = self.nextId, cause = event.cause, day = event.startDay, fieldId = event.fieldId,
            farmId = event.farmId, crop = event.crop, share = event.share }
        self.nextId = self.nextId + 1
        table.insert(self.log, entry)
        if TornadoInsurance ~= nil and TornadoInsurance.onDamageLogged ~= nil then
            TornadoInsurance:onDamageLogged(entry)   -- crop insurance claims
        end
        if TornadoDebug then
            TornadoDebug:info("DAMAGE", string.format("%s: field %d (farm %d, %s) lost %.1f %% of its crop.", event.cause,
                event.fieldId, event.farmId, tostring(event.crop), event.share * 100))
        end
        if self.REPORTED_CAUSES[event.cause] and event.farmId ~= 0 and event.share >= self.MIN_REPORT_SHARE then
            local reportKey = event.farmId .. "|" .. event.cause
            local report = reports[reportKey]
            if report == nil then
                report = { farmId = event.farmId, cause = event.cause, fields = 0, ha = 0, worstField = 0, worstShare = 0 }
                reports[reportKey] = report
            end
            report.fields = report.fields + 1
            report.ha = report.ha + event.share * (event.areaHa or 0)
            if event.share > report.worstShare then
                report.worstField, report.worstShare = event.fieldId, event.share
            end
        end
    end
    while #self.log > self.MAX_LOG do
        table.remove(self.log, 1)
    end
    for _, report in pairs(reports) do
        self:sendReport(report)
    end
end

function TornadoInsuranceDamage:sendReport(report)
    if TornadoSync == nil or TornadoSync.sendMessage == nil or TornadoText == nil then
        return
    end
    if TornadoDebug then
        TornadoDebug:info("DAMAGE", string.format("Report to farm %d: %s, %d fields, %.2f ha lost, worst field %d (%.0f %%).",
            report.farmId, report.cause, report.fields, report.ha, report.worstField, report.worstShare * 100))
    end
    TornadoSync:sendMessage("tp_msg_damage_report", {
        TornadoText.key(self.CAUSE_KEYS[report.cause] or report.cause),
        TornadoText.num(report.fields),
        TornadoText.num(report.ha),
        TornadoText.num(report.worstField),
        TornadoText.num(math.floor(report.worstShare * 100 + 0.5)),
    }, TornadoSync.MSG_INFO, report.farmId)
end

--- Closed log entries of a farm (all farms when farmId is nil), newest last.
function TornadoInsuranceDamage:getLog(farmId)
    if farmId == nil then
        return self.log
    end
    local entries = {}
    for _, entry in ipairs(self.log) do
        if entry.farmId == farmId then
            table.insert(entries, entry)
        end
    end
    return entries
end

-- =========================================================================
-- SAVEGAME (TornadoDamage.xml) - the closed log; open events are closed first. The per-cell memory is not
-- saved: a tornado crossing the same crop again after a reload counts that crop's cells once more.
-- =========================================================================

function TornadoInsuranceDamage:getPath()
    if TornadoDestruction == nil or TornadoDestruction._resolveSavegamePath == nil then
        return nil
    end
    local dir = TornadoDestruction:_resolveSavegamePath()
    return dir ~= nil and (dir .. self.FILE) or nil
end

function TornadoInsuranceDamage:loadState()
    local path = self:getPath()
    if path == nil or not fileExists(path) then
        return
    end
    local xmlId = loadXMLFile("TornadoDamage", path)
    if xmlId == nil or xmlId == 0 then
        return
    end
    self.nextId = getXMLInt(xmlId, "TornadoDamage#nextId") or 1
    local i = 0
    while true do
        local key = string.format("TornadoDamage.log.event(%d)", i)
        local cause = getXMLString(xmlId, key .. "#cause")
        if cause == nil then break end
        local id = getXMLInt(xmlId, key .. "#id") or 0
        table.insert(self.log, { id = id, cause = cause, day = getXMLInt(xmlId, key .. "#day") or 0,
            fieldId = getXMLInt(xmlId, key .. "#field") or 0, farmId = getXMLInt(xmlId, key .. "#farm") or 0,
            crop = getXMLString(xmlId, key .. "#crop"), share = getXMLFloat(xmlId, key .. "#share") or 0 })
        self.nextId = math.max(self.nextId, id + 1)
        i = i + 1
    end
    delete(xmlId)
end

function TornadoInsuranceDamage:save()
    if not isServer() then
        return
    end
    self:closeEvents(true)
    local path = self:getPath()
    if path == nil then
        return
    end
    local xmlId = createXMLFile("TornadoDamage", path, "TornadoDamage")
    if xmlId == nil or xmlId == 0 then
        return
    end
    setXMLInt(xmlId, "TornadoDamage#version", 1)
    setXMLInt(xmlId, "TornadoDamage#nextId", self.nextId or 1)
    for i, entry in ipairs(self.log or {}) do
        local key = string.format("TornadoDamage.log.event(%d)", i - 1)
        setXMLInt(xmlId, key .. "#id", entry.id)
        setXMLString(xmlId, key .. "#cause", entry.cause)
        setXMLInt(xmlId, key .. "#day", entry.day)
        setXMLInt(xmlId, key .. "#field", entry.fieldId)
        setXMLInt(xmlId, key .. "#farm", entry.farmId)
        setXMLString(xmlId, key .. "#crop", entry.crop or "")
        setXMLFloat(xmlId, key .. "#share", entry.share)
    end
    saveXMLFile(xmlId)
    delete(xmlId)
end

-- =========================================================================
-- CONSOLE
-- =========================================================================

--- t_dev insurance damage [farm]  - the last 20 damage log entries (+ open events)
function TornadoInsuranceDamage:printLog(farmId)
    local entries = self:getLog(farmId)
    print("---------------- STORM DAMAGE LOG (last 20) ----------------")
    for i = math.max(1, #entries - 19), #entries do
        local e = entries[i]
        print(string.format("  #%d day %d  %-8s field %3d  farm %d  %-12s %5.1f %%", e.id, e.day, e.cause, e.fieldId, e.farmId,
            tostring(e.crop), e.share * 100))
    end
    local open = 0
    for _, event in pairs(self.events) do
        open = open + 1
        print(string.format("  (open) %-8s field %3d  farm %d  %-12s %5.1f %% so far", event.cause, event.fieldId, event.farmId,
            tostring(event.crop), event.share * 100))
    end
    print("------------------------------------------------------------")
    return string.format("Damage: %d logged events, %d open.", #entries, open)
end

--- t_dev insurance hit <field | here> [radius] [perlin]  - real disaster call on a circle at the field centre, or
--- where the player stands ("here": several sizes on one big field, e.g. to find the size the game still handles).
function TornadoInsuranceDamage:testHit(fieldId, radius, perlin)
    if not isServer() then
        return "Damage: run on the host / server."
    end
    if fieldId == "here" then
        if g_localPlayer == nil or g_localPlayer.getPosition == nil or DensityMapCircle == nil then
            return "Damage: needs a player in the world."
        end
        local px, _, pz = g_localPlayer:getPosition()
        local r = tonumber(radius) or 20
        local hereCircle = DensityMapCircle.new()
        hereCircle:updateFromWorldPosition(px, pz, r, 16)
        self:setCause(self.CAUSE_TORNADO, nil)
        FSDensityMapUtil.updateDisasterArea(hereCircle, tonumber(perlin) or 2500)
        self:setCause(nil, nil)
        return string.format("Damage: test hit at your position (%.0f, %.0f), %.0f m radius = %.0f m across, perlin %d - look at the crop; the report follows %s.",
            px, pz, r, r * 2, tonumber(perlin) or 2500, self:isTornadoOnMap() and "when the tornado ends" or "within a game minute")
    end
    local field = g_fieldManager ~= nil and g_fieldManager:getFieldById(tonumber(fieldId) or -1) or nil
    if field == nil or DensityMapCircle == nil then
        return "Usage: t_dev insurance hit <field number | here> [radius m, default 20] [perlin 0-10000, default 2500]"
    end
    local x, z = field:getCenterOfFieldWorldPosition()
    local circle = DensityMapCircle.new()
    circle:updateFromWorldPosition(x, z, tonumber(radius) or 20, 16)
    self:setCause(self.CAUSE_TORNADO, nil)
    FSDensityMapUtil.updateDisasterArea(circle, tonumber(perlin) or 2500)
    self:setCause(nil, nil)
    local crop = self:getDestroyableCrop(field)
    -- No tornado on the map: the event closes at the next game minute (onMinuteChanged), else when the tornado ends.
    return string.format("Damage: test hit on field %d (%s) - the report follows %s; t_dev insurance damage shows it now.",
        field:getId(), crop or "no destroyable crop", self:isTornadoOnMap() and "when the tornado ends" or "within a game minute")
end
