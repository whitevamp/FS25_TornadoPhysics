-- Offline test for scripts/TornadoHazards.lua (drought, phase 1) - Lua 5.1, outside the game.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_hazards.lua
-- Stubs the weather, fields, fruit types, message center, disaster function, messages and XML save / load.
-- Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- stubs
local files = {}                      -- fake file system for the savegame XML: path -> { key -> value }
local xmlHandles, nextHandle = {}, 1
function createXMLFile(_, path) local h = nextHandle nextHandle = nextHandle + 1 xmlHandles[h] = { path = path, data = {} } return h end
function loadXMLFile(_, path)
    if files[path] == nil then return 0 end
    local h = nextHandle nextHandle = nextHandle + 1
    xmlHandles[h] = { path = path, data = files[path] }
    return h
end
local function setter(h, key, value) xmlHandles[h].data[key] = value end
setXMLFloat, setXMLInt, setXMLBool, setXMLString = setter, setter, setter, setter
local function getter(h, key) return xmlHandles[h].data[key] end
getXMLFloat, getXMLInt, getXMLBool, getXMLString = getter, getter, getter, getter
function saveXMLFile(h) files[xmlHandles[h].path] = xmlHandles[h].data end
function delete(h) xmlHandles[h] = nil end
function fileExists(path) return files[path] ~= nil end

FruitType = { UNKNOWN = 0 }
DisasterDestructionState = { ENABLED = 1, VISUALS_ONLY = 2, DISABLED = 3 }
MessageType = { HOUR_CHANGED = 1, DAY_CHANGED = 2 }
local subscriptions = {}
g_messageCenter = {
    subscribe = function(_, kind, fn, target) subscriptions[kind] = { fn = fn, target = target } end,
    unsubscribeAll = function() subscriptions = {} end,
}
g_modIsLoaded = {}

local weather = { rain = 0, snow = 0, temp = 25, maxTemp = 28 }
function weather:getRainFallScale() return self.rain end
function weather:getSnowFallScale() return self.snow end
function weather:getCurrentTemperature() return self.temp end
function weather:getCurrentMinMaxTemperatures() return self.temp - 8, self.maxTemp end

g_currentMission = {
    getIsServer = function() return true end,
    environment = { weather = weather, currentMonotonicDay = 1, currentHour = 12 },
    missionInfo = { disasterDestructionState = DisasterDestructionState.ENABLED, timeScale = 1 },
}

local fruitNames = { [1] = "WHEAT", [2] = "RICE", [3] = "GRASS", [4] = "CANOLA" }
g_fruitTypeManager = { getFruitTypeByIndex = function(_, i)
    return fruitNames[i] and { name = fruitNames[i], minHarvestingGrowthState = 4, maxHarvestingGrowthState = 5 } or nil
end }
-- Terrain: every field sits at its own height (field id * 10 m, field 1 lowest) - see fieldHeights below.
local fieldHeights = {}
g_terrainNode = 1
function getTerrainHeightAtWorldPos(_, x, _, z) return fieldHeights[x] or 100 end
function getWorldTranslation(node) return node.x, 0, node.z end
FarmlandManager = { NO_OWNER_FARM_ID = 0 }
local circles = {}
DensityMapCircle = { new = function()
    local c = {}
    function c:updateFromWorldPosition(x, z, radius) self.x, self.z, self.radius = x, z, radius table.insert(circles, { x = x, radius = radius }) end
    return c
end }

local function makeField(id, fruit, growth, owner)
    local state = { isValid = true, fruitTypeIndex = fruit, growthState = growth }
    fieldHeights[id] = id * 10      -- field centre x = id, so its height is id * 10
    return {
        getId = function() return id end,
        getFieldState = function() return state end,
        getDensityMapPolygon = function() return { fieldId = id } end,
        getOwner = function() return owner end,
        getCenterOfFieldWorldPosition = function() return id, 0 end,
        getPolygonPoints = function() return {} end,
        getAreaHa = function() return 4 end,
        setFruit = function(f, g) state.fruitTypeIndex, state.growthState = f, g end,
    }
end
local fields = {
    makeField(1, 1, 3, 1),   -- wheat, growing, farm 1
    makeField(2, 2, 3, 1),   -- rice, growing -> spared
    makeField(3, 3, 2, 2),   -- grass, farm 2 -> half damage
    makeField(4, 4, 0, 1),   -- canola, not growing (growth 0) -> skipped
    makeField(5, 0, 0, 0),   -- empty field
    makeField(6, 1, 5, 0),   -- wheat, nobody owns it -> damaged, no message
}
g_fieldManager = { getFields = function() return fields end }

