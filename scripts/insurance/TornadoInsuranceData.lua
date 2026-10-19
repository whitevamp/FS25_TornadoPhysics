---@class TornadoInsuranceData
---@version 1.0
---@description Reads the crop insurance profile of the map's country (DB/CropInsurance_<country>.xml, built by
--- tools/build_crop_insurance.py) - the parts every profile shares: header, programme type, the region tree
--- (country -> states / provinces) and the crop list per region. Coverage curves (plan -> coverage level ->
--- rates; US, Canada, Brazil) are read too, with the fallback rules of docs/INSURANCE_DESIGN.md §9.3.
--- The other programme types (named perils, multi-risk, modules, peril groups, state schemes) keep their
--- own elements for the crop policy code (phase 2) - only their crop list is read here.
--- Plain data, no game state: works on every machine (clients show quotes too).

TornadoInsuranceData = {}

TornadoInsuranceData.DB_DIR = "DB/"
TornadoInsuranceData.PROGRAM_CURVES = "curves"     -- plan / level elements, no <program> (US, CA, BR)
TornadoInsuranceData.PROGRAM_SCHEMES = "schemes"   -- state schemes, no <program> (South-East Asia)
TornadoInsuranceData.DEFAULT_CROP = "DEFAULT"

-- Attributes read for the programme types other than coverage curves (phase 2b). The GIANTS XML functions cannot
-- list an element's attributes, so the names are spelled out.
local PROGRAM_NUMBERS = { "subsidyShare", "subsidy", "insuranceTax", "insurancePremiumTax", "gst", "threshold",
    "maxSubsidy", "rateCap", "hailPlusFactor", "multiPerilRate", "calibration" }
local PROGRAM_STRINGS = { "basePeril", "perils", "optionalPerils", "multiPeril", "insuranceTaxPerils" }
local RATE_KEYS = { "hail", "package", "namedPeril", "multiPeril", "multiRisk", "hailOnly", "hailPlus", "allRisk" }

local function readNumbers(xmlId, key, names, into)
    for _, name in ipairs(names) do
        local value = getXMLFloat(xmlId, key .. "#" .. name)
        if value ~= nil then
            into[name] = value
        end
    end
end

local function readStrings(xmlId, key, names, into)
    for _, name in ipairs(names) do
        local value = getXMLString(xmlId, key .. "#" .. name)
        if value ~= nil then
            into[name] = value
        end
    end
end

--- Repeated child elements: { { attr = value ... }, ... } with the given number / string attributes.
local function readList(xmlId, key, element, numbers, strings)
    local list = {}
    local i = 0
    while true do
        local itemKey = string.format("%s.%s(%d)", key, element, i)
        local present = false
        local item = {}
        for _, name in ipairs(numbers or {}) do
            local value = getXMLFloat(xmlId, itemKey .. "#" .. name)
            if value ~= nil then item[name] = value present = true end
        end
        for _, name in ipairs(strings or {}) do
            local value = getXMLString(xmlId, itemKey .. "#" .. name)
            if value ~= nil then item[name] = value present = true end
        end
        if not present then break end
        table.insert(list, item)
        i = i + 1
    end
    return list
end

--- The <program> element of named-peril / multi-risk / modules / peril-group files (nil for curves / schemes).
local function readProgram(xmlId)
    local key = "cropInsurance.program"
    if getXMLString(xmlId, key .. "#type") == nil then
        return nil
    end
    local program = {}
    readNumbers(xmlId, key, PROGRAM_NUMBERS, program)
    readStrings(xmlId, key, PROGRAM_STRINGS, program)
    program.deductibles = readList(xmlId, key, "deductible", { "share", "rateFactor" })
    program.franchises = readList(xmlId, key, "franchise", { "share", "rateFactor" })
    program.perilList = readList(xmlId, key, "peril", nil, { "id", "mandatory", "optional", "base" })
    program.packages = readList(xmlId, key, "package", nil, { "perils" })
    program.policyTypes = readList(xmlId, key, "policyType", { "subsidy", "rateFactor" }, { "id", "needs", "label" })
    program.modules = readList(xmlId, key, "module", { "subsidy", "rateFactor" }, { "id", "cover" })
    program.perilGroups = readList(xmlId, key, "perilGroup", nil, { "id", "perils" })
    program.rateCaps = {}
    for _, cap in ipairs(readList(xmlId, key, "rateCap", { "share" }, { "group" })) do
        program.rateCaps[cap.group] = cap.share
    end
    program.years = readList(xmlId, key, "year", { "share" }, { "id" })
    program.hailOnlyTax = getXMLFloat(xmlId, key .. ".hailOnly#insuranceTax")
    program.subsidyBase = getXMLFloat(xmlId, key .. ".subsidy#base")
    program.cerealBonus = getXMLFloat(xmlId, key .. ".bonuses#cereals")
    program.poolMaxShare = getXMLFloat(xmlId, key .. ".subsidyPool#maxShare")
    return program
