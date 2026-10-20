---@class TornadoInsuranceLivestock
---@version 0.1 (livestock insurance)
---@description Livestock cover per farm (decided 2026-10-19). Animals only die in the mod when the husbandry module
--- (t_set husbandry) is on: TornadoHusbandry:executeKill removes a few animals from an outdoor pasture the tornado
--- hits and reports every kill here first (onAnimalsKilled), with the group's own sell price (age + health).
---
--- Policy: covers all of the farm's animals. Monthly premium = herd value (sell price x animals) x the yearly
--- rate / 12 (x cost scale): Poland uses its data (subsidised rate, cap per head), everywhere else RATE.
--- Cover starts after WAIT_DAYS real-life days, never bought while a tornado is on the ground.
--- Claims open when the tornado ends (TornadoInsuranceDamage:onTornadoEnded -> onStormEnded), one per pasture hit;
--- adjuster -> decision -> payout like the other claims. Payout = insured value (sell price, + REPLACEMENT_MARKUP
--- with the "replacement value" setting; capped per head in Poland) minus EXCESS_SHARE, minus what the state pays.
--- United States: the USDA Livestock Indemnity Program pays GOV_SHARE (75 %) of the market value for animals killed
--- by severe weather (tornadoes included) - free, without a policy too, as long as the insurance is on.
--- State + private never pay more than the insured value.

TornadoInsuranceLivestock = {}

TornadoInsuranceLivestock.WAIT_DAYS = 7
TornadoInsuranceLivestock.ADJUSTER_DAYS = 3
TornadoInsuranceLivestock.DECISION_DAYS = 2
TornadoInsuranceLivestock.PAYOUT_DAYS = 1
TornadoInsuranceLivestock.RATE = 0.008              -- per year of the herd value (estimate: storm-only livestock cover)
TornadoInsuranceLivestock.EXCESS_SHARE = 0.05       -- of every claim
TornadoInsuranceLivestock.REPLACEMENT_MARKUP = 0.15
TornadoInsuranceLivestock.GOV_SHARE = 0.75          -- USDA LIP: 75 % of the market value
TornadoInsuranceLivestock.GOV_COUNTRIES = { US = true }
TornadoInsuranceLivestock.MAX_CLAIMS = 100

TornadoInsuranceLivestock.TIMER_ACTIVE = "LIVESTOCK_ACTIVE"
TornadoInsuranceLivestock.TIMER_ADJUSTER = "LIVESTOCK_ADJUSTER"
TornadoInsuranceLivestock.TIMER_DECISION = "LIVESTOCK_DECISION"
TornadoInsuranceLivestock.TIMER_PAYOUT = "LIVESTOCK_PAYOUT"

TornadoInsuranceLivestock.STATUS_PENDING = "PENDING"
TornadoInsuranceLivestock.STATUS_ACTIVE = "ACTIVE"

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

local function isStormActive()
    if TornadoInsuranceCrop ~= nil and TornadoInsuranceCrop.isStormActive ~= nil then
        return TornadoInsuranceCrop:isStormActive()
    end
    return false
end

-- =========================================================================
-- SETUP (called from TornadoInsurance:loadMap)
-- =========================================================================

function TornadoInsuranceLivestock:install(insurance)
    self.insurance = insurance
    self.kills = {}               -- animals killed in the running storm (saved with the farm)
    insurance:registerPremiumSource("livestock", function(_, farmId)
        return TornadoInsuranceLivestock:getMonthlyPremium(farmId)
    end)
    local handlers = {
        [self.TIMER_ACTIVE] = self.onPolicyActive, [self.TIMER_ADJUSTER] = self.onAdjuster,
        [self.TIMER_DECISION] = self.onDecision, [self.TIMER_PAYOUT] = self.onPayout,
    }
    for kind, fn in pairs(handlers) do
        insurance:registerTimerHandler(kind, function(_, timer) fn(TornadoInsuranceLivestock, timer) end)
    end
    insurance:registerClaimSource(function(_, farmId, farm, list) TornadoInsuranceLivestock:addClaimSummaries(farmId, farm, list) end)
    insurance:registerAction("livestockBuy", true, function(_, farmId) return TornadoInsuranceLivestock:buy(farmId) end)
    insurance:registerAction("livestockCancel", true, function(_, farmId) return TornadoInsuranceLivestock:cancel(farmId) end)
    insurance:registerFarmData(function(xmlId, key, farm) TornadoInsuranceLivestock:saveFarm(xmlId, key, farm) end,
        function(xmlId, key, farm) TornadoInsuranceLivestock:loadFarm(xmlId, key, farm) end)
    if isServer() and g_messageCenter ~= nil and MessageType ~= nil and MessageType.MINUTE_CHANGED ~= nil then
        g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
    end
