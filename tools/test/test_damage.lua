-- Offline test for scripts/insurance/TornadoInsuranceDamage.lua (insurance phase 1: storm damage report) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_damage.lua
-- Stubs fields (square outlines), fruit types, the disaster function, the clock, messages and the savegame XML.
-- Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- stubs
local files = {}
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
function getWorldTranslation(node) return node.x, 0, node.z end
function entityExists(node) return node ~= nil end

MessageType = { MINUTE_CHANGED = 1 }
local subscriptions = {}
g_messageCenter = {
    subscribe = function(_, kind, fn, target) subscriptions[kind] = { fn = fn, target = target } end,
    unsubscribeAll = function() subscriptions = {} end,
}
FruitType = { UNKNOWN = 0 }
local fruits = {
    [1] = { name = "WHEAT", minDisasterDestructionState = 2, maxDisasterDestructionState = 6 },
    [2] = { name = "BARLEY", minDisasterDestructionState = 2, maxDisasterDestructionState = 6 },
}
g_fruitTypeManager = {
    getFruitTypeByIndex = function(_, i) return fruits[i] end,
    getFillTypeNameByFruitTypeIndex = function(_, i) return fruits[i] and fruits[i].name or nil end,
}

local environment = { currentMonotonicDay = 3, dayTime = 0 }
g_currentMission = { getIsServer = function() return true end, environment = environment, terrainSize = 2048 }
local tornadoNode = { x = 50, z = 50 }
TornadoPhysics = { tornadoNode = tornadoNode }

-- Fields: squares of `side` metres, lower-left corner at (x0, z0).
local function makeField(id, x0, z0, side, owner, fruit, growth)
    local state = { isValid = true, fruitTypeIndex = fruit, growthState = growth }
    local nodes = { { x = x0, z = z0 }, { x = x0 + side, z = z0 }, { x = x0 + side, z = z0 + side }, { x = x0, z = z0 + side } }
    return {
        getId = function() return id end,
        getPolygonPoints = function() return nodes end,
        getAreaHa = function() return side * side / 10000 end,
        getOwner = function() return owner end,
        getFieldState = function() return state end,
        getCenterOfFieldWorldPosition = function() return x0 + side / 2, z0 + side / 2 end,
        getDensityMapPolygon = function() return { whole = id } end,
        state = state,
    }
end
local fields = {
    makeField(1, 0, 0, 100, 1, 1, 4),       -- 1 ha wheat, farm 1
    makeField(2, 100, 0, 100, 0, 2, 4),     -- 1 ha barley next to it, nobody owns it
    makeField(3, 0, 200, 100, 1, 1, 1),     -- wheat just sown (growth 1) - nothing to destroy
}
g_fieldManager = { getFields = function() return fields end,
    getFieldById = function(_, id) for _, f in ipairs(fields) do if f.getId() == id then return f end end return nil end }

-- Areas like the game's: a circle (hail, our hazards) and a node polygon (twister).
local function circle(x, z, radius, segments)
    segments = segments or 32
    local c = {}
    function c:getVerticesAs3DCoordinates()
        local v = {}
        for i = 1, segments do
            local a = (i - 1) / segments * 2 * math.pi
            table.insert(v, x + math.cos(a) * radius) table.insert(v, 0) table.insert(v, z + math.sin(a) * radius)
        end
        return v
    end
    return c
end
local function nodePolygon(points)
    local p = { nodes = {} }
    for _, point in ipairs(points) do table.insert(p.nodes, { x = point[1], z = point[2] }) end
    function p:getVerticesAs3DCoordinates()
        local v = {}
        for _, n in ipairs(self.nodes) do table.insert(v, n.x) table.insert(v, 0) table.insert(v, n.z) end
        return v
    end
    return p
end
DensityMapCircle = { new = function()
    local c = {}
    function c:updateFromWorldPosition(x, z, radius, segments)
        local built = circle(x, z, radius, segments)
        self.getVerticesAs3DCoordinates = built.getVerticesAs3DCoordinates
    end
    return c
end }

local originalCalls = 0
FSDensityMapUtil = { updateDisasterArea = function() originalCalls = originalCalls + 1 end }

