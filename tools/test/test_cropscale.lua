-- Offline test for the twister destruction hooks in TornadoPhysics (our crop circles by EF, object radius,
-- bales left to the physics) - Lua 5.1. Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_cropscale.lua
-- Stubs: the twister object, DensityMapCircle, FSDensityMapUtil.updateDisasterArea, the damage module's cause.
-- Exit code 0 = all checks passed.

local twisterPos = { 500, 0, 300 }
function getWorldTranslation() return twisterPos[1], twisterPos[2], twisterPos[3] end

local calls = {}
DensityMapCircle = { new = function()
    return { updateFromWorldPosition = function(self, x, z, r, segments) self.x, self.z, self.r, self.segments = x, z, r, segments end }
end }
local causeDuringCall = nil
FSDensityMapUtil = { updateDisasterArea = function(area, perlin)
    table.insert(calls, { x = area.x, z = area.z, r = area.r, perlin = perlin, cause = causeDuringCall })
end }
TornadoInsuranceDamage = { CAUSE_TORNADO = "TORNADO", setCause = function(_, cause) causeDuringCall = cause end }

TornadoPhysics = nil
dofile("scripts/TornadoPhysics.lua")
local P = TornadoPhysics

local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "number" and type(got) == "number" then ok = math.abs(got - want) < 0.01 end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-62s got %s, want %s", label, tostring(got), tostring(want)))
    else
        print(string.format("ok    %-62s %s", label, tostring(got)))
    end
end

-- The game's twister object (only what the hooks touch)
local finishCalls = 0
local twister = { rootNode = 1, isSpawned = true, fadeValue = 1, objectDestructionRadius = 30,
    objectDestructionInnerRadius = 10, objectDestructionHeight = 30, foundObjects = {}, currentObjects = {} }
twister.onFinishCallback = function(self) finishCalls = finishCalls + 1 end
twister.updateDestructionAreas = function() error("game's sliver areas must not run") end

-- Curve (measured in game 2026-10-18)
check("measured: 60 % -> 4000", P.perlinForShare(0.60), 4000)
check("measured: 31 % -> 7000", P.perlinForShare(0.31), 7000)
check("100 % -> 0, 0 % -> 10000", P.perlinForShare(1.0) == 0 and P.perlinForShare(0) == 10000, true)

-- EF-2, radius 80 m
P:applyTwisterDestruction(twister, 80, 2)
local zones = twister.tornadoCropZones
check("three zones", #zones, 3)
check("inner circle 30 % = 24 m", zones[1].radius, 24)
check("middle circle 60 % = 48 m", zones[2].radius, 48)
check("outer circle = the radius", zones[3].radius, 80)
check("EF-2 inner 90 %", zones[1].perlin, P.perlinForShare(0.90))
check("EF-2 outer 60 % -> 4000", zones[3].perlin, 4000)
check("objects always destroyed inside 24 m", twister.objectDestructionInnerRadius, 24)
check("trees / buildings up to 48 m", twister.objectDestructionRadius, 48)
check("cylinder height kept at least 30", twister.objectDestructionHeight, 30)

-- The game calls updateDestructionAreas: one zone per call, our circles at the funnel, cause TORNADO
twister:updateDestructionAreas()
twister:updateDestructionAreas()
twister:updateDestructionAreas()
check("three calls = three zones crushed", #calls, 3)
check("first call: inner 24 m at the funnel", calls[1].r == 24 and calls[1].x == 500 and calls[1].z == 300, true)
check("third call: outer 80 m with its perlin", calls[3].r == 80 and calls[3].perlin == 4000, true)
check("damage report sees the cause TORNADO", calls[1].cause, "TORNADO")
check("cause cleared after the call", causeDuringCall, nil)

-- Not moved: nothing again; moved a little: only the small zone (its step is 2.4 m, the outer one 8 m)
twister:updateDestructionAreas()
check("funnel did not move: no new crush", #calls, 3)
twisterPos[1] = 503
twister:updateDestructionAreas()
check("moved 3 m: the inner zone again", #calls == 4 and calls[4].r == 24, true)
twister:updateDestructionAreas()
twister:updateDestructionAreas()
check("moved 3 m: middle (step 4.8) and outer (step 8) wait", #calls, 4)
twisterPos[1] = 510
for _ = 1, 3 do twister:updateDestructionAreas() end
check("moved 10 m: every zone again", #calls, 7)

-- Fading in: the game's own rule, nothing happens
twister.fadeValue = 0.5
twisterPos[1] = 600
twister:updateDestructionAreas()
check("still fading in: nothing", #calls, 7)
twister.fadeValue = 1

-- Bales are never deleted by the game's object destruction; trees / buildings are
twister.foundObjects = { [11] = { isBale = true }, [12] = { isSplitShape = true }, [13] = { isPlaceable = true } }
twister.currentObjects = { [14] = { isBale = true, destructObject = true } }
twister:onFinishCallback()
check("game's object check still runs", finishCalls, 1)
check("bale removed from the found objects", twister.foundObjects[11], nil)
check("tree kept", twister.foundObjects[12] ~= nil, true)
check("building kept", twister.foundObjects[13] ~= nil, true)
check("bale removed from the current objects", twister.currentObjects[14], nil)

-- Re-roll to EF-4, 143 m: hooks stay once, zones and object radius follow
local hookedUpdate = twister.updateDestructionAreas
P:applyTwisterDestruction(twister, 143, 4)
check("hooks installed once", twister.updateDestructionAreas, hookedUpdate)
check("EF-4 outer circle 143 m, 80 %", twister.tornadoCropZones[3].radius == 143 and twister.tornadoCropZones[3].perlin == P.perlinForShare(0.80), true)
check("EF-4 trees / buildings up to 85.8 m", twister.objectDestructionRadius, 85.8)
twister:onFinishCallback()
check("bale filter wraps once (one game call per check)", finishCalls, 2)

-- EF-0 small: inner 60 %
P:applyTwisterDestruction(twister, 20, 0)
check("EF-0 inner 60 % -> 4000", twister.tornadoCropZones[1].perlin, 4000)
check("EF-0 outer 30 %", twister.tornadoCropZones[3].perlin, P.perlinForShare(0.30))

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