end

function TornadoInsuranceLivestock:uninstall()
    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end
    self.kills = {}
end

-- =========================================================================
-- ANIMALS + VALUES
-- =========================================================================

--- Animal type name of a group ("COW"), or "?".
function TornadoInsuranceLivestock.getAnimalType(cluster)
    local system = g_currentMission ~= nil and g_currentMission.animalSystem or nil
    if system == nil or cluster == nil or cluster.getSubTypeIndex == nil then
        return "?"
    end
    local subType = system:getSubTypeByIndex(cluster:getSubTypeIndex())
    local animalType = subType ~= nil and system:getTypeByIndex(subType.typeIndex) or nil
    return animalType ~= nil and animalType.name or "?"
end

function TornadoInsuranceLivestock.getPlaceName(placeable)
    return placeable ~= nil and placeable.getName ~= nil and placeable:getName() or "?"
end

--- Is the husbandry module killing animals (otherwise there is nothing to insure against)?
function TornadoInsuranceLivestock.isHusbandryOn()
    return TornadoHusbandry ~= nil and TornadoHusbandry.isActive == true
end

--- The country's livestock data for an animal type ({ rate, maxSumPerHead }) or nil.
function TornadoInsuranceLivestock:getAnimalData(animalType)
    if TornadoInsurance == nil or TornadoInsuranceData == nil or TornadoInsuranceData.getAnimal == nil then
        return nil
    end
    local profile, regionId = TornadoInsurance:getProfile()
    return TornadoInsuranceData.getAnimal(profile, regionId, animalType)
end

--- Yearly farmer rate for an animal type: the country's subsidised rate (Poland) or RATE.
function TornadoInsuranceLivestock:getRate(animalType)
    local data = self:getAnimalData(animalType)
    if data == nil or data.rate == nil then
        return self.RATE
    end
    local profile = TornadoInsurance:getProfile()
    local program = profile ~= nil and profile.program or nil
    local rate = data.rate
    if program ~= nil and program.subsidyShare ~= nil then
        local cap = program.rateCaps ~= nil and program.rateCaps.animal or nil
        local subsidised = cap ~= nil and math.min(rate, cap) or rate
        rate = rate - subsidised * math.max(0, math.min(1, program.subsidyShare))
    end
    return rate
end

--- Insured value of animals: sell price (+ replacement markup), capped per head where the data says so.
function TornadoInsuranceLivestock:getInsuredValue(animalType, count, value)
    local insured = value or 0
    if TornadoInsurance ~= nil and TornadoInsurance.replacementValue then
        insured = insured * (1 + self.REPLACEMENT_MARKUP)
    end
    local data = self:getAnimalData(animalType)
    if data ~= nil and data.maxSumPerHead ~= nil and count ~= nil and count > 0 then
        insured = math.min(insured, data.maxSumPerHead * count)
    end
    return insured
end

--- Does the state pay for weather-killed animals here (USDA LIP)?
function TornadoInsuranceLivestock:hasGovProgram()
    if TornadoInsurance == nil or TornadoInsurance.resolveRegion == nil then
        return false
    end
    return self.GOV_COUNTRIES[TornadoInsurance:resolveRegion().country or ""] == true
end