local disasterCalls = {}
FSDensityMapUtil = { updateDisasterArea = function(polygon, perlin) table.insert(disasterCalls, { field = polygon.fieldId, perlin = perlin }) end }

local messages = {}
local broadcasts = {}
TornadoSync = {
    MSG_BLINKING = 1, MSG_CRITICAL = 2, MSG_INFO = 3,
    sendMessage = function(_, key, params, kind, farmId) table.insert(messages, { key = key, farmId = farmId, params = params }) end,
    broadcast = function(_, event) table.insert(broadcasts, event) end,
}
TornadoText = { num = function(v) return v end, str = function(v) return v end }
local fxCalls = {}
TornadoFieldFireFX = {
    start = function(_, data) table.insert(fxCalls, { kind = "start", data = data }) end,
    stop = function(_, id) table.insert(fxCalls, { kind = "stop", id = id }) end,
}
TornadoFieldFireEvent = { START = 1, STOP = 2, new = function(kind, data) return { kind = kind, data = data } end }
TornadoDestruction = { _resolveSavegamePath = function() return "savegame1/" end }

dofile("scripts/TornadoHazards.lua")

-- ---------------------------------------------------------------- helpers
local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "function" then ok = want(got) end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-60s got %s", label, tostring(got)))
    else
        print(string.format("ok    %-60s %s", label, tostring(got)))
    end
end
local function hours(n) for _ = 1, n do subscriptions[MessageType.HOUR_CHANGED].fn(subscriptions[MessageType.HOUR_CHANGED].target) end end
local function day()
    g_currentMission.environment.currentMonotonicDay = g_currentMission.environment.currentMonotonicDay + 1
    subscriptions[MessageType.DAY_CHANGED].fn(subscriptions[MessageType.DAY_CHANGED].target)
end
local function countMessages(key, farmId)
    local n = 0
    for _, m in ipairs(messages) do if m.key == key and (farmId == nil or m.farmId == farmId) then n = n + 1 end end
    return n
end

-- ---------------------------------------------------------------- tests
TornadoHazards.isEnabled = true
TornadoHazards:loadMap()
check("subscribed to hour and day", subscriptions[MessageType.HOUR_CHANGED] ~= nil and subscriptions[MessageType.DAY_CHANGED] ~= nil, true)
check("starts at WATER_START", TornadoHazards.water, 0.6)

-- Disabled module does nothing.
TornadoHazards.isEnabled = false
hours(24)
check("disabled: soil water unchanged", TornadoHazards.water, 0.6)
TornadoHazards.isEnabled = true

-- Cold weather: no drying.
weather.temp = 2
hours(48)
check("below 5 C: soil water unchanged", TornadoHazards.water, 0.6)

-- Hot dry weather dries the soil; warning fires exactly once.
weather.temp = 25
local daysToDry = 0
while TornadoHazards.water >= TornadoHazards.DROUGHT_LEVEL and daysToDry < 30 do
    hours(24)
    day()
    daysToDry = daysToDry + 1
end
print(string.format("info  days of 25 C without rain until soil water < %.0f %%: %d", TornadoHazards.DROUGHT_LEVEL * 100, daysToDry))
check("hot dry spell empties the soil within 4 - 12 days", daysToDry, function(v) return v >= 4 and v <= 12 end)
check("dry-spell warning sent once", countMessages("tp_msg_dry_spell"), 1)
check("no drought yet on the first dry day", TornadoHazards.droughtDay, 0)

-- Two more dry days -> drought starts with damage on day 1.
disasterCalls = {}
hours(24) day()
hours(24) day()
check("drought started", TornadoHazards.droughtDay >= 1, true)
check("drought start message", countMessages("tp_msg_drought_start"), 1)
local hitFields = {}
for _, c in ipairs(disasterCalls) do hitFields[c.field] = c.perlin end
check("wheat field 1 damaged", hitFields[1] ~= nil, true)
check("rice field 2 spared", hitFields[2], nil)
check("grass field 3 damaged", hitFields[3] ~= nil, true)
check("not-growing field 4 skipped", hitFields[4], nil)
check("empty field 5 skipped", hitFields[5], nil)
check("unowned wheat field 6 damaged", hitFields[6] ~= nil, true)
check("grass hit lighter (higher perlin) than wheat", hitFields[3] > hitFields[1], true)
check("farm 1 got a damage message", countMessages("tp_msg_drought_damage", 1) >= 1, true)
check("farm 2 got a damage message", countMessages("tp_msg_drought_damage", 2) >= 1, true)
check("no message to 'farm 0'", countMessages("tp_msg_drought_damage", 0), 0)

