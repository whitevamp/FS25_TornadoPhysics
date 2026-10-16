-- Offline test for scripts/TornadoRegion.lua and TornadoClimate:detectRegion (Lua 5.1, outside the game).
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_region.lua
-- Stubs only what the two modules use: XML reading (a tiny reader for our generated DB files), file helpers,
-- map manager and mission info. Uses the real DB/InsuranceRegions.xml and DB/TornadoClimate*.xml - rebuild them
-- (tools/build_crop_insurance.py) before running. Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- tiny XML reader (our generated files)
local docs = {}
local function parseXML(text)
    text = text:gsub("<%?.-%?>", ""):gsub("<!%-%-.-%-%->", "")
    local root = { name = "#doc", attrs = {}, children = {} }
    local stack = { root }
    for close, name, attrs, selfClose in text:gmatch("<(/?)([%w_:%-]+)(.-)(/?)>") do
        if close == "/" then
            table.remove(stack)
        else
            local node = { name = name, attrs = {}, children = {} }
            for k, v in attrs:gmatch('([%w_:%-]+)%s*=%s*"(.-)"') do
                v = v:gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
                node.attrs[k] = v
            end
            table.insert(stack[#stack].children, node)
            if selfClose ~= "/" then table.insert(stack, node) end
        end
    end
    return root
end

local function resolve(id, path)
    local doc = docs[id]
    if doc == nil then return nil end
    local elementPath, attr = path:match("^(.-)#(.+)$")
    local node = doc
    for segment in elementPath:gmatch("[^%.]+") do
        local name, index = segment:match("^(.-)%((%d+)%)$")
        name = name or segment
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
    return node.attrs[attr]
end

local nextId = 1
function loadXMLFile(_, path)
    local f = io.open(path, "rb")
    if f == nil then return 0 end
    local text = f:read("*a")
    f:close()
    local id = nextId
    nextId = nextId + 1
    docs[id] = parseXML(text)
    return id
end
function getXMLString(id, path) return resolve(id, path) end
function getXMLFloat(id, path) local v = resolve(id, path) return v and tonumber(v) end
function getXMLInt(id, path) local v = resolve(id, path) return v and math.floor(tonumber(v)) end
function getXMLBool(id, path) local v = resolve(id, path) return v ~= nil and v == "true" end
function delete(id) docs[id] = nil end
function fileExists(path) local f = io.open(path, "rb") if f then f:close() return true end return false end
Utils = { getFilename = function(file, dir) return (dir or "") .. file end }
utf8ToLower = string.lower   -- the game's version also lowers non-ASCII letters

-- ---------------------------------------------------------------- modules under test
dofile("scripts/TornadoRegion.lua")
dofile("scripts/TornadoClimate.lua")
TornadoClimate.installHooks = function() end
TornadoRegion:loadMap("")
TornadoClimate:loadMap("")

-- ---------------------------------------------------------------- map stub
local function setMap(mapId, modName, title, description, environment)
    g_currentMission = {
        missionInfo = { mapId = mapId, mapTitle = title },
        environment = { xmlFilename = environment },
    }
    g_mapManager = { getMapById = function(_, id)
        return { customEnvironment = modName, title = title, description = description }
    end }
    TornadoRegion.cached = nil
end

local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL  %-58s got %-10s want %s", label, tostring(got), tostring(want)))
    else
        print(string.format("ok    %-58s %s", label, tostring(got)))
    end
end

local cases = {
    -- label, mapId, modName, title, description, environment, wantCountry, wantSource, wantClimate
    { "Riverbend Springs (base map)", "MapUS", nil, "Riverbend Springs", "", "data/maps/mapUS/config/environment.xml", "US", "baseMap", "US" },
    { "Zielonka (base map)", "MapEU", nil, "Zielonka", "", "data/maps/mapEU/config/environment.xml", "PL", "baseMap", nil },
    { "Hutan Pantai (base map)", "MapAS", nil, "Hutan Pantai", "", "data/maps/mapAS/config/environment.xml", "SEA", "baseMap", nil },
    { "Known map Nordkirchen", "FS25_Nordkirchen.SampleMap", "FS25_Nordkirchen", "Nordkirchen", "", "", "DE", "knownMap", nil },
    { "Known US map, state in title", "FS25_Prairie_Farm_Michigan.M", "FS25_Prairie_Farm_Michigan", "Prairie Farm Michigan", "", "", "US", "knownMap", "US_MI" },
    { "Known US map, state only in description", "FS25_WillowBend.M", "FS25_WillowBend", "Willow Bend", "Farming in rural Iowa with big fields.", "", "US", "knownMap", "US_IA" },
    { "Known Canadian map (Quebec)", "FS25_La_Campagne_Quebecoise.M", "FS25_La_Campagne_Quebecoise", "The Quebec Countryside", "", "", "CA", "knownMap", "CAN_QC" },
    { "Unknown map, keyword Bavarian", "FS25_X.M", "FS25_X", "Bavarian Hills", "", "", "DE", "keywords", nil },
    { "Unknown map, UTF-8 Thüringen in description", "FS25_Y.M", "FS25_Y", "Hofgut", "Ein Hof in Thüringen.", "", "DE", "keywords", nil },
    { "South America beats America", "FS25_Z.M", "FS25_Z", "Rancho", "A ranch somewhere in South America.", "", "SAM", "keywords", nil },
    { "Northern Ireland beats Ireland", "FS25_W.M", "FS25_W", "Hill Farm", "Set in Northern Ireland.", "", "GB", "keywords", nil },
    { "Swiss Jura: swiss beats jura", "FS25_V.M", "FS25_V", "Plateau", "Inspired by the Swiss Jura.", "", "CH", "keywords", nil },
    { "Word inside another word is no match", "FS25_U.M", "FS25_U", "Germanyville Farm", "", "", "US", "default", nil },
    { "Fictional map on EU climate", "FS25_T.M", "FS25_T", "Green Valley", "A fictional map.", "$data/maps/mapEU/config/environment.xml", "EU", "climate", nil },
    { "Fictional map on US climate -> US climate", "FS25_S.M", "FS25_S", "Green Valley", "A fictional map.", "$data/maps/mapUS/config/environment.xml", "US", "climate", "US" },
    { "Nothing known -> default (climate: classic)", "FS25_R.M", "FS25_R", "Green Valley", "A fictional map.", "maps/custom/environment.xml", "US", "default", nil },
    { "Oklahoma in title (old rule still works)", "FS25_Q.M", "FS25_Q", "Redstone County-Oklahoma", "", "", "US", "keywords", "US_OK" },
}

print("Loaded known maps / keywords:", (function() local n = 0 for _ in pairs(TornadoRegion.knownMaps) do n = n + 1 end return n end)(), #TornadoRegion.keywords)
print("Climate regions loaded:", #TornadoClimate.regionOrder)
for _, c in ipairs(cases) do
    setMap(c[2], c[3], c[4], c[5], c[6])
    local r = TornadoRegion:detect()
    check(c[1] .. " | country", r.country, c[7])
    check(c[1] .. " | source", r.source, c[8])
    check(c[1] .. " | climate", (TornadoClimate:detectRegion()), c[9])
end

check("nearest AT -> DE", TornadoRegion:getProfileCountry("AT"), "DE")
check("nearest EE -> PL", TornadoRegion:getProfileCountry("EE"), "PL")
check("nearest EU -> DE", TornadoRegion:getProfileCountry("EU"), "DE")
check("nearest NONE -> US (default)", TornadoRegion:getProfileCountry("NONE"), "US")
check("nearest ZZ (unknown) -> US", TornadoRegion:getProfileCountry("ZZ"), "US")
check("profile region CA", TornadoRegion:getProfileRegion("CA"), "CAN")
setMap("FS25_Nordkirchen.SampleMap", "FS25_Nordkirchen", "Nordkirchen", "", "")
print("status text:", TornadoRegion:getStatusText())

-- Keyword fallback alone: every real-place map of the survey list by its title only (known-map step off).
-- Informational only - titles rarely name the country; in game the description adds most of the hits.
local savedKnown = TornadoRegion.knownMaps
TornadoRegion.knownMaps = {}
local right, wrong, none = 0, 0, 0
for line in io.lines("tools/map_countries.csv") do
    if line:sub(1, 1) ~= "#" and line ~= "" then
        local _, country, kind, title = line:match("^([^|]*)|([^|]*)|([^|]*)|(.*)$")
        if kind == "real" then
            setMap("X.M", "", title, "", "")
            local r = TornadoRegion:detect()
            if r.source == TornadoRegion.SOURCE_DEFAULT then
                none = none + 1
            elseif r.country == country then
                right = right + 1
            else
                wrong = wrong + 1
                print(string.format("info  title only: %s -> %s (%s), list says %s", title, r.country, r.detail, country))
            end
        end
    end
end
TornadoRegion.knownMaps = savedKnown
print(string.format("info  keyword fallback on titles only: right %d, wrong %d, no keyword %d", right, wrong, none))

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
