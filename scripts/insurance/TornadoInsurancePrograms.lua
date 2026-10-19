---@class TornadoInsurancePrograms
---@version 1.0 (insurance phase 2b)
---@description Turns the non-curve insurance programmes of DB/CropInsurance_*.xml into cover options the crop
--- policy (TornadoInsuranceCrop) can sell - the same shape for every country (docs/INSURANCE_DESIGN.md §18.4):
---   option = { plan id, causes it pays for, coverage levels (100 % minus the deductible) with their rate factor,
---              rule "deductible" (pays the loss beyond the uninsured part) or "threshold" (pays the whole loss once
---              it reaches the damage threshold) }
---   terms  = option + the farmer-paid rate per year of the sum insured for one crop (after subsidy, taxes added)
---            + the real-world sum insured per hectare (converted to game money) for the "real values" setting.
--- Programmes:
---   namedPeril (DE, PL, GB, AU, AR, CL) - hail, hail + storm / rain, package, hail plus, named perils, multi-peril
---   multiRisk  (FR, NL)                 - multi-risk (franchise / threshold) and unsubsidised hail-only
---   modules    (ES)                     - module 1 (whole farm, catastrophic), 2 (all risks), P (named perils)
---   perilGroups (IT)                    - policy types a, b, c, c2, d, SMART
---   schemes    (South-East Asia)        - the state rice scheme (pays from the damage threshold)
--- Country perils are mapped to the game's damage causes (TornadoInsuranceDamage): hail, windstorm -> TORNADO,
--- heavy rain / flood -> FLOOD, drought, fire / lightning -> FIRE; frost, snow, pests ... have no cause in the game.
--- Deductibles the data does not give are estimates (decided 2026-10-17): ES module 1 30 %, 2 20 %, P 10 %;
--- IT the 20 % damage threshold; GB / AU / AR / CL none. State disaster funds (France ISN, Italy AgriCat), the Dutch
--- pool cut, Poland's obligation fee, Spain's extra subsidies and the provincial schemes are not modelled yet.

TornadoInsurancePrograms = {}

TornadoInsurancePrograms.ALL_CAUSES = { TORNADO = true, HAIL = true, DROUGHT = true, FLOOD = true, FIRE = true }

TornadoInsurancePrograms.PERIL_CAUSES = {
    HAIL = "HAIL",
    WINDSTORM = "TORNADO", STORM = "TORNADO", WHIRLWIND = "TORNADO",
    HEAVY_RAIN = "FLOOD", TORRENTIAL_RAIN = "FLOOD", FLOOD = "FLOOD", EXCESS_WATER = "FLOOD",
    DROUGHT = "DROUGHT",
    FIRE = "FIRE", LIGHTNING = "FIRE", LIGHTNING_FIRE = "FIRE",
}

-- Display order of the options (first = default choice in the menu).
TornadoInsurancePrograms.ORDER = { "PACKAGE", "PACKAGE_WIND", "MRC", "MOD2", "IT_A", "STATE", "NAMED", "MULTI",
    "HAIL_STORM", "HAIL_PLUS", "HAIL", "HAIL_ONLY", "MOD1", "MODP", "IT_B", "IT_C", "IT_C2", "IT_D", "IT_F" }

-- Spain: deductible per module (estimates).
TornadoInsurancePrograms.ES_MODULE_COVERAGE = { ["1"] = 0.70, ["2"] = 0.80, P = 0.90 }
TornadoInsurancePrograms.ES_MODULE_CAUSES = { ["1"] = "ALL", ["2"] = "ALL", P = "HAIL FIRE" }

-- Italy: what each policy type pays for (peril groups mapped to game causes).
TornadoInsurancePrograms.IT_TYPE_CAUSES = { a = "HAIL TORNADO FLOOD DROUGHT", b = "HAIL TORNADO FLOOD DROUGHT",
    c = "HAIL TORNADO FLOOD", c2 = "HAIL TORNADO", d = "FLOOD DROUGHT", f = "HAIL TORNADO FLOOD DROUGHT" }