--- The farm's animals: { animals, value, monthlyPremium (cost scale applied), byType = { TYPE = { count, value } } }.
function TornadoInsuranceLivestock:getFarmQuote(farmId)
    local quote = { animals = 0, value = 0, monthlyPremium = 0, byType = {} }
    local system = g_currentMission ~= nil and g_currentMission.placeableSystem or nil
    for _, placeable in pairs(system ~= nil and system.placeables or {}) do
        if placeable.spec_husbandry ~= nil and placeable.getClusters ~= nil and placeable.getOwnerFarmId ~= nil
            and placeable:getOwnerFarmId() == farmId then
            for _, cluster in pairs(placeable:getClusters() or {}) do
                local count = cluster.getNumAnimals ~= nil and cluster:getNumAnimals() or 0
                if count > 0 then
                    local value = (cluster.getSellPrice ~= nil and cluster:getSellPrice() or 0) * count
                    local animalType = self.getAnimalType(cluster)
                    local entry = quote.byType[animalType] or { count = 0, value = 0 }
                    entry.count = entry.count + count
                    entry.value = entry.value + value
                    quote.byType[animalType] = entry
                    quote.animals = quote.animals + count
                    quote.value = quote.value + value
                end
            end
        end
    end
    local yearly = 0
    for animalType, entry in pairs(quote.byType) do
        yearly = yearly + self:getInsuredValue(animalType, entry.count, entry.value) * self:getRate(animalType)
    end
    quote.monthlyPremium = yearly / 12 * getCostScale()
    return quote
end

function TornadoInsuranceLivestock:getMonthlyPremium(farmId)
    local farm = self.insurance ~= nil and self.insurance.farms[farmId] or nil
    local policy = farm ~= nil and farm.livestock or nil
    if policy == nil or policy.status ~= self.STATUS_ACTIVE then
        return 0
    end
    local scale = getCostScale()
    return scale > 0 and self:getFarmQuote(farmId).monthlyPremium / scale or 0
end

-- =========================================================================
-- BUY / CANCEL
-- =========================================================================

function TornadoInsuranceLivestock:buy(farmId)
    if isStormActive() then
        return "tp_msg_ins_crop_storm"
    end
    local insurance = self.insurance
    local farm = insurance:getFarm(farmId)
    if farm.livestock ~= nil then
        return "tp_msg_ins_lv_already"
    end
    local quote = self:getFarmQuote(farmId)
    farm.livestock = { status = self.STATUS_PENDING }
    farm.livestock.timerId = insurance:addTimer(farmId, self.TIMER_ACTIVE, self.WAIT_DAYS, "")
    local days, hours = insurance:getRemainingDaysHours(insurance.realDaysToMonths(self.WAIT_DAYS))
    insurance:addInbox(farmId, "tp_msg_ins_lv_bought", { TornadoText.num(quote.animals), TornadoText.cash(quote.monthlyPremium),
        TornadoText.num(days), TornadoText.num(hours) }, MSG_INFO)
    return nil
end

function TornadoInsuranceLivestock:cancel(farmId)
    local insurance = self.insurance
    local farm = insurance:getFarm(farmId)
    if farm.livestock == nil then
        return "tp_msg_ins_lv_none"
    end
    if farm.livestock.timerId ~= nil then
        insurance:removeTimer(farm.livestock.timerId)
    end
    farm.livestock = nil
    insurance:addInbox(farmId, "tp_msg_ins_lv_cancelled", {}, MSG_INFO)   -- open claims carry on
    return nil
end

function TornadoInsuranceLivestock:onPolicyActive(timer)
    local farm = self.insurance:getFarm(timer.farmId)
    if farm.livestock == nil or farm.livestock.status ~= self.STATUS_PENDING then
        return
    end
    farm.livestock.status = self.STATUS_ACTIVE
    farm.livestock.activeDay = getDay()
    farm.livestock.timerId = nil
    self.insurance:addInbox(timer.farmId, "tp_msg_ins_lv_active", {}, MSG_INFO)
end

-- =========================================================================
-- KILLS + CLAIMS (server)
-- =========================================================================