local messages = {}
TornadoSync = { MSG_INFO = 3,
    sendMessage = function(_, key, params, kind, farmId) table.insert(messages, { key = key, params = params, farmId = farmId }) end }
TornadoText = { key = function(v) return { type = 2, value = v } end, num = function(v) return { type = 1, value = v } end }
TornadoDestruction = { _resolveSavegamePath = function() return "savegame1/" end }

dofile("scripts/insurance/TornadoInsuranceDamage.lua")

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
local function near(value, eps) return function(got) return type(got) == "number" and math.abs(got - value) <= eps end end
local function minutes(n)
    environment.dayTime = environment.dayTime + n * 60000
    subscriptions[MessageType.MINUTE_CHANGED].fn(subscriptions[MessageType.MINUTE_CHANGED].target)
end
local function openShare(cause, fieldId)
    local event = TornadoInsuranceDamage.events[cause .. "|" .. fieldId]
    return event ~= nil and event.share or 0
end
local M = TornadoInsuranceDamage

-- ---------------------------------------------------------------- hook
M:loadMap()
check("hook installed", FSDensityMapUtil.tornadoDamageHooked, true)
local hooked = FSDensityMapUtil.updateDisasterArea
M:installHook()
check("hook installed only once", FSDensityMapUtil.updateDisasterArea == hooked, true)

-- ---------------------------------------------------------------- hail spot (circle, no cause named)
FSDensityMapUtil.updateDisasterArea(circle(50, 50, 20), 0)
check("original disaster function still runs", originalCalls, 1)
local expected = math.pi * 20 * 20 / 10000
check("hail circle r 20 m, perlin 0: share ~ area ratio (12.6 %)", openShare("HAIL", 1), near(expected, expected * 0.06))
local first = openShare("HAIL", 1)
FSDensityMapUtil.updateDisasterArea(circle(50, 50, 20), 0)
check("same spot again: nothing new", openShare("HAIL", 1), first)
FSDensityMapUtil.updateDisasterArea(circle(50, 50, 20), 5000)
check("weaker hit on the same spot: nothing new", openShare("HAIL", 1), first)

-- perlin 5000 = half of the cells' crop
FSDensityMapUtil.updateDisasterArea(circle(150, 50, 20), 5000)
check("unowned barley field: half destroyed inside the circle", openShare("HAIL", 2), near(expected / 2, 0.01))
FSDensityMapUtil.updateDisasterArea(circle(150, 50, 20), 0)
check("stronger hit later: only the rest counts (total = full circle)", openShare("HAIL", 2), near(expected, expected * 0.06))

FSDensityMapUtil.updateDisasterArea(circle(50, 250, 20), 0)
check("just sown (growth 1): nothing destroyable", openShare("HAIL", 3), 0)

-- ---------------------------------------------------------------- twister (node polygon) across two fields
FSDensityMapUtil.updateDisasterArea(nodePolygon({ { 80, 0 }, { 120, 0 }, { 120, 100 }, { 80, 100 } }), 0)
check("twister strip 40 x 100 m over the boundary: field 1 gets ~20 % new", openShare("TORNADO", 1), near(0.20 - 0, 0.03))
check("... and field 2 too", openShare("TORNADO", 2), function(v) return v > 0.15 end)

