---@class TornadoInsurance
---@version 0.1 (phase 0 - foundation)
---@description Optional per-farm insurance (docs/INSURANCE_DESIGN.md). OFF by default.
--- Phase 0 is the shared foundation the crop and equipment policies build on:
---   * settings: on/off, who may manage policies (farm manager + admin / admin only), insurance region
---   * the insurance profile of the map's country (DB/CropInsurance_<country>.xml via TornadoInsuranceData)
---   * time model (§5): monthly billing on the game's month change, countdowns in real-life days that tick
---     down by in-game time actually passed (correct at any days-per-month setting, also when it changes)
---   * money: own money types (premiums / payouts, shown under "Other" on the finance page), cost scale
---   * per-farm state: inbox, premium / payout totals and monthly history - saved in TornadoInsurance.xml
---   * multiplayer: client -> server actions (TornadoInsuranceActionEvent, permission checked on the
---     server), server -> farm state (TornadoInsuranceStateEvent), joining players get every farm's state
--- Policies register a premium source (registerPremiumSource), timer kinds (registerTimerHandler) and
--- actions (registerAction); phase 0 itself only has the dev test versions of them.
--- Gameplay (billing, timers, money, saving) runs on the server only.

TornadoInsurance = {}

-- Settings (TornadoSettings / TornadoSync)
TornadoInsurance.isEnabled = false
TornadoInsurance.adminOnly = false            -- true: only the server admin may buy / change / cancel policies
TornadoInsurance.regionSetting = "auto"       -- "auto", a profile country ("DE") or "country:region" ("US:US_KS")
TornadoInsurance.salesClosing = "auto"        -- crop policies only in late winter / early spring: "auto" (with seasonal growth), "on", "off"

TornadoInsurance.REGION_AUTO = "auto"
TornadoInsurance.FILE = "TornadoInsurance.xml"
TornadoInsurance.REAL_DAYS_PER_MONTH = 30     -- durations are real-life days; 30 of them = one in-game month
TornadoInsurance.MAX_INBOX = 50
TornadoInsurance.HISTORY_MONTHS = 24
TornadoInsurance.MAX_PARAMS = 15
TornadoInsurance.MS_PER_DAY = 24 * 60 * 60 * 1000

TornadoInsurance.TIMER_TEST = "TEST"

-- Message kind (same value as TornadoSync.MSG_INFO; TornadoSync may not exist in offline tests)
local MSG_INFO = 3

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

local function isMultiplayer()
    return TornadoSync ~= nil and TornadoSync.isMultiplayer ~= nil and TornadoSync:isMultiplayer()
end

local function getEnvironment()
    return g_currentMission ~= nil and g_currentMission.environment or nil
end

function TornadoInsurance:loadMap(modDir, modName)
    self.modDir = modDir
    self.modName = modName
    self.farms = {}               -- farmId -> farm state (see getFarm)
    self.timers = {}              -- { id, farmId, kind, remaining (months), data (string) }
    self.nextTimerId = 1
    self.lastAbsoluteMs = nil     -- in-game time of the last timer tick
    self.profiles = {}            -- country -> loaded profile (false = file missing)
    self.resolved = nil           -- cached region resolution { setting, country, regionId, source }
    self.testPremium = 0          -- dev: monthly premium of the test source (t_dev insurance testpremium)

    self.premiumSources = {}      -- { name, fn(self, farmId) -> amount before cost scale }
    self.timerHandlers = {}       -- kind -> fn(self, timer)
    self.actions = {}             -- name -> { managerOnly, run = fn(self, farmId, args, connection) -> resultKey }
    self.farmData = {}            -- { save = fn(xmlId, farmKey, farm), load = fn(xmlId, farmKey, farm) } per policy type
    self.damageListeners = {}     -- fn(self, entry) for every closed storm damage event

    self:registerMoneyTypes()
    self:registerBuiltIns()
    if TornadoInsuranceCrop ~= nil then
        TornadoInsuranceCrop:install(self)
    end

    if isServer() then
        self:loadState()
        if g_messageCenter ~= nil then
            g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
            g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
        end
    end
    if TornadoDebug then
        TornadoDebug:info("INSURANCE", string.format("V0.1 loaded (enabled %s, %s)", tostring(self.isEnabled),
            self:getRegionStatusText()))
    end
end

function TornadoInsurance:deleteMap()
    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end
    if TornadoInsuranceCrop ~= nil then
        TornadoInsuranceCrop:uninstall()
    end
    self.farms = {}
    self.timers = {}
    self.profiles = {}
    self.resolved = nil
end

--- Module running (gameplay side): enabled and on the server.
function TornadoInsurance:isActive()
    return self.isEnabled and isServer()
end

-- =========================================================================
-- EXTENSION POINTS (used by the policy phases)
-- =========================================================================

--- fn(self, farmId) -> monthly premium of this source before the cost scale (0 / nil = nothing).
function TornadoInsurance:registerPremiumSource(name, fn)
    for _, source in ipairs(self.premiumSources) do
        if source.name == name then
            source.fn = fn
            return
        end
    end
    table.insert(self.premiumSources, { name = name, fn = fn })
end

--- fn(self, timer) runs on the server when a timer of this kind runs out.
function TornadoInsurance:registerTimerHandler(kind, fn)
    self.timerHandlers[kind] = fn