-- Real-world sums -> game money (game money taken as euros; approximate 2026 rates, display-level accuracy).
TornadoInsurancePrograms.TO_GAME_MONEY = { EUR = 1.0, USD = 0.92, GBP = 1.17, AUD = 0.60, CAD = 0.68, BRL = 0.17,
    CLF = 38.0, IDR = 0.000056, MYR = 0.20 }

local P = TornadoInsurancePrograms

--- "HAIL WINDSTORM ..." (or "ALL") -> { HAIL = true, TORNADO = true }.
function TornadoInsurancePrograms.causesFrom(perils)
    local causes = {}
    if perils == "ALL" then
        for cause in pairs(P.ALL_CAUSES) do causes[cause] = true end
        return causes
    end
    for peril in string.gmatch(perils or "", "%S+") do
        local cause = P.PERIL_CAUSES[peril] or (P.ALL_CAUSES[peril] and peril or nil)
        if cause ~= nil then
            causes[cause] = true
        end
    end
    return causes
end

--- Sorted cause list for the console: "DROUGHT FLOOD HAIL".
function TornadoInsurancePrograms.causesText(causes)
    local list = {}
    for cause in pairs(causes or {}) do table.insert(list, cause) end
    table.sort(list)
    return table.concat(list, " ")
end

--- The data entry that carries the rates for a crop: its own, a parent region's, borrowedFrom followed, else DEFAULT.
function TornadoInsurancePrograms.findRatedCrop(profile, regionId, name)
    local crop = TornadoInsuranceData.findCrop(profile, regionId, name)
    if crop ~= nil and (crop.rates ~= nil or crop.modules ~= nil or profile.programType == TornadoInsuranceData.PROGRAM_SCHEMES) then
        return crop
    end
    return TornadoInsuranceData.findCrop(profile, regionId, TornadoInsuranceData.DEFAULT_CROP)
end

--- The crop's own entry (no borrowedFrom) says "no state scheme" (South-East Asia: every crop but rice).
function TornadoInsurancePrograms.hasNoStateScheme(profile, regionId, name)
    for _, region in ipairs(TornadoInsuranceData.getRegionChain(profile, regionId)) do
        local own = region.crops[name or ""]
        if own ~= nil then
            return own.noStateScheme == true
        end
    end
    -- Not listed at all: rated as DEFAULT, which says it for South-East Asia.
    local default = TornadoInsuranceData.findCrop(profile, regionId, TornadoInsuranceData.DEFAULT_CROP)
    return profile.programType == TornadoInsuranceData.PROGRAM_SCHEMES and default ~= nil
end

local function firstInChain(profile, regionId, field)
    for _, region in ipairs(TornadoInsuranceData.getRegionChain(profile, regionId)) do
        if region[field] ~= nil then
            return region[field], region
        end
    end
    return nil, nil
end

local function getScheme(profile, regionId)
    local scheme = firstInChain(profile, regionId, "scheme")
    return scheme
end

--- The data's own sum insured per hectare in game money (nil when the data has none).
local function getRealValuePerHa(profile, regionId, crop, scheme)
    local sum = crop ~= nil and crop.sumPerHa or nil
    local currency = profile.currency
    if sum == nil and scheme ~= nil then
        sum = scheme.sumInsuredPerHa
        currency = select(1, firstInChain(profile, regionId, "currency")) or currency
    end
    local factor = P.TO_GAME_MONEY[currency or ""]
    if sum == nil or factor == nil then
        return nil
    end
    return sum * factor
end

-- =========================================================================
-- OPTIONS PER PROGRAMME: list of { id, rate, causes, levels = { {coverage, rateFactor} }, rule, threshold }
-- for one crop data entry (rate before subsidy / taxes).
-- =========================================================================