-- Damage grows day by day up to the cap.
local firstPerlin = hitFields[1]
for _ = 1, 10 do hours(24) day() end
disasterCalls = {}
hours(24) day()
local lastPerlin
for _, c in ipairs(disasterCalls) do if c.field == 1 then lastPerlin = c.perlin end end
check("later drought days hit harder (lower perlin)", lastPerlin < firstPerlin, true)
check("damage capped at MAX_SHARE (mild)", TornadoHazards:getDroughtShare(), TornadoHazards.MAX_SHARE)
print(string.format("info  perlin day 1 = %d, capped = %d", firstPerlin, lastPerlin))

-- Disaster destruction off -> no crop damage.
g_currentMission.missionInfo.disasterDestructionState = DisasterDestructionState.VISUALS_ONLY
disasterCalls = {}
hours(24) day()
check("visuals-only setting: no crop damage", #disasterCalls, 0)
g_currentMission.missionInfo.disasterDestructionState = DisasterDestructionState.ENABLED

-- Rain ends the drought.
weather.rain = 1.0
hours(12)
weather.rain = 0
day()
check("rain ends the drought", TornadoHazards.droughtDay, 0)
check("drought end message", countMessages("tp_msg_drought_end"), 1)

-- Events logged and saved / loaded.
local numEvents = #TornadoHazards.events
check("events logged", numEvents > 0, true)
TornadoHazards.water = 0.42
TornadoHazards:save()
TornadoHazards:deleteMap()
TornadoHazards:loadMap()
check("save / load keeps soil water", TornadoHazards.water, 0.42)
check("save / load keeps the event log", #TornadoHazards.events, numEvents)
check("loaded event has field + farm", TornadoHazards.events[1].fieldId ~= 0 and TornadoHazards.events[1].kind == "DROUGHT", true)

-- RealisticWeather installed -> off.
g_modIsLoaded["FS25_RealisticWeather"] = true
local before = TornadoHazards.water
weather.temp = 30
hours(48)
check("RealisticWeather installed: module idle", TornadoHazards.water, before)
check("status says RealisticWeather", TornadoHazards:getStatusText():find("RealisticWeather") ~= nil, true)
g_modIsLoaded["FS25_RealisticWeather"] = nil

-- Intensity scales the cap.
TornadoHazards.intensity = 3.0
TornadoHazards.droughtDay = 20
check("intensity 300 % caps at 45 %", math.floor(TornadoHazards:getDroughtShare() * 100 + 0.5), 45)

TornadoHazards.intensity = 1.0
TornadoHazards.droughtDay = 0

-- "Only damage owned fields": unowned field 6 is skipped by the drought.
TornadoHazards.ownedOnly = true
TornadoHazards.droughtDay = 1
disasterCalls = {}
TornadoHazards:applyDroughtDamage()
hitFields = {}
for _, c in ipairs(disasterCalls) do hitFields[c.field] = true end
check("owned only: owned wheat field 1 still damaged", hitFields[1], true)
check("owned only: unowned field 6 skipped", hitFields[6], nil)
TornadoHazards.ownedOnly = false
TornadoHazards.droughtDay = 0

-- Flood: heavy rain on soaked soil for FLOOD_HOURS hours.
-- Make fields 1 and 6 the only low growing ones: 6 fields, lowest 20 % = the lowest 2 (fields 1 and 2 by height).
fields[2].setFruit(1, 3)          -- field 2 now wheat too (was rice) so the two lowest are 1 and 2
TornadoHazards.lowPoints = nil
messages, disasterCalls, circles = {}, {}, {}
TornadoHazards.water = 0.5
weather.temp, weather.rain = 15, 1.0
hours(2)
check("no flood while the soil is not soaked yet", countMessages("tp_msg_flood"), 0)
hours(10)
check("flood after hours of heavy rain on soaked soil", countMessages("tp_msg_flood"), 1)
local floodFields = {}
for _, c in ipairs(disasterCalls) do floodFields[#floodFields + 1] = c end
check("flood hits the 2 lowest growing fields", #circles, 2)
check("flood circle at field 1's low point", circles[1] ~= nil and (circles[1].x == 1 or circles[2].x == 1), true)
check("flood radius within 12 - 70 m", circles[1].radius >= 12 and circles[1].radius <= 70, true)
check("flood damage message to farm 1", countMessages("tp_msg_flood_damage", 1), 1)
local floodEvents = 0
for _, e in ipairs(TornadoHazards.events) do if e.kind == "FLOOD" then floodEvents = floodEvents + 1 end end
check("flood events logged", floodEvents, 2)
hours(10)
check("cooldown: no second flood the same day", countMessages("tp_msg_flood"), 1)
day() day() day()
hours(4)
check("after the cooldown another flood is possible", countMessages("tp_msg_flood"), 2)

-- Rice is spared by floods; flood toggle off stops floods.
fields[1].setFruit(2, 3)          -- field 1 rice
TornadoHazards.floodCooldownUntil = 0
circles = {}
TornadoHazards:triggerFlood()
local riceHit = false
for _, c in ipairs(circles) do if c.x == 1 then riceHit = true end end
check("flood spares the rice field", riceHit, false)
TornadoHazards.floodEnabled = false
TornadoHazards.floodCooldownUntil = 0
local before = countMessages("tp_msg_flood")
hours(6)
check("flood toggle OFF: no flood", countMessages("tp_msg_flood"), before)
TornadoHazards.floodEnabled = true

-- Low point = inside the field (grid), not a raised outline corner.
-- A 200 x 200 m square field; corners raised to 50 m, a dip at (150, 40) inside the field at 20 m.
local savedHeight = getTerrainHeightAtWorldPos
getTerrainHeightAtWorldPos = function(_, x, _, z)
    local corner = (x <= 1 or x >= 199) and (z <= 1 or z >= 199)
    if corner then return 10 end                       -- corners LOWER than the inside: must be ignored
    local dx, dz = x - 150, z - 40
    return 20 + math.sqrt(dx * dx + dz * dz) * 0.1     -- lowest near (150, 40)
end
local square = {
    getId = function() return 99 end,
    getCenterOfFieldWorldPosition = function() return 100, 100 end,
    getPolygonPoints = function() return { { x = 0, z = 0 }, { x = 200, z = 0 }, { x = 200, z = 200 }, { x = 0, z = 200 } } end,
}
TornadoHazards.lowPoints = nil
local low = TornadoHazards:getFieldLowPoint(square)
check("low point is inside the field, not a corner", low.x > 1 and low.x < 199 and low.z > 1 and low.z < 199, true)
check("low point near the dip (150, 40)", math.abs(low.x - 150) <= 30 and math.abs(low.z - 40) <= 30, true)
check("low point lower than the centre", (low.belowCentre or 0) > 0, true)
check("point-in-polygon: outside point rejected", TornadoHazards:isInsideOutline(
    { { x = 0, z = 0 }, { x = 10, z = 0 }, { x = 10, z = 10 }, { x = 0, z = 10 } }, 15, 5), false)
getTerrainHeightAtWorldPos = savedHeight
TornadoHazards.lowPoints = nil

-- Flood state saved / loaded.
TornadoHazards.floodCooldownUntil = 77
TornadoHazards:save()
TornadoHazards:deleteMap()
TornadoHazards:loadMap()
check("save / load keeps the flood cooldown", TornadoHazards.floodCooldownUntil, 77)

-- ---------------------------------------------------------------- FIELD FIRE
-- A ripe 200 x 200 m wheat field (growth 5 = harvest ready) with a real outline, owned by farm 1.
local fireState = { isValid = true, fruitTypeIndex = 1, growthState = 5 }
local fireField = {
    getId = function() return 7 end,
    getFieldState = function() return fireState end,
    getDensityMapPolygon = function() return { fieldId = 7 } end,
    getOwner = function() return 1 end,
    getCenterOfFieldWorldPosition = function() return 1100, 100 end,
    getPolygonPoints = function() return { { x = 1000, z = 0 }, { x = 1200, z = 0 }, { x = 1200, z = 200 }, { x = 1000, z = 200 } } end,
    getAreaHa = function() return 4 end,
}
table.insert(fields, fireField)
for _, f in ipairs(fields) do
    if f ~= fireField and f.setFruit ~= nil then f.setFruit(1, 3) end   -- every other field: growing, not ripe
end
TornadoHazards.isEnabled, TornadoHazards.fireEnabled = true, true
TornadoHazards.fire = nil
weather.temp, weather.rain = 30, 0
g_currentMission.environment.currentHour = 12
messages, broadcasts, fxCalls, disasterCalls = {}, {}, {}, {}
TornadoHazards.FIRE_CHANCE_PER_HOUR = 1.0     -- force the roll for the test

TornadoHazards.droughtDay = 0
hours(1)
check("no fire without a drought", TornadoHazards.fire, nil)

TornadoHazards.droughtDay = 1
TornadoHazards.water = 0.05
g_currentMission.environment.currentHour = 22
hours(1)
check("no fire at night", TornadoHazards.fire, nil)

g_currentMission.environment.currentHour = 12
weather.temp = 20
hours(1)
check("no fire below 25 C", TornadoHazards.fire, nil)

weather.temp = 30
hours(1)
check("fire starts on the ripe field", TornadoHazards.fire ~= nil and TornadoHazards.fire.fieldId, 7)
local f = TornadoHazards.fire
check("fire start spot inside the field", f.x > 1000 and f.x < 1200 and f.z > 0 and f.z < 200, true)
check("fire max radius stays inside the field (<= room, <= 80 m)",
    f.maxRadius <= 80 and f.maxRadius <= math.min(f.x - 1000, 1200 - f.x, f.z, 200 - f.z) + 0.01, true)
check("fire alert sent", countMessages("tp_msg_field_fire"), 1)
check("fire visuals started on the host", #fxCalls == 1 and fxCalls[1].kind == "start", true)
check("fire START sent to clients", #broadcasts == 1 and broadcasts[1].kind == 1, true)
hours(1)
check("only one fire at a time", countMessages("tp_msg_field_fire"), 1)

-- Spread and burn: one game minute per update (timeScale 1, dt 60 000 ms).
local startRadius = f.radius
TornadoHazards:update(60000)
check("fire spreads", f.radius > startRadius, true)
check("fire burns the crop (perlin 0 = full)", #disasterCalls >= 1 and disasterCalls[#disasterCalls].perlin, 0)
for _ = 1, 200 do
    if TornadoHazards.fire == nil then break end
    TornadoHazards:update(60000)
end
check("fire burns out at full size", TornadoHazards.fire, nil)
check("burnt-out message", countMessages("tp_msg_fire_out"), 1)
check("fire visuals stopped", fxCalls[#fxCalls].kind, "stop")
local lastEvent = TornadoHazards.events[#TornadoHazards.events]
check("FIRE event logged for farm 1", lastEvent.kind == "FIRE" and lastEvent.farmId == 1 and lastEvent.fieldId == 7, true)
check("burnt share between 0 and 1", lastEvent.share > 0 and lastEvent.share <= 1, true)

-- Rain puts it out.
hours(1)
check("a new fire can start after the last one", TornadoHazards.fire ~= nil, true)
weather.rain = 0.5
TornadoHazards:update(1000)
check("rain puts the fire out", TornadoHazards.fire, nil)
check("rain message", countMessages("tp_msg_fire_out_rain"), 1)
weather.rain = 0

-- Not ripe -> no candidate; only owned fields respected; dev command.
fireState.growthState = 3
hours(1)
check("unripe field does not burn by itself", TornadoHazards.fire, nil)
check("t_dev hazards fire 7 still works on a growing field", TornadoHazards:consoleCommand("fire", "7"):find("field 7") ~= nil, true)
TornadoHazards:consoleCommand("fireout")
check("t_dev hazards fireout", TornadoHazards.fire, nil)
fireState.growthState = 5
TornadoHazards.ownedOnly = true
local ownerBackup = fireField.getOwner
fireField.getOwner = function() return 0 end
hours(1)
check("owned only: unowned ripe field does not burn", TornadoHazards.fire, nil)
fireField.getOwner = ownerBackup
TornadoHazards.ownedOnly = false
TornadoHazards.fireEnabled = false
hours(1)
check("fire toggle OFF: no fire", TornadoHazards.fire, nil)
TornadoHazards.fireEnabled = true

print(TornadoHazards:getStatusText())
print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