end

--- Action a player can ask the server for. run(self, farmId, args, connection) -> result text key or nil.
--- managerOnly: needs the policy-manager permission (canManage); false for read-only actions.
function TornadoInsurance:registerAction(name, managerOnly, run)
    self.actions[name] = { managerOnly = managerOnly == true, run = run }
end

--- Per-farm data of a policy type, saved inside the farm's element of TornadoInsurance.xml.
function TornadoInsurance:registerFarmData(saveFn, loadFn)
    table.insert(self.farmData, { save = saveFn, load = loadFn })
end

--- fn(self, entry) for every closed storm damage event (TornadoInsuranceDamage log entry) - claims.
function TornadoInsurance:registerDamageListener(fn)
    table.insert(self.damageListeners, fn)
end

--- Server: called by TornadoInsuranceDamage when an event is closed and logged.
function TornadoInsurance:onDamageLogged(entry)
    if not isServer() then
        return
    end
    for _, fn in ipairs(self.damageListeners or {}) do
        fn(self, entry)
    end
end

function TornadoInsurance:registerBuiltIns()
    -- Dev test premium (t_dev insurance testpremium <amount>) - not saved.
    self:registerPremiumSource("test", function(insurance, _)
        return insurance.testPremium or 0
    end)
    self:registerTimerHandler(self.TIMER_TEST, function(insurance, timer)
        insurance:addInbox(timer.farmId, "tp_msg_ins_test_timer", {}, MSG_INFO)
    end)
    -- Client asks for its farm's state (opening the panel, after switching farms).
    self:registerAction("refresh", false, function(insurance, farmId, _, connection)
        insurance:sendFarmState(farmId, connection)
        return nil
    end)
    -- Inbox messages read.
    self:registerAction("read", false, function(insurance, farmId)
        local farm = insurance:getFarm(farmId)
        for _, message in ipairs(farm.inbox) do
            message.read = true
        end
        insurance:syncFarm(farmId)
        return nil
    end)
end

-- =========================================================================
-- MONEY
-- =========================================================================

--- Own money types, registered on every machine in the same order (the ids travel over the network).
--- Statistics = our own Finances-page rows (TornadoInsuranceFinance); "other" when those could not be added.
--- The HUD money popup shows our own title.
function TornadoInsurance:registerMoneyTypes()
    if MoneyType == nil or MoneyType.register == nil then
        return
    end
    local premiumStat, payoutStat = "other", "other"
    if TornadoInsuranceFinance ~= nil and FinanceStats ~= nil and FinanceStats.statNameToIndex ~= nil
        and FinanceStats.statNameToIndex[TornadoInsuranceFinance.STAT_PREMIUM] ~= nil then
        premiumStat, payoutStat = TornadoInsuranceFinance.STAT_PREMIUM, TornadoInsuranceFinance.STAT_PAYOUT
    end
    self.moneyTypePremium = MoneyType.register(premiumStat, "tp_money_ins_premium", self.modName)
    self.moneyTypePayout = MoneyType.register(payoutStat, "tp_money_ins_payout", self.modName)
    self.redTapeLinked = TornadoInsuranceFinance ~= nil and TornadoInsuranceFinance.installRedTape() or false
end

function TornadoInsurance:getCostScale()
    if TornadoSettings ~= nil and TornadoSettings.getCostScale ~= nil then
        return TornadoSettings:getCostScale()
    end
    return 1.0
end

--- Month index for the history (counts up from year 1, early spring).
function TornadoInsurance:getMonthIndex()
    local environment = getEnvironment()
    if environment == nil then
        return 0
    end
    local periods = Environment ~= nil and Environment.PERIODS_IN_YEAR or 12
    return ((environment.currentYear or 1) - 1) * periods + (environment.currentPeriod or 1)
end