--- TornadoHusbandry, just before `count` animals of `cluster` are removed from `placeable`.
function TornadoInsuranceLivestock:onAnimalsKilled(placeable, cluster, count)
    local insurance = self.insurance
    if insurance == nil or not insurance.isEnabled or not isServer() or count == nil or count <= 0 or placeable == nil then
        return
    end
    local farmId = placeable.getOwnerFarmId ~= nil and placeable:getOwnerFarmId() or 0
    if farmId == nil or farmId == 0 or (FarmManager ~= nil and farmId == FarmManager.SPECTATOR_FARM_ID) then
        return
    end
    local perHead = cluster ~= nil and cluster.getSellPrice ~= nil and (cluster:getSellPrice() or 0) or 0
    -- placeId: the pasture's unique id, so two pastures with the same name stay two claims.
    local placeId = placeable.getUniqueId ~= nil and placeable:getUniqueId() or nil
    table.insert(self.kills, { farmId = farmId, place = self.getPlaceName(placeable), placeId = tostring(placeId or self.getPlaceName(placeable)),
        animalType = self.getAnimalType(cluster), count = count, value = perHead * count, day = getDay() })
    if TornadoDebug then
        TornadoDebug:info("INSURANCE", string.format("Livestock: %d %s killed at %s (farm %d), value %.0f - claim when the tornado ends.",
            count, self.getAnimalType(cluster), self.getPlaceName(placeable), farmId, perHead * count))
    end
end

--- No tornado on the map any more (a kill test, a storm that ended without the end call): close the kills.
function TornadoInsuranceLivestock:onMinuteChanged()
    if #(self.kills or {}) > 0 and not isStormActive() then
        self:onStormEnded()
    end
end

--- The tornado is over: one claim per farm and pasture, adding up EVERY hit of this storm on that pasture
--- (a slow tornado crossing a big pasture hits it again each time the husbandry immunity runs out).
function TornadoInsuranceLivestock:onStormEnded()
    if self.insurance == nil or not isServer() or self.kills == nil or #self.kills == 0 then
        return
    end
    local groups, order = {}, {}
    for _, kill in ipairs(self.kills) do
        local key = kill.farmId .. "|" .. (kill.placeId or kill.place)
        local group = groups[key]
        if group == nil then
            group = { farmId = kill.farmId, place = kill.place, day = kill.day, count = 0, value = 0, insured = 0, byType = {} }
            groups[key] = group
            table.insert(order, key)
        end
        group.count = group.count + kill.count
        group.value = group.value + kill.value
        group.insured = group.insured + self:getInsuredValue(kill.animalType, kill.count, kill.value)
        group.byType[kill.animalType] = (group.byType[kill.animalType] or 0) + kill.count
    end
    self.kills = {}
    for _, key in ipairs(order) do
        self:openClaim(groups[key])
    end
end

function TornadoInsuranceLivestock:openClaim(group)
    local insurance = self.insurance
    local farm = insurance:getFarm(group.farmId)
    local policy = farm.livestock
    local insured = policy ~= nil and policy.status == self.STATUS_ACTIVE and group.day >= (policy.activeDay or 0)
    local gov = self:hasGovProgram()
    if not insured and not gov then
        return   -- nobody pays: the storm report already told the farm
    end
    farm.livestockClaims = farm.livestockClaims or {}
    farm.livestockNextClaimId = (farm.livestockNextClaimId or 0) + 1
    local claim = { id = farm.livestockNextClaimId, place = group.place, count = group.count, value = group.value,
        insured = insured and group.insured or 0, gov = gov, day = getDay(), status = "RECEIVED", payout = 0, govPayout = 0,
        animals = group.byType }
    table.insert(farm.livestockClaims, claim)
    while #farm.livestockClaims > self.MAX_CLAIMS do
        table.remove(farm.livestockClaims, 1)
    end
    insurance:addInbox(group.farmId, "tp_msg_ins_lv_claim_received", { TornadoText.num(claim.count), TornadoText.str(claim.place),
        TornadoText.cash(claim.value) }, MSG_INFO)
    insurance:addTimer(group.farmId, self.TIMER_ADJUSTER, self.ADJUSTER_DAYS, tostring(claim.id))