local function deductibleLevels(program)
    local levels = {}
    local list = program ~= nil and (#program.deductibles > 0 and program.deductibles or program.franchises) or {}
    for _, entry in ipairs(list) do
        table.insert(levels, { coverage = 1 - (entry.share or 0), rateFactor = entry.rateFactor or 1 })
    end
    if #levels == 0 then
        local threshold = program ~= nil and program.threshold or nil
        table.insert(levels, { coverage = 1 - (threshold or 0), rateFactor = 1 })
    end
    table.sort(levels, function(a, b) return a.coverage < b.coverage end)
    return levels
end

local function namedPerilOptions(profile, crop)
    local program = profile.program or {}
    local rates = crop.rates or {}
    local addOns = crop.addOns or {}
    local levels = deductibleLevels(program)
    local options = {}
    if rates.hail ~= nil then
        table.insert(options, { id = "HAIL", rate = rates.hail, causes = P.causesFrom("HAIL"), levels = levels })
        if addOns.WINDSTORM ~= nil and addOns.HEAVY_RAIN ~= nil then
            table.insert(options, { id = "HAIL_STORM", rate = rates.hail + addOns.WINDSTORM + addOns.HEAVY_RAIN
                + (addOns.SEVERE_FROST or 0), causes = P.causesFrom("HAIL WINDSTORM HEAVY_RAIN"), levels = levels })
        end
    end
    if rates.package ~= nil then
        local perils = program.packages ~= nil and program.packages[1] ~= nil and program.packages[1].perils or nil
        if perils == nil then
            local mandatory = {}
            for _, peril in ipairs(program.perilList or {}) do
                if peril.mandatory == "true" then table.insert(mandatory, peril.id) end
            end
            perils = table.concat(mandatory, " ")
        end
        local causes = P.causesFrom(perils)
        table.insert(options, { id = "PACKAGE", rate = rates.package, causes = causes, levels = levels })
        if addOns.WINDSTORM ~= nil and not causes.TORNADO then
            local windCauses = P.causesFrom(perils .. " WINDSTORM")
            table.insert(options, { id = "PACKAGE_WIND", rate = rates.package + addOns.WINDSTORM, causes = windCauses, levels = levels })
        end
    end
    if rates.hailPlus ~= nil then
        table.insert(options, { id = "HAIL_PLUS", rate = rates.hailPlus, causes = P.causesFrom("HAIL WINDSTORM FIRE"), levels = levels })
    end
    if rates.namedPeril ~= nil then
        table.insert(options, { id = "NAMED", rate = rates.namedPeril, causes = P.causesFrom(program.perils or "HAIL FIRE"), levels = levels })
    end
    local multi = rates.multiPeril or program.multiPerilRate
    if multi ~= nil then
        table.insert(options, { id = "MULTI", rate = multi, causes = P.causesFrom("ALL"), levels = levels })
    end
    return options
end

local function multiRiskOptions(profile, crop)
    local program = profile.program or {}
    local rates = crop.rates or {}
    local options = {}
    if rates.multiRisk ~= nil then
        table.insert(options, { id = "MRC", rate = rates.multiRisk, levels = deductibleLevels(program),
            causes = P.causesFrom(program.perils or "HAIL WINDSTORM FLOOD DROUGHT") })
    end
    if rates.hailOnly ~= nil then
        table.insert(options, { id = "HAIL_ONLY", rate = rates.hailOnly, causes = P.causesFrom("HAIL"),
            levels = { { coverage = 1.0, rateFactor = 1 } } })
    end
    return options
end

local function moduleOptions(profile, crop)
    local options = {}
    for id, module in pairs(crop.modules or {}) do
        local coverage = P.ES_MODULE_COVERAGE[id]
        if coverage ~= nil then
            table.insert(options, { id = "MOD" .. id, rate = module.rate or 0, baseSubsidy = module.baseSubsidy,
                causes = P.causesFrom(P.ES_MODULE_CAUSES[id]), levels = { { coverage = coverage, rateFactor = 1 } } })
        end
    end
    return options
end

local function perilGroupOptions(profile, crop)
    local program = profile.program or {}
    local allRisk = crop.rates ~= nil and crop.rates.allRisk or nil
    local options = {}
    if allRisk == nil then
        return options
    end
    local coverage = 1 - (program.threshold or 0.2)
    for _, policyType in ipairs(program.policyTypes or {}) do
        local causes = P.IT_TYPE_CAUSES[policyType.id]
        if causes ~= nil then
            table.insert(options, { id = "IT_" .. string.upper(policyType.id), rate = allRisk * (policyType.rateFactor or 1),
                typeSubsidy = policyType.subsidy, causes = P.causesFrom(causes), levels = { { coverage = coverage, rateFactor = 1 } } })
        end
    end
    return options
end

local function schemeOptions(profile, regionId)
    local scheme = getScheme(profile, regionId)
    if scheme == nil or scheme.rate == nil then
        return {}
    end
    return { { id = "STATE", rate = scheme.rate, schemeSubsidy = scheme.subsidy, causes = P.causesFrom(scheme.perils),
        rule = "threshold", threshold = scheme.damageThreshold or 0.75, levels = { { coverage = 1.0, rateFactor = 1 } } } }
end

--- Raw options for one crop data entry (rates before subsidy / taxes).
function TornadoInsurancePrograms.getCropOptions(profile, regionId, crop)
    local programType = profile.programType
    if programType == "namedPeril" then
        return namedPerilOptions(profile, crop)
    elseif programType == "multiRisk" then
        return multiRiskOptions(profile, crop)
    elseif programType == "modules" then
        return moduleOptions(profile, crop)
    elseif programType == "perilGroups" then
        return perilGroupOptions(profile, crop)
    elseif programType == TornadoInsuranceData.PROGRAM_SCHEMES then
        return schemeOptions(profile, regionId)
    end
    return {}
end

-- =========================================================================
-- FARMER-PAID RATE: subsidy, caps, taxes, regional factors
-- =========================================================================

--- Rate the farmer pays per year of the sum insured for a raw option (and the chosen level's rate factor).
function TornadoInsurancePrograms.getFarmerRate(profile, regionId, crop, option, levelRateFactor)
    local program = profile.program or {}
    local rate = option.rate * (levelRateFactor or 1)

    -- Subsidy
    local subsidy = 0
    if option.id == "HAIL_ONLY" then
        subsidy = 0                                            -- hail-only cover is never subsidised (FR, NL)
    elseif option.schemeSubsidy ~= nil then
        subsidy = option.schemeSubsidy
    elseif option.typeSubsidy ~= nil then
        subsidy = option.typeSubsidy
    elseif option.baseSubsidy ~= nil then
        subsidy = math.min(option.baseSubsidy, program.maxSubsidy or 1)
    elseif program.subsidyBase ~= nil then
        subsidy = program.subsidyBase + ((crop.cerealBonus and program.cerealBonus) or 0)
    elseif program.subsidyShare ~= nil then
        subsidy = program.subsidyShare
    elseif program.years ~= nil and #program.years > 0 then
        subsidy = program.years[#program.years].share or program.poolMaxShare or 0   -- NL: the latest pool share
    end
    -- Subsidy only up to a rate cap (PL per crop group, ES 20 %).
    local cap = (crop.capGroup ~= nil and program.rateCaps ~= nil and program.rateCaps[crop.capGroup]) or program.rateCap
    local subsidised = cap ~= nil and math.min(rate, cap) or rate
    rate = rate - subsidised * math.max(0, math.min(1, subsidy))

    -- Taxes
    if program.insuranceTax ~= nil and option.id ~= "HAIL_ONLY" then
        rate = rate + program.insuranceTax                     -- DE: share of the sum insured
    end
    if option.id == "HAIL_ONLY" and program.hailOnlyTax ~= nil then
        rate = rate * (1 + program.hailOnlyTax)                -- NL: 21 % on unsubsidised hail cover
    end
    if program.insurancePremiumTax ~= nil then
        rate = rate * (1 + program.insurancePremiumTax)        -- GB IPT 12 %
    end
    if program.gst ~= nil then
        local duty, region = firstInChain(profile, regionId, "stampDuty")
        if region ~= nil and region.cropStampDutyExempt then
            duty = 0
        end
        rate = rate * (1 + program.gst + (duty or 0))          -- AU GST + state stamp duty
    end

    -- Regional risk (AR provinces)
    local regionFactor = firstInChain(profile, regionId, "rateFactor")
    if regionFactor ~= nil and profile.programType ~= TornadoInsuranceData.PROGRAM_CURVES then
        rate = rate * regionFactor
    end
    return math.max(0, rate)
end

-- =========================================================================
-- PUBLIC: options, levels, terms
-- =========================================================================

--- Option ids the region offers (any crop that has them), in ORDER.
function TornadoInsurancePrograms.getOptions(profile, regionId)
    local seen = {}
    if profile.programType == TornadoInsuranceData.PROGRAM_SCHEMES then
        for _, option in ipairs(schemeOptions(profile, regionId)) do seen[option.id] = true end
    else
        for _, region in ipairs(TornadoInsuranceData.getRegionChain(profile, regionId)) do
            for _, crop in pairs(region.crops) do
                for _, option in ipairs(P.getCropOptions(profile, regionId, crop)) do
                    seen[option.id] = true
                end
            end
        end
    end
    local options = {}
    for _, id in ipairs(P.ORDER) do
        if seen[id] then table.insert(options, id) end
    end
    return options
end

--- Coverage levels (1 - deductible) of an option, from the DEFAULT crop (levels are programme-wide).
function TornadoInsurancePrograms.getLevels(profile, regionId, optionId)
    local crop = P.findRatedCrop(profile, regionId, TornadoInsuranceData.DEFAULT_CROP)
    for _, option in ipairs(crop ~= nil and P.getCropOptions(profile, regionId, crop) or schemeOptions(profile, regionId)) do
        if option.id == optionId then
            local levels = {}
            for _, level in ipairs(option.levels) do table.insert(levels, level.coverage) end
            return levels
        end
    end
    return {}
end

--- Terms for one crop (name = the cross-referenced crop): nil when the option is not offered for it.
--- { plan, coverage, rate (farmer, per year of the sum insured), causes, rule, threshold, realValuePerHa,
---   noStateScheme }
function TornadoInsurancePrograms.getTerms(profile, regionId, name, optionId, coverage)
    local crop = P.findRatedCrop(profile, regionId, name)
    if crop == nil then
        return nil
    end
    for _, option in ipairs(P.getCropOptions(profile, regionId, crop)) do
        if option.id == optionId then
            -- Level: exact, else the next lower one, else the lowest.
            local chosen, lowest = nil, nil
            for _, level in ipairs(option.levels) do
                if lowest == nil or level.coverage < lowest.coverage then lowest = level end
                if level.coverage <= (coverage or 1) + 0.001 and (chosen == nil or level.coverage > chosen.coverage) then
                    chosen = level
                end
            end
            chosen = chosen or lowest
            return {
                plan = optionId,
                coverage = chosen.coverage,
                rate = P.getFarmerRate(profile, regionId, crop, option, chosen.rateFactor),
                causes = option.causes,
                rule = option.rule or "deductible",
                threshold = option.threshold,
                realValuePerHa = getRealValuePerHa(profile, regionId, crop, getScheme(profile, regionId)),
                noStateScheme = P.hasNoStateScheme(profile, regionId, name),
            }
        end
    end
    return nil
end
