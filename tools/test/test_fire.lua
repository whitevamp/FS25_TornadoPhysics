-- Offline test for the vehicle fire roll in scripts/TornadoEffects.lua - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_fire.lua
-- Checks: one roll per vehicle (also after the effect entry is flushed), chance by EF, off = no fires,
-- a repair clears the roll. Exit code 0 = all checks passed.

function entityExists(node) return node ~= nil end
function getName(node) return "vehicle" .. tostring(node) end
Utils = { getFilename = function(name, dir) return (dir or "") .. name end }
g_currentMission = { time = 0 }
TornadoPhysics = { currentEfNum = 2 }

dofile("scripts/TornadoEffects.lua")
local FX = TornadoEffects

local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "number" and type(got) == "number" then ok = math.abs(got - want) < 0.0001 end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-58s got %s, want %s", label, tostring(got), tostring(want)))
    else
        print(string.format("ok    %-58s %s", label, tostring(got)))
    end
end

-- Chance by EF
local expected = { [0] = 0.05, [1] = 0.10, [2] = 0.15, [3] = 0.25, [4] = 0.35, [5] = 0.45 }
for ef = 0, 5 do
    TornadoPhysics.currentEfNum = ef
    check("EF" .. ef .. " fire chance", FX:getFireChance(), expected[ef])
end
TornadoPhysics.currentEfNum = nil
check("EF unknown: fallback chance", FX:getFireChance(), 0.15)

-- One roll per vehicle: calling every frame and flushing the effect entry does not roll again.
FX.CONFIG.RANDOM_FIRE_MODE = true
TornadoPhysics.currentEfNum = 3
local rolls = 0
local realRandom = math.random
math.random = function(...) if select("#", ...) == 0 then rolls = rolls + 1 end return realRandom(...) end
for _ = 1, 100 do FX:igniteVehicle(11) end
FX.activeEffects[11] = nil            -- time-skip flush / faded smoke
for _ = 1, 100 do FX:igniteVehicle(11) end
check("one roll for 200 calls and a flush", rolls, 1)
check("effect follows the roll", FX.activeEffects[11].willBurn, FX:willBurn(11))
math.random = realRandom

-- Rate over many vehicles is the EF chance (EF3 = 25 %), not ~100 %.
math.randomseed(42)
local burned, n = 0, 4000
for node = 1000, 1000 + n - 1 do
    for _ = 1, 5 do FX:igniteVehicle(node) end
    FX.activeEffects[node] = nil
    FX:igniteVehicle(node)
    if FX:willBurn(node) then burned = burned + 1 end
end
local rate = burned / n
check("EF3: about 25 % of vehicles burn", rate > 0.22 and rate < 0.28, true)
print(string.format("      (%.1f %% of %d vehicles)", rate * 100, n))

-- Off = no vehicle fires.
FX.CONFIG.RANDOM_FIRE_MODE = false
FX:igniteVehicle(50)
check("fires off: no fire", FX:willBurn(50), false)
check("fires off: effect does not burn", FX.activeEffects[50].willBurn, false)

-- Client told by the server that it burns.
FX:markBurning(60)
check("server-decided fire on a client", FX:willBurn(60), true)

-- Repair clears the roll (TornadoRecovery does fireFate[node] = nil); a deleted vehicle too.
FX.fireFate[11] = nil
FX.CONFIG.RANDOM_FIRE_MODE = true
TornadoPhysics.currentEfNum = 5
FX:igniteVehicle(11)
check("after repair: rolled again", FX.fireFate[11] ~= nil, true)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
