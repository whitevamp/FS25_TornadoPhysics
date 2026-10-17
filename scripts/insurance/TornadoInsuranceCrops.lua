---@class TornadoInsuranceCrops
---@version 1.0
---@description Which insurance data a crop uses. Map mods bring their own crops (rye, spelt, triticale, winter
--- wheat, alfalfa ...) and players can plant any crop on any map, but the insurance data only knows the
--- base-game crops of each country. Every crop of the loaded map (g_fruitTypeManager) is cross-referenced with
--- DB/InsuranceCropAliases.xml (docs/INSURANCE_DESIGN.md §6.4):
---   1. the country's data has the crop          -> "data"
---   2. alias (same crop / close relative)        -> "alias"    (SPELT -> WHEAT, BEETROOT -> REDBEET)
---   3. name without a prefix exists              -> "prefix"   (WINTERWHEAT -> WHEAT)
---   4. the game's machine group of the crop      -> "category" (GRAINHEADER -> WHEAT)
---   5. all field crops                           -> "default"
---   cover crops / green manure / decoration      -> not insurable
--- "isLocal": the crop (or its alias) is listed for the region in use - the nearest region of the chain that
--- lists crops at all (a US state lists the crops it really insures, a country lists its programme). A crop
--- that is not local is an "unusual crop for this region" (surcharge / coverage cap / refused - phase 2 setting).
--- The resolver itself is pure (resolve) so it can be tested offline; scanMap reads the game.

TornadoInsuranceCrops = {}

TornadoInsuranceCrops.FILE = "DB/InsuranceCropAliases.xml"

TornadoInsuranceCrops.METHOD_DATA = "data"
TornadoInsuranceCrops.METHOD_ALIAS = "alias"
TornadoInsuranceCrops.METHOD_PREFIX = "prefix"
TornadoInsuranceCrops.METHOD_CATEGORY = "category"
TornadoInsuranceCrops.METHOD_DEFAULT = "default"
TornadoInsuranceCrops.METHOD_NOT_INSURABLE = "notInsurable"

--- Reads the cross-reference. Returns { aliases = {name -> {ratedAs, note}}, prefixes = {..},
--- categories = { {name, ratedAs}, ... in file order }, notInsurable = {name -> note} } (empty lists when missing).
function TornadoInsuranceCrops.loadAliases(path)
    local data = { aliases = {}, prefixes = {}, categories = {}, notInsurable = {} }
    if path == nil or not fileExists(path) then
        return data
    end
    local xmlId = loadXMLFile("TornadoInsuranceCrops", path)
    if xmlId == nil or xmlId == 0 then
        return data
    end
    local i = 0
    while true do
        local key = string.format("insuranceCropAliases.alias(%d)", i)
        local name = getXMLString(xmlId, key .. "#fillType")
        if name == nil then break end
        data.aliases[string.upper(name)] = { ratedAs = string.upper(getXMLString(xmlId, key .. "#ratedAs") or ""),
            note = getXMLString(xmlId, key .. "#note") }
        i = i + 1
    end
    i = 0
    while true do
        local value = getXMLString(xmlId, string.format("insuranceCropAliases.prefix(%d)#value", i))
        if value == nil then break end
        table.insert(data.prefixes, string.upper(value))
        i = i + 1
    end
    i = 0
    while true do
        local key = string.format("insuranceCropAliases.category(%d)", i)
        local name = getXMLString(xmlId, key .. "#name")
        if name == nil then break end
        table.insert(data.categories, { name = string.upper(name), ratedAs = string.upper(getXMLString(xmlId, key .. "#ratedAs") or "") })
        i = i + 1
    end
    i = 0
    while true do
        local key = string.format("insuranceCropAliases.notInsurable(%d)", i)
        local name = getXMLString(xmlId, key .. "#fillType")
        if name == nil then break end
        data.notInsurable[string.upper(name)] = getXMLString(xmlId, key .. "#note") or ""
        i = i + 1
    end
    delete(xmlId)
    return data
end