end

--- Loads one profile file. Returns the profile table or nil (missing / broken file).
--- profile = { file, source, years, currency, programType,
---             regions = { id -> { id, name, parent, defaultChild, currency, curvesFrom, crops = { fillType -> crop } } },
---             regionOrder = { ids in file order }, rootId }
--- crop = { fillType, borrowedFrom, rateFactor, plans = { planId -> { id, levels = { {coverage, premiumRate, farmerRate,
---          subsidyShare}, ... sorted by coverage } } } }
function TornadoInsuranceData.load(path, fileName)
    if path == nil or not fileExists(path) then
        return nil
    end
    local xmlId = loadXMLFile("TornadoInsuranceData", path)
    if xmlId == nil or xmlId == 0 then
        return nil
    end
    local profile = {
        file = fileName,
        source = getXMLString(xmlId, "cropInsurance#source") or "",
        years = getXMLString(xmlId, "cropInsurance#years") or "",
        currency = getXMLString(xmlId, "cropInsurance#currency") or "",
        programType = getXMLString(xmlId, "cropInsurance.program#type"),
        program = readProgram(xmlId),
        regions = {},
        regionOrder = {},
        rootId = nil,
    }

    local hasPlans = false
    local r = 0
    while true do
        local regionKey = string.format("cropInsurance.region(%d)", r)
        local id = getXMLString(xmlId, regionKey .. "#id")
        if id == nil then break end
        local region = {
            id = id,
            name = getXMLString(xmlId, regionKey .. "#name") or id,
            parent = getXMLString(xmlId, regionKey .. "#parent"),
            defaultChild = getXMLString(xmlId, regionKey .. "#defaultChild"),
            currency = getXMLString(xmlId, regionKey .. "#currency"),
            curvesFrom = getXMLString(xmlId, regionKey .. "#curvesFrom"),
            rateFactor = getXMLFloat(xmlId, regionKey .. "#rateFactor"),
            stampDuty = getXMLFloat(xmlId, regionKey .. "#stampDuty"),
            cropStampDutyExempt = getXMLBool(xmlId, regionKey .. "#cropStampDutyExempt"),
            crops = {},
            numCrops = 0,
        }
        local schemeKey = regionKey .. ".scheme"
        if getXMLString(xmlId, schemeKey .. "#name") ~= nil then
            region.scheme = { name = getXMLString(xmlId, schemeKey .. "#name"), perils = getXMLString(xmlId, schemeKey .. "#perils"),
                rate = getXMLFloat(xmlId, schemeKey .. "#rate"), subsidy = getXMLFloat(xmlId, schemeKey .. "#subsidy"),
                damageThreshold = getXMLFloat(xmlId, schemeKey .. "#damageThreshold"),
                sumInsuredPerHa = getXMLFloat(xmlId, schemeKey .. "#sumInsuredPerHaSeason") }
        end
        local c = 0
        while true do
            local cropKey = string.format("%s.crop(%d)", regionKey, c)
            local fillType = getXMLString(xmlId, cropKey .. "#fillType")
            if fillType == nil then break end
            local crop = {
                fillType = fillType,
                borrowedFrom = getXMLString(xmlId, cropKey .. "#borrowedFrom"),
                rateFactor = getXMLFloat(xmlId, cropKey .. "#rateFactor"),
                plans = {},
                group = getXMLString(xmlId, cropKey .. "#group"),
                capGroup = getXMLString(xmlId, cropKey .. "#capGroup"),
                cerealBonus = getXMLBool(xmlId, cropKey .. "#cerealBonus"),
                noStateScheme = getXMLBool(xmlId, cropKey .. "#noStateScheme"),
                sumPerHa = getXMLFloat(xmlId, cropKey .. "#sumPerHa") or getXMLFloat(xmlId, cropKey .. "#maxSumPerHa"),
                rates = nil,
                addOns = nil,
                modules = nil,
            }
            local ratesKey = cropKey .. ".rates"
            for _, name in ipairs(RATE_KEYS) do
                local value = getXMLFloat(xmlId, ratesKey .. "#" .. name)
                if value ~= nil then
                    crop.rates = crop.rates or {}
                    crop.rates[name] = value
                end
            end
            for _, addOn in ipairs(readList(xmlId, cropKey, "addOn", { "rate" }, { "peril" })) do
                crop.addOns = crop.addOns or {}
                crop.addOns[addOn.peril] = addOn.rate
            end
            for _, module in ipairs(readList(xmlId, cropKey, "module", { "rate", "baseSubsidy" }, { "id" })) do
                crop.modules = crop.modules or {}
                crop.modules[module.id] = module
            end
            local p = 0
            while true do
                local planKey = string.format("%s.plan(%d)", cropKey, p)
                local planId = getXMLString(xmlId, planKey .. "#id")
                if planId == nil then break end
                local plan = { id = planId, levels = {} }
                local l = 0
                while true do
                    local levelKey = string.format("%s.level(%d)", planKey, l)
                    local coverage = getXMLFloat(xmlId, levelKey .. "#coverage")
                    if coverage == nil then break end
                    table.insert(plan.levels, {
                        coverage = coverage,
                        premiumRate = getXMLFloat(xmlId, levelKey .. "#premiumRate") or 0,
                        farmerRate = getXMLFloat(xmlId, levelKey .. "#farmerRate") or 0,
                        subsidyShare = getXMLFloat(xmlId, levelKey .. "#subsidyShare") or 0,
                    })
                    l = l + 1
                end
                table.sort(plan.levels, function(a, b) return a.coverage < b.coverage end)
                if #plan.levels > 0 then
                    crop.plans[planId] = plan
                    hasPlans = true
                end
                p = p + 1
            end
            region.crops[fillType] = crop
            region.numCrops = region.numCrops + 1
            c = c + 1
        end
        -- Livestock cover per animal type (so far only the Polish data has it): rate per year, sum cap per head.
        region.animals = {}
        for _, animal in ipairs(readList(xmlId, regionKey, "animal", { "rate", "maxSumPerHead" }, { "type" })) do
            if animal.type ~= nil then
                region.animals[string.upper(animal.type)] = animal
            end
        end
        profile.regions[id] = region
        table.insert(profile.regionOrder, id)
        if profile.rootId == nil and region.parent == nil then
            profile.rootId = id
        end
        r = r + 1
    end
    delete(xmlId)

    if profile.rootId == nil then
        return nil
    end
    if profile.programType == nil then
        profile.programType = hasPlans and TornadoInsuranceData.PROGRAM_CURVES or TornadoInsuranceData.PROGRAM_SCHEMES
    end
    return profile
