---@class TornadoInsuranceCrop
---@version 0.1 (insurance phase 2a: coverage-curve countries - US, Canada, Brazil)
---@description Crop insurance policy per farm (docs/INSURANCE_DESIGN.md §6.2, §8, §9.3, §18 phase 2a).
---
--- Policy: one plan (YP / RPHPE / RP / APH in the US, YP in Canada, YP / COST / FULL in Brazil - whatever the
--- country's data offers) and one coverage level; it covers every field the farm owns with an insurable crop.
---   * bought / changed only while sales are open (salesClosing setting: auto = only with seasonal growth, late
---     winter + early spring; on; off), never while a tornado is on the ground or an outbreak runs;
---   * cover starts after WAIT_DAYS real-life days (TornadoInsurance time model);
---   * prices are locked per crop the first time the policy year needs them (average of every selling station that
---     buys the crop - decided 2026-10-16), reset when the game year changes;
---   * monthly premium per field = area x standard yield (fruit type litersPerSqm) x locked price x coverage
---     x farmer rate (curve of the crop's plan + level) x state factor x 1.25 for unusual crops / 12 x cost scale.
--- Crops: TornadoInsuranceCrops cross-reference (map crops rated like base crops, cover crops not insurable,
--- "unusual" crops: +25 % premium and at most 70 % coverage). A crop without the chosen plan uses the first plan its
--- curve offers (YP, APH, FULL, COST, RPHPE, RP); a missing level uses the next lower one.
--- Claims: every closed damage-log event (TornadoInsuranceDamage - tornado, hail, drought, flood, fire) on an owned
--- field with an active policy opens a claim: adjuster after ADJUSTER_DAYS, decision after DECISION_DAYS, payout
--- after PAYOUT_DAYS. Per field and crop the policy year adds up the lost share; the insured loss is what goes
--- beyond the uninsured part (1 - coverage) - like a real yield guarantee, no extra deductible (decided 2026-10-17).
--- RP pays at the higher of the locked and the current price (capped at 200 %), the other plans at the locked price.
--- Other programme types (named perils, multi-risk ...) follow in phase 2b; buying is refused there for now.

TornadoInsuranceCrop = {}

TornadoInsuranceCrop.WAIT_DAYS = 7            -- real-life days until new cover starts
TornadoInsuranceCrop.ADJUSTER_DAYS = 3
TornadoInsuranceCrop.DECISION_DAYS = 2
TornadoInsuranceCrop.PAYOUT_DAYS = 1
TornadoInsuranceCrop.UNUSUAL_SURCHARGE = 0.25
TornadoInsuranceCrop.UNUSUAL_MAX_COVERAGE = 0.70
TornadoInsuranceCrop.RP_PRICE_CAP = 2.0
TornadoInsuranceCrop.DEFAULT_COVERAGE = 0.75
TornadoInsuranceCrop.SALES_PERIODS = { [12] = true, [1] = true }   -- late winter, early spring
TornadoInsuranceCrop.PLAN_FALLBACK = { "YP", "APH", "FULL", "COST", "RPHPE", "RP" }
TornadoInsuranceCrop.PLAN_KEYS = { YP = "tp_plan_YP", RP = "tp_plan_RP", RPHPE = "tp_plan_RPHPE", APH = "tp_plan_APH",
    COST = "tp_plan_COST", FULL = "tp_plan_FULL" }
TornadoInsuranceCrop.MAX_CLAIMS = 100
TornadoInsuranceCrop.MIN_CLAIM_SHARE = 0.01    -- events below 1 % of a field open no claim (hail specks)

TornadoInsuranceCrop.TIMER_ACTIVE = "CROP_ACTIVE"
TornadoInsuranceCrop.TIMER_ADJUSTER = "CROP_ADJUSTER"
TornadoInsuranceCrop.TIMER_DECISION = "CROP_DECISION"
TornadoInsuranceCrop.TIMER_PAYOUT = "CROP_PAYOUT"

TornadoInsuranceCrop.STATUS_PENDING = "PENDING"
TornadoInsuranceCrop.STATUS_ACTIVE = "ACTIVE"

local MSG_INFO = 3

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

local function getEnvironment()
    return g_currentMission ~= nil and g_currentMission.environment or nil
end

local function getDay()
    local environment = getEnvironment()
    return environment ~= nil and environment.currentMonotonicDay or 0
end

local function percent(value)
    return math.floor((value or 0) * 100 + 0.5)
end

-- =========================================================================
-- SETUP (called from TornadoInsurance:loadMap)
-- =========================================================================

function TornadoInsuranceCrop:install(insurance)
    self.insurance = insurance
    insurance:registerPremiumSource("crop", function(_, farmId)
        return TornadoInsuranceCrop:getMonthlyPremium(farmId)
    end)
    insurance:registerTimerHandler(self.TIMER_ACTIVE, function(_, timer) TornadoInsuranceCrop:onPolicyActive(timer) end)
    insurance:registerTimerHandler(self.TIMER_ADJUSTER, function(_, timer) TornadoInsuranceCrop:onAdjuster(timer) end)
    insurance:registerTimerHandler(self.TIMER_DECISION, function(_, timer) TornadoInsuranceCrop:onDecision(timer) end)
    insurance:registerTimerHandler(self.TIMER_PAYOUT, function(_, timer) TornadoInsuranceCrop:onPayout(timer) end)
    insurance:registerAction("cropBuy", true, function(_, farmId, args) return TornadoInsuranceCrop:buy(farmId, args) end)
    insurance:registerAction("cropCancel", true, function(_, farmId) return TornadoInsuranceCrop:cancel(farmId) end)
    insurance:registerFarmData(function(xmlId, key, farm) TornadoInsuranceCrop:saveFarm(xmlId, key, farm) end,
        function(xmlId, key, farm) TornadoInsuranceCrop:loadFarm(xmlId, key, farm) end)
    insurance:registerDamageListener(function(_, entry) TornadoInsuranceCrop:onDamage(entry) end)
    if isServer() and g_messageCenter ~= nil and MessageType ~= nil and MessageType.YEAR_CHANGED ~= nil then
        g_messageCenter:subscribe(MessageType.YEAR_CHANGED, self.onYearChanged, self)
    end
end

function TornadoInsuranceCrop:uninstall()
    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end
end

-- =========================================================================
-- DATA: plans, levels, prices, yields
-- =========================================================================

--- Crop insurance can be sold with the loaded profile (phase 2a: coverage curves only).
function TornadoInsuranceCrop:isAvailable()
    local profile = TornadoInsurance ~= nil and TornadoInsurance:getProfile() or nil
    return profile ~= nil and profile.programType == TornadoInsuranceData.PROGRAM_CURVES
end

--- Plans the region offers (from the DEFAULT crop, plus every crop's plans), in PLAN_FALLBACK order then others.
function TornadoInsuranceCrop:getOfferedPlans()
    local profile, regionId = TornadoInsurance:getProfile()
    local seen, plans = {}, {}
    if profile == nil then
        return plans
    end
    for _, region in ipairs(TornadoInsuranceData.getRegionChain(profile, regionId)) do
        for _, crop in pairs(region.crops) do
            for planId in pairs(crop.plans) do
                seen[planId] = true
            end
        end
    end
    -- Most popular first: RP is the US default, then the others in fallback order.
    for _, planId in ipairs({ "RP", "RPHPE", "YP", "APH", "FULL", "COST" }) do
        if seen[planId] then
            table.insert(plans, planId)
            seen[planId] = nil
        end
    end
    for planId in pairs(seen) do
        table.insert(plans, planId)
    end
    return plans
end

--- Coverage levels offered for a plan (the DEFAULT crop's curve, else the first crop curve that has the plan).
function TornadoInsuranceCrop:getCoverageLevels(planId)
    local profile, regionId = TornadoInsurance:getProfile()
    local curve = profile ~= nil and TornadoInsuranceData.getCurve(profile, regionId, TornadoInsuranceData.DEFAULT_CROP, planId) or nil
    if curve == nil and profile ~= nil then
        for _, region in ipairs(TornadoInsuranceData.getRegionChain(profile, regionId)) do
            for _, crop in pairs(region.crops) do
                if crop.plans[planId] ~= nil then
                    curve = crop.plans[planId]
                    break
                end
            end
            if curve ~= nil then break end
        end
    end
    local levels = {}
    for _, level in ipairs(curve ~= nil and curve.levels or {}) do
        table.insert(levels, level.coverage)
    end
    return levels
end

--- The plan used for a crop: the chosen one if its curve has it, else the first one it has (PLAN_FALLBACK order).
function TornadoInsuranceCrop:resolvePlan(profile, regionId, ratedAs, planId)
    local curve = TornadoInsuranceData.getCurve(profile, regionId, ratedAs, planId)
    if curve ~= nil then
        return planId, curve
    end
    for _, fallback in ipairs(self.PLAN_FALLBACK) do
        curve = TornadoInsuranceData.getCurve(profile, regionId, ratedAs, fallback)
        if curve ~= nil then
            return fallback, curve
        end
    end
    return nil, nil
end

--- The curve level for a coverage: exact, else the highest one below it, else the lowest one.
function TornadoInsuranceCrop.resolveLevel(curve, coverage)
    local best, lowest = nil, nil
    for _, level in ipairs(curve ~= nil and curve.levels or {}) do
        if lowest == nil or level.coverage < lowest.coverage then
            lowest = level
        end
        if level.coverage <= coverage + 0.001 and (best == nil or level.coverage > best.coverage) then
            best = level
        end
    end
    return best or lowest
end

--- Is this selling station part of the map (preplaced), not one a player bought and placed? Bought stations -
--- often mod placeables that pay 10 %+ more - would raise the insured price (user's note 2026-10-17).
local function isMapStation(station)
    local placeable = station.owningPlaceable
    if placeable == nil or placeable.getIsPreplaced == nil then
        return true   -- built into the map itself
    end
    return placeable:getIsPreplaced() == true
end

--- Average price per litre over the map's own selling stations that buy the fill type; if none of those buy it,
--- over every station that does; else the game's base price.
function TornadoInsuranceCrop:getAveragePrice(fillTypeIndex)
    local storage = g_currentMission ~= nil and g_currentMission.storageSystem or nil
    local mapTotal, mapCount, allTotal, allCount = 0, 0, 0, 0
    if storage ~= nil and storage.getUnloadingStations ~= nil and SellingStation ~= nil then
        for _, station in pairs(storage:getUnloadingStations()) do
            if station.isa ~= nil and station:isa(SellingStation) and station:getIsFillTypeAllowed(fillTypeIndex) then
                local price = station:getEffectiveFillTypePrice(fillTypeIndex)
                if price ~= nil and price > 0 then
                    allTotal, allCount = allTotal + price, allCount + 1
                    if isMapStation(station) then
                        mapTotal, mapCount = mapTotal + price, mapCount + 1
                    end
                end
            end
        end
    end
    if mapCount > 0 then
        return mapTotal / mapCount
    end
    if allCount > 0 then
        return allTotal / allCount
    end
    local economy = g_currentMission ~= nil and g_currentMission.economyManager or nil
    return economy ~= nil and economy:getPricePerLiter(fillTypeIndex) or 0
end

--- Planted crop of a field: { fieldId, areaHa, fruitType, fillTypeIndex, fillTypeName, owner } or nil.
function TornadoInsuranceCrop:getFieldCrop(field)
    local state = field.getFieldState ~= nil and field:getFieldState() or nil
    if state == nil or not state.isValid or state.fruitTypeIndex == nil or FruitType == nil
        or state.fruitTypeIndex == FruitType.UNKNOWN or g_fruitTypeManager == nil then
        return nil
    end
    local fruitType = g_fruitTypeManager:getFruitTypeByIndex(state.fruitTypeIndex)
    local fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(state.fruitTypeIndex)
    if fruitType == nil or fillTypeIndex == nil then
        return nil
    end
    return {
        fieldId = field:getId(),
        areaHa = field.getAreaHa ~= nil and field:getAreaHa() or 0,
        fruitType = fruitType,
        fillTypeIndex = fillTypeIndex,
        fillTypeName = g_fruitTypeManager:getFillTypeNameByFruitTypeIndex(state.fruitTypeIndex) or fruitType.name,
        owner = field.getOwner ~= nil and field:getOwner() or 0,
    }
end

--- Standard yield in litres per hectare (the game's harvest litersPerSqm).
function TornadoInsuranceCrop.getYieldPerHa(fruitType)
    return (fruitType ~= nil and fruitType.literPerSqm or 0) * 10000
end

--- The farm's locked price for a crop (locked now when this policy year has none yet, server).
function TornadoInsuranceCrop:getLockedPrice(policy, crop)
    if policy == nil then
        return self:getAveragePrice(crop.fillTypeIndex)
    end
    policy.prices = policy.prices or {}
    local price = policy.prices[crop.fillTypeName]
    if price == nil then
        price = self:getAveragePrice(crop.fillTypeIndex)
        if isServer() and price > 0 then
            policy.prices[crop.fillTypeName] = price
        end
    end
    return price
end

-- =========================================================================
-- QUOTES + PREMIUM
-- =========================================================================

--- Insurance terms of one field's crop for a plan / coverage. policy = the farm's policy (locked prices) or nil.
--- Returns nil for crops that cannot be insured, else { crop, ratedAs, isLocal, plan, coverage, price, yieldPerHa,
--- liability, yearlyPremium }.
function TornadoInsuranceCrop:getFieldTerms(crop, planId, coverage, policy)
    local profile, regionId = TornadoInsurance:getProfile()
    if profile == nil or TornadoInsuranceCrops == nil then
        return nil
    end
    local info = TornadoInsuranceCrops:getCropInfo(crop.fillTypeName)
    if info == nil or not info.insurable then
        return nil
    end
    local plan, curve = self:resolvePlan(profile, regionId, info.ratedAs, planId)
    if curve == nil then
        return nil
    end
    local wanted = coverage or self.DEFAULT_COVERAGE
    if not info.isLocal then
        wanted = math.min(wanted, self.UNUSUAL_MAX_COVERAGE)
    end
    local level = self.resolveLevel(curve, wanted)
    if level == nil then
        return nil
    end
    local price = self:getLockedPrice(policy, crop)
    local yieldPerHa = self.getYieldPerHa(crop.fruitType)
    local liability = crop.areaHa * yieldPerHa * price * level.coverage
    local rate = level.farmerRate * TornadoInsuranceData.getRateFactor(profile, regionId, info.ratedAs)
    if not info.isLocal then
        rate = rate * (1 + self.UNUSUAL_SURCHARGE)
    end
    return { crop = crop, ratedAs = info.ratedAs, isLocal = info.isLocal, plan = plan, coverage = level.coverage,
        price = price, yieldPerHa = yieldPerHa, liability = liability, yearlyPremium = liability * rate }
end

--- Totals over the farm's owned fields: { fields, uninsurable, liability, monthlyPremium (cost scale applied) }.
function TornadoInsuranceCrop:getFarmQuote(farmId, planId, coverage, policy)
    local quote = { fields = 0, uninsurable = 0, liability = 0, monthlyPremium = 0 }
    if g_fieldManager == nil then
        return quote
    end
    for _, field in pairs(g_fieldManager:getFields()) do
        local crop = self:getFieldCrop(field)
        if crop ~= nil and crop.owner == farmId then
            local terms = self:getFieldTerms(crop, planId, coverage, policy)
            if terms ~= nil then
                quote.fields = quote.fields + 1
                quote.liability = quote.liability + terms.liability
                quote.monthlyPremium = quote.monthlyPremium + terms.yearlyPremium / 12
            else
                quote.uninsurable = quote.uninsurable + 1
            end
        end
    end
    quote.monthlyPremium = quote.monthlyPremium * (TornadoInsurance:getCostScale() or 1)
    return quote
end

--- Premium source: the active policy's monthly premium (before the cost scale - TornadoInsurance applies it).
function TornadoInsuranceCrop:getMonthlyPremium(farmId)
    local farm = self.insurance ~= nil and self.insurance.farms[farmId] or nil
    local policy = farm ~= nil and farm.crop or nil
    if policy == nil or policy.status ~= self.STATUS_ACTIVE then
        return 0
    end
    local quote = self:getFarmQuote(farmId, policy.plan, policy.coverage, policy)
    local scale = TornadoInsurance:getCostScale() or 1
    return scale > 0 and quote.monthlyPremium / scale or 0
end

-- =========================================================================
-- BUY / CHANGE / CANCEL (server, through TornadoInsurance actions)
-- =========================================================================

--- Sales open now? salesClosing: "auto" (only with seasonal growth), "on", "off".
function TornadoInsuranceCrop:isSalesOpen()
    local mode = TornadoInsurance.salesClosing or "auto"
    if mode == "off" then
        return true
    end
    if mode == "auto" then
        local growth = g_currentMission ~= nil and g_currentMission.growthSystem ~= nil
            and g_currentMission.growthSystem.getGrowthMode ~= nil and g_currentMission.growthSystem:getGrowthMode() or nil
        if GrowthMode == nil or growth ~= GrowthMode.SEASONAL then
            return true
        end
    end
    local environment = getEnvironment()
    return environment ~= nil and self.SALES_PERIODS[environment.currentPeriod or 0] == true
end

--- A tornado on the ground or an outbreak day: no new / bigger cover.
function TornadoInsuranceCrop:isStormActive()
    if TornadoOutbreak ~= nil and TornadoOutbreak.isActive then
        return true
    end
    local node = TornadoPhysics ~= nil and TornadoPhysics.tornadoNode or nil
    return node ~= nil and node ~= 0 and entityExists(node)
end

--- args = "PLAN COVERAGE" (coverage 0.5 - 0.85 or 50 - 85). Returns the result text key (shown to the player).
function TornadoInsuranceCrop:buy(farmId, args)
    local planId, coverageText = string.match(args or "", "^(%S+)%s*(%S*)")
    planId = planId ~= nil and string.upper(planId) or nil
    local coverage = tonumber(coverageText) or self.DEFAULT_COVERAGE
    if coverage > 1 then
        coverage = coverage / 100
    end
    if not self:isAvailable() then
        return "tp_msg_ins_crop_unavailable"
    end
    local offered = false
    for _, id in ipairs(self:getOfferedPlans()) do
        if id == planId then offered = true end
    end
    if not offered then
        return "tp_msg_ins_crop_unknown_plan"
    end
    if not self:isSalesOpen() then
        return "tp_msg_ins_crop_sales_closed"
    end
    if self:isStormActive() then
        return "tp_msg_ins_crop_storm"
    end
    local insurance = self.insurance
    local farm = insurance:getFarm(farmId)
    local quote = self:getFarmQuote(farmId, planId, coverage, nil)
    local params = { TornadoText.key(self.PLAN_KEYS[planId] or planId), TornadoText.num(percent(coverage)),
        TornadoText.cash(quote.monthlyPremium) }
    if farm.crop == nil then
        farm.crop = { plan = planId, coverage = coverage, status = self.STATUS_PENDING, prices = {}, fields = {},
            boughtDay = getDay() }
        farm.crop.timerId = insurance:addTimer(farmId, self.TIMER_ACTIVE, self.WAIT_DAYS, "")
        local days, hours = insurance:getRemainingDaysHours(insurance.realDaysToMonths(self.WAIT_DAYS))
        table.insert(params, TornadoText.num(days))
        table.insert(params, TornadoText.num(hours))
        insurance:addInbox(farmId, "tp_msg_ins_crop_bought", params, MSG_INFO)
    else
        farm.crop.plan = planId
        farm.crop.coverage = coverage
        insurance:addInbox(farmId, "tp_msg_ins_crop_changed", params, MSG_INFO)
    end
    return nil
end

function TornadoInsuranceCrop:cancel(farmId)
    local insurance = self.insurance
    local farm = insurance:getFarm(farmId)
    if farm.crop == nil then
        return "tp_msg_ins_crop_none"
    end
    if farm.crop.timerId ~= nil then
        insurance:removeTimer(farm.crop.timerId)
    end
    farm.crop = nil
    insurance:addInbox(farmId, "tp_msg_ins_crop_cancelled", {}, MSG_INFO)   -- open claims carry on
    return nil
end

function TornadoInsuranceCrop:onPolicyActive(timer)
    local farm = self.insurance:getFarm(timer.farmId)
    if farm.crop == nil or farm.crop.status ~= self.STATUS_PENDING then
        return
    end
    farm.crop.status = self.STATUS_ACTIVE
    farm.crop.activeDay = getDay()
    farm.crop.timerId = nil
    self.insurance:addInbox(timer.farmId, "tp_msg_ins_crop_active",
        { TornadoText.key(self.PLAN_KEYS[farm.crop.plan] or farm.crop.plan), TornadoText.num(percent(farm.crop.coverage)) }, MSG_INFO)
end

--- New game year = new policy year: prices are locked again, the per-field loss totals start over.
function TornadoInsuranceCrop:onYearChanged()
    if self.insurance == nil or not self.insurance.isEnabled then
        return
    end
    for farmId, farm in pairs(self.insurance.farms) do
        if farm.crop ~= nil and farm.crop.status == self.STATUS_ACTIVE then
            farm.crop.prices = {}
            farm.crop.fields = {}
            self.insurance:addInbox(farmId, "tp_msg_ins_crop_renewed", {}, MSG_INFO)
        end
    end
end

-- =========================================================================
-- CLAIMS
-- =========================================================================

function TornadoInsuranceCrop:findClaim(farmId, claimId)
    local farm = self.insurance.farms[farmId]
    for _, claim in ipairs(farm ~= nil and farm.claims or {}) do
        if claim.id == claimId then
            return claim, farm
        end
    end
    return nil, farm
end

--- A closed damage-log event (TornadoInsuranceDamage) - opens a claim when the field is covered.
function TornadoInsuranceCrop:onDamage(entry)
    local insurance = self.insurance
    if insurance == nil or not insurance.isEnabled or entry == nil or entry.farmId == nil or entry.farmId == 0 then
        return
    end
    local farm = insurance.farms[entry.farmId]
    local policy = farm ~= nil and farm.crop or nil
    if policy == nil or policy.status ~= self.STATUS_ACTIVE or (entry.day or 0) < (policy.activeDay or 0)
        or (entry.share or 0) < self.MIN_CLAIM_SHARE then
        return
    end
    local info = TornadoInsuranceCrops ~= nil and TornadoInsuranceCrops:getCropInfo(entry.crop or "") or nil
    if info == nil or not info.insurable then
        return
    end
    -- Only the farm's own fields (a field sold between the storm and the report is no longer covered).
    local field = g_fieldManager ~= nil and g_fieldManager:getFieldById(entry.fieldId) or nil
    if field == nil or field.getOwner == nil or field:getOwner() ~= entry.farmId then
        return
    end
    farm.claims = farm.claims or {}
    farm.nextClaimId = (farm.nextClaimId or 0) + 1
    local claim = { id = farm.nextClaimId, fieldId = entry.fieldId, cause = entry.cause, crop = entry.crop,
        share = entry.share, day = getDay(), status = "RECEIVED", payout = 0 }
    table.insert(farm.claims, claim)
    while #farm.claims > self.MAX_CLAIMS do
        table.remove(farm.claims, 1)
    end
    local causeKey = TornadoInsuranceDamage ~= nil and TornadoInsuranceDamage.CAUSE_KEYS[entry.cause] or entry.cause
    insurance:addInbox(entry.farmId, "tp_msg_ins_claim_received", { TornadoText.num(entry.fieldId),
        TornadoText.key(causeKey), TornadoText.num(math.max(1, percent(entry.share))) }, MSG_INFO)
    insurance:addTimer(entry.farmId, self.TIMER_ADJUSTER, self.ADJUSTER_DAYS, tostring(claim.id))
end

function TornadoInsuranceCrop:onAdjuster(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil then
        return
    end
    claim.status = "INSPECTED"
    self.insurance:addInbox(timer.farmId, "tp_msg_ins_claim_inspected", { TornadoText.num(claim.fieldId) }, MSG_INFO)
    self.insurance:addTimer(timer.farmId, self.TIMER_DECISION, self.DECISION_DAYS, tostring(claim.id))
end

--- The loss counts against the farm's policy as it is now (also after a cancel: cover at the time of the event).
function TornadoInsuranceCrop:onDecision(timer)
    local claim, farm = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil then
        return
    end
    local result = self:decide(timer.farmId, farm, claim)
    claim.status = result.status
    claim.payout = result.payout
    if result.status == "APPROVED" then
        self.insurance:addInbox(timer.farmId, "tp_msg_ins_claim_approved", { TornadoText.num(claim.fieldId),
            TornadoText.cash(result.payout) }, MSG_INFO)
        self.insurance:addTimer(timer.farmId, self.TIMER_PAYOUT, self.PAYOUT_DAYS, tostring(claim.id))
    else
        self.insurance:addInbox(timer.farmId, result.reasonKey, result.params or { TornadoText.num(claim.fieldId) }, MSG_INFO)
    end
end

--- The claim's crop as a field crop (same shape as getFieldCrop), from its fill type name and the field's area.
function TornadoInsuranceCrop:getClaimCrop(claim)
    local field = g_fieldManager ~= nil and g_fieldManager:getFieldById(claim.fieldId) or nil
    if field == nil or g_fillTypeManager == nil or g_fruitTypeManager == nil or claim.crop == nil then
        return nil
    end
    local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(claim.crop)
    local fruitType = fillTypeIndex ~= nil and g_fruitTypeManager:getFruitTypeByFillTypeIndex(fillTypeIndex) or nil
    if fruitType == nil then
        return nil
    end
    return { fieldId = claim.fieldId, areaHa = field.getAreaHa ~= nil and field:getAreaHa() or 0, fruitType = fruitType,
        fillTypeIndex = fillTypeIndex, fillTypeName = claim.crop, owner = field.getOwner ~= nil and field:getOwner() or 0 }
end

--- Indemnity: per field and crop the policy year adds up the lost share; paid is what goes beyond the uninsured
--- part (1 - coverage) and was not paid before, x area x standard yield x price.
--- Returns { status = "APPROVED" | "DENIED", payout, reasonKey, params }.
function TornadoInsuranceCrop:decide(farmId, farm, claim)
    local denied = function(key, params) return { status = "DENIED", payout = 0, reasonKey = key, params = params } end
    local policy = farm ~= nil and farm.crop or nil
    if policy == nil then
        return denied("tp_msg_ins_claim_no_policy", { TornadoText.num(claim.fieldId) })
    end
    -- The crop of the event (the field may be harvested / replanted by now).
    local crop = self:getClaimCrop(claim)
    if crop == nil then
        return denied("tp_msg_ins_claim_no_crop", { TornadoText.num(claim.fieldId) })
    end
    local terms = self:getFieldTerms(crop, policy.plan, policy.coverage, policy)
    if terms == nil then
        return denied("tp_msg_ins_claim_no_crop", { TornadoText.num(claim.fieldId) })
    end
    policy.fields = policy.fields or {}
    local record = policy.fields[claim.fieldId]
    if record == nil or record.crop ~= claim.crop then
        record = { crop = claim.crop, lost = 0, paid = 0 }
        policy.fields[claim.fieldId] = record
    end
    record.lost = math.min(1, record.lost + (claim.share or 0))
    local insuredShare = math.max(0, record.lost - (1 - terms.coverage)) - record.paid
    if insuredShare <= 0.0001 then
        return denied("tp_msg_ins_claim_deductible", { TornadoText.num(claim.fieldId),
            TornadoText.num(percent(record.lost)), TornadoText.num(percent(terms.coverage)) })
    end
    local price = terms.price
    if terms.plan == "RP" then
        local current = self:getAveragePrice(crop.fillTypeIndex)
        price = math.min(math.max(price, current), price * self.RP_PRICE_CAP)
    end
    record.paid = record.paid + insuredShare
    local payout = insuredShare * crop.areaHa * terms.yieldPerHa * price
    return { status = "APPROVED", payout = payout }
end

function TornadoInsuranceCrop:onPayout(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "APPROVED" then
        return
    end
    claim.status = "PAID"
    self.insurance:payOut(timer.farmId, claim.payout, "tp_msg_ins_claim_paid",
        { TornadoText.num(claim.fieldId), TornadoText.cash(claim.payout) })
end

function TornadoInsuranceCrop:getOpenClaimCount(farm)
    local count = 0
    for _, claim in ipairs(farm ~= nil and farm.claims or {}) do
        if claim.status == "RECEIVED" or claim.status == "INSPECTED" or claim.status == "APPROVED" then
            count = count + 1
        end
    end
    return count
end

-- =========================================================================
-- SAVEGAME (inside TornadoInsurance.xml, per farm)
-- =========================================================================

function TornadoInsuranceCrop:saveFarm(xmlId, key, farm)
    local policy = farm.crop
    if policy ~= nil then
        local policyKey = key .. ".crop"
        setXMLString(xmlId, policyKey .. "#plan", policy.plan)
        setXMLFloat(xmlId, policyKey .. "#coverage", policy.coverage)
        setXMLString(xmlId, policyKey .. "#status", policy.status)
        setXMLInt(xmlId, policyKey .. "#activeDay", policy.activeDay or 0)
        setXMLInt(xmlId, policyKey .. "#timerId", policy.timerId or 0)
        local i = 0
        for name, price in pairs(policy.prices or {}) do
            setXMLString(xmlId, string.format("%s.price(%d)#crop", policyKey, i), name)
            setXMLFloat(xmlId, string.format("%s.price(%d)#value", policyKey, i), price)
            i = i + 1
        end
        i = 0
        for fieldId, record in pairs(policy.fields or {}) do
            local fieldKey = string.format("%s.field(%d)", policyKey, i)
            setXMLInt(xmlId, fieldKey .. "#id", fieldId)
            setXMLString(xmlId, fieldKey .. "#crop", record.crop or "")
            setXMLFloat(xmlId, fieldKey .. "#lost", record.lost or 0)
            setXMLFloat(xmlId, fieldKey .. "#paid", record.paid or 0)
            i = i + 1
        end
    end
    setXMLInt(xmlId, key .. ".claims#nextId", farm.nextClaimId or 0)
    for i, claim in ipairs(farm.claims or {}) do
        local claimKey = string.format("%s.claims.claim(%d)", key, i - 1)
        setXMLInt(xmlId, claimKey .. "#id", claim.id)
        setXMLInt(xmlId, claimKey .. "#field", claim.fieldId)
        setXMLString(xmlId, claimKey .. "#cause", claim.cause or "")
        setXMLString(xmlId, claimKey .. "#crop", claim.crop or "")
        setXMLFloat(xmlId, claimKey .. "#share", claim.share or 0)
        setXMLInt(xmlId, claimKey .. "#day", claim.day or 0)
        setXMLString(xmlId, claimKey .. "#status", claim.status or "")
        setXMLFloat(xmlId, claimKey .. "#payout", claim.payout or 0)
    end
end

function TornadoInsuranceCrop:loadFarm(xmlId, key, farm)
    local policyKey = key .. ".crop"
    local plan = getXMLString(xmlId, policyKey .. "#plan")
    if plan ~= nil then
        local timerId = getXMLInt(xmlId, policyKey .. "#timerId") or 0
        local policy = { plan = plan, coverage = getXMLFloat(xmlId, policyKey .. "#coverage") or self.DEFAULT_COVERAGE,
            status = getXMLString(xmlId, policyKey .. "#status") or self.STATUS_PENDING,
            activeDay = getXMLInt(xmlId, policyKey .. "#activeDay") or 0, timerId = timerId > 0 and timerId or nil,
            prices = {}, fields = {} }
        local i = 0
        while true do
            local name = getXMLString(xmlId, string.format("%s.price(%d)#crop", policyKey, i))
            if name == nil then break end
            policy.prices[name] = getXMLFloat(xmlId, string.format("%s.price(%d)#value", policyKey, i)) or 0
            i = i + 1
        end
        i = 0
        while true do
            local fieldKey = string.format("%s.field(%d)", policyKey, i)
            local fieldId = getXMLInt(xmlId, fieldKey .. "#id")
            if fieldId == nil then break end
            policy.fields[fieldId] = { crop = getXMLString(xmlId, fieldKey .. "#crop"),
                lost = getXMLFloat(xmlId, fieldKey .. "#lost") or 0, paid = getXMLFloat(xmlId, fieldKey .. "#paid") or 0 }
            i = i + 1
        end
        farm.crop = policy
    end
    farm.nextClaimId = getXMLInt(xmlId, key .. ".claims#nextId") or 0
    farm.claims = {}
    local i = 0
    while true do
        local claimKey = string.format("%s.claims.claim(%d)", key, i)
        local id = getXMLInt(xmlId, claimKey .. "#id")
        if id == nil then break end
        table.insert(farm.claims, { id = id, fieldId = getXMLInt(xmlId, claimKey .. "#field") or 0,
            cause = getXMLString(xmlId, claimKey .. "#cause"), crop = getXMLString(xmlId, claimKey .. "#crop"),
            share = getXMLFloat(xmlId, claimKey .. "#share") or 0, day = getXMLInt(xmlId, claimKey .. "#day") or 0,
            status = getXMLString(xmlId, claimKey .. "#status") or "", payout = getXMLFloat(xmlId, claimKey .. "#payout") or 0 })
        i = i + 1
    end
end

-- =========================================================================
-- CONSOLE (t_dev insurance crop ...)
-- =========================================================================

function TornadoInsuranceCrop:consoleCommand(farmId, sub, value, extra)
    local farm = self.insurance:getFarm(farmId)
    if sub == "plans" or sub == nil then
        local lines = {}
        for _, planId in ipairs(self:getOfferedPlans()) do
            local levels = {}
            for _, coverage in ipairs(self:getCoverageLevels(planId)) do
                table.insert(levels, tostring(percent(coverage)))
            end
            table.insert(lines, string.format("%s (%s %%)", planId, table.concat(levels, "/")))
        end
        return string.format("Crop insurance in %s: %s. Sales %s. Use t_dev insurance crop quote <PLAN> <coverage>.",
            TornadoInsurance:getRegionName(), #lines > 0 and table.concat(lines, ", ") or "not available (phase 2b)",
            self:isSalesOpen() and "OPEN" or "closed (late winter / early spring only)")
    elseif sub == "quote" then
        local planId = string.upper(value or "RP")
        local coverage = (tonumber(extra) or 75) / 100
        print(string.format("---------------- CROP INSURANCE QUOTE farm %d: %s %d %% ----------------", farmId, planId, percent(coverage)))
        if g_fieldManager ~= nil then
            for _, field in pairs(g_fieldManager:getFields()) do
                local crop = self:getFieldCrop(field)
                if crop ~= nil and crop.owner == farmId then
                    local terms = self:getFieldTerms(crop, planId, coverage, farm.crop)
                    if terms ~= nil then
                        print(string.format("  field %3d %-12s %5.2f ha  %s%s %d %%  value %9.0f  premium %8.0f / year%s",
                            crop.fieldId, crop.fillTypeName, crop.areaHa, terms.plan, terms.ratedAs ~= crop.fillTypeName
                            and (" as " .. terms.ratedAs) or "", percent(terms.coverage), terms.liability, terms.yearlyPremium,
                            terms.isLocal and "" or "  (unusual crop: +25 %, max 70 %)"))
                    else
                        print(string.format("  field %3d %-12s not insurable", crop.fieldId, crop.fillTypeName))
                    end
                end
            end
        end
        local quote = self:getFarmQuote(farmId, planId, coverage, farm.crop)
        return string.format("Crop insurance quote: %d fields, insured value %.0f, premium %.0f per month (cost scale applied), %d not insurable.",
            quote.fields, quote.liability, quote.monthlyPremium, quote.uninsurable)
    elseif sub == "buy" then
        TornadoInsurance:requestAction(farmId, "cropBuy", string.format("%s %s", tostring(value or ""), tostring(extra or "")))
        return "Crop insurance: request sent."
    elseif sub == "cancel" then
        TornadoInsurance:requestAction(farmId, "cropCancel", "")
        return "Crop insurance: cancel request sent."
    elseif sub == "claims" then
        print(string.format("---------------- CROP CLAIMS farm %d ----------------", farmId))
        for _, claim in ipairs(farm.claims or {}) do
            print(string.format("  #%d day %d field %d %-8s %-10s %5.1f %%  %-9s %8.0f", claim.id, claim.day, claim.fieldId,
                tostring(claim.cause), tostring(claim.crop), (claim.share or 0) * 100, claim.status, claim.payout or 0))
        end
        local policy = farm.crop
        return policy ~= nil and string.format("Crop policy: %s %d %% %s, %d claims (%d open).", policy.plan, percent(policy.coverage),
            policy.status, #(farm.claims or {}), self:getOpenClaimCount(farm)) or "Crop policy: none."
    end
    return "Usage: t_dev insurance crop <plans | quote <PLAN> <coverage> | buy <PLAN> <coverage> | cancel | claims>"
end