--- Is the crop listed anywhere in the region chain (the country's programme)?
local function isListed(chain, name)
    for _, region in ipairs(chain) do
        if region.crops[name] ~= nil then
            return true
        end
    end
    return false
end

--- Is the crop listed in the nearest region of the chain that lists crops at all?
local function isListedLocally(chain, name)
    for _, region in ipairs(chain) do
        if region.numCrops > 0 then
            return region.crops[name] ~= nil
        end
    end
    return false
end

--- Pure resolver. name = fill type name of the crop; categories = { [CATEGORY] = true } of the crop (may be nil).
--- Returns { fillType, ratedAs, method, insurable, isLocal, note }.
function TornadoInsuranceCrops.resolve(aliasData, profile, regionId, name, categories)
    name = string.upper(name or "")
    local result = { fillType = name, ratedAs = nil, method = nil, insurable = true, isLocal = false, note = nil }
    aliasData = aliasData or { aliases = {}, prefixes = {}, categories = {}, notInsurable = {} }

    if aliasData.notInsurable[name] ~= nil then
        result.method = TornadoInsuranceCrops.METHOD_NOT_INSURABLE
        result.insurable = false
        result.note = aliasData.notInsurable[name]
        return result
    end
    local chain = profile ~= nil and TornadoInsuranceData.getRegionChain(profile, regionId) or {}

    if isListed(chain, name) then
        result.ratedAs, result.method = name, TornadoInsuranceCrops.METHOD_DATA
    end
    if result.method == nil then
        local alias = aliasData.aliases[name]
        if alias ~= nil and alias.ratedAs ~= "" and isListed(chain, alias.ratedAs) then
            result.ratedAs, result.method, result.note = alias.ratedAs, TornadoInsuranceCrops.METHOD_ALIAS, alias.note
        end
    end
    if result.method == nil then
        for _, prefix in ipairs(aliasData.prefixes) do
            if #name > #prefix and string.sub(name, 1, #prefix) == prefix then
                local rest = string.sub(name, #prefix + 1)
                local target = isListed(chain, rest) and rest or nil
                if target == nil and aliasData.aliases[rest] ~= nil and isListed(chain, aliasData.aliases[rest].ratedAs) then
                    target = aliasData.aliases[rest].ratedAs   -- WINTERSPELT -> SPELT -> WHEAT
                end
                if target ~= nil then
                    result.ratedAs, result.method = target, TornadoInsuranceCrops.METHOD_PREFIX
                    break
                end
            end
        end
    end
    if result.method == nil and categories ~= nil then
        for _, category in ipairs(aliasData.categories) do
            if categories[category.name] and isListed(chain, category.ratedAs) then
                result.ratedAs, result.method, result.note = category.ratedAs, TornadoInsuranceCrops.METHOD_CATEGORY, category.name
                break
            end
        end
    end
    if result.method == nil then
        result.ratedAs, result.method = TornadoInsuranceData.DEFAULT_CROP, TornadoInsuranceCrops.METHOD_DEFAULT
    end

    -- A best guess (machine group / all crops) is never "local"; same crop under another name can be.
    local exactish = result.method == TornadoInsuranceCrops.METHOD_DATA or result.method == TornadoInsuranceCrops.METHOD_ALIAS
        or result.method == TornadoInsuranceCrops.METHOD_PREFIX
    result.isLocal = exactish and isListedLocally(chain, result.ratedAs)
    return result
end

-- =========================================================================
-- RUNTIME (game)
-- =========================================================================

function TornadoInsuranceCrops:loadMap(modDir)
    local path = modDir ~= nil and Utils.getFilename(self.FILE, modDir) or nil
    self.aliasData = self.loadAliases(path)
    self.mapCrops = nil   -- built on first use (fruit types are complete after the map loaded)
    self.cache = {}
    self.cacheKey = nil
end

function TornadoInsuranceCrops:deleteMap()
    self.mapCrops = nil
    self.cache = {}
    self.cacheKey = nil
end

--- The crops of the loaded map: { { fillType = "SPELT", categories = { GRAINHEADER = true } }, ... }.
function TornadoInsuranceCrops:scanMap()
    if self.mapCrops ~= nil then
        return self.mapCrops
    end
    local crops = {}
    local manager = g_fruitTypeManager
    if manager == nil then
        return crops
    end
    -- Category membership: every category this file names, asked from the game.
    local membership = {}
    for _, category in ipairs((self.aliasData or {}).categories or {}) do
        if manager.categories ~= nil and manager.categories[category.name] ~= nil then
            for _, fruitType in ipairs(manager:getFruitTypesByCategoryNames(category.name)) do
                membership[fruitType.index] = membership[fruitType.index] or {}
                membership[fruitType.index][category.name] = true
            end
        end
    end
    for _, fruitType in ipairs(manager:getFruitTypes()) do
        local fillTypeName = manager:getFillTypeNameByFruitTypeIndex(fruitType.index)
        if fillTypeName ~= nil then
            table.insert(crops, { fillType = string.upper(fillTypeName), categories = membership[fruitType.index] or {} })
        end
    end
    table.sort(crops, function(a, b) return a.fillType < b.fillType end)
    self.mapCrops = crops
    return crops
end

--- Insurance info of a crop for the profile / region in use (cached until the region changes).
function TornadoInsuranceCrops:getCropInfo(fillTypeName)
    if TornadoInsurance == nil then
        return nil
    end
    local profile, regionId = TornadoInsurance:getProfile()
    local key = (profile ~= nil and profile.file or "-") .. "|" .. tostring(regionId)
    if key ~= self.cacheKey then
        self.cache = {}
        self.cacheKey = key
    end
    local name = string.upper(fillTypeName or "")
    if self.cache[name] == nil then
        local categories = nil
        for _, crop in ipairs(self:scanMap()) do
            if crop.fillType == name then
                categories = crop.categories
                break
            end
        end
        self.cache[name] = self.resolve(self.aliasData, profile, regionId, name, categories)
    end
    return self.cache[name]
end

--- Console table: every crop of the map and how the insurance rates it.
function TornadoInsuranceCrops:printMapCrops()
    local crops = self:scanMap()
    print("---------------- INSURANCE: CROPS OF THIS MAP ----------------")
    print("  region: " .. (TornadoInsurance ~= nil and TornadoInsurance:getRegionName() or "?"))
    local counts = {}
    for _, crop in ipairs(crops) do
        local info = self:getCropInfo(crop.fillType)
        counts[info.method] = (counts[info.method] or 0) + 1
        local rated = info.insurable and (info.ratedAs == crop.fillType and "own data" or ("rated as " .. info.ratedAs)) or "not insurable"
        print(string.format("  %-20s %-22s %-12s %s%s", crop.fillType, rated, info.method,
            info.insurable and (info.isLocal and "local" or "UNUSUAL for region") or "",
            info.note ~= nil and info.note ~= "" and ("  (" .. info.note .. ")") or ""))
    end
    print("--------------------------------------------------------------")
    local parts = {}
    for _, method in ipairs({ "data", "alias", "prefix", "category", "default", "notInsurable" }) do
        if counts[method] ~= nil then
            table.insert(parts, method .. " " .. counts[method])
        end
    end
    return string.format("Insurance: %d crops on this map (%s).", #crops, table.concat(parts, ", "))
end