-- ---------------------------------------------------------------- closing + report
minutes(40)
check("tornado on the map: its events stay open (one report per storm)", M.events["TORNADO|1"] ~= nil and M.events["TORNADO|2"] ~= nil, true)
check("hail closed after its quiet time", M.events["HAIL|1"], nil)
TornadoPhysics.mapBoundary = 1024
TornadoPhysics.settings = { geo_fence = 40 }
tornadoNode.x = 970    -- still inside the boundary line (1024 - 40 = 984)
minutes(1)
check("tornado near the edge but inside the line: still open", M.events["TORNADO|1"] ~= nil, true)
tornadoNode.x = 990    -- reached the mod's boundary line (map boundary - geo-fence)
minutes(1)
check("tornado reached the boundary line: all its events closed", next(M.events), nil)
tornadoNode.x = 50
check("4 events logged (hail 1, hail 2, tornado 1, tornado 2)", #M.log, 4)
local reports = {}
for _, m in ipairs(messages) do if m.key == "tp_msg_damage_report" then table.insert(reports, m) end end
check("reports only to the owning farm (farm 1: hail + tornado)", #reports, 2)
check("report goes to farm 1", reports[1].farmId, 1)
local hailReport
for _, m in ipairs(reports) do if m.params[1].value == "tp_cause_hail" then hailReport = m end end
check("hail report: 1 field, worst field 1", hailReport ~= nil and hailReport.params[2].value == 1 and hailReport.params[4].value == 1, true)
check("hail report: ha lost ~ 0.126", hailReport ~= nil and hailReport.params[3].value, near(expected, expected * 0.06))
check("log entry has crop + farm", M.log[1].crop == "WHEAT" and M.log[1].farmId == 1, true)
check("getLog(farm 1)", #M:getLog(1), 2)

-- ---------------------------------------------------------------- drought (whole field, named cause)
M:setCause("DROUGHT", fields[1])
FSDensityMapUtil.updateDisasterArea(fields[1].getDensityMapPolygon(), 9700)   -- 3 %
M:setCause(nil)
local alreadyLost = M.memory[1].sumCells / M.fieldGeometry[1].numCells
check("drought day 1: 3 % of what is still standing", openShare("DROUGHT", 1), near(0.03 * (1 - alreadyLost), 1e-6))
M:setCause("DROUGHT", fields[1])
FSDensityMapUtil.updateDisasterArea(fields[1].getDensityMapPolygon(), 9400)   -- 6 % cumulative
M:setCause(nil)
check("drought day 2: only the rise (3 % more) counts", openShare("DROUGHT", 1), near(0.06 * (1 - alreadyLost), 1e-6))
check("no report message for drought (own message)", (function()
    minutes(10)
    for _, m in ipairs(messages) do if m.params[1].value == "tp_cause_drought" then return false end end
    return true
end)(), true)

-- ---------------------------------------------------------------- new crop resets the memory
fields[1].state.fruitTypeIndex = 2
fields[1].state.growthState = 3
FSDensityMapUtil.updateDisasterArea(circle(50, 50, 20), 0)
check("new crop: the same spot counts again", openShare("HAIL", 1), near(expected, expected * 0.06))
fields[1].state.growthState = 2   -- resown (growth went down)
FSDensityMapUtil.updateDisasterArea(circle(50, 50, 20), 0)
check("resown: counts again (second hit in the same event)", openShare("HAIL", 1), near(expected * 2, expected * 0.12))

-- ---------------------------------------------------------------- save / load
M:save()
check("save closes open events", next(M.events), nil)
local logged = #M.log
M:deleteMap()
M:loadMap()
check("log restored", #M.log, logged)
check("next id restored", M.nextId, logged + 1)
check("entry restored", M.log[1].cause == "HAIL" and M.log[1].fieldId == 1 and M.log[1].crop == "WHEAT", true)

-- ---------------------------------------------------------------- tornado over -> report at once
local reportsBefore = 0
for _, m in ipairs(messages) do if m.key == "tp_msg_damage_report" then reportsBefore = reportsBefore + 1 end end
FSDensityMapUtil.updateDisasterArea(nodePolygon({ { 10, 10 }, { 30, 10 }, { 30, 30 }, { 10, 30 } }), 0)
FSDensityMapUtil.updateDisasterArea(circle(150, 50, 5), 0)   -- hail still going on the other field
M:onTornadoEnded()
check("tornado ended: its event closes at once", M.events["TORNADO|1"], nil)
check("... other causes stay open", M.events["HAIL|2"] ~= nil, true)
local reportsAfter = 0
for _, m in ipairs(messages) do if m.key == "tp_msg_damage_report" then reportsAfter = reportsAfter + 1 end end
check("... and the report is sent right away", reportsAfter, reportsBefore + 1)

-- ---------------------------------------------------------------- dev hit
check("t_dev hit on an unknown field: usage", M:testHit(99):find("Usage", 1, true) ~= nil, true)
M:testHit(1, 10, 0)
check("t_dev hit counts as tornado", openShare("TORNADO", 1), function(v) return v > 0.02 end)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
