---@class TornadoInsuranceEquipment
---@version 0.1 (insurance phase 3: equipment)
---@description Equipment insurance per farm (docs/INSURANCE_DESIGN.md §6.1, §7, §18 phase 3).
---
--- Policy: one deductible (DEDUCTIBLES, x cost scale); it covers every vehicle and tool the farm OWNS (not leased,
--- mission or shop-preview vehicles, no pallets / big bags). Cover starts after WAIT_DAYS real-life days, never
--- bought or changed while a tornado is on the ground. Monthly premium = the farm's total sell value x the yearly
--- rate of the deductible / 12 (x cost scale, TornadoInsurance bills it).
--- Value: the sell price is recorded the first time the tornado touches a vehicle (onVehicleContact - before any
--- damage; ADS's condition-based price when ADS is installed). With the "replacement value" setting the insurer
--- pays REPLACEMENT_MARKUP more (a dealer's margin).
--- The values recorded in a running storm are saved with the farm, so a save / reload mid-storm keeps them.
--- Claims open when the tornado ends (TornadoInsuranceDamage:onTornadoEnded -> onStormEnded) for every insured
--- vehicle it damaged. Estimate = the emergency tow bill (TornadoRecovery:estimateRepairCost: tow, parts, wheels,
--- tracks) + the engine work for the damage the storm added + the ADS repair price the storm added. A vehicle reset
--- before the storm ended keeps the estimate of its tow bill. Adjuster -> decision -> payout like crop claims.
---   * estimate - deductible <= 0: closed, nothing paid
---   * repairable: estimate - deductible is paid (the tow bill is charged as usual when the vehicle is reset)
---   * total loss (estimate >= TOTAL_LOSS_SHARE of the value, or a vehicle whose fire roll came up -
---     TornadoEffects:willBurn): the farm chooses
---       accept   - value - deductible, the insurer takes the wreck (removed; with "remove totalled vehicles" off
---                  the wreck stays like a buy-back)
---       buy back - value - deductible - SALVAGE_SHARE of the value, the farm keeps it with a Salvage title
---     no choice within CHOICE_DAYS real-life days = accepted (reminder halfway).
--- Titles: Salvage (bought back) becomes Rebuilt once the vehicle is repaired. Both lower its sell price for good
--- (settings salvagePenalty / rebuiltPenalty) - every vehicle's getSellPrice is wrapped once, per vehicle, so the
--- shop, selling and ADS all see the lower value.
--- A claim still pays when the vehicle was sold before the decision (the loss happened while the farm owned it).

TornadoInsuranceEquipment = {}

TornadoInsuranceEquipment.WAIT_DAYS = 7
TornadoInsuranceEquipment.ADJUSTER_DAYS = 3
TornadoInsuranceEquipment.DECISION_DAYS = 2
TornadoInsuranceEquipment.PAYOUT_DAYS = 1
TornadoInsuranceEquipment.CHOICE_DAYS = 7          -- total loss: accepted automatically after this
TornadoInsuranceEquipment.REMINDER_DAYS = 3.5
TornadoInsuranceEquipment.TOTAL_LOSS_SHARE = 0.75
TornadoInsuranceEquipment.SALVAGE_SHARE = 0.15
TornadoInsuranceEquipment.REPLACEMENT_MARKUP = 0.15
TornadoInsuranceEquipment.DEDUCTIBLES = { 1000, 2500, 5000, 10000 }
TornadoInsuranceEquipment.RATES = { [1000] = 0.015, [2500] = 0.012, [5000] = 0.010, [10000] = 0.008 }   -- per year of the value
TornadoInsuranceEquipment.DEFAULT_DEDUCTIBLE = 2500
TornadoInsuranceEquipment.MAX_CLAIMS = 100
TornadoInsuranceEquipment.MIN_ESTIMATE = 1
TornadoInsuranceEquipment.ENGINE_MIN_COST = 1500   -- same as TornadoRecovery's dead-engine minimum
TornadoInsuranceEquipment.REBUILT_MAX_DAMAGE = 0.05
TornadoInsuranceEquipment.SCAN_MINUTES = 1         -- in-game minutes between vehicle scans (titles on reset / new copies, removals)

TornadoInsuranceEquipment.TIMER_ACTIVE = "EQUIP_ACTIVE"
TornadoInsuranceEquipment.TIMER_ADJUSTER = "EQUIP_ADJUSTER"
TornadoInsuranceEquipment.TIMER_DECISION = "EQUIP_DECISION"
TornadoInsuranceEquipment.TIMER_PAYOUT = "EQUIP_PAYOUT"
TornadoInsuranceEquipment.TIMER_REMINDER = "EQUIP_REMINDER"
TornadoInsuranceEquipment.TIMER_CHOICE = "EQUIP_CHOICE"

TornadoInsuranceEquipment.STATUS_PENDING = "PENDING"
TornadoInsuranceEquipment.STATUS_ACTIVE = "ACTIVE"

-- Claim states: RECEIVED -> INSPECTED -> APPROVED -> PAID | DENIED | TOTAL (waiting for the farm's choice)
--               -> SETTLED (accepted) | BOUGHT_BACK
TornadoInsuranceEquipment.TITLE_SALVAGE = "SALVAGE"
TornadoInsuranceEquipment.TITLE_REBUILT = "REBUILT"

local MSG_INFO = 3

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

local function getDay()
    local environment = g_currentMission ~= nil and g_currentMission.environment or nil
    return environment ~= nil and environment.currentMonotonicDay or 0
end

local function getCostScale()
    return TornadoInsurance ~= nil and TornadoInsurance:getCostScale() or 1
end

local function getVehicleSystem()
    return g_currentMission ~= nil and g_currentMission.vehicleSystem or nil
end

-- =========================================================================
-- SETUP (called from TornadoInsurance:loadMap)
-- =========================================================================

function TornadoInsuranceEquipment:install(insurance)
    self.insurance = insurance
    self.contacts = {}            -- uniqueId -> value snapshot of the current storm (server, not saved)
    self.scanMinutes = 0
    insurance:registerPremiumSource("equipment", function(_, farmId)
        return TornadoInsuranceEquipment:getMonthlyPremium(farmId)
    end)
    local handlers = {
        [self.TIMER_ACTIVE] = self.onPolicyActive, [self.TIMER_ADJUSTER] = self.onAdjuster,
        [self.TIMER_DECISION] = self.onDecision, [self.TIMER_PAYOUT] = self.onPayout,
        [self.TIMER_REMINDER] = self.onReminder, [self.TIMER_CHOICE] = self.onChoiceTimeout,
    }
    for kind, fn in pairs(handlers) do
        insurance:registerTimerHandler(kind, function(_, timer) fn(TornadoInsuranceEquipment, timer) end)
    end
    insurance:registerClaimSource(function(_, farmId, farm, list) TornadoInsuranceEquipment:addClaimSummaries(farmId, farm, list) end)
    insurance:registerAction("equipBuy", true, function(_, farmId, args) return TornadoInsuranceEquipment:buy(farmId, args) end)
    insurance:registerAction("equipCancel", true, function(_, farmId) return TornadoInsuranceEquipment:cancel(farmId) end)
    insurance:registerAction("equipAccept", true, function(_, farmId, args)
        return TornadoInsuranceEquipment:choose(farmId, tonumber(args), true, false)
    end)
    insurance:registerAction("equipBuyBack", true, function(_, farmId, args)
        return TornadoInsuranceEquipment:choose(farmId, tonumber(args), false, false)
    end)
    insurance:registerFarmData(function(xmlId, key, farm) TornadoInsuranceEquipment:saveFarm(xmlId, key, farm) end,
        function(xmlId, key, farm) TornadoInsuranceEquipment:loadFarm(xmlId, key, farm) end)
    -- Every machine: titles must lower the sell price the shop shows, not only the server's.
    if g_messageCenter ~= nil and MessageType ~= nil and MessageType.MINUTE_CHANGED ~= nil then
        g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
    end
end

function TornadoInsuranceEquipment:uninstall()
    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end
    self.contacts = {}
end

-- =========================================================================
-- VEHICLES + VALUES
-- =========================================================================

--- Can this vehicle be insured? Owned (not leased / mission / shop preview), by a farm, not a pallet or big bag.
function TornadoInsuranceEquipment.isInsurable(vehicle)
    if vehicle == nil or vehicle.rootNode == nil or vehicle.getSellPrice == nil or vehicle.getOwnerFarmId == nil then
        return false
    end
    if VehiclePropertyState ~= nil and vehicle.propertyState ~= VehiclePropertyState.OWNED then
        return false
    end
    local farmId = vehicle:getOwnerFarmId()
    if farmId == nil or farmId == 0 or (FarmManager ~= nil and farmId == FarmManager.SPECTATOR_FARM_ID) then
        return false
    end
    local typeName = string.lower(tostring(vehicle.typeName or ""))
    if string.find(typeName, "pallet", 1, true) or string.find(typeName, "bigbag", 1, true) or vehicle.isPallet then
        return false
    end
    if vehicle.isTrain or vehicle.spec_locomotive ~= nil then
        return false
    end
    return true
end

function TornadoInsuranceEquipment.getName(vehicle)
    if vehicle ~= nil and vehicle.getFullName ~= nil then
        return vehicle:getFullName()
    end
    if vehicle ~= nil and vehicle.getName ~= nil then
        return vehicle:getName()
    end
    return "?"
end

function TornadoInsuranceEquipment.getUniqueId(vehicle)
    if vehicle == nil then
        return nil
    end
    if vehicle.getUniqueId ~= nil then
        return vehicle:getUniqueId()
    end
    return vehicle.uniqueId
end

--- Sell price as the game (and ADS, and the title) sees it.
function TornadoInsuranceEquipment.getValue(vehicle)
    return math.max(0, tonumber(vehicle:getSellPrice()) or 0)
end

--- ADS repair price of every selectable breakdown (dealer, OEM parts) - 0 without ADS.
function TornadoInsuranceEquipment.getAdsRepairPrice(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil or vehicle.getServicePrice == nil then
        return 0
    end
    if vehicle.getIsADSExcluded ~= nil and vehicle:getIsADSExcluded() then
        return 0
    end
    -- ADS's class lives in its own mod environment; the constants below are its values if it cannot be reached.
    local ads = AdvancedDamageSystem
    if ads == nil and _G ~= nil and _G["FS25_AdvancedDamageSystem"] ~= nil then
        ads = _G["FS25_AdvancedDamageSystem"].AdvancedDamageSystem
    end
    local status = ads ~= nil and ads.STATUS ~= nil and ads.STATUS.REPAIR or "ads_spec_state_repair"
    local repairType = ads ~= nil and ads.REPAIR_TYPES ~= nil and ads.REPAIR_TYPES.MEDIUM or "ads_spec_repair_type_replacement"
    local parts = ads ~= nil and ads.PART_TYPES ~= nil and ads.PART_TYPES.OEM or "ads_spec_part_types_oem"
    local workshop = ads ~= nil and ads.WORKSHOP ~= nil and ads.WORKSHOP.DEALER or "ads_spec_workshop_dealer"
    return math.max(0, tonumber(vehicle:getServicePrice(status, repairType, parts, false, workshop, true)) or 0)
end

--- Did the tornado set this vehicle on fire? The fire roll (TornadoEffects), not tornadoIsOnFire - that one
--- only means the damage reached the ignite threshold, which nearly every motorized vehicle in a storm does.
function TornadoInsuranceEquipment.hasBurned(vehicle)
    return vehicle ~= nil and vehicle.rootNode ~= nil and TornadoEffects ~= nil and TornadoEffects.willBurn ~= nil
        and TornadoEffects:willBurn(vehicle.rootNode)
end

function TornadoInsuranceEquipment.getDamage(vehicle)
    if vehicle ~= nil and vehicle.getDamageAmount ~= nil then
        return vehicle:getDamageAmount() or 0
    end
    return 0
end

--- Engine work for the damage the storm added (same formula as TornadoRecovery: up to 8 % of the price,
--- a full overhaul when the engine is dead), cost scale applied.
function TornadoInsuranceEquipment.getEngineCost(price, before, now)
    local factor = TornadoRecovery ~= nil and TornadoRecovery.ENGINE_MAX_FACTOR or 0.08
    local added = math.max(0, (now or 0) - (before or 0))
    if added <= 0 then
        return 0
    end
    local cost
    if now >= 1.0 then
        cost = math.max(TornadoInsuranceEquipment.ENGINE_MIN_COST, price * factor) * math.min(1, added / now)
    else
        cost = price * factor * added
    end
    return math.floor(cost * getCostScale() + 0.5)
end

--- The farm's insurable vehicles and their total value.
function TornadoInsuranceEquipment:getFarmQuote(farmId, deductible)
    local quote = { vehicles = 0, value = 0, monthlyPremium = 0 }
    local system = getVehicleSystem()
    for _, vehicle in pairs(system ~= nil and system.vehicles or {}) do
        if self.isInsurable(vehicle) and vehicle:getOwnerFarmId() == farmId then
            quote.vehicles = quote.vehicles + 1
            quote.value = quote.value + self.getValue(vehicle)
        end
    end
    local rate = self.RATES[deductible or self.DEFAULT_DEDUCTIBLE] or self.RATES[self.DEFAULT_DEDUCTIBLE]
    quote.monthlyPremium = quote.value * rate / 12 * getCostScale()
    return quote
end

--- Premium source: before the cost scale (TornadoInsurance applies it).
function TornadoInsuranceEquipment:getMonthlyPremium(farmId)
    local farm = self.insurance ~= nil and self.insurance.farms[farmId] or nil
    local policy = farm ~= nil and farm.equipment or nil
    if policy == nil or policy.status ~= self.STATUS_ACTIVE then
        return 0
    end
    local quote = self:getFarmQuote(farmId, policy.deductible)
    local scale = getCostScale()
    return scale > 0 and quote.monthlyPremium / scale or 0
end

-- =========================================================================
-- BUY / CHANGE / CANCEL
-- =========================================================================

local function isStormActive()
    if TornadoInsuranceCrop ~= nil and TornadoInsuranceCrop.isStormActive ~= nil then
        return TornadoInsuranceCrop:isStormActive()
    end
    return false
end

function TornadoInsuranceEquipment:isDeductible(amount)
    for _, deductible in ipairs(self.DEDUCTIBLES) do
        if deductible == amount then
            return true
        end
    end
    return false
end

--- args = deductible (1000 / 2500 / 5000 / 10000, before the cost scale). Returns the result text key.
function TornadoInsuranceEquipment:buy(farmId, args)
    local deductible = tonumber(args) or self.DEFAULT_DEDUCTIBLE
    if not self:isDeductible(deductible) then
        return "tp_msg_ins_eq_unknown_deductible"
    end
    if isStormActive() then
        return "tp_msg_ins_crop_storm"
    end
    local insurance = self.insurance
    local farm = insurance:getFarm(farmId)
    local quote = self:getFarmQuote(farmId, deductible)
    local params = { TornadoText.cash(deductible * getCostScale()), TornadoText.num(quote.vehicles),
        TornadoText.cash(quote.monthlyPremium) }
    if farm.equipment == nil then
        farm.equipment = { deductible = deductible, status = self.STATUS_PENDING }
        farm.equipment.timerId = insurance:addTimer(farmId, self.TIMER_ACTIVE, self.WAIT_DAYS, "")
        local days, hours = insurance:getRemainingDaysHours(insurance.realDaysToMonths(self.WAIT_DAYS))
        table.insert(params, TornadoText.num(days))
        table.insert(params, TornadoText.num(hours))
        insurance:addInbox(farmId, "tp_msg_ins_eq_bought", params, MSG_INFO)
    else
        farm.equipment.deductible = deductible
        insurance:addInbox(farmId, "tp_msg_ins_eq_changed", params, MSG_INFO)
    end
    return nil
end

function TornadoInsuranceEquipment:cancel(farmId)
    local insurance = self.insurance
    local farm = insurance:getFarm(farmId)
    if farm.equipment == nil then
        return "tp_msg_ins_eq_none"
    end
    if farm.equipment.timerId ~= nil then
        insurance:removeTimer(farm.equipment.timerId)
    end
    farm.equipment = nil
    insurance:addInbox(farmId, "tp_msg_ins_eq_cancelled", {}, MSG_INFO)   -- open claims carry on
    return nil
end

function TornadoInsuranceEquipment:onPolicyActive(timer)
    local farm = self.insurance:getFarm(timer.farmId)
    if farm.equipment == nil or farm.equipment.status ~= self.STATUS_PENDING then
        return
    end
    farm.equipment.status = self.STATUS_ACTIVE
    farm.equipment.activeDay = getDay()
    farm.equipment.timerId = nil
    self.insurance:addInbox(timer.farmId, "tp_msg_ins_eq_active",
        { TornadoText.cash(farm.equipment.deductible * getCostScale()) }, MSG_INFO)
end

function TornadoInsuranceEquipment:getActivePolicy(farmId)
    local farm = self.insurance ~= nil and self.insurance.farms[farmId] or nil
    local policy = farm ~= nil and farm.equipment or nil
    if policy ~= nil and policy.status == self.STATUS_ACTIVE then
        return policy, farm
    end
    return nil, farm
end

-- =========================================================================
-- STORM: value snapshot, estimate, claims (server)
-- =========================================================================

--- The tornado reached a vehicle (TornadoPhysics, before any damage): records its value the first time per storm.
function TornadoInsuranceEquipment:onVehicleContact(vehicle)
    local insurance = self.insurance
    if insurance == nil or not insurance.isEnabled or not isServer() or self.contacts == nil then
        return
    end
    local uniqueId = self.getUniqueId(vehicle)
    if uniqueId == nil or self.contacts[uniqueId] ~= nil or not self.isInsurable(vehicle) then
        return
    end
    local farmId = vehicle:getOwnerFarmId()
    if self:getActivePolicy(farmId) == nil then
        return
    end
    local contact = { uniqueId = uniqueId, farmId = farmId, name = self.getName(vehicle),
        value = self.getValue(vehicle), damage = self.getDamage(vehicle), ads = self.getAdsRepairPrice(vehicle),
        price = vehicle.getPrice ~= nil and (vehicle:getPrice() or 0) or 0, day = getDay() }
    self.contacts[uniqueId] = contact
    if TornadoDebug then
        TornadoDebug:info("INSURANCE", string.format("Storm reached insured %s (farm %d): value %.0f recorded%s - claim when the tornado ends.",
            contact.name, farmId, contact.value, contact.ads > 0 and string.format(", ADS repair before %.0f", contact.ads) or ""))
    end
end

--- TornadoRecovery: the vehicle is being reset (tow bill) - keep its estimate for the storm's claim, and a
--- Salvage title becomes Rebuilt (the vehicle is repaired now).
function TornadoInsuranceEquipment:onVehicleRecovered(vehicle, estimate)
    if self.insurance == nil or not isServer() then
        return
    end
    local uniqueId = self.getUniqueId(vehicle)
    local contact = uniqueId ~= nil and self.contacts ~= nil and self.contacts[uniqueId] or nil
    if contact ~= nil and estimate ~= nil and contact.recovered == nil then
        contact.recovered = estimate
        contact.burned = contact.burned or self.hasBurned(vehicle)
        contact.adsNow = self.getAdsRepairPrice(vehicle)
    end
    self:markRebuilt(vehicle)
end

--- What the storm cost on one vehicle: { estimate, parts, engine, ads, burned } or nil when nothing.
function TornadoInsuranceEquipment:assess(contact)
    local system = getVehicleSystem()
    local vehicle = system ~= nil and system.getVehicleByUniqueId ~= nil and system:getVehicleByUniqueId(contact.uniqueId) or nil
    local recovery = contact.recovered
    if recovery == nil and vehicle ~= nil and TornadoRecovery ~= nil then
        recovery = TornadoRecovery:estimateRepairCost(vehicle)
    end
    if recovery == nil and vehicle == nil then
        return nil
    end
    local damageNow = recovery ~= nil and recovery.engineDamage or self.getDamage(vehicle)
    local parts = recovery ~= nil and math.max(0, (recovery.total or 0) - (recovery.engineCost or 0)) or 0
    local engine = self.getEngineCost(contact.price or 0, contact.damage, damageNow)
    local adsNow = contact.adsNow or (vehicle ~= nil and self.getAdsRepairPrice(vehicle) or contact.ads or 0)
    local ads = math.max(0, adsNow - (contact.ads or 0))
    local burned = contact.burned or self.hasBurned(vehicle)
    local estimate = math.floor(parts + engine + ads + 0.5)
    if estimate < self.MIN_ESTIMATE and not burned then
        return nil
    end
    return { estimate = estimate, parts = parts, engine = engine, ads = ads, burned = burned == true }
end

--- The tornado is over (TornadoInsuranceDamage:onTornadoEnded): a claim for every damaged insured vehicle.
function TornadoInsuranceEquipment:onStormEnded()
    if self.insurance == nil or not isServer() or self.contacts == nil or next(self.contacts) == nil then
        self.contacts = self.contacts or {}
        return
    end
    local contacts = self.contacts
    self.contacts = {}
    local list = {}
    for _, contact in pairs(contacts) do
        table.insert(list, contact)
    end
    table.sort(list, function(a, b) return tostring(a.uniqueId) < tostring(b.uniqueId) end)
    for _, contact in ipairs(list) do
        local policy = self:getActivePolicy(contact.farmId)
        local result = policy ~= nil and self:assess(contact) or nil
        if result ~= nil then
            self:openClaim(contact, result, policy)
        end
    end
end

function TornadoInsuranceEquipment:openClaim(contact, result, policy)
    local insurance = self.insurance
    local farm = insurance:getFarm(contact.farmId)
    farm.equipClaims = farm.equipClaims or {}
    farm.equipNextClaimId = (farm.equipNextClaimId or 0) + 1
    local claim = { id = farm.equipNextClaimId, uniqueId = contact.uniqueId, name = contact.name, day = getDay(),
        value = contact.value, estimate = result.estimate, burned = result.burned,
        deductible = math.floor(policy.deductible * getCostScale() + 0.5), status = "RECEIVED", payout = 0 }
    table.insert(farm.equipClaims, claim)
    while #farm.equipClaims > self.MAX_CLAIMS do
        table.remove(farm.equipClaims, 1)
    end
    insurance:addInbox(contact.farmId, "tp_msg_ins_eq_claim_received", { TornadoText.str(claim.name),
        TornadoText.cash(claim.estimate) }, MSG_INFO)
    insurance:addTimer(contact.farmId, self.TIMER_ADJUSTER, self.ADJUSTER_DAYS, tostring(claim.id))
    if TornadoDebug then
        TornadoDebug:info("INSURANCE", string.format("Equipment claim #%d farm %d: %s value %.0f, estimate %.0f (parts %.0f, engine %.0f, ADS %.0f)%s",
            claim.id, contact.farmId, claim.name, claim.value, result.estimate, result.parts, result.engine, result.ads,
            result.burned and ", burned" or ""))
    end
end

function TornadoInsuranceEquipment:findClaim(farmId, claimId)
    local farm = self.insurance.farms[farmId]
    for _, claim in ipairs(farm ~= nil and farm.equipClaims or {}) do
        if claim.id == claimId then
            return claim, farm
        end
    end
    return nil, farm
end

function TornadoInsuranceEquipment:onAdjuster(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "RECEIVED" then
        return
    end
    claim.status = "INSPECTED"
    self.insurance:addInbox(timer.farmId, "tp_msg_ins_eq_claim_inspected", { TornadoText.str(claim.name) }, MSG_INFO)
    self.insurance:addTimer(timer.farmId, self.TIMER_DECISION, self.DECISION_DAYS, tostring(claim.id))
end

--- The insured value of a claim (replacement value setting: + REPLACEMENT_MARKUP).
function TornadoInsuranceEquipment:getInsuredValue(claim)
    local value = claim.value or 0
    if TornadoInsurance ~= nil and TornadoInsurance.replacementValue then
        value = value * (1 + self.REPLACEMENT_MARKUP)
    end
    return value
end

--- Returns { status = "APPROVED" | "DENIED" | "TOTAL", payout, lossPayout, buyBackPayout }.
function TornadoInsuranceEquipment:decide(claim)
    local value = self:getInsuredValue(claim)
    local deductible = claim.deductible or 0
    if claim.burned or (value > 0 and claim.estimate >= self.TOTAL_LOSS_SHARE * value) then
        local lossPayout = math.max(0, value - deductible)
        local buyBackPayout = math.max(0, value - deductible - value * self.SALVAGE_SHARE)
        return { status = "TOTAL", payout = 0, value = value, lossPayout = math.floor(lossPayout + 0.5),
            buyBackPayout = math.floor(buyBackPayout + 0.5) }
    end
    local payout = math.floor(claim.estimate - deductible + 0.5)
    if payout <= 0 then
        return { status = "DENIED", payout = 0 }
    end
    return { status = "APPROVED", payout = payout }
end

function TornadoInsuranceEquipment:onDecision(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "INSPECTED" then
        return
    end
    local insurance = self.insurance
    local result = self:decide(claim)
    claim.status = result.status
    claim.payout = result.payout
    if result.status == "APPROVED" then
        insurance:addInbox(timer.farmId, "tp_msg_ins_eq_claim_approved", { TornadoText.str(claim.name),
            TornadoText.cash(claim.estimate), TornadoText.cash(claim.deductible), TornadoText.cash(result.payout) }, MSG_INFO)
        insurance:addTimer(timer.farmId, self.TIMER_PAYOUT, self.PAYOUT_DAYS, tostring(claim.id))
    elseif result.status == "TOTAL" then
        claim.lossPayout = result.lossPayout
        claim.buyBackPayout = result.buyBackPayout
        claim.reminderTimer = insurance:addTimer(timer.farmId, self.TIMER_REMINDER, self.REMINDER_DAYS, tostring(claim.id))
        claim.choiceTimer = insurance:addTimer(timer.farmId, self.TIMER_CHOICE, self.CHOICE_DAYS, tostring(claim.id))
        local days, hours = insurance:getRemainingDaysHours(insurance.realDaysToMonths(self.CHOICE_DAYS))
        insurance:addInbox(timer.farmId, claim.burned and "tp_msg_ins_eq_total_burned" or "tp_msg_ins_eq_total",
            { TornadoText.str(claim.name), TornadoText.cash(result.value), TornadoText.cash(result.lossPayout),
            TornadoText.cash(result.buyBackPayout), TornadoText.num(days), TornadoText.num(hours) }, MSG_INFO)
    else
        insurance:addInbox(timer.farmId, "tp_msg_ins_eq_claim_deductible", { TornadoText.str(claim.name),
            TornadoText.cash(claim.estimate), TornadoText.cash(claim.deductible) }, MSG_INFO)
    end
end

function TornadoInsuranceEquipment:onPayout(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "APPROVED" then
        return
    end
    claim.status = "PAID"
    self.insurance:payOut(timer.farmId, claim.payout, "tp_msg_ins_eq_claim_paid",
        { TornadoText.str(claim.name), TornadoText.cash(claim.payout) }, "equipment")
end

function TornadoInsuranceEquipment:onReminder(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "TOTAL" then
        return
    end
    claim.reminderTimer = nil
    local remaining = self.CHOICE_DAYS - self.REMINDER_DAYS
    local days, hours = self.insurance:getRemainingDaysHours(self.insurance.realDaysToMonths(remaining))
    self.insurance:addInbox(timer.farmId, "tp_msg_ins_eq_total_reminder", { TornadoText.str(claim.name),
        TornadoText.num(days), TornadoText.num(hours) }, MSG_INFO)
end

function TornadoInsuranceEquipment:onChoiceTimeout(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "TOTAL" then
        return
    end
    claim.choiceTimer = nil
    self:choose(timer.farmId, claim.id, true, true)
end

--- Total loss: accept (insurer takes the wreck) or buy back (keep it, Salvage title). auto = no choice in time.
function TornadoInsuranceEquipment:choose(farmId, claimId, accept, auto)
    local claim = claimId ~= nil and self:findClaim(farmId, claimId) or nil
    if claim == nil or claim.status ~= "TOTAL" then
        return "tp_msg_ins_eq_no_total"
    end
    local insurance = self.insurance
    for _, field in ipairs({ "reminderTimer", "choiceTimer" }) do
        if claim[field] ~= nil then
            insurance:removeTimer(claim[field])
            claim[field] = nil
        end
    end
    local system = getVehicleSystem()
    local vehicle = system ~= nil and system.getVehicleByUniqueId ~= nil and system:getVehicleByUniqueId(claim.uniqueId) or nil
    local owned = vehicle ~= nil and vehicle.getOwnerFarmId ~= nil and vehicle:getOwnerFarmId() == farmId
    local removeWreck = accept and TornadoInsurance.removeTotaled ~= false
    if accept and removeWreck then
        claim.status = "SETTLED"
        claim.payout = claim.lossPayout or 0
        if owned then
            claim.removePending = true
            self:tryRemove(claim)
        end
        insurance:payOut(farmId, claim.payout, auto and "tp_msg_ins_eq_settled_auto" or "tp_msg_ins_eq_settled",
            { TornadoText.str(claim.name), TornadoText.cash(claim.payout) }, "equipment")
    else
        -- Bought back (or accepted while totalled vehicles are kept): the farm keeps the wreck.
        claim.status = "BOUGHT_BACK"
        claim.payout = claim.buyBackPayout or 0
        if owned then
            self:setTitle(farmId, claim.uniqueId, self.TITLE_SALVAGE)
        end
        local key = "tp_msg_ins_eq_bought_back"
        if auto then
            key = "tp_msg_ins_eq_kept_auto"
        elseif accept then
            key = "tp_msg_ins_eq_kept"
        end
        insurance:payOut(farmId, claim.payout, key, { TornadoText.str(claim.name), TornadoText.cash(claim.payout) }, "equipment")
    end
    return nil
end

--- Removes an accepted wreck (later when someone sits in it).
function TornadoInsuranceEquipment:tryRemove(claim)
    local system = getVehicleSystem()
    local vehicle = system ~= nil and system.getVehicleByUniqueId ~= nil and system:getVehicleByUniqueId(claim.uniqueId) or nil
    if vehicle == nil or vehicle.isDeleted or vehicle.markedForDeletion then
        claim.removePending = nil
        return true
    end
    if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
        return false
    end
    if TornadoDestruction ~= nil and TornadoDestruction._destroyedObjects ~= nil and vehicle.rootNode ~= nil then
        TornadoDestruction._destroyedObjects[vehicle.rootNode] = nil
    end
    vehicle:delete()
    claim.removePending = nil
    return true
end

function TornadoInsuranceEquipment:getOpenClaimCount(farm)
    local count = 0
    for _, claim in ipairs(farm ~= nil and farm.equipClaims or {}) do
        if claim.status == "RECEIVED" or claim.status == "INSPECTED" or claim.status == "APPROVED" or claim.status == "TOTAL" then
            count = count + 1
        end
    end
    return count
end

--- Claim summaries for the Insurance tab (TornadoInsurance:registerClaimSource): values = { insured value,
--- repair estimate, deductible, payout, total loss: accept payout, buy-back payout }; flag = burned. A total loss
--- counts down to the automatic accept.
function TornadoInsuranceEquipment:addClaimSummaries(farmId, farm, list)
    local kinds = { [self.TIMER_ADJUSTER] = true, [self.TIMER_DECISION] = true, [self.TIMER_PAYOUT] = true }
    for _, claim in ipairs(farm ~= nil and farm.equipClaims or {}) do
        local remaining
        if claim.status == "TOTAL" then
            remaining = claim.choiceTimer ~= nil and self.insurance:getTimerRemaining(farmId, kinds, nil, claim.choiceTimer) or -1
        else
            remaining = self.insurance:getTimerRemaining(farmId, kinds, tostring(claim.id))
        end
        table.insert(list, { kind = "EQUIP", id = claim.id, day = claim.day or 0, status = claim.status or "",
            subject = claim.name or "?", info = "", cause = "",
            values = { self:getInsuredValue(claim), claim.estimate or 0, claim.deductible or 0, claim.payout or 0,
                claim.lossPayout or 0, claim.buyBackPayout or 0 }, flag = claim.burned == true, remaining = remaining })
    end
end

--- Total losses waiting for the farm's choice (the panel's Accept / Buy back rows).
function TornadoInsuranceEquipment:getPendingTotals(farm)
    local list = {}
    for _, claim in ipairs(farm ~= nil and farm.equipClaims or {}) do
        if claim.status == "TOTAL" then
            table.insert(list, claim)
        end
    end
    return list
end

-- =========================================================================
-- TITLES (Salvage / Rebuilt) - sell price wrapper on every machine
-- =========================================================================

function TornadoInsuranceEquipment:setTitle(farmId, uniqueId, title)
    local farm = self.insurance:getFarm(farmId)
    farm.titles = farm.titles or {}
    farm.titles[uniqueId] = title
    self.insurance:syncFarm(farmId)
end

function TornadoInsuranceEquipment:getTitle(vehicle)
    local insurance = self.insurance
    if insurance == nil or insurance.farms == nil or vehicle == nil or vehicle.getOwnerFarmId == nil then
        return nil
    end
    local farm = insurance.farms[vehicle:getOwnerFarmId()]
    local uniqueId = self.getUniqueId(vehicle)
    return farm ~= nil and farm.titles ~= nil and uniqueId ~= nil and farm.titles[uniqueId] or nil
end

function TornadoInsuranceEquipment.getTitlePenalty(title)
    if TornadoInsurance == nil then
        return 0
    end
    if title == TornadoInsuranceEquipment.TITLE_SALVAGE then
        return TornadoInsurance.salvagePenalty or 0.5
    elseif title == TornadoInsuranceEquipment.TITLE_REBUILT then
        return TornadoInsurance.rebuiltPenalty or 0.3
    end
    return 0
end

--- The sell price after the vehicle's title (insurance on; no title = unchanged).
function TornadoInsuranceEquipment:applyTitle(vehicle, price)
    if TornadoInsurance == nil or not TornadoInsurance.isEnabled or price == nil then
        return price
    end
    local penalty = self.getTitlePenalty(self:getTitle(vehicle))
    if penalty <= 0 then
        return price
    end
    return price * math.max(0, 1 - penalty)
end

--- Wraps one vehicle's getSellPrice (once - the functions are copied into every vehicle when it loads).
function TornadoInsuranceEquipment.wrapSellPrice(vehicle)
    if vehicle == nil or vehicle.tornadoTitleWrapped or vehicle.getSellPrice == nil then
        return
    end
    local original = vehicle.getSellPrice
    vehicle.getSellPrice = function(v, ...)
        local price = original(v, ...)
        if TornadoInsuranceEquipment == nil or TornadoInsuranceEquipment.insurance == nil then
            return price
        end
        return TornadoInsuranceEquipment:applyTitle(v, price)
    end
    vehicle.tornadoTitleWrapped = true
end

--- A Salvage vehicle that is repaired (no tornado parts missing, engine fixed) becomes Rebuilt.
function TornadoInsuranceEquipment:markRebuilt(vehicle)
    if self:getTitle(vehicle) ~= self.TITLE_SALVAGE then
        return
    end
    self:setTitle(vehicle:getOwnerFarmId(), self.getUniqueId(vehicle), self.TITLE_REBUILT)
    self.insurance:addInbox(vehicle:getOwnerFarmId(), "tp_msg_ins_eq_rebuilt", { TornadoText.str(self.getName(vehicle)) }, MSG_INFO)
end

function TornadoInsuranceEquipment:isRepaired(vehicle)
    if TornadoDestruction ~= nil and TornadoDestruction._destroyedObjects ~= nil and vehicle.rootNode ~= nil
        and TornadoDestruction._destroyedObjects[vehicle.rootNode] ~= nil then
        return false
    end
    return self.getDamage(vehicle) <= self.REBUILT_MAX_DAMAGE
end

--- Every few in-game minutes: wrap new vehicles; server: Salvage -> Rebuilt, wrecks waiting for removal.
function TornadoInsuranceEquipment:onMinuteChanged()
    self.scanMinutes = (self.scanMinutes or 0) + 1
    if self.scanMinutes < self.SCAN_MINUTES then
        return
    end
    self.scanMinutes = 0
    self:scan()
end

function TornadoInsuranceEquipment:scan()
    -- Insurance OFF: no vehicle price is touched (docs/INSURANCE_DESIGN.md §19).
    local insurance = self.insurance
    if insurance == nil or not insurance.isEnabled then
        return
    end
    local system = getVehicleSystem()
    for _, vehicle in pairs(system ~= nil and system.vehicles or {}) do
        self.wrapSellPrice(vehicle)
    end
    if not isServer() then
        return
    end
    for farmId, farm in pairs(insurance.farms) do
        for uniqueId, title in pairs(farm.titles or {}) do
            if title == self.TITLE_SALVAGE and system ~= nil and system.getVehicleByUniqueId ~= nil then
                local vehicle = system:getVehicleByUniqueId(uniqueId)
                if vehicle ~= nil and vehicle:getOwnerFarmId() == farmId and self:isRepaired(vehicle) then
                    self:markRebuilt(vehicle)
                end
            end
        end
        for _, claim in ipairs(farm.equipClaims or {}) do
            if claim.removePending then
                self:tryRemove(claim)
            end
        end
    end
end

-- =========================================================================
-- SAVEGAME (inside TornadoInsurance.xml, per farm)
-- =========================================================================

function TornadoInsuranceEquipment:saveFarm(xmlId, key, farm)
    local policy = farm.equipment
    if policy ~= nil then
        local policyKey = key .. ".equipment"
        setXMLInt(xmlId, policyKey .. "#deductible", policy.deductible)
        setXMLString(xmlId, policyKey .. "#status", policy.status)
        setXMLInt(xmlId, policyKey .. "#activeDay", policy.activeDay or 0)
        setXMLInt(xmlId, policyKey .. "#timerId", policy.timerId or 0)
    end
    setXMLInt(xmlId, key .. ".equipClaims#nextId", farm.equipNextClaimId or 0)
    for i, claim in ipairs(farm.equipClaims or {}) do
        local claimKey = string.format("%s.equipClaims.claim(%d)", key, i - 1)
        setXMLInt(xmlId, claimKey .. "#id", claim.id)
        setXMLString(xmlId, claimKey .. "#vehicle", tostring(claim.uniqueId or ""))
        setXMLString(xmlId, claimKey .. "#name", claim.name or "")
        setXMLInt(xmlId, claimKey .. "#day", claim.day or 0)
        setXMLFloat(xmlId, claimKey .. "#value", claim.value or 0)
        setXMLFloat(xmlId, claimKey .. "#estimate", claim.estimate or 0)
        setXMLFloat(xmlId, claimKey .. "#deductible", claim.deductible or 0)
        setXMLBool(xmlId, claimKey .. "#burned", claim.burned == true)
        setXMLString(xmlId, claimKey .. "#status", claim.status or "")
        setXMLFloat(xmlId, claimKey .. "#payout", claim.payout or 0)
        setXMLFloat(xmlId, claimKey .. "#lossPayout", claim.lossPayout or 0)
        setXMLFloat(xmlId, claimKey .. "#buyBackPayout", claim.buyBackPayout or 0)
        setXMLInt(xmlId, claimKey .. "#reminderTimer", claim.reminderTimer or 0)
        setXMLInt(xmlId, claimKey .. "#choiceTimer", claim.choiceTimer or 0)
        setXMLBool(xmlId, claimKey .. "#removePending", claim.removePending == true)
    end
    local c = 0
    for _, contact in pairs(self.contacts or {}) do
        if self.insurance ~= nil and self.insurance.farms[contact.farmId] == farm then
            local contactKey = string.format("%s.stormContacts.contact(%d)", key, c)
            setXMLString(xmlId, contactKey .. "#vehicle", tostring(contact.uniqueId))
            setXMLInt(xmlId, contactKey .. "#farm", contact.farmId)
            setXMLString(xmlId, contactKey .. "#name", contact.name or "")
            setXMLFloat(xmlId, contactKey .. "#value", contact.value or 0)
            setXMLFloat(xmlId, contactKey .. "#damage", contact.damage or 0)
            setXMLFloat(xmlId, contactKey .. "#ads", contact.ads or 0)
            setXMLFloat(xmlId, contactKey .. "#price", contact.price or 0)
            setXMLInt(xmlId, contactKey .. "#day", contact.day or 0)
            setXMLBool(xmlId, contactKey .. "#burned", contact.burned == true)
            if contact.adsNow ~= nil then
                setXMLFloat(xmlId, contactKey .. "#adsNow", contact.adsNow)
            end
            local recovered = contact.recovered
            if recovered ~= nil then
                setXMLFloat(xmlId, contactKey .. "#recoveredTotal", recovered.total or 0)
                setXMLFloat(xmlId, contactKey .. "#recoveredEngine", recovered.engineCost or 0)
                setXMLFloat(xmlId, contactKey .. "#recoveredDamage", recovered.engineDamage or 0)
            end
            c = c + 1
        end
    end
    local i = 0
    for uniqueId, title in pairs(farm.titles or {}) do
        local titleKey = string.format("%s.titles.title(%d)", key, i)
        setXMLString(xmlId, titleKey .. "#vehicle", tostring(uniqueId))
        setXMLString(xmlId, titleKey .. "#title", title)
        i = i + 1
    end
end

function TornadoInsuranceEquipment:loadFarm(xmlId, key, farm)
    local policyKey = key .. ".equipment"
    local deductible = getXMLInt(xmlId, policyKey .. "#deductible")
    if deductible ~= nil then
        local timerId = getXMLInt(xmlId, policyKey .. "#timerId") or 0
        farm.equipment = { deductible = deductible, status = getXMLString(xmlId, policyKey .. "#status") or self.STATUS_PENDING,
            activeDay = getXMLInt(xmlId, policyKey .. "#activeDay") or 0, timerId = timerId > 0 and timerId or nil }
    end
    farm.equipNextClaimId = getXMLInt(xmlId, key .. ".equipClaims#nextId") or 0
    farm.equipClaims = {}
    local i = 0
    while true do
        local claimKey = string.format("%s.equipClaims.claim(%d)", key, i)
        local id = getXMLInt(xmlId, claimKey .. "#id")
        if id == nil then break end
        local reminderTimer = getXMLInt(xmlId, claimKey .. "#reminderTimer") or 0
        local choiceTimer = getXMLInt(xmlId, claimKey .. "#choiceTimer") or 0
        table.insert(farm.equipClaims, { id = id, uniqueId = getXMLString(xmlId, claimKey .. "#vehicle"),
            name = getXMLString(xmlId, claimKey .. "#name") or "?", day = getXMLInt(xmlId, claimKey .. "#day") or 0,
            value = getXMLFloat(xmlId, claimKey .. "#value") or 0, estimate = getXMLFloat(xmlId, claimKey .. "#estimate") or 0,
            deductible = getXMLFloat(xmlId, claimKey .. "#deductible") or 0, burned = getXMLBool(xmlId, claimKey .. "#burned") == true,
            status = getXMLString(xmlId, claimKey .. "#status") or "", payout = getXMLFloat(xmlId, claimKey .. "#payout") or 0,
            lossPayout = getXMLFloat(xmlId, claimKey .. "#lossPayout") or 0,
            buyBackPayout = getXMLFloat(xmlId, claimKey .. "#buyBackPayout") or 0,
            reminderTimer = reminderTimer > 0 and reminderTimer or nil, choiceTimer = choiceTimer > 0 and choiceTimer or nil,
            removePending = getXMLBool(xmlId, claimKey .. "#removePending") == true or nil })
        i = i + 1
    end
    self.contacts = self.contacts or {}
    i = 0
    while true do
        local contactKey = string.format("%s.stormContacts.contact(%d)", key, i)
        local uniqueId = getXMLString(xmlId, contactKey .. "#vehicle")
        if uniqueId == nil then break end
        local contact = { uniqueId = uniqueId, farmId = getXMLInt(xmlId, contactKey .. "#farm") or 0,
            name = getXMLString(xmlId, contactKey .. "#name") or "?", value = getXMLFloat(xmlId, contactKey .. "#value") or 0,
            damage = getXMLFloat(xmlId, contactKey .. "#damage") or 0, ads = getXMLFloat(xmlId, contactKey .. "#ads") or 0,
            price = getXMLFloat(xmlId, contactKey .. "#price") or 0, day = getXMLInt(xmlId, contactKey .. "#day") or 0,
            burned = getXMLBool(xmlId, contactKey .. "#burned") == true or nil, adsNow = getXMLFloat(xmlId, contactKey .. "#adsNow") }
        local recoveredTotal = getXMLFloat(xmlId, contactKey .. "#recoveredTotal")
        if recoveredTotal ~= nil then
            contact.recovered = { total = recoveredTotal, engineCost = getXMLFloat(xmlId, contactKey .. "#recoveredEngine") or 0,
                engineDamage = getXMLFloat(xmlId, contactKey .. "#recoveredDamage") or 0 }
        end
        self.contacts[uniqueId] = contact
        i = i + 1
    end
    farm.titles = {}
    i = 0
    while true do
        local titleKey = string.format("%s.titles.title(%d)", key, i)
        local uniqueId = getXMLString(xmlId, titleKey .. "#vehicle")
        if uniqueId == nil then break end
        farm.titles[uniqueId] = getXMLString(xmlId, titleKey .. "#title")
        i = i + 1
    end
end

-- =========================================================================
-- CONSOLE (t_dev insurance equip ...)
-- =========================================================================

local function getCurrentVehicle()
    if g_localPlayer ~= nil and g_localPlayer.getCurrentVehicle ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        if vehicle ~= nil then
            return vehicle
        end
    end
    return g_currentMission ~= nil and g_currentMission.controlledVehicle or nil
end

function TornadoInsuranceEquipment:consoleCommand(farmId, sub, value, extra)
    local farm = self.insurance:getFarm(farmId)
    if sub == "quote" or sub == nil then
        print(string.format("---------------- EQUIPMENT INSURANCE QUOTE farm %d ----------------", farmId))
        local system = getVehicleSystem()
        for _, vehicle in pairs(system ~= nil and system.vehicles or {}) do
            if vehicle.getOwnerFarmId ~= nil and vehicle:getOwnerFarmId() == farmId then
                local title = self:getTitle(vehicle)
                print(string.format("  %-40s %s value %9.0f%s", self.getName(vehicle),
                    self.isInsurable(vehicle) and "insured    " or "not insured", self.getValue(vehicle),
                    title ~= nil and ("  title " .. title) or ""))
            end
        end
        for _, deductible in ipairs(self.DEDUCTIBLES) do
            local quote = self:getFarmQuote(farmId, deductible)
            print(string.format("  deductible %6.0f: %d vehicles, value %.0f, premium %.0f per month (%.1f %% a year)",
                deductible * getCostScale(), quote.vehicles, quote.value, quote.monthlyPremium, self.RATES[deductible] * 100))
        end
        local policy = farm.equipment
        return policy ~= nil and string.format("Equipment policy: deductible %d, %s.", policy.deductible, policy.status)
            or "Equipment policy: none (t_dev insurance equip buy <1000 | 2500 | 5000 | 10000>)."
    elseif sub == "buy" then
        TornadoInsurance:requestAction(farmId, "equipBuy", tostring(value or self.DEFAULT_DEDUCTIBLE))
        return "Equipment insurance: request sent."
    elseif sub == "cancel" then
        TornadoInsurance:requestAction(farmId, "equipCancel", "")
        return "Equipment insurance: cancel request sent."
    elseif sub == "accept" or sub == "buyback" then
        local claimId = tonumber(value)
        if claimId == nil then
            local pending = self:getPendingTotals(farm)
            claimId = pending[1] ~= nil and pending[1].id or nil
        end
        if claimId == nil then return "Equipment insurance: no total loss waiting for a choice." end
        TornadoInsurance:requestAction(farmId, sub == "accept" and "equipAccept" or "equipBuyBack", tostring(claimId))
        return "Equipment insurance: choice sent for claim #" .. claimId .. "."
    elseif sub == "claims" then
        print(string.format("---------------- EQUIPMENT CLAIMS farm %d ----------------", farmId))
        for _, claim in ipairs(farm.equipClaims or {}) do
            print(string.format("  #%d day %d %-32s value %8.0f estimate %8.0f deductible %6.0f %-11s payout %8.0f%s%s",
                claim.id, claim.day, claim.name, claim.value, claim.estimate, claim.deductible, claim.status, claim.payout or 0,
                claim.burned and " burned" or "", claim.status == "TOTAL" and string.format(" (accept %.0f / buy back %.0f)",
                claim.lossPayout or 0, claim.buyBackPayout or 0) or ""))
        end
        for uniqueId, title in pairs(farm.titles or {}) do
            print(string.format("  title %-9s %s", title, tostring(uniqueId)))
        end
        return string.format("Equipment: %d claims (%d open), %d storm contacts recorded now.", #(farm.equipClaims or {}),
            self:getOpenClaimCount(farm), self.contacts ~= nil and (function() local n = 0 for _ in pairs(self.contacts) do n = n + 1 end return n end)() or 0)
    end

    if not isServer() then
        return "Equipment insurance: test commands run on the host / server only."
    end
    if sub == "hit" then
        -- Test: the vehicle you sit in is hit by a "storm": value recorded, damage added, parts wrecked.
        local vehicle = getCurrentVehicle()
        if vehicle == nil then return "Equipment insurance: sit in the vehicle to test (t_dev insurance equip hit <damage 0-1>)." end
        local before = self.contacts[self.getUniqueId(vehicle)]
        self:onVehicleContact(vehicle)
        if self.contacts[self.getUniqueId(vehicle)] == nil then
            return "Equipment insurance: not recorded (insurance off, no active policy, or the vehicle is not insurable)."
        end
        local amount = math.max(0, math.min(1, tonumber(value) or 0.3))
        if vehicle.setDamageAmount ~= nil then
            vehicle:setDamageAmount(math.min(1, self.getDamage(vehicle) + amount))
        end
        if TornadoDestruction ~= nil and TornadoDestruction.destroyTarget ~= nil then
            vehicle.tornadoLastDestructionScan = nil
            TornadoDestruction:destroyTarget(vehicle)
        end
        if extra == "fire" and TornadoEffects ~= nil and TornadoEffects.fireFate ~= nil then
            TornadoEffects.fireFate[vehicle.rootNode] = true
        end
        local contact = self.contacts[self.getUniqueId(vehicle)]
        local result = self:assess(contact)
        return string.format("Equipment insurance: %s %s - value %.0f, estimate now %.0f%s. t_dev insurance equip end opens the claims.",
            contact.name, before ~= nil and "hit again" or "hit", contact.value, result ~= nil and result.estimate or 0,
            result ~= nil and result.burned and " (burned = total loss)" or "")
    elseif sub == "end" then
        self:onStormEnded()
        return "Equipment insurance: storm ended - claims opened for the damaged insured vehicles."
    elseif sub == "title" then
        local vehicle = getCurrentVehicle()
        if vehicle == nil then return "Equipment insurance: sit in the vehicle (t_dev insurance equip title <salvage | rebuilt | none>)." end
        local title = value ~= nil and string.upper(value) or nil
        if title ~= self.TITLE_SALVAGE and title ~= self.TITLE_REBUILT then
            title = nil
        end
        self:setTitle(vehicle:getOwnerFarmId(), self.getUniqueId(vehicle), title)
        self.wrapSellPrice(vehicle)
        return string.format("Equipment insurance: %s title = %s, sell price now %.0f.", self.getName(vehicle), tostring(title),
            self.getValue(vehicle))
    end
    return "Usage: t_dev insurance equip <quote | buy <deductible> | cancel | claims | accept [claim] | buyback [claim] | hit <damage> [fire] | end | title <salvage | rebuilt | none>>"
end
