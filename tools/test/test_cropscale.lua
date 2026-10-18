-- Offline test for TornadoPhysics:applyCropDamageScale (twister crop damage sized to the physics radius,
-- strength by EF) - Lua 5.1. Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_cropscale.lua
-- A small node tree stands in for the twister i3d: rootNode -> component -> destructionAreas -> ring -> points.
-- World positions follow the scales of every parent (no rotation). Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- node tree stubs
local nodes = {}
local function newNode(parent, x, z, scale)
    local id = #nodes + 1
    nodes[id] = { parent = parent or 0, x = x or 0, z = z or 0, sx = scale or 1, sy = scale or 1, sz = scale or 1 }
    return id
end
function getParent(id) return nodes[id] ~= nil and nodes[id].parent or 0 end
function getScale(id) local n = nodes[id] return n.sx, n.sy, n.sz end
function setScale(id, x, y, z) local n = nodes[id] n.sx, n.sy, n.sz = x, y, z end
function getWorldTranslation(id)
    -- walk to the root: world = parent world + parent scale * local
    local chain = {}
    local n = id
    while n ~= 0 do table.insert(chain, 1, n) n = nodes[n].parent end
    local wx, wz, scaleX, scaleZ = 0, 0, 1, 1
    for _, c in ipairs(chain) do
        local node = nodes[c]
        wx, wz = wx + node.x * scaleX, wz + node.z * scaleZ
        scaleX, scaleZ = scaleX * node.sx, scaleZ * node.sz
    end
    return wx, 0, wz
end

-- Game twister: outer ring 35 m, middle 20 m, inner strip at 10 m; perlin 1500 / 3000 / 6000.
local function buildTwister(outer, componentScale)
    nodes = {}
    local root = newNode(0, 500, 300)
    local component = newNode(root, 0, 0, componentScale or 1)
    local areasNode = newNode(component)
    local function ring(radius, perlin)
        local group = newNode(areasNode)
        local polygon = { nodes = { newNode(group, radius, 0), newNode(group, radius * 0.5, radius * 0.866),
            newNode(group, radius * 0.48, radius * 0.83), newNode(group, radius * 0.95, 0) } }
        return { polygon = polygon, perlinPercentage = perlin }
    end
    local twister = { rootNode = root, destructionAreas = { ring(10, 1500), ring(outer * 20 / 35, 3000), ring(outer, 6000) } }
    return twister, areasNode
end

TornadoPhysics = nil
dofile("scripts/TornadoPhysics.lua")
local P = TornadoPhysics

local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "function" then ok = want(got) end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-62s got %s", label, tostring(got)))
    else
        print(string.format("ok    %-62s %s", label, tostring(got)))
    end
end
local function near(v, eps) return function(got) return math.abs(got - v) <= eps end end
local function outerRadius(twister)
    local cx, _, cz = getWorldTranslation(twister.rootNode)
    local best = 0
    for _, area in ipairs(twister.destructionAreas) do
        for _, node in ipairs(area.polygon.nodes) do
            local x, _, z = getWorldTranslation(node)
            best = math.max(best, math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2))
        end
    end
    return best
end

-- EF-0, physics radius 25 m, visual root scale 1.0
local twister, areasNode = buildTwister(35)
P:applyCropDamageScale(twister, 25, 0)
check("EF-0: outer ring sized to the 25 m physics radius", outerRadius(twister), near(25, 0.01))
check("EF-0 strength x0.6: inner 85 % -> 51 % (perlin 4900)", twister.destructionAreas[1].perlinPercentage, 4900)
check("EF-0: outer 40 % -> 24 % (perlin 7600)", twister.destructionAreas[3].perlinPercentage, 7600)
check("areas node found", twister.tornadoAreasNode, areasNode)

-- Same twister object, respawn as EF-2 radius 82 m with the root scaled visually (1 + 2 * 0.8)
setScale(twister.rootNode, 2.6, 2.6, 2.6)
P:applyCropDamageScale(twister, 82, 2)
check("respawn EF-2 (root scaled 2.6): outer ring 82 m", outerRadius(twister), near(82, 0.01))
check("EF-2 strength x1.0 from the ORIGINAL value: inner back to 1500", twister.destructionAreas[1].perlinPercentage, 1500)

-- EF-5: capped at 98 %
P:applyCropDamageScale(twister, 150, 5)
check("EF-5: inner 85 % x1.45 capped at 98 % (perlin 200)", twister.destructionAreas[1].perlinPercentage, 200)
check("EF-5: outer 40 % x1.45 = 58 % (perlin 4200)", twister.destructionAreas[3].perlinPercentage, 4200)

-- A map's own twister: rings twice as large, component scaled 1.3 (like the Hutan Pantai one)
local mapTwister = buildTwister(70, 1.3)
P:applyCropDamageScale(mapTwister, 43, 1)
check("map twister (70 m rings, component x1.3) -> 43 m", outerRadius(mapTwister), near(43, 0.01))

-- Client / no areas: nothing happens
check("no destruction areas (client): no error", P:applyCropDamageScale({ rootNode = 1 }, 30, 1), nil)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