function TornadoInsurance:addHistory(farm, premiums, payouts)
    local index = self:getMonthIndex()
    local last = farm.history[#farm.history]
    if last == nil or last.month ~= index then
        last = { month = index, premiums = 0, payouts = 0 }
        table.insert(farm.history, last)
        while #farm.history > self.HISTORY_MONTHS do
            table.remove(farm.history, 1)
        end
    end
    last.premiums = last.premiums + (premiums or 0)
    last.payouts = last.payouts + (payouts or 0)
end

--- Server: takes a premium from the farm. amount is final (cost scale already applied). Returns true when charged.
function TornadoInsurance:chargePremium(farmId, amount, messageKey, params)
    if not isServer() or farmId == nil or farmId == 0 or amount == nil or amount <= 0 then
        return false
    end
    amount = math.floor(amount + 0.5)
    if amount <= 0 then
        return false
    end
    if g_farmManager ~= nil and g_farmManager:getFarmById(farmId) == nil then
        return false
    end
    g_currentMission:addMoney(-amount, farmId, self.moneyTypePremium or MoneyType.OTHER, true, true)
    local farm = self:getFarm(farmId)
    farm.premiumsTotal = farm.premiumsTotal + amount
    self:addHistory(farm, amount, 0)
    if messageKey ~= nil then
        local messageParams = params or { TornadoText.cash(amount) }
        self:addInbox(farmId, messageKey, messageParams, MSG_INFO)
    else
        self:syncFarm(farmId)
    end
    return true
end

--- Server: pays money to the farm (claims). amount comes from in-game values - no cost scale.
function TornadoInsurance:payOut(farmId, amount, messageKey, params)
    if not isServer() or farmId == nil or farmId == 0 or amount == nil or amount <= 0 then
        return false
    end
    amount = math.floor(amount + 0.5)
    if amount <= 0 then
        return false
    end
    if g_farmManager ~= nil and g_farmManager:getFarmById(farmId) == nil then
        return false
    end
    g_currentMission:addMoney(amount, farmId, self.moneyTypePayout or MoneyType.OTHER, true, true)
    local farm = self:getFarm(farmId)
    farm.payoutsTotal = farm.payoutsTotal + amount
    self:addHistory(farm, 0, amount)
    if messageKey ~= nil then
        self:addInbox(farmId, messageKey, params or { TornadoText.cash(amount) }, MSG_INFO)
    else
        self:syncFarm(farmId)
    end
    return true
end

--- Monthly billing (game month change). Every premium source is asked for each farm.
function TornadoInsurance:onPeriodChanged()
    if not self:isActive() or g_farmManager == nil then
        return
    end
    local scale = self:getCostScale()
    for _, farm in ipairs(g_farmManager:getFarms()) do
        local farmId = farm.farmId
        if farmId ~= nil and farmId ~= 0 and (FarmManager == nil or farmId ~= FarmManager.SPECTATOR_FARM_ID) then
            local total = 0
            for _, source in ipairs(self.premiumSources) do
                total = total + math.max(0, tonumber(source.fn(self, farmId)) or 0)
            end
            if total > 0 then
                self:chargePremium(farmId, total * scale, "tp_msg_ins_premium_charged")
            end
        end
    end
end

-- =========================================================================
-- TIME MODEL (§5)
-- =========================================================================

function TornadoInsurance.realDaysToMonths(days)
    return (tonumber(days) or 0) / TornadoInsurance.REAL_DAYS_PER_MONTH
end

function TornadoInsurance:getDaysPerMonth()
    local environment = getEnvironment()
    return math.max(1, environment ~= nil and environment.daysPerPeriod or 1)
end

--- In-game time in ms since day 0 (monotonic: does not jump back at a new year).
function TornadoInsurance:getAbsoluteMs()
    local environment = getEnvironment()
    if environment == nil then
        return nil
    end
    return (environment.currentMonotonicDay or 0) * self.MS_PER_DAY + (environment.dayTime or 0)
end

--- Server: starts a countdown of realDays real-life days. data is a string the handler can read. Returns the id.
function TornadoInsurance:addTimer(farmId, kind, realDays, data)
    local timer = {
        id = self.nextTimerId,
        farmId = farmId or 0,
        kind = kind,
        remaining = self.realDaysToMonths(realDays),
        data = data or "",
    }
    self.nextTimerId = self.nextTimerId + 1
    table.insert(self.timers, timer)
    return timer.id
end

function TornadoInsurance:removeTimer(id)
    for i = #self.timers, 1, -1 do
        if self.timers[i].id == id then
            table.remove(self.timers, i)
            return true
        end
    end
    return false
end

--- Counts every timer down by the in-game time passed since the last call (months = time / month length,
--- with the month length read now - a days-per-month change mid-countdown stays fair).
function TornadoInsurance:advanceTimers(elapsedMs)
    if elapsedMs == nil or elapsedMs <= 0 or #self.timers == 0 then
        return
    end
    local months = elapsedMs / (self:getDaysPerMonth() * self.MS_PER_DAY)
    local due = {}
    for i = #self.timers, 1, -1 do
        local timer = self.timers[i]
        timer.remaining = timer.remaining - months
        if timer.remaining <= 1e-9 then   -- float steps can stop a hair above zero
            table.remove(self.timers, i)
            table.insert(due, 1, timer)
        end
    end
    for _, timer in ipairs(due) do
        local handler = self.timerHandlers[timer.kind]
        if handler ~= nil then
            handler(self, timer)
        elseif TornadoDebug then
            TornadoDebug:info("INSURANCE", "No handler for timer kind " .. tostring(timer.kind))
        end
    end
end

function TornadoInsurance:onMinuteChanged()
    local now = self:getAbsoluteMs()
    if now == nil then
        return
    end
    local last = self.lastAbsoluteMs
    self.lastAbsoluteMs = now
    if last == nil or not self:isActive() then
        return
    end
    self:advanceTimers(now - last)
end

--- Remaining time of a countdown in in-game days and hours.
function TornadoInsurance:getRemainingDaysHours(months)
    local hours = math.max(0, (months or 0) * self:getDaysPerMonth() * 24)
    local days = math.floor(hours / 24)
    return days, math.floor(hours - days * 24 + 0.5)
end

-- =========================================================================
-- FARM STATE + INBOX
-- =========================================================================

function TornadoInsurance:getFarm(farmId)
    local farm = self.farms[farmId]
    if farm == nil then
        farm = { premiumsTotal = 0, payoutsTotal = 0, inbox = {}, history = {} }
        self.farms[farmId] = farm
    end
    return farm
end

local function getDay()
    local environment = getEnvironment()
    return environment ~= nil and environment.currentMonotonicDay or 0
end

--- Server: letter from the insurer - kept in the farm's inbox and shown as a notification to that farm.
function TornadoInsurance:addInbox(farmId, key, params, kind)
    if farmId == nil or farmId == 0 then
        return
    end
    local farm = self:getFarm(farmId)
    table.insert(farm.inbox, { key = key, params = params or {}, day = getDay(), read = false })
    while #farm.inbox > self.MAX_INBOX do
        table.remove(farm.inbox, 1)
    end
    if TornadoSync ~= nil and TornadoSync.sendMessage ~= nil then
        TornadoSync:sendMessage(key, params or {}, kind or MSG_INFO, farmId)
    end
    self:syncFarm(farmId)
end

function TornadoInsurance:getUnreadCount(farmId)
    local count = 0
    for _, message in ipairs(self:getFarm(farmId).inbox) do
        if not message.read then
            count = count + 1
        end
    end
    return count
end

-- =========================================================================
-- PERMISSIONS + ACTIONS
-- =========================================================================

--- Server: may the player behind this connection buy / change / cancel the farm's policies?
--- Server admin always; farm manager too unless "admin only". No connection = host / console / single player.
function TornadoInsurance:canManage(connection, farmId)
    if connection == nil then
        return true
    end
    local userManager = g_currentMission ~= nil and g_currentMission.userManager or nil
    local user = userManager ~= nil and userManager:getUserByConnection(connection) or nil
    if user == nil then
        return false
    end
    if user:getIsMasterUser() then
        return true
    end
    if self.adminOnly then
        return false
    end
    local farm = g_farmManager ~= nil and g_farmManager:getFarmById(farmId) or nil
    return farm ~= nil and farm:isUserFarmManager(user:getId())
end

--- Server: runs a player's action after the checks. Returns the result text key (or nil).
function TornadoInsurance:handleAction(connection, farmId, name, args)
    local action = self.actions[name]
    if action == nil or farmId == nil or farmId == 0 then
        return nil
    end
    if action.managerOnly then
        if not self.isEnabled then
            return "tp_msg_ins_off"
        end
        if not self:canManage(connection, farmId) then
            return self.adminOnly and "tp_msg_ins_denied_admin" or "tp_msg_ins_denied"
        end
    end
    return action.run(self, farmId, args or "", connection)
end

--- Any machine: asks the server for an action (runs directly on the server / in single player).
function TornadoInsurance:requestAction(farmId, name, args)
    if isServer() then
        local resultKey = self:handleAction(nil, farmId, name, args)
        if resultKey ~= nil and TornadoMessageEvent ~= nil then
            TornadoMessageEvent.show(TornadoText.formatMessage(resultKey, {}), MSG_INFO)
        end
        return
    end
    if g_client ~= nil and TornadoInsuranceActionEvent ~= nil then
        g_client:getServerConnection():sendEvent(TornadoInsuranceActionEvent.new(farmId, name, args))
    end
end

-- =========================================================================
-- MULTIPLAYER STATE
-- =========================================================================

--- Server: sends a farm's state to its players (or to one connection).
function TornadoInsurance:sendFarmState(farmId, connection)
    if not isServer() or not isMultiplayer() or TornadoInsuranceStateEvent == nil then
        return
    end
    local event = TornadoInsuranceStateEvent.new(farmId, self:getFarm(farmId))
    if connection ~= nil then
        connection:sendEvent(event)
    elseif g_currentMission.broadcastEventToFarm ~= nil then
        g_currentMission:broadcastEventToFarm(event, farmId, false)
    end
end

function TornadoInsurance:syncFarm(farmId)
    self:sendFarmState(farmId, nil)
end

--- Server: every farm's state to a joining player (they choose their farm after joining).
function TornadoInsurance:sendInitialState(connection)
    if TornadoInsuranceStateEvent == nil then
        return
    end
    for farmId, farm in pairs(self.farms) do
        connection:sendEvent(TornadoInsuranceStateEvent.new(farmId, farm))
    end
end

--- Client: state received from the server.
function TornadoInsurance:applyFarmState(farmId, state)
    if self.farms == nil or state == nil then
        return
    end
    local farm = self:getFarm(farmId)
    farm.premiumsTotal = state.premiumsTotal or 0
    farm.payoutsTotal = state.payoutsTotal or 0
    farm.inbox = state.inbox or {}
    -- Crop policy summary (clients show it; the server keeps the full policy).
    if state.cropPlan ~= nil and state.cropPlan ~= "" then
        farm.crop = { plan = state.cropPlan, coverage = state.cropCoverage, status = state.cropStatus, prices = {}, fields = {} }
    else
        farm.crop = nil
    end
    farm.openClaims = state.openClaims or 0
    if TornadoMenu ~= nil and TornadoMenu.INSTANCE ~= nil and TornadoMenu.INSTANCE.isOpen then
        TornadoMenu.INSTANCE:refreshAllPages()
    end
end

-- =========================================================================
-- REGION + DATA
-- =========================================================================

--- Splits the region setting: "DE" -> "DE", nil; "US:US_KS" -> "US", "US_KS".
local function splitRegionSetting(setting)
    local country, region = string.match(setting or "", "^([^:]+):(.+)$")
    if country ~= nil then
        return country, region
    end
    return setting, nil
end

--- Country and sub-region whose insurance rules apply: the setting, or auto-detected from the map
--- (TornadoRegion: known map / base map / keywords / climate; a state named by the climate detection).
--- Returns { country, regionId (nil = whole country), source }.
function TornadoInsurance:resolveRegion()
    local setting = self.regionSetting or self.REGION_AUTO
    if self.resolved ~= nil and self.resolved.setting == setting then
        return self.resolved
    end
    local result = { setting = setting, country = "US", regionId = nil, source = "default" }
    local hasRegion = TornadoRegion ~= nil and TornadoRegion.isLoaded
    if setting ~= self.REGION_AUTO then
        local country, regionId = splitRegionSetting(setting)
        result.country = country
        result.regionId = regionId
        result.source = "setting"
    elseif hasRegion then
        local detected = TornadoRegion:detect()
        result.country = TornadoRegion:getProfileCountry(detected.country)
        result.source = detected.source
        result.regionId = detected.region
        -- A state / province the climate detection found ("... in the heart of Kansas").
        if result.regionId == nil and TornadoClimate ~= nil and TornadoClimate.detectRegionShared ~= nil
            and TornadoClimate.regions ~= nil then
            result.regionId = TornadoClimate:detectRegionShared()
        end
    end
    if hasRegion then
        result.country = TornadoRegion:getProfileCountry(result.country)
    end
    -- Keep only a sub-region (state / province) the country's data knows - not the country itself
    -- (the climate detection returns "US" when it finds no state).
    local profile = self:getProfileFor(result.country)
    if result.regionId ~= nil and (profile == nil or profile.regions[result.regionId] == nil
        or profile.regions[result.regionId].parent == nil) then
        result.regionId = nil
    end
    self.resolved = result
    return result
end

--- Loaded profile of a country (cached; nil when the file is missing).
function TornadoInsurance:getProfileFor(country)
    if country == nil or TornadoInsuranceData == nil then
        return nil
    end
    local cached = self.profiles[country]
    if cached ~= nil then
        return cached or nil
    end
    local info = TornadoRegion ~= nil and TornadoRegion.profiles ~= nil and TornadoRegion.profiles[country] or nil
    local fileName = info ~= nil and info.file or ("CropInsurance_" .. country .. ".xml")
    local path = self.modDir ~= nil and Utils.getFilename(TornadoInsuranceData.DB_DIR .. fileName, self.modDir) or nil
    local profile = TornadoInsuranceData.load(path, fileName)
    self.profiles[country] = profile or false
    if profile == nil then
        print("TORNADO INSURANCE: no insurance data for " .. tostring(country) .. " (" .. fileName .. ")")
    end
    return profile
end

--- The profile and region id that apply now.
function TornadoInsurance:getProfile()
    local resolved = self:resolveRegion()
    return self:getProfileFor(resolved.country), resolved.regionId
end

--- "region" setting choices: auto, every profile country, and their states / provinces.
--- Returns { { value, country, regionId, name } } in profile order.
function TornadoInsurance:getRegionOptions()
    local options = {}
    if TornadoRegion == nil or TornadoRegion.profiles == nil then
        return options
    end
    local countries = {}
    for country in pairs(TornadoRegion.profiles) do
        table.insert(countries, country)
    end
    table.sort(countries, function(a, b) return TornadoRegion:getCountryName(a) < TornadoRegion:getCountryName(b) end)
    for _, country in ipairs(countries) do
        table.insert(options, { value = country, country = country, name = TornadoRegion:getCountryName(country) })
        local profile = self:getProfileFor(country)
        if profile ~= nil then
            for _, id in ipairs(profile.regionOrder) do
                local region = profile.regions[id]
                if region.parent ~= nil then
                    table.insert(options, { value = country .. ":" .. id, country = country, regionId = id,
                        name = TornadoRegion:getCountryName(country) .. " - " .. region.name })
                end
            end
        end
    end
    return options
end

--- Accepts "auto", a country code, "country:region" or a region id alone ("US_KS"). Returns true when valid.
function TornadoInsurance:setRegion(value)
    if value == nil then
        return false
    end
    if string.lower(value) == self.REGION_AUTO then
        self.regionSetting = self.REGION_AUTO
        self.resolved = nil
        return true
    end
    local wanted = string.upper(value)
    for _, option in ipairs(self:getRegionOptions()) do
        if string.upper(option.value) == wanted or (option.regionId ~= nil and string.upper(option.regionId) == wanted) then
            self.regionSetting = option.value
            self.resolved = nil
            return true
        end
    end
    return false
end

--- Display name of the region that applies ("United States - Kansas").
function TornadoInsurance:getRegionName()
    local resolved = self:resolveRegion()
    local name = TornadoRegion ~= nil and TornadoRegion.getCountryName ~= nil and TornadoRegion:getCountryName(resolved.country)
        or tostring(resolved.country)
    local profile = self:getProfileFor(resolved.country)
    if resolved.regionId ~= nil and profile ~= nil and profile.regions[resolved.regionId] ~= nil then
        name = name .. " - " .. profile.regions[resolved.regionId].name
    end
    return name
end

function TornadoInsurance:getRegionStatusText()
    local resolved = self:resolveRegion()
    local profile = self:getProfileFor(resolved.country)
    local data = "no data"
    if profile ~= nil then
        data = string.format("%s, %s programme, %s, %s, %d crops", profile.file, profile.programType, profile.years,
            profile.currency, TornadoInsuranceData.getNumCrops(profile, resolved.regionId))
    end
    return string.format("region %s (%s) - %s", self:getRegionName(),
        resolved.source == "setting" and "setting" or ("auto via " .. tostring(resolved.source)), data)
end

-- =========================================================================
-- SAVEGAME (TornadoInsurance.xml next to the other Tornado files)
-- =========================================================================

function TornadoInsurance:getPath()
    if TornadoDestruction == nil or TornadoDestruction._resolveSavegamePath == nil then
        return nil
    end
    local dir = TornadoDestruction:_resolveSavegamePath()
    return dir ~= nil and (dir .. self.FILE) or nil
end

local function writeParams(xmlId, key, params)
    for i, param in ipairs(params or {}) do
        local paramKey = string.format("%s.param(%d)", key, i - 1)
        setXMLInt(xmlId, paramKey .. "#type", param.type or 0)
        setXMLString(xmlId, paramKey .. "#value", tostring(param.value))
    end
end

local function readParams(xmlId, key)
    local params = {}
    local i = 0
    while true do
        local paramKey = string.format("%s.param(%d)", key, i)
        local paramType = getXMLInt(xmlId, paramKey .. "#type")
        if paramType == nil then break end
        local text = getXMLString(xmlId, paramKey .. "#value") or ""
        local value
        if TornadoText ~= nil and (paramType == TornadoText.PARAM_NUMBER or paramType == TornadoText.PARAM_MONEY) then
            value = tonumber(text) or 0
        else
            value = text
        end
        table.insert(params, { type = paramType, value = value })
        i = i + 1
    end
    return params
end

function TornadoInsurance:loadState()
    local path = self:getPath()
    if path == nil or not fileExists(path) then
        return
    end
    local xmlId = loadXMLFile("TornadoInsurance", path)
    if xmlId == nil or xmlId == 0 then
        return
    end
    self.nextTimerId = getXMLInt(xmlId, "TornadoInsurance#nextTimerId") or 1
    local f = 0
    while true do
        local farmKey = string.format("TornadoInsurance.farms.farm(%d)", f)
        local farmId = getXMLInt(xmlId, farmKey .. "#id")
        if farmId == nil then break end
        local farm = self:getFarm(farmId)
        farm.premiumsTotal = getXMLFloat(xmlId, farmKey .. "#premiums") or 0
        farm.payoutsTotal = getXMLFloat(xmlId, farmKey .. "#payouts") or 0
        local h = 0
        while true do
            local monthKey = string.format("%s.history.month(%d)", farmKey, h)
            local month = getXMLInt(xmlId, monthKey .. "#index")
            if month == nil then break end
            table.insert(farm.history, { month = month, premiums = getXMLFloat(xmlId, monthKey .. "#premiums") or 0,
                payouts = getXMLFloat(xmlId, monthKey .. "#payouts") or 0 })
            h = h + 1
        end
        for _, data in ipairs(self.farmData) do
            data.load(xmlId, farmKey, farm)
        end
        local m = 0
        while true do
            local messageKey = string.format("%s.inbox.message(%d)", farmKey, m)
            local key = getXMLString(xmlId, messageKey .. "#key")
            if key == nil then break end
            table.insert(farm.inbox, { key = key, day = getXMLInt(xmlId, messageKey .. "#day") or 0,
                read = getXMLBool(xmlId, messageKey .. "#read") == true, params = readParams(xmlId, messageKey) })
            m = m + 1
        end
        f = f + 1
    end
    local t = 0
    while true do
        local timerKey = string.format("TornadoInsurance.timers.timer(%d)", t)
        local id = getXMLInt(xmlId, timerKey .. "#id")
        if id == nil then break end
        table.insert(self.timers, {
            id = id,
            farmId = getXMLInt(xmlId, timerKey .. "#farm") or 0,
            kind = getXMLString(xmlId, timerKey .. "#kind") or "",
            remaining = getXMLFloat(xmlId, timerKey .. "#remaining") or 0,
            data = getXMLString(xmlId, timerKey .. "#data") or "",
        })
        self.nextTimerId = math.max(self.nextTimerId, id + 1)
        t = t + 1
    end
    delete(xmlId)
end

function TornadoInsurance:save()
    if not isServer() then
        return
    end
    local path = self:getPath()
    if path == nil then
        return
    end
    local xmlId = createXMLFile("TornadoInsurance", path, "TornadoInsurance")
    if xmlId == nil or xmlId == 0 then
        return
    end
    setXMLInt(xmlId, "TornadoInsurance#version", 1)
    setXMLInt(xmlId, "TornadoInsurance#nextTimerId", self.nextTimerId or 1)
    local farmIds = {}
    for farmId in pairs(self.farms or {}) do
        table.insert(farmIds, farmId)
    end
    table.sort(farmIds)
    for f, farmId in ipairs(farmIds) do
        local farm = self.farms[farmId]
        local farmKey = string.format("TornadoInsurance.farms.farm(%d)", f - 1)
        setXMLInt(xmlId, farmKey .. "#id", farmId)
        setXMLFloat(xmlId, farmKey .. "#premiums", farm.premiumsTotal or 0)
        setXMLFloat(xmlId, farmKey .. "#payouts", farm.payoutsTotal or 0)
        for h, month in ipairs(farm.history) do
            local monthKey = string.format("%s.history.month(%d)", farmKey, h - 1)
            setXMLInt(xmlId, monthKey .. "#index", month.month)
            setXMLFloat(xmlId, monthKey .. "#premiums", month.premiums)
            setXMLFloat(xmlId, monthKey .. "#payouts", month.payouts)
        end
        for _, data in ipairs(self.farmData) do
            data.save(xmlId, farmKey, farm)
        end
        for m, message in ipairs(farm.inbox) do
            local messageKey = string.format("%s.inbox.message(%d)", farmKey, m - 1)
            setXMLString(xmlId, messageKey .. "#key", message.key)
            setXMLInt(xmlId, messageKey .. "#day", message.day or 0)
            setXMLBool(xmlId, messageKey .. "#read", message.read == true)
            writeParams(xmlId, messageKey, message.params)
        end
    end
    for t, timer in ipairs(self.timers or {}) do
        local timerKey = string.format("TornadoInsurance.timers.timer(%d)", t - 1)
        setXMLInt(xmlId, timerKey .. "#id", timer.id)
        setXMLInt(xmlId, timerKey .. "#farm", timer.farmId)
        setXMLString(xmlId, timerKey .. "#kind", timer.kind)
        setXMLFloat(xmlId, timerKey .. "#remaining", timer.remaining)
        setXMLString(xmlId, timerKey .. "#data", timer.data or "")
    end
    saveXMLFile(xmlId)
    delete(xmlId)
end

-- =========================================================================
-- STATUS / CONSOLE
-- =========================================================================

function TornadoInsurance:getStatusText()
    local farms = 0
    for _ in pairs(self.farms or {}) do
        farms = farms + 1
    end
    local damage = TornadoInsuranceDamage ~= nil and TornadoInsuranceDamage.log ~= nil and #TornadoInsuranceDamage.log or 0
    local finance = self.moneyTypePremium ~= nil and self.moneyTypePremium.statistic ~= "other" and "own rows" or "Other"
    if self.redTapeLinked then
        finance = finance .. " + Red Tape tax"
    end
    local crop = "n/a"
    if TornadoInsuranceCrop ~= nil then
        crop = string.format("%s, sales %s (%s)", TornadoInsuranceCrop:isAvailable() and "available" or "not available yet (phase 2b)",
            TornadoInsuranceCrop:isSalesOpen() and "open" or "closed", self.salesClosing or "auto")
    end
    return string.format("Insurance: Enabled = %s | Policy managers = %s | %s | Days per month = %d | Cost scale = %.0f %% | Farms with records = %d | Countdowns = %d | Damage events logged = %d | Finances = %s | Crop insurance = %s",
        tostring(self.isEnabled), self.adminOnly and "server admin only" or "farm manager + admin",
        self:getRegionStatusText(), self:getDaysPerMonth(), self:getCostScale() * 100, farms, #(self.timers or {}), damage, finance, crop)
end

--- Farm the console works on: the player's own farm, else farm 1.
function TornadoInsurance:getConsoleFarmId(value)
    local wanted = tonumber(value)
    if wanted ~= nil then
        return wanted
    end
    local farmId = g_currentMission ~= nil and g_currentMission.getFarmId ~= nil and g_currentMission:getFarmId() or nil
    if farmId == nil or farmId == 0 then
        return 1
    end
    return farmId
end

--- t_dev insurance <status | bill | testpremium <amount> | charge <amount> [farm] | pay <amount> [farm] |
---                  timer <real days> [farm] | timers | inbox [farm] | rate <FILLTYPE> <PLAN> <coverage %> | regions | crops>
function TornadoInsurance:consoleCommand(sub, value, extra, more)
    if sub == "crop" then
        if TornadoInsuranceCrop == nil then return "Insurance: crop policies missing." end
        return TornadoInsuranceCrop:consoleCommand(self:getConsoleFarmId(nil), value, extra, more)
    elseif sub == "damage" then
        if TornadoInsuranceDamage == nil then return "Insurance: damage report missing." end
        return TornadoInsuranceDamage:printLog(tonumber(value))
    elseif sub == "hit" then
        if TornadoInsuranceDamage == nil then return "Insurance: damage report missing." end
        return TornadoInsuranceDamage:testHit(value, extra, more)
    elseif sub == "crops" then
        if TornadoInsuranceCrops == nil then return "Insurance: crop cross-reference missing." end
        return TornadoInsuranceCrops:printMapCrops()
    elseif sub == "regions" then
        print("---------------- INSURANCE REGIONS ----------------")
        print("  auto")
        for _, option in ipairs(self:getRegionOptions()) do
            print(string.format("  %-12s %s", option.value, option.name))
        end
        print("---------------------------------------------------")
        return "Insurance: use t_set insurance region <value>."
    elseif sub == "rate" then
        local profile, regionId = self:getProfile()
        if profile == nil then return "Insurance: no data loaded." end
        if profile.programType ~= TornadoInsuranceData.PROGRAM_CURVES then
            return "Insurance: " .. profile.file .. " uses the '" .. profile.programType ..
                "' programme - its rates come with the crop policy (phase 2)."
        end
        local cropName = string.upper(value or "WHEAT")
        local planId = string.upper(extra or "RP")
        local coverage = (tonumber(more) or 75) / 100
        -- Map / mod crops are rated like their cross-referenced crop (SPELT -> WHEAT).
        local fillType = cropName
        local info = TornadoInsuranceCrops ~= nil and TornadoInsuranceCrops:getCropInfo(cropName) or nil
        if info ~= nil then
            if not info.insurable then
                return string.format("Insurance: %s is not insurable (%s).", cropName, tostring(info.note))
            end
            fillType = info.ratedAs
            if fillType ~= cropName or not info.isLocal then
                print(string.format("Insurance: %s rated as %s (%s)%s.", cropName, fillType, info.method,
                    info.isLocal and "" or " - unusual crop for this region"))
            end
        end
        local plan = TornadoInsuranceData.getCurve(profile, regionId, fillType, planId)
        if plan == nil then
            local offered = TornadoInsuranceData.getPlanIds(profile, regionId, fillType)
            return string.format("Insurance: plan %s is not offered for %s in %s. Offered: %s.", planId, fillType,
                self:getRegionName(), #offered > 0 and table.concat(offered, ", ") or "none")
        end
        local level = TornadoInsuranceData.getLevel(plan, coverage)
        local levels = {}
        for _, entry in ipairs(plan.levels) do
            table.insert(levels, string.format("%d", math.floor(entry.coverage * 100 + 0.5)))
        end
        if level == nil then
            return string.format("Insurance: %s %s has no %d %% level. Offered: %s %%.", fillType, planId,
                math.floor(coverage * 100 + 0.5), table.concat(levels, " / "))
        end
        local factor = TornadoInsuranceData.getRateFactor(profile, regionId, fillType)
        return string.format("Insurance: %s %s %d %% in %s - premium %.2f %%, subsidy %.0f %%, farmer pays %.2f %% x state factor %.3f = %.2f %% of the insured value per year. Levels: %s %%.",
            fillType, planId, math.floor(coverage * 100 + 0.5), self:getRegionName(), level.premiumRate * 100,
            level.subsidyShare * 100, level.farmerRate * 100, factor, level.farmerRate * factor * 100, table.concat(levels, " / "))
    end

    if not isServer() then
        return "Insurance: dev commands run on the host / server only."
    end
    if sub == "bill" then
        if not self.isEnabled then return "Insurance: module is OFF (t_set insurance on)." end
        self:onPeriodChanged()
        return "Insurance: monthly billing run now."
    elseif sub == "testpremium" then
        local amount = tonumber(value)
        if amount == nil then return "Usage: t_dev insurance testpremium <amount per month, 0 = off>" end
        self.testPremium = math.max(0, amount)
        return string.format("Insurance: test premium = %d per month (before cost scale %.0f %%), not saved.",
            math.floor(self.testPremium + 0.5), self:getCostScale() * 100)
    elseif sub == "charge" or sub == "pay" then
        local amount = tonumber(value)
        if amount == nil then return "Usage: t_dev insurance " .. sub .. " <amount> [farm]" end
        local farmId = self:getConsoleFarmId(extra)
        local done
        if sub == "charge" then
            done = self:chargePremium(farmId, amount, "tp_msg_ins_premium_charged")
        else
            done = self:payOut(farmId, amount, "tp_msg_ins_payout")
        end
        return done and string.format("Insurance: %s %d for farm %d.", sub == "charge" and "charged" or "paid",
            math.floor(amount + 0.5), farmId) or "Insurance: nothing booked (unknown farm or amount <= 0)."
    elseif sub == "timer" then
        local days = tonumber(value)
        if days == nil then return "Usage: t_dev insurance timer <real-life days> [farm]" end
        if not self.isEnabled then return "Insurance: module is OFF (t_set insurance on) - countdowns only run while it is ON." end
        local farmId = self:getConsoleFarmId(extra)
        local id = self:addTimer(farmId, self.TIMER_TEST, days, "")
        local d, h = self:getRemainingDaysHours(self.realDaysToMonths(days))
        return string.format("Insurance: test countdown %d for farm %d - %g real days = %d in-game days %d h at %d days per month.",
            id, farmId, days, d, h, self:getDaysPerMonth())
    elseif sub == "timers" then
        print("---------------- INSURANCE COUNTDOWNS ----------------")
        for _, timer in ipairs(self.timers) do
            local d, h = self:getRemainingDaysHours(timer.remaining)
            print(string.format("  #%d farm %d %-10s %d d %d h left  %s", timer.id, timer.farmId, timer.kind, d, h, timer.data))
        end
        print("------------------------------------------------------")
        return string.format("Insurance: %d countdowns.", #self.timers)
    elseif sub == "inbox" then
        local farmId = self:getConsoleFarmId(value)
        local farm = self:getFarm(farmId)
        print(string.format("---------------- INSURANCE INBOX farm %d ----------------", farmId))
        for _, message in ipairs(farm.inbox) do
            print(string.format("  day %d %s %s", message.day, message.read and " " or "*", TornadoText.formatMessage(message.key, message.params)))
        end
        print(string.format("  premiums paid %d, payouts received %d", math.floor(farm.premiumsTotal + 0.5),
            math.floor(farm.payoutsTotal + 0.5)))
        print("---------------------------------------------------------")
        return string.format("Insurance: %d messages (%d unread).", #farm.inbox, self:getUnreadCount(farmId))
    end
    return self:getStatusText()
end