end

function TornadoInsuranceLivestock:findClaim(farmId, claimId)
    local farm = self.insurance.farms[farmId]
    for _, claim in ipairs(farm ~= nil and farm.livestockClaims or {}) do
        if claim.id == claimId then
            return claim, farm
        end
    end
    return nil, farm
end

function TornadoInsuranceLivestock:onAdjuster(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "RECEIVED" then
        return
    end
    claim.status = "INSPECTED"
    self.insurance:addInbox(timer.farmId, "tp_msg_ins_lv_claim_inspected", { TornadoText.str(claim.place) }, MSG_INFO)
    self.insurance:addTimer(timer.farmId, self.TIMER_DECISION, self.DECISION_DAYS, tostring(claim.id))
end

--- State: GOV_SHARE of the market value. Private: insured value minus the excess, minus the state's part.
--- Returns govPayout, payout (both rounded).
function TornadoInsuranceLivestock:decide(claim)
    local govPayout = claim.gov and claim.value * self.GOV_SHARE or 0
    local payout = 0
    if (claim.insured or 0) > 0 then
        payout = math.max(0, claim.insured * (1 - self.EXCESS_SHARE) - govPayout)
    end
    return math.floor(govPayout + 0.5), math.floor(payout + 0.5)
end

function TornadoInsuranceLivestock:onDecision(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "INSPECTED" then
        return
    end
    local govPayout, payout = self:decide(claim)
    claim.govPayout, claim.payout = govPayout, payout
    claim.status = "APPROVED"
    if govPayout > 0 then
        self.insurance:addInbox(timer.farmId, "tp_msg_ins_lv_gov_approved", { TornadoText.num(claim.count), TornadoText.str(claim.place),
            TornadoText.cash(govPayout) }, MSG_INFO)
    end
    if (claim.insured or 0) > 0 then
        self.insurance:addInbox(timer.farmId, "tp_msg_ins_lv_claim_approved", { TornadoText.str(claim.place), TornadoText.cash(claim.insured),
            TornadoText.cash(payout) }, MSG_INFO)
    end
    self.insurance:addTimer(timer.farmId, self.TIMER_PAYOUT, self.PAYOUT_DAYS, tostring(claim.id))
end

function TornadoInsuranceLivestock:onPayout(timer)
    local claim = self:findClaim(timer.farmId, tonumber(timer.data))
    if claim == nil or claim.status ~= "APPROVED" then
        return
    end
    claim.status = "PAID"
    if (claim.govPayout or 0) > 0 then
        self.insurance:payOut(timer.farmId, claim.govPayout, "tp_msg_ins_lv_gov_paid", { TornadoText.cash(claim.govPayout) })
    end
    if (claim.payout or 0) > 0 then
        self.insurance:payOut(timer.farmId, claim.payout, "tp_msg_ins_lv_claim_paid",
            { TornadoText.str(claim.place), TornadoText.cash(claim.payout) })
    end
end

--- Claim summaries for the Insurance tab (TornadoInsurance:registerClaimSource): values = { animals, market value,
--- insured value (0 = no policy), state payout, policy payout }; flag = state programme (USDA LIP) pays too.
function TornadoInsuranceLivestock:addClaimSummaries(farmId, farm, list)
    local kinds = { [self.TIMER_ADJUSTER] = true, [self.TIMER_DECISION] = true, [self.TIMER_PAYOUT] = true }
    for _, claim in ipairs(farm ~= nil and farm.livestockClaims or {}) do
        local govPayout, payout = claim.govPayout or 0, claim.payout or 0
        if claim.status == "RECEIVED" or claim.status == "INSPECTED" then
            govPayout, payout = self:decide(claim)   -- what the decision will pay (shown as expected)
        end
        table.insert(list, { kind = "LIVESTOCK", id = claim.id, day = claim.day or 0, status = claim.status or "",
            subject = claim.place or "?", info = "", cause = "",
            values = { claim.count or 0, claim.value or 0, claim.insured or 0, govPayout, payout }, flag = claim.gov == true,
            remaining = self.insurance:getTimerRemaining(farmId, kinds, tostring(claim.id)) })
    end
end

function TornadoInsuranceLivestock:getOpenClaimCount(farm)
    local count = 0
    for _, claim in ipairs(farm ~= nil and farm.livestockClaims or {}) do
        if claim.status == "RECEIVED" or claim.status == "INSPECTED" or claim.status == "APPROVED" then
            count = count + 1
        end
    end
    return count
end

-- =========================================================================
-- SAVEGAME (inside TornadoInsurance.xml, per farm)
-- =========================================================================

function TornadoInsuranceLivestock:saveFarm(xmlId, key, farm)
    local policy = farm.livestock
    if policy ~= nil then
        setXMLString(xmlId, key .. ".livestock#status", policy.status)
        setXMLInt(xmlId, key .. ".livestock#activeDay", policy.activeDay or 0)
        setXMLInt(xmlId, key .. ".livestock#timerId", policy.timerId or 0)
    end
    setXMLInt(xmlId, key .. ".livestockClaims#nextId", farm.livestockNextClaimId or 0)
    for i, claim in ipairs(farm.livestockClaims or {}) do
        local claimKey = string.format("%s.livestockClaims.claim(%d)", key, i - 1)
        setXMLInt(xmlId, claimKey .. "#id", claim.id)
        setXMLString(xmlId, claimKey .. "#place", claim.place or "")
        setXMLInt(xmlId, claimKey .. "#count", claim.count or 0)
        setXMLFloat(xmlId, claimKey .. "#value", claim.value or 0)
        setXMLFloat(xmlId, claimKey .. "#insured", claim.insured or 0)
        setXMLBool(xmlId, claimKey .. "#gov", claim.gov == true)
        setXMLInt(xmlId, claimKey .. "#day", claim.day or 0)
        setXMLString(xmlId, claimKey .. "#status", claim.status or "")
        setXMLFloat(xmlId, claimKey .. "#payout", claim.payout or 0)
        setXMLFloat(xmlId, claimKey .. "#govPayout", claim.govPayout or 0)
    end
    local k = 0
    for _, kill in ipairs(self.kills or {}) do
        if self.insurance ~= nil and self.insurance.farms[kill.farmId] == farm then
            local killKey = string.format("%s.livestockKills.kill(%d)", key, k)
            setXMLInt(xmlId, killKey .. "#farm", kill.farmId)
            setXMLString(xmlId, killKey .. "#place", kill.place or "")
            setXMLString(xmlId, killKey .. "#placeId", kill.placeId or kill.place or "")
            setXMLString(xmlId, killKey .. "#type", kill.animalType or "?")
            setXMLInt(xmlId, killKey .. "#count", kill.count or 0)
            setXMLFloat(xmlId, killKey .. "#value", kill.value or 0)
            setXMLInt(xmlId, killKey .. "#day", kill.day or 0)
            k = k + 1
        end
    end
end

function TornadoInsuranceLivestock:loadFarm(xmlId, key, farm)
    local status = getXMLString(xmlId, key .. ".livestock#status")
    if status ~= nil then
        local timerId = getXMLInt(xmlId, key .. ".livestock#timerId") or 0
        farm.livestock = { status = status, activeDay = getXMLInt(xmlId, key .. ".livestock#activeDay") or 0,
            timerId = timerId > 0 and timerId or nil }
    end
    farm.livestockNextClaimId = getXMLInt(xmlId, key .. ".livestockClaims#nextId") or 0
    farm.livestockClaims = {}
    local i = 0
    while true do
        local claimKey = string.format("%s.livestockClaims.claim(%d)", key, i)
        local id = getXMLInt(xmlId, claimKey .. "#id")
        if id == nil then break end
        table.insert(farm.livestockClaims, { id = id, place = getXMLString(xmlId, claimKey .. "#place") or "?",
            count = getXMLInt(xmlId, claimKey .. "#count") or 0, value = getXMLFloat(xmlId, claimKey .. "#value") or 0,
            insured = getXMLFloat(xmlId, claimKey .. "#insured") or 0, gov = getXMLBool(xmlId, claimKey .. "#gov") == true,
            day = getXMLInt(xmlId, claimKey .. "#day") or 0, status = getXMLString(xmlId, claimKey .. "#status") or "",
            payout = getXMLFloat(xmlId, claimKey .. "#payout") or 0, govPayout = getXMLFloat(xmlId, claimKey .. "#govPayout") or 0 })
        i = i + 1
    end
    self.kills = self.kills or {}
    i = 0
    while true do
        local killKey = string.format("%s.livestockKills.kill(%d)", key, i)
        local farmId = getXMLInt(xmlId, killKey .. "#farm")
        if farmId == nil then break end
        table.insert(self.kills, { farmId = farmId, place = getXMLString(xmlId, killKey .. "#place") or "?",
            placeId = getXMLString(xmlId, killKey .. "#placeId"),
            animalType = getXMLString(xmlId, killKey .. "#type") or "?", count = getXMLInt(xmlId, killKey .. "#count") or 0,
            value = getXMLFloat(xmlId, killKey .. "#value") or 0, day = getXMLInt(xmlId, killKey .. "#day") or 0 })
        i = i + 1
    end
end

-- =========================================================================
-- CONSOLE (t_dev insurance livestock ...)
-- =========================================================================

function TornadoInsuranceLivestock:consoleCommand(farmId, sub)
    local farm = self.insurance:getFarm(farmId)
    if sub == "quote" or sub == nil then
        local quote = self:getFarmQuote(farmId)
        print(string.format("---------------- LIVESTOCK INSURANCE QUOTE farm %d ----------------", farmId))
        for animalType, entry in pairs(quote.byType) do
            local data = self:getAnimalData(animalType)
            print(string.format("  %-10s %5d animals  value %10.0f  insured %10.0f  rate %.2f %% a year%s", animalType, entry.count,
                entry.value, self:getInsuredValue(animalType, entry.count, entry.value), self:getRate(animalType) * 100,
                data ~= nil and data.maxSumPerHead ~= nil and string.format("  (cap %.0f per head)", data.maxSumPerHead) or ""))
        end
        local policy = farm.livestock
        return string.format("Livestock: %d animals, value %.0f, premium %.0f per month (cost scale applied). State programme: %s. Husbandry module: %s. Policy: %s.",
            quote.animals, quote.value, quote.monthlyPremium, self:hasGovProgram() and "USDA LIP, 75 %" or "none",
            self.isHusbandryOn() and "ON" or "OFF (animals cannot die)", policy ~= nil and policy.status or "none")
    elseif sub == "buy" then
        TornadoInsurance:requestAction(farmId, "livestockBuy", "")
        return "Livestock insurance: request sent."
    elseif sub == "cancel" then
        TornadoInsurance:requestAction(farmId, "livestockCancel", "")
        return "Livestock insurance: cancel request sent."
    elseif sub == "claims" then
        print(string.format("---------------- LIVESTOCK CLAIMS farm %d ----------------", farmId))
        for _, claim in ipairs(farm.livestockClaims or {}) do
            print(string.format("  #%d day %d %-28s %3d animals value %8.0f insured %8.0f %-9s state %8.0f policy %8.0f",
                claim.id, claim.day, claim.place, claim.count, claim.value, claim.insured or 0, claim.status, claim.govPayout or 0,
                claim.payout or 0))
        end
        return string.format("Livestock: %d claims (%d open), %d kills waiting for the storm to end.", #(farm.livestockClaims or {}),
            self:getOpenClaimCount(farm), #(self.kills or {}))
    elseif sub == "end" then
        self:onStormEnded()
        return "Livestock insurance: storm ended - claims opened for the animals killed."
    end
    return "Usage: t_dev insurance livestock <quote | buy | cancel | claims | end>  (kill test: t_dev kill_test)"
end