end

--- The region and its parents, nearest first ("US_KS" -> { US_KS, US }). Unknown / no region: the root, or
--- the root's defaultChild when the root is only a container (South-East Asia -> Indonesia).
--- Livestock cover of an animal type ({ type, rate, maxSumPerHead }) from the region chain, or nil.
function TornadoInsuranceData.getAnimal(profile, regionId, animalType)
    if profile == nil or animalType == nil then
        return nil
    end
    for _, region in ipairs(TornadoInsuranceData.getRegionChain(profile, regionId)) do
        local animal = region.animals ~= nil and region.animals[string.upper(animalType)] or nil
        if animal ~= nil then
            return animal
        end
    end
    return nil
end

function TornadoInsuranceData.getRegionChain(profile, regionId)
    local chain = {}
    local seen = {}
    local id = regionId
    if profile == nil or profile.regions[id] == nil then
        id = profile ~= nil and profile.rootId or nil
        local root = id ~= nil and profile.regions[id] or nil
        if root ~= nil and root.defaultChild ~= nil and profile.regions[root.defaultChild] ~= nil then
            id = root.defaultChild
        end
    end
    while id ~= nil and not seen[id] and profile.regions[id] ~= nil do
        seen[id] = true
        table.insert(chain, profile.regions[id])
        id = profile.regions[id].parent
    end
    return chain
