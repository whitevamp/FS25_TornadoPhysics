-- Offline test for scripts/insurance/TornadoInsurancePrograms.lua (insurance phase 2b: named perils, multi-risk,
-- modules, peril groups, state schemes) against the real DB/CropInsurance_*.xml files - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_programs.lua
-- Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- tiny XML reader
local function parseXML(text)
    text = text:gsub("<%?.-%?>", ""):gsub("<!%-%-.-%-%->", "")
    text = text:gsub('"[^"]*"', function(quoted) return (quoted:gsub(">", "&gt;")) end)
    local root = { name = "#root", attrs = {}, children = {} }
    local stack = { root }
    for slash, name, attrText, selfClose in text:gmatch("<(/?)([%w_:]+)(.-)(/?)>") do
        if slash == "/" then
            table.remove(stack)
        else
            local node = { name = name, attrs = {}, children = {} }
            for key, value in attrText:gmatch('([%w_:]+)%s*=%s*"(.-)"') do node.attrs[key] = value end
            table.insert(stack[#stack].children, node)
            if selfClose ~= "/" then table.insert(stack, node) end
        end
    end
    return root
end
local function xmlLookup(tree, path)
    local elements, attr = path:match("^(.-)#(.+)$")
    if elements == nil then elements = path end
    local node = tree
    for part in elements:gmatch("[^%.]+") do
        local name, index = part:match("^(.-)%((%d+)%)$")
        name = name or part
        index = tonumber(index or 0)
        local found, count = nil, 0
        for _, child in ipairs(node.children) do
            if child.name == name then
                if count == index then found = child break end
                count = count + 1
            end
        end
        if found == nil then return nil end
        node = found
    end
    return attr ~= nil and node.attrs[attr] or nil
end
local handles, nextHandle = {}, 1
function loadXMLFile(_, path)
    local f = io.open(path, "r")
    if f == nil then return 0 end
    local h = nextHandle nextHandle = nextHandle + 1
    handles[h] = parseXML(f:read("*a"))
    f:close()
    return h
end
function delete(h) handles[h] = nil end
function fileExists(path) local f = io.open(path, "r") if f then f:close() return true end return false end
getXMLString = function(h, key) return xmlLookup(handles[h], key) end
getXMLFloat = function(h, key) local v = getXMLString(h, key) return v ~= nil and tonumber(v) or nil end
getXMLInt = getXMLFloat
getXMLBool = function(h, key) local v = getXMLString(h, key) if v == nil then return nil end return v == "true" end

dofile("scripts/insurance/TornadoInsuranceData.lua")
dofile("scripts/insurance/TornadoInsurancePrograms.lua")
local D, P = TornadoInsuranceData, TornadoInsurancePrograms

local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "function" then ok = want(got) end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-66s got %s", label, tostring(got)))
    else
        print(string.format("ok    %-66s %s", label, tostring(got)))
    end
end
local function near(v, eps) return function(got) return type(got) == "number" and math.abs(got - v) <= (eps or 1e-6) end end
local function load(country) return D.load("DB/CropInsurance_" .. country .. ".xml", country) end
local function opts(profile, region) return table.concat(P.getOptions(profile, region), ",") end
local function terms(profile, region, crop, option, coverage) return P.getTerms(profile, region, crop, option, coverage) end
local function causes(t) return t ~= nil and P.causesText(t.causes) or "nil" end

-- ---------------------------------------------------------------- every programme profile offers something
for _, country in ipairs({ "DE", "PL", "GB", "AU", "AR", "CL", "FR", "NL", "ES", "IT", "SEA" }) do
    check(country .. ": options offered", #P.getOptions(load(country), nil) > 0, true)
end

-- ---------------------------------------------------------------- Germany: hail, hail + storm, package; deductibles
local de = load("DE")
check("DE options", opts(de), "PACKAGE,HAIL_STORM,HAIL")
check("DE levels = 100 % minus deductible 20 / 10 / 0 %", table.concat(P.getLevels(de, nil, "HAIL"), ","), "0.8,0.9,1")
local t = terms(de, nil, "WHEAT", "HAIL", 1.0)
check("DE wheat hail: 0.92 % + 0.03 % insurance tax", t.rate, near(0.0095))
check("DE hail pays for hail only", causes(t), "HAIL")
t = terms(de, nil, "WHEAT", "PACKAGE", 0.8)
check("DE package 20 % deductible: 6.62 % x 0.7 + tax", t.rate, near(0.0662 * 0.7 + 0.0003))
check("DE package causes (hail, storm, heavy rain, drought)", causes(t), "DROUGHT FLOOD HAIL TORNADO")
check("DE hail + storm + rain", causes(terms(de, nil, "WHEAT", "HAIL_STORM", 1)), "FLOOD HAIL TORNADO")
check("DE real value: 1 500 EUR / ha", t.realValuePerHa, near(1500))

-- ---------------------------------------------------------------- Poland: 65 % subsidy up to the rate cap
local pl = load("PL")
check("PL options", opts(pl), "PACKAGE,PACKAGE_WIND,HAIL")
t = terms(pl, nil, "WHEAT", "PACKAGE", 1)
check("PL wheat package 3.55 % - 65 % subsidy", t.rate, near(0.0355 * 0.35))
check("PL package: mandatory perils (no windstorm)", causes(t), "DROUGHT FLOOD HAIL")
check("PL package + windstorm adds the tornado", causes(terms(pl, nil, "WHEAT", "PACKAGE_WIND", 1)), "DROUGHT FLOOD HAIL TORNADO")
check("PL real value = max sum insured 3 835 EUR", t.realValuePerHa, near(3835))

-- ---------------------------------------------------------------- United Kingdom: hail + fire, 12 % premium tax
local gb = load("GB")
t = terms(gb, nil, "WHEAT", "NAMED", 1)
check("GB named perils = hail + fire", causes(t), "FIRE HAIL")
check("GB wheat 0.6 % + 12 % IPT", t.rate, near(0.006 * 1.12))
check("GB real value: 1 600 GBP in game money", t.realValuePerHa, near(1600 * 1.17))

-- ---------------------------------------------------------------- Australia: GST + stamp duty by state
local au = load("AU")
check("AU options", opts(au), "NAMED,MULTI")
check("AU national: 1.5 % + 10 % GST", terms(au, nil, "WHEAT", "NAMED", 1).rate, near(0.015 * 1.1))
check("AU NSW: crops exempt from stamp duty", terms(au, "AUS_NSW", "WHEAT", "NAMED", 1).rate, near(0.015 * 1.1))
check("AU QLD: + 9 % stamp duty", terms(au, "AUS_QLD", "WHEAT", "NAMED", 1).rate, near(0.015 * 1.19))
check("AU multi-peril pays for everything", causes(terms(au, nil, "WHEAT", "MULTI", 1)), "DROUGHT FIRE FLOOD HAIL TORNADO")

-- ---------------------------------------------------------------- Argentina: province rate factors
local ar = load("AR")
check("AR options", opts(ar), "MULTI,HAIL_PLUS,HAIL")
check("AR wheat hail 3.5 %", terms(ar, nil, "WHEAT", "HAIL", 1).rate, near(0.035))
check("AR Cordoba x1.36 (hail hot spot)", terms(ar, "ARG_CB", "WHEAT", "HAIL", 1).rate, near(0.035 * 1.36))
check("AR hail plus: hail, wind, fire", causes(terms(ar, nil, "WHEAT", "HAIL_PLUS", 1)), "FIRE HAIL TORNADO")
check("AR multi-peril 8 % (programme rate)", terms(ar, nil, "WHEAT", "MULTI", 1).rate, near(0.08))

-- ---------------------------------------------------------------- Chile: 40 % subsidy + 5 % for cereals
local cl = load("CL")
t = terms(cl, nil, "WHEAT", "NAMED", 1)
check("CL wheat 4.5 % - (40 + 5) % subsidy", t.rate, near(0.045 * 0.55))
check("CL perils: drought, rain, wind, hail", causes(t), "DROUGHT FLOOD HAIL TORNADO")
check("CL real value: 50 UF", t.realValuePerHa, near(50 * 38))

-- ---------------------------------------------------------------- France: 70 % subsidy, franchise 20 - 40 %
local fr = load("FR")
check("FR options", opts(fr), "MRC,HAIL_ONLY")
check("FR franchise levels", table.concat(P.getLevels(fr, nil, "MRC"), ","), "0.6,0.7,0.75,0.8")
check("FR wheat MRC 20 %: 3.81 % x 30 %", terms(fr, nil, "WHEAT", "MRC", 0.8).rate, near(0.0381 * 0.3))
check("FR wheat MRC 25 % franchise: x 0.8", terms(fr, nil, "WHEAT", "MRC", 0.75).rate, near(0.0381 * 0.8 * 0.3))
check("FR hail only: not subsidised", terms(fr, nil, "WHEAT", "HAIL_ONLY", 1).rate, near(0.01))
check("FR multi-risk causes", causes(terms(fr, nil, "WHEAT", "MRC", 0.8)), "DROUGHT FLOOD HAIL TORNADO")

-- ---------------------------------------------------------------- Netherlands: pool share, 20 % threshold
local nl = load("NL")
t = terms(nl, nil, "WHEAT", "MRC", 1)
check("NL broad weather: pays above 20 %", t.coverage, near(0.8))
check("NL subsidy = latest pool share (46.27 %)", t.rate, near(0.04 * (1 - 0.4627)))
check("NL perils incl. lightning fire", causes(t), "DROUGHT FIRE FLOOD HAIL TORNADO")
check("NL hail only + 21 % tax", terms(nl, nil, "WHEAT", "HAIL_ONLY", 1).rate, near(0.006 * 1.21))

-- ---------------------------------------------------------------- Spain: modules
local es = load("ES")
check("ES options", opts(es), "MOD2,MOD1,MODP")
check("ES module 2: 3.81 % - 22 % subsidy", terms(es, nil, "WHEAT", "MOD2", 1).rate, near(0.0381 * 0.78))
check("ES module 2 coverage 80 % (estimate)", terms(es, nil, "WHEAT", "MOD2", 1).coverage, near(0.8))
check("ES module 1: 75 % subsidy, 70 % coverage", terms(es, nil, "WHEAT", "MOD1", 1).rate, near(0.0267 * 0.25))
check("ES module P: hail + fire", causes(terms(es, nil, "WHEAT", "MODP", 1)), "FIRE HAIL")

-- ---------------------------------------------------------------- Italy: policy types
local it = load("IT")
check("IT options", opts(it), "IT_A,IT_B,IT_C,IT_C2,IT_D,IT_F")
check("IT type A: 7.49 % x 30 %", terms(it, nil, "WHEAT", "IT_A", 1).rate, near(0.0749 * 0.3))
check("IT type D: catastrophic only", causes(terms(it, nil, "WHEAT", "IT_D", 1)), "DROUGHT FLOOD")
check("IT type C2: 65 % subsidy", terms(it, nil, "WHEAT", "IT_C2", 1).rate, near(0.0749 * 0.45 * 0.35))
check("IT 20 % threshold as deductible", terms(it, nil, "WHEAT", "IT_A", 1).coverage, near(0.8))

-- ---------------------------------------------------------------- South-East Asia: state rice scheme
local sea = load("SEA")
t = terms(sea, nil, "RICE", "STATE", 1)
check("SEA default = Indonesia AUTP: 3 % - 80 % subsidy", t.rate, near(0.03 * 0.2))
check("SEA AUTP pays for flood + drought", causes(t), "DROUGHT FLOOD")
check("SEA: from 75 % damage", t.rule == "threshold" and t.threshold == 0.75, true)
check("SEA rice is in the scheme", t.noStateScheme, false)
check("SEA wheat: no state scheme (-> unusual crop)", terms(sea, nil, "WHEAT", "STATE", 1).noStateScheme, true)
check("SEA real value: Rp 6 000 000 / ha", t.realValuePerHa, near(6000000 * 0.000056))
local mys = terms(sea, "MYS", "RICE", "STATE", 1)
check("SEA Malaysia: premium paid by the state", mys.rate, near(0))
check("SEA Malaysia: flood only", causes(mys), "FLOOD")

-- ---------------------------------------------------------------- curve countries are not programmes
check("US is a curve profile (no programme options)", #P.getOptions(load("US"), nil), 0)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
