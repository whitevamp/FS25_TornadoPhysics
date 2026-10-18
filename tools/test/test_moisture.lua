-- Offline test for scripts/TornadoMoisture.lua (FS25_MoistureSystem integration) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_moisture.lua
-- Moisture System is a stand-in: its WitheringSystem:witherPatchAtField does what 2.0.0.8 does (3 random draws:
-- patch x, z inside the field bounds, radius 4 + r * 6; skips when the patch spot is wetter than the threshold).
-- The real damage tracker (TornadoInsuranceDamage) records the patches. Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- stubs
math.randomseed(7)
function getWorldTranslation(node) return node.x, 0, node.z end
function entityExists() return true end
function fileExists() return false end
MessageType = { MINUTE_CHANGED = 1 }
g_messageCenter = { subscribe = function() end, unsubscribeAll = function() end }
FruitType = { UNKNOWN = 0 }
local fruits = { [1] = { name = "WHEAT", minDisasterDestructionState = 1, maxDisasterDestructionState = 8 } }
g_fruitTypeManager = {
    getFruitTypeByIndex = function(_, i) return fruits[i] end,
    getFillTypeNameByFruitTypeIndex = function(_, i) return fruits[i] and fruits[i].name end,
    getFillTypeIndexByFruitTypeIndex = function(_, i) return i == 1 and 101 or nil end,
}
local environment = { currentMonotonicDay = 1, dayTime = 0 }
g_currentMission = { getIsServer = function() return true end, environment = environment, terrainSize = 2048 }
g_modIsLoaded = { FS25_MoistureSystem = true }
FSDensityMapUtil = { updateDisasterArea = function() end }

local nodes = { { x = 0, z = 0 }, { x = 100, z = 0 }, { x = 100, z = 100 }, { x = 0, z = 100 } }
local field = {
    getId = function() return 1 end,
    getPolygonPoints = function() return nodes end,
    getAreaHa = function() return 1 end,
    getOwner = function() return 1 end,
    getFieldState = function() return { isValid = true, fruitTypeIndex = 1, growthState = 4 } end,
    getCenterOfFieldWorldPosition = function() return 50, 50 end,
}
g_fieldManager = { getFields = function() return { field } end }

-- Moisture System stand-in
local fieldMoisture = 0.02
local painted = 0
local witheringSystem = {}
function witheringSystem:witherPatchAtField(f, fruitTypeIndex, witherThreshold)
    local px = 0 + math.random() * 100
    local pz = 0 + math.random() * 100
    if fieldMoisture >= witherThreshold then return end
    local radius = 4 + math.random() * 6
    painted = painted + 1
    self.lastPatch = { x = px, z = pz, radius = radius }
end
g_currentMission.witheringSystem = witheringSystem
g_currentMission.MoistureSystem = {
    getMoistureAtPosition = function() return fieldMoisture end,
    settings = { witheringEnabled = true },
    currentMoisturePercent = 0.04,
}
FS25_MoistureSystem = { CropValueMap = { getCropDef = function(index)
    return index == 101 and { witherThreshold = 0.03, yieldCurveFloor = 0.05 } or nil end } }

dofile("scripts/insurance/TornadoInsuranceDamage.lua")
dofile("scripts/TornadoMoisture.lua")

-- ---------------------------------------------------------------- helpers
local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "function" then ok = want(got) end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-64s got %s", label, tostring(got)))
    else
        print(string.format("ok    %-64s %s", label, tostring(got)))
    end
end
local function openShare() local e = TornadoInsuranceDamage.events["DROUGHT|1"] return e ~= nil and e.share or 0 end

-- ---------------------------------------------------------------- detection + moisture reads
TornadoInsuranceDamage:loadMap()
local M = TornadoMoisture
M:loadMap()
check("Moisture System detected", M:isActive(), true)
check("hooked at load (WitheringSystem already there)", M.hookedSystem, witheringSystem)
check("field moisture read", M:getFieldMoisture(field), 0.02)
check("wither threshold from its CropValueMap", M:getWitherThreshold(101), 0.03)
check("unknown crop -> default threshold", M:getWitherThreshold(999), 0.03)
check("2 % < 3 %: field too dry", M:isFieldTooDry(field), true)
fieldMoisture = 0.05
check("5 %: not too dry", M:isFieldTooDry(field), false)
check("fire threshold = yieldCurveFloor", M:getFireThreshold(101), 0.05)
check("unknown crop -> default fire threshold", M:getFireThreshold(999), 0.05)
fieldMoisture = 0.04
check("4 %: dry enough to burn, not withering", M:isFieldFireDry(field) and not M:isFieldTooDry(field), true)
fieldMoisture = 0.05

-- ---------------------------------------------------------------- withering -> damage report
local realRandom = math.random
fieldMoisture = 0.05
witheringSystem:witherPatchAtField(field, 1, 0.03)
check("wet spot: patch skipped, nothing recorded", openShare(), 0)
check("math.random restored after the call", math.random == realRandom, true)

fieldMoisture = 0.02
witheringSystem:witherPatchAtField(field, 1, 0.03)
local patch = witheringSystem.lastPatch
-- centre square r^2 + 4 corner squares (r/2)^2 that overlap the centre by (r/4)^2 each = 1.75 r^2
local discArea = 1.75 * patch.radius * patch.radius
local inside = patch.x - patch.radius > 0 and patch.x + patch.radius < 100 and patch.z - patch.radius > 0 and patch.z + patch.radius < 100
check("(test setup) patch lies inside the field", inside, true)
check("patch painted", painted, 1)
check("withered patch recorded as drought, share ~ disc area", openShare(), function(v)
    return math.abs(v - discArea / 10000) <= discArea / 10000 * 0.15 + 0.0008 end)
check("patches counted", M.patchesRecorded, 1)
local before = openShare()
for _ = 1, 20 do witheringSystem:witherPatchAtField(field, 1, 0.03) end
check("20 more patches add up", openShare() > before, true)
check("math.random still restored", math.random == realRandom, true)

-- Moisture System changed (more draws than expected): warn once, record nothing.
local changed = {}
function changed:witherPatchAtField() for _ = 1, 4 do math.random() end end
g_currentMission.witheringSystem = changed
M:update(2000)
check("new WitheringSystem instance hooked", M.hookedSystem, changed)
local shareBefore = openShare()
changed:witherPatchAtField(field, 1, 0.03)
check("unexpected pattern: nothing recorded", openShare(), shareBefore)
check("... warned once", M.warnedPattern, true)

-- ---------------------------------------------------------------- dev: t_dev moisture wither
FruitType.UNKNOWN = 0
g_fieldManager.getFieldById = function(_, id) return id == 1 and field or nil end
g_currentMission.witheringSystem = witheringSystem
M.hookedSystem = nil
M:tryHook()
fieldMoisture = 0.5     -- wet: its own skip check is passed with threshold 1.0
local recorded = M.patchesRecorded
check("t_dev moisture wither paints + records", M:consoleCommand("wither", "1", "3"):find("3 recorded", 1, true) ~= nil, true)
check("... 3 more patches recorded", M.patchesRecorded, recorded + 3)
check("t_dev moisture field", M:consoleCommand("field", "1"):find("fire below 5.0", 1, true) ~= nil, true)

-- ---------------------------------------------------------------- not installed
g_modIsLoaded = {}
M:loadMap()
check("not installed: inactive", M:isActive(), false)
check("not installed: never too dry", M:isFieldTooDry(field), false)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