end

--- The crop entry the data has for a fill type in a region: own entry, else a parent's; borrowedFrom followed
--- (max 3 steps). Returns crop, region it was found in (or nil, nil).
function TornadoInsuranceData.findCrop(profile, regionId, fillType)
    local chain = TornadoInsuranceData.getRegionChain(profile, regionId)
    local wanted = fillType
    for _ = 1, 3 do
        local found, foundIn = nil, nil
        for _, region in ipairs(chain) do
            if region.crops[wanted] ~= nil then
                found, foundIn = region.crops[wanted], region
                break
            end
        end
        if found == nil then
            return nil, nil
        end
        if found.borrowedFrom == nil or found.borrowedFrom == wanted then
            return found, foundIn
        end
        wanted = found.borrowedFrom
    end
    return nil, nil
end

--- Coverage curve of a crop and plan (curve profiles only), following §9.3:
---   crop has the plan -> its curve; plan missing for the crop -> nil (plan not offered);
---   crop missing (or no plans at all) -> the DEFAULT crop's curve; borrowedFrom crops -> the named crop.
--- State / province entries usually carry only a rateFactor: the curve is searched up the region chain.
--- Returns plan (with levels) or nil.
function TornadoInsuranceData.getCurve(profile, regionId, fillType, planId)
    if profile == nil then
        return nil
    end
    local chain = TornadoInsuranceData.getRegionChain(profile, regionId)
    local function curveFor(name)
        local wanted = name
        for _ = 1, 3 do
            local crop = nil
            for _, region in ipairs(chain) do
                local entry = region.crops[wanted]
                if entry ~= nil and (next(entry.plans) ~= nil or entry.borrowedFrom ~= nil) then
                    crop = entry
                    break
                end
            end
            if crop == nil then
                return nil, false
            end
            if next(crop.plans) ~= nil then
                return crop.plans[planId], true
            end
            wanted = crop.borrowedFrom
        end
        return nil, false
    end
    local plan, cropHasCurves = curveFor(fillType)
    if cropHasCurves then
        return plan
    end
    plan = curveFor(TornadoInsuranceData.DEFAULT_CROP)
    return plan
end

--- Plan ids offered for a crop (curve profiles), sorted; the DEFAULT crop's plans for unknown crops.
function TornadoInsuranceData.getPlanIds(profile, regionId, fillType)
    local ids = {}
    if profile == nil then
        return ids
    end
    local chain = TornadoInsuranceData.getRegionChain(profile, regionId)
    for _, name in ipairs({ fillType, TornadoInsuranceData.DEFAULT_CROP }) do
        local wanted = name
        for _ = 1, 3 do
            local crop = nil
            for _, region in ipairs(chain) do
                local entry = region.crops[wanted]
                if entry ~= nil and (next(entry.plans) ~= nil or entry.borrowedFrom ~= nil) then
                    crop = entry
                    break
                end
            end
            if crop == nil then
                break
            end
            if next(crop.plans) ~= nil then
                for id in pairs(crop.plans) do
                    table.insert(ids, id)
                end
                table.sort(ids)
                return ids
            end
            wanted = crop.borrowedFrom
        end
    end
    return ids
end

--- The level of a curve for a coverage (exact match within 0.001), nil when that level is not offered.
function TornadoInsuranceData.getLevel(plan, coverage)
    if plan == nil or coverage == nil then
        return nil
    end
    for _, level in ipairs(plan.levels) do
        if math.abs(level.coverage - coverage) < 0.001 then
            return level
        end
    end
    return nil
end

--- How much more (or less) cover costs in this state / province than in the whole country (1.0 when unknown):
--- the nearest rateFactor of the crop in the region chain.
function TornadoInsuranceData.getRateFactor(profile, regionId, fillType)
    for _, region in ipairs(TornadoInsuranceData.getRegionChain(profile, regionId)) do
        local crop = region.crops[fillType]
        if crop ~= nil and crop.rateFactor ~= nil then
            return crop.rateFactor
        end
    end
    return 1.0
end

--- Number of crops listed in a region (the root region when regionId is unknown).
function TornadoInsuranceData.getNumCrops(profile, regionId)
    local chain = TornadoInsuranceData.getRegionChain(profile, regionId)
    return chain[1] ~= nil and chain[1].numCrops or 0
end
