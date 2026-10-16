---@class TornadoRegion
---@version 1.0
---@description Shared "which country is this map in" detection, used by the climate module and later by the
--- insurance module. Data: DB/InsuranceRegions.xml (built by tools/build_crop_insurance.py from
--- tools/map_countries.csv). Each module keeps its own manual setting and asks this module only on "Auto".
---
--- Order (first hit wins):
---   1. known map     - the map's mod name (FS25_Nordkirchen ...) is in the survey list
---   2. base map      - MapUS / MapEU / MapAS
---   3. keywords      - country / region words in the map title, description, id or mod name (whole words,
---                      longest match wins)
---   4. climate       - the base-game environment file the map reuses ($data/maps/mapUS/ ...)
---   5. default       - the file's default country (callers may ignore this one)
--- getProfileCountry() then turns a country without own data into its nearest profile (Austria -> Germany ...).

TornadoRegion = {}

TornadoRegion.DB_FILE = "DB/InsuranceRegions.xml"

TornadoRegion.SOURCE_KNOWN_MAP = "knownMap"
TornadoRegion.SOURCE_BASE_MAP = "baseMap"
TornadoRegion.SOURCE_KEYWORDS = "keywords"
TornadoRegion.SOURCE_CLIMATE = "climate"
TornadoRegion.SOURCE_DEFAULT = "default"

function TornadoRegion:loadMap(modDir)
    self.profiles = {}       -- country -> { region = "DEU", file = "CropInsurance_DE.xml", name = "Germany" }
    self.nearest = {}        -- country -> profile country
    self.baseMaps = {}       -- map id -> country
    self.environments = {}   -- { path = "maps/mapus/", country = "US" }
    self.keywords = {}       -- { word = "bavaria", country = "DE", region = nil / "US_OK" }, longest first
    self.knownMaps = {}      -- lower-case mod name -> { country, kind, title }
    self.defaultCountry = "US"
    self.cached = nil
    self.isLoaded = false

    local path = Utils.getFilename(self.DB_FILE, modDir)
    if not fileExists(path) then
        print("TORNADO REGION: " .. self.DB_FILE .. " not found - map region detection limited to the map title.")
        return
    end
    local xmlId = loadXMLFile("TornadoRegion", path)
    if xmlId == nil or xmlId == 0 then
        print("TORNADO REGION: could not open " .. path)
        return
    end

    self.defaultCountry = getXMLString(xmlId, "insuranceRegions#default") or self.defaultCountry

    local i = 0
    while true do
        local key = string.format("insuranceRegions.profiles.profile(%d)", i)
        local country = getXMLString(xmlId, key .. "#country")
        if country == nil then break end
        self.profiles[country] = {
            region = getXMLString(xmlId, key .. "#region") or country,
            file = getXMLString(xmlId, key .. "#file"),
            name = getXMLString(xmlId, key .. "#name") or country,
        }
        i = i + 1
    end

    i = 0
    while true do
        local key = string.format("insuranceRegions.nearest.country(%d)", i)
        local country = getXMLString(xmlId, key .. "#id")
        if country == nil then break end
        self.nearest[country] = getXMLString(xmlId, key .. "#useProfile")
        i = i + 1
    end

    i = 0
    while true do
        local key = string.format("insuranceRegions.baseMaps.map(%d)", i)
        local mapId = getXMLString(xmlId, key .. "#id")
        if mapId == nil then break end
        self.baseMaps[mapId] = getXMLString(xmlId, key .. "#country")
        i = i + 1
    end

    i = 0
    while true do
        local key = string.format("insuranceRegions.environments.environment(%d)", i)
        local pathPart = getXMLString(xmlId, key .. "#pathContains")
        if pathPart == nil then break end
        table.insert(self.environments, { path = string.lower(pathPart), country = getXMLString(xmlId, key .. "#country") })
        i = i + 1
    end

    i = 0
    while true do
        local key = string.format("insuranceRegions.keywords.country(%d)", i)
        local country = getXMLString(xmlId, key .. "#id")
        if country == nil then break end
        local words = getXMLString(xmlId, key .. "#words") or ""
        for word in string.gmatch(words, "[^,]+") do
            word = self:toLower(word:match("^%s*(.-)%s*$"))
            if word ~= "" then
                table.insert(self.keywords, { word = word, country = country })
            end
        end
        i = i + 1
    end
    -- States / provinces of the profile files count as keywords for their country (and name the sub-region).
    i = 0
    while true do
        local key = string.format("insuranceRegions.subRegions.subRegion(%d)", i)
        local country = getXMLString(xmlId, key .. "#country")
        if country == nil then break end
        local name = self:toLower(getXMLString(xmlId, key .. "#name") or "")
        if name ~= "" then
            table.insert(self.keywords, { word = name, country = country, region = getXMLString(xmlId, key .. "#region") })
        end
        i = i + 1
    end

    -- Longest first: "northern ireland" must be tried before "ireland", "west virginia" before "virginia".
    table.sort(self.keywords, function(a, b) return #a.word > #b.word end)

    i = 0
    while true do
        local key = string.format("insuranceRegions.knownMaps.map(%d)", i)
        local mod = getXMLString(xmlId, key .. "#mod")
        if mod == nil then break end
        self.knownMaps[string.lower(mod)] = {
            country = getXMLString(xmlId, key .. "#country"),
            kind = getXMLString(xmlId, key .. "#kind") or "real",
            title = getXMLString(xmlId, key .. "#title") or mod,
        }
        i = i + 1
    end

    delete(xmlId)
    self.isLoaded = true

    if TornadoDebug then
        local numKnown = 0
        for _ in pairs(self.knownMaps) do numKnown = numKnown + 1 end
        TornadoDebug:info("REGION", string.format("V1.0 Loaded %d known maps, %d keywords", numKnown, #self.keywords))
    end
end

function TornadoRegion:deleteMap()
    self.cached = nil
    self.isLoaded = false
end

-- =========================================================================
-- TEXT HELPERS
-- =========================================================================

function TornadoRegion:toLower(text)
    if text == nil then return "" end
    if utf8ToLower ~= nil then
        return utf8ToLower(text)
    end
    return string.lower(text)
end

--- Letters, digits and every byte of a multi-byte UTF-8 letter count as "inside a word".
local function isWordByte(byte)
    return byte ~= nil and (byte >= 128 or (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122))
end

--- True if `word` appears in `haystack` as a whole word (both lower case).
function TornadoRegion:containsWord(haystack, word)
    local init = 1
    while true do
        local first, last = string.find(haystack, word, init, true)
        if first == nil then
            return false
        end
        if not isWordByte(string.byte(haystack, first - 1)) and not isWordByte(string.byte(haystack, last + 1)) then
            return true
        end
        init = first + 1
    end
end

--- Information about the current map: id, mod name, title, description and its environment file.
function TornadoRegion:getMapInfo()
    local info = { mapId = "", modName = "", title = "", description = "", environment = "" }
    if g_currentMission == nil or g_currentMission.missionInfo == nil then
        return info
    end
    local missionInfo = g_currentMission.missionInfo
    info.mapId = missionInfo.mapId or ""
    info.title = missionInfo.mapTitle or ""
    if g_mapManager ~= nil and g_mapManager.getMapById ~= nil then
        local map = g_mapManager:getMapById(info.mapId)
        if map ~= nil then
            info.modName = map.customEnvironment or ""
            if map.title ~= nil and map.title ~= info.title then
                info.title = info.title .. " " .. map.title
            end
            info.description = map.description or ""
        end
    end
    if g_currentMission.environment ~= nil and g_currentMission.environment.xmlFilename ~= nil then
        info.environment = g_currentMission.environment.xmlFilename
    end
    return info
end

--- The text searched for names: title + id + mod name (underscores as spaces); with the description if asked.
function TornadoRegion:getSearchText(withDescription)
    local info = self:getMapInfo()
    local text = info.title .. " " .. info.mapId .. " " .. string.gsub(info.modName, "_", " ")
    if withDescription then
        text = text .. " " .. info.description
    end
    return " " .. self:toLower(text) .. " "
end

--- Longest of the given names found in the map texts. names = { { id = "US_OK", name = "Oklahoma" }, ... }.
--- withDescription: also search the map description (more hits, but also more false ones).
function TornadoRegion:findLongestName(names, withDescription)
    local haystack = self:getSearchText(withDescription)
    local bestId, bestLength = nil, 0
    for _, entry in ipairs(names) do
        local name = self:toLower(entry.name)
        if #name > bestLength and self:containsWord(haystack, name) then
            bestId, bestLength = entry.id, #name
        end
    end
    return bestId
end

-- =========================================================================
-- DETECTION
-- =========================================================================

--- { country = "DE", region = nil / "US_OK", source = TornadoRegion.SOURCE_*, detail = "Nordkirchen" } for the
--- current map. region is only set when a state / province name was the matching keyword.
--- The map does not change during a session, so the result is cached.
function TornadoRegion:detect()
    if self.cached ~= nil then
        return self.cached
    end
    local info = self:getMapInfo()
    local result = nil

    -- 1. Known map (survey list), by the map's mod name.
    local known = self.knownMaps ~= nil and self.knownMaps[string.lower(info.modName)] or nil
    if known ~= nil and known.country ~= nil then
        result = { country = known.country, source = self.SOURCE_KNOWN_MAP, detail = known.title }
    end

    -- 2. Base-game map.
    if result == nil and self.baseMaps ~= nil and self.baseMaps[info.mapId] ~= nil then
        result = { country = self.baseMaps[info.mapId], source = self.SOURCE_BASE_MAP, detail = info.mapId }
    end

    -- 3. Keywords in title / id / mod name / description (list is sorted longest first).
    if result == nil and self.keywords ~= nil and #self.keywords > 0 then
        local haystack = self:getSearchText(true)
        for _, entry in ipairs(self.keywords) do
            if self:containsWord(haystack, entry.word) then
                result = { country = entry.country, region = entry.region, source = self.SOURCE_KEYWORDS, detail = entry.word }
                break
            end
        end
    end

    -- 4. The base-game climate the map reuses.
    if result == nil and self.environments ~= nil then
        local environment = string.lower(string.gsub(info.environment, "\\", "/"))
        for _, entry in ipairs(self.environments) do
            if string.find(environment, entry.path, 1, true) ~= nil then
                result = { country = entry.country, source = self.SOURCE_CLIMATE, detail = entry.path }
                break
            end
        end
    end

    -- 5. Default.
    if result == nil then
        result = { country = self.defaultCountry or "US", source = self.SOURCE_DEFAULT, detail = "" }
    end

    self.cached = result
    if TornadoDebug then
        TornadoDebug:info("REGION", string.format("Map '%s' (%s): country %s via %s (%s)",
            info.title, info.modName ~= "" and info.modName or info.mapId, tostring(result.country), result.source,
            tostring(result.detail)))
    end
    return result
end

--- Country -> the country whose data is used (itself if it has a profile, else its nearest rule, else default).
function TornadoRegion:getProfileCountry(country)
    local seen = {}
    while country ~= nil and not seen[country] do
        if self.profiles ~= nil and self.profiles[country] ~= nil then
            return country
        end
        seen[country] = true
        country = self.nearest ~= nil and self.nearest[country] or nil
    end
    return self.defaultCountry
end

--- Region id of a country's profile ("CA" -> "CAN", "DE" -> "DEU"), nil when unknown.
function TornadoRegion:getProfileRegion(country)
    local profile = self.profiles ~= nil and self.profiles[country] or nil
    return profile ~= nil and profile.region or nil
end

--- Display name of a country ("DE" -> "Germany"), the code itself when there is no profile.
function TornadoRegion:getCountryName(country)
    local profile = self.profiles ~= nil and self.profiles[country] or nil
    return profile ~= nil and profile.name or tostring(country)
end

--- One line for the console: "Germany via known map (Nordkirchen)".
function TornadoRegion:getStatusText()
    if not self.isLoaded then
        return "region data not loaded"
    end
    local result = self:detect()
    local profile = self:getProfileCountry(result.country)
    local text = string.format("%s via %s", self:getCountryName(result.country), result.source)
    if result.detail ~= nil and result.detail ~= "" then
        text = text .. " (" .. result.detail .. ")"
    end
    if profile ~= result.country then
        text = text .. " -> data: " .. self:getCountryName(profile)
    end
    return text
end
