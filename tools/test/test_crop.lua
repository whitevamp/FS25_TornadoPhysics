-- Offline test for scripts/insurance/TornadoInsuranceCrop.lua (insurance phase 2a: crop policies) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_crop.lua
-- Real: TornadoInsurance, TornadoInsuranceData (DB/CropInsurance_US.xml), TornadoInsuranceCrops (aliases).
-- Stubs: fields, fruit / fill types, selling stations, clock, growth mode, money, messages, savegame XML.
-- Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- tiny XML reader (DB files)
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

-- ---------------------------------------------------------------- stubs: XML, files
local files, xmlHandles, nextHandle, dbCache = {}, {}, 1, {}
function createXMLFile(_, path) local h = nextHandle nextHandle = nextHandle + 1 xmlHandles[h] = { path = path, data = {} } return h end
function loadXMLFile(_, path)
    local h = nextHandle nextHandle = nextHandle + 1
    if path:find("DB/", 1, true) then
        if dbCache[path] == nil then
            local f = io.open(path, "r")
            if f == nil then return 0 end
            dbCache[path] = parseXML(f:read("*a"))
            f:close()
        end
        xmlHandles[h] = { tree = dbCache[path] }
        return h
    end
    if files[path] == nil then return 0 end
    xmlHandles[h] = { path = path, data = files[path] }
    return h
end
local function setter(h, key, value) xmlHandles[h].data[key] = value end
setXMLFloat, setXMLInt, setXMLBool, setXMLString = setter, setter, setter, setter
local function getString(h, key)
    local handle = xmlHandles[h]
    if handle.tree ~= nil then return xmlLookup(handle.tree, key) end
    return handle.data[key]
end
getXMLString = getString
getXMLInt = function(h, key) local v = getString(h, key) return v ~= nil and tonumber(v) or nil end
getXMLFloat = getXMLInt
getXMLBool = function(h, key) local v = getString(h, key) if type(v) == "boolean" then return v end return v ~= nil and v == "true" or nil end
function saveXMLFile(h) files[xmlHandles[h].path] = xmlHandles[h].data end
function delete(h) xmlHandles[h] = nil end
function fileExists(path)
    if path:find("DB/", 1, true) then local f = io.open(path, "r") if f then f:close() return true end return false end
    return files[path] ~= nil
end
function entityExists(node) return node ~= nil end
Utils = { getFilename = function(name, dir) return (dir or "") .. name end }

-- ---------------------------------------------------------------- stubs: game
MessageType = { PERIOD_CHANGED = 1, MINUTE_CHANGED = 2, YEAR_CHANGED = 3 }
local subscriptions = {}
g_messageCenter = {
    subscribe = function(_, kind, fn, target) subscriptions[kind] = subscriptions[kind] or {} table.insert(subscriptions[kind], { fn = fn, target = target }) end,
    unsubscribeAll = function(_, target)
        for _, list in pairs(subscriptions) do for i = #list, 1, -1 do if list[i].target == target then table.remove(list, i) end end end
    end,
}
local function publish(kind) for _, s in ipairs(subscriptions[kind] or {}) do s.fn(s.target) end end

MoneyType = { OTHER = { id = 1, statistic = "other" }, register = function(statistic, title) return { statistic = statistic, title = title } end }
Environment = { PERIODS_IN_YEAR = 12 }
FarmManager = { SPECTATOR_FARM_ID = 0, FARM_ID_SEND_NUM_BITS = 4 }
GrowthMode = { SEASONAL = 1, DAILY = 2, DISABLED = 3 }
FruitType = { UNKNOWN = 0 }

local balance = 0
local farmList = { { farmId = 0 }, { farmId = 1, isUserFarmManager = function() return true end } }
g_farmManager = {
    getFarms = function() return farmList end,
    getFarmById = function(_, id) return id == 1 and farmList[2] or nil end,
}
local environment = { daysPerPeriod = 1, currentMonotonicDay = 10, dayTime = 0, currentYear = 1, currentPeriod = 5 }
local growthMode = GrowthMode.SEASONAL
g_currentMission = {
    getIsServer = function() return true end,
    getFarmId = function() return 1 end,
    environment = environment,
    growthSystem = { getGrowthMode = function() return growthMode end },
    addMoney = function(_, amount) balance = balance + amount end,
}

-- Fruit / fill types: WHEAT (index 1, 0.9 l/m2), RICE (2, 0.8 l/m2)
local fruits = { [1] = { index = 1, name = "WHEAT", literPerSqm = 0.9 }, [2] = { index = 2, name = "RICE", literPerSqm = 0.8 } }
g_fruitTypeManager = {
    getFruitTypeByIndex = function(_, i) return fruits[i] end,
    getFillTypeIndexByFruitTypeIndex = function(_, i) return fruits[i] and (100 + i) or nil end,
    getFillTypeNameByFruitTypeIndex = function(_, i) return fruits[i] and fruits[i].name or nil end,
    getFruitTypeByFillTypeIndex = function(_, idx) return fruits[idx - 100] end,
    getFruitTypes = function() return { fruits[1], fruits[2] } end,
    getFruitTypesByCategoryNames = function() return {} end,
    categories = {},
}
g_fillTypeManager = { getFillTypeIndexByName = function(_, name) for i, f in pairs(fruits) do if f.name == name then return 100 + i end end return nil end }

-- Selling stations: two buy wheat (0.30 / 0.40), one does not.
SellingStation = {}
local function station(prices)
    return { isa = function(_, class) return class == SellingStation end,
        getIsFillTypeAllowed = function(_, idx) return prices[idx] ~= nil end,
        getEffectiveFillTypePrice = function(_, idx) return prices[idx] end }
end
local wheatPrices = { 0.30, 0.40 }
local stations = { station({ [101] = 0.30, [102] = 0.50 }), station({ [101] = 0.40 }), station({}) }
g_currentMission.storageSystem = { getUnloadingStations = function() return stations end }
g_currentMission.economyManager = { getPricePerLiter = function() return 0.2 end }

-- Fields: 1 = 10 ha wheat (farm 1), 2 = 4 ha rice (farm 1, unusual in Kansas), 3 = 5 ha wheat of another farm
local function makeField(id, ha, fruit, owner)
    local state = { isValid = true, fruitTypeIndex = fruit, growthState = 3 }
    return { getId = function() return id end, getAreaHa = function() return ha end, getOwner = function() return owner end,
        getFieldState = function() return state end, state = state }
end
local fields = { makeField(1, 10, 1, 1), makeField(2, 4, 2, 1), makeField(3, 5, 1, 2) }
g_fieldManager = { getFields = function() return fields end,
    getFieldById = function(_, id) for _, f in ipairs(fields) do if f.getId() == id then return f end end return nil end }

local messages = {}
TornadoSync = { MSG_INFO = 3, isMultiplayer = function() return false end,
    sendMessage = function(_, key, params, kind, farmId) table.insert(messages, { key = key, params = params, farmId = farmId }) end }
TornadoText = { PARAM_STRING = 0, PARAM_NUMBER = 1, PARAM_KEY = 2, PARAM_MONEY = 3,
    cash = function(v) return { type = 3, value = v } end, num = function(v) return { type = 1, value = v } end,
    key = function(v) return { type = 2, value = v } end, formatMessage = function(key) return key end }
TornadoSettings = { getCostScale = function() return 1.0 end }
TornadoDestruction = { _resolveSavegamePath = function() return "savegame1/" end }
TornadoRegion = { isLoaded = true, profiles = { US = { file = "CropInsurance_US.xml", name = "United States" },
        DE = { file = "CropInsurance_DE.xml", name = "Germany" }, AU = { file = "CropInsurance_AU.xml", name = "Australia" },
        SEA = { file = "CropInsurance_SEA.xml", name = "South-East Asia" } },
    detect = function() return { country = "US", source = "baseMap" } end,
    getProfileCountry = function(self, country) return self.profiles[country] ~= nil and country or "US" end,
    getCountryName = function(self, country) return self.profiles[country] ~= nil and self.profiles[country].name or country end }
TornadoClimate = { regions = {}, detectRegionShared = function() return "US_KS" end }
TornadoInsuranceDamage = { CAUSE_KEYS = { TORNADO = "tp_cause_tornado", HAIL = "tp_cause_hail" } }
TornadoPhysics = { tornadoNode = nil }
TornadoOutbreak = { isActive = false }

dofile("scripts/insurance/TornadoInsuranceData.lua")
dofile("scripts/insurance/TornadoInsuranceCrops.lua")
dofile("scripts/insurance/TornadoInsurancePrograms.lua")
dofile("scripts/insurance/TornadoInsuranceCrop.lua")
dofile("scripts/insurance/TornadoInsurance.lua")

-- ---------------------------------------------------------------- helpers
local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "function" then ok = want(got) end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-64s got %s", label, tostring(got)))
    else
        print(string.format("ok    %-64s %s", label, tostring(got)))
    end
end
local function near(v, eps) return function(got) return type(got) == "number" and math.abs(got - v) <= (eps or 1e-6) end end
local MS_DAY = 24 * 60 * 60 * 1000
local function advance(ms)
    local absolute = environment.currentMonotonicDay * MS_DAY + environment.dayTime + ms
    environment.currentMonotonicDay = math.floor(absolute / MS_DAY)
    environment.dayTime = absolute - environment.currentMonotonicDay * MS_DAY
    publish(MessageType.MINUTE_CHANGED)
end
local function realDays(days) advance(days / 30 * MS_DAY + 1000) end   -- 1 day per month
local function lastMessage() return messages[#messages] and messages[#messages].key end
local function has(key) for _, m in ipairs(messages) do if m.key == key then return true end end return false end

-- ---------------------------------------------------------------- setup
local I, C = TornadoInsurance, TornadoInsuranceCrop
I.isEnabled = true
TornadoInsuranceCrops:loadMap("")
I:loadMap("", "FS25_TornadoPhysics")
publish(MessageType.MINUTE_CHANGED)   -- clock baseline
local profile, regionId = I:getProfile()
check("region Kansas, curve programme", regionId == "US_KS" and C:isAvailable(), true)
check("premium source registered", I.premiumSources[2] ~= nil and I.premiumSources[2].name, "crop")

local plans = table.concat(C:getOfferedPlans(), ",")
check("US plans, RP first", plans:sub(1, 2), "RP")
check("US plans include YP and APH", plans:find("YP", 1, true) ~= nil and plans:find("APH", 1, true) ~= nil, true)
local levels = C:getCoverageLevels("RP")
check("RP levels 50 - 85 %", levels[1] == 0.5 and levels[#levels] == 0.85, true)

-- ---------------------------------------------------------------- prices + terms
check("average price over the stations that buy wheat", C:getAveragePrice(101), near(0.35))
check("no station buys it: game base price", C:getAveragePrice(999), 0.2)
-- A player-bought (not preplaced) station paying more is left out of the average.
local bought = station({ [101] = 0.80 })
bought.owningPlaceable = { getIsPreplaced = function() return false end }
table.insert(stations, bought)
check("bought high-price station ignored", C:getAveragePrice(101), near(0.35))
stations[#stations] = nil
local onlyBought = { station({ [103] = 0.60 }) }
onlyBought[1].owningPlaceable = { getIsPreplaced = function() return false end }
local saved = stations
stations = onlyBought
g_currentMission.storageSystem = { getUnloadingStations = function() return stations end }
check("only bought stations buy it: their average is used", C:getAveragePrice(103), near(0.60))
stations = saved
g_currentMission.storageSystem = { getUnloadingStations = function() return stations end }
local wheat = C:getFieldCrop(fields[1])
local terms = C:getFieldTerms(wheat, "RP", 0.75, nil)
local curve = TornadoInsuranceData.getCurve(profile, regionId, "WHEAT", "RP")
local level = TornadoInsuranceData.getLevel(curve, 0.75)
local factor = TornadoInsuranceData.getRateFactor(profile, regionId, "WHEAT")
check("wheat yield 0.9 l/m2 = 9000 l/ha", terms.yieldPerHa, near(9000))
check("liability = 10 ha x 9000 x 0.35 x 75 %", terms.liability, near(10 * 9000 * 0.35 * 0.75, 0.01))
check("premium = liability x farmer rate x Kansas factor", terms.yearlyPremium, near(terms.liability * level.farmerRate * factor, 0.01))
local rice = C:getFieldCrop(fields[2])
local riceTerms = C:getFieldTerms(rice, "RP", 0.85, nil)
check("rice is unusual in Kansas: coverage capped at 70 %", riceTerms ~= nil and riceTerms.coverage, near(0.70))
local riceCurve = TornadoInsuranceData.getCurve(profile, regionId, "RICE", riceTerms.plan)
local riceLevel = TornadoInsuranceData.getLevel(riceCurve, 0.70)
check("unusual crop: +25 % premium", riceTerms.yearlyPremium,
    near(riceTerms.liability * riceLevel.farmerRate * TornadoInsuranceData.getRateFactor(profile, regionId, "RICE") * 1.25, 0.01))
local quote = C:getFarmQuote(1, "RP", 0.75, nil)
check("farm quote covers its own 2 fields only", quote.fields, 2)
check("level 52 % -> next lower offered (50 %)", C.resolveLevel(curve, 0.52).coverage, 0.5)

-- ---------------------------------------------------------------- buying: sales window, storm
check("May with seasonal growth: sales closed", C:isSalesOpen(), false)
check("buy refused while closed", I:handleAction(nil, 1, "cropBuy", "RP 75"), "tp_msg_ins_crop_sales_closed")
I.salesClosing = "off"
check("sales closing OFF: open", C:isSalesOpen(), true)
I.salesClosing = "auto"
growthMode = GrowthMode.DAILY
check("auto + crops grow all year: open", C:isSalesOpen(), true)
growthMode = GrowthMode.SEASONAL
environment.currentPeriod = 1
check("auto + early spring: open", C:isSalesOpen(), true)
TornadoPhysics.tornadoNode = 42
check("buy refused while a tornado is on the ground", I:handleAction(nil, 1, "cropBuy", "RP 75"), "tp_msg_ins_crop_storm")
TornadoPhysics.tornadoNode = nil
check("unknown plan refused", I:handleAction(nil, 1, "cropBuy", "XX 75"), "tp_msg_ins_crop_unknown_plan")
check("buy RP 75 %", I:handleAction(nil, 1, "cropBuy", "RP 75"), nil)
local farm = I:getFarm(1)
check("policy pending", farm.crop ~= nil and farm.crop.status, "PENDING")
check("letter: bought", lastMessage(), "tp_msg_ins_crop_bought")
check("no premium while pending", C:getMonthlyPremium(1), 0)

-- ---------------------------------------------------------------- activation + billing
realDays(7)
check("active after 7 real days", farm.crop.status, "ACTIVE")
check("letter: active", lastMessage(), "tp_msg_ins_crop_active")
publish(MessageType.PERIOD_CHANGED)
local expectedMonthly = C:getFarmQuote(1, "RP", 0.75, farm.crop).monthlyPremium
check("monthly premium charged", balance, near(-math.floor(expectedMonthly + 0.5), 0.5))
check("prices locked at billing", farm.crop.prices.WHEAT, near(0.35))

-- ---------------------------------------------------------------- claims
local function damage(fieldId, share, crop) I:onDamageLogged({ cause = "TORNADO", day = environment.currentMonotonicDay,
    fieldId = fieldId, farmId = 1, crop = crop or "WHEAT", share = share }) end
damage(1, 0.10)
check("claim received", #farm.claims == 1 and farm.claims[1].status, "RECEIVED")
check("letter: claim received", lastMessage(), "tp_msg_ins_claim_received")
realDays(3)
check("adjuster after 3 days", farm.claims[1].status, "INSPECTED")
realDays(2)
check("10 % lost < 25 % uninsured part: denied", farm.claims[1].status, "DENIED")
check("letter: within uninsured part", lastMessage(), "tp_msg_ins_claim_deductible")

-- Prices up: RP pays at the higher current price (capped at 200 %).
stations[1] = station({ [101] = 0.90 })   -- average (0.90 + 0.40) / 2 = 0.65
damage(1, 0.30)
realDays(3) realDays(2)
check("second event: 40 % lost this year -> approved", farm.claims[2].status, "APPROVED")
local expectedPayout = (0.40 - 0.25) * 10 * 9000 * 0.65
check("payout = 15 % x 10 ha x 9000 l x current 0.65 (RP)", farm.claims[2].payout, near(expectedPayout, 0.5))
local before = balance
realDays(1)
check("paid after 1 day", farm.claims[2].status, "PAID")
check("money booked", balance - before, near(math.floor(expectedPayout + 0.5), 0.5))
damage(1, 0.10)
realDays(3) realDays(2)
check("third event: only the new 10 % is paid", farm.claims[3].payout, near(0.10 * 10 * 9000 * 0.65, 0.5))
check("field record", farm.crop.fields[1].lost, near(0.5))
stations[1] = station({ [101] = 2.00 })   -- way up: capped at 200 % of locked 0.35
local cappedTerms = C:getFieldTerms(wheat, "RP", 0.75, farm.crop)
check("(setup) locked price stays 0.35", cappedTerms.price, near(0.35))
damage(1, 0.10)
realDays(3) realDays(2)
check("RP harvest price capped at 200 % of the locked price", farm.claims[4].payout, near(0.10 * 10 * 9000 * 0.70, 0.5))
stations[1] = station({ [101] = 0.30 })

check("other farm's field: no claim", (function() damage(3, 0.5) return #farm.claims end)(), 4)
check("tiny loss (0.3 %): no claim", (function() damage(1, 0.003) return #farm.claims end)(), 4)
check("cover crop / not insurable: no claim", (function()
    I:onDamageLogged({ cause = "HAIL", day = 1, fieldId = 1, farmId = 1, crop = "GREENRYE", share = 0.5 }) return #farm.claims end)(), 4)

-- ---------------------------------------------------------------- save / load
I:save()
I:deleteMap()
I:loadMap("", "FS25_TornadoPhysics")
farm = I:getFarm(1)
check("policy restored", farm.crop ~= nil and farm.crop.plan == "RP" and farm.crop.status == "ACTIVE", true)
check("locked price restored", farm.crop.prices.WHEAT, near(0.35))
check("field record restored", farm.crop.fields[1] ~= nil and farm.crop.fields[1].lost, near(0.6))
check("claims restored", #farm.claims, 4)
check("claim ids continue", farm.nextClaimId, 4)

-- ---------------------------------------------------------------- new year, change, cancel
publish(MessageType.YEAR_CHANGED)
check("new policy year: prices + field totals reset", next(farm.crop.prices) == nil and next(farm.crop.fields) == nil, true)
check("letter: renewed", lastMessage(), "tp_msg_ins_crop_renewed")
check("change to YP 85 %", I:handleAction(nil, 1, "cropBuy", "YP 85"), nil)
check("changed", farm.crop.plan == "YP" and farm.crop.coverage == 0.85, true)
check("cancel", I:handleAction(nil, 1, "cropCancel", ""), nil)
check("policy gone", farm.crop, nil)
check("cancel again: nothing to cancel", I:handleAction(nil, 1, "cropCancel", ""), "tp_msg_ins_crop_none")

-- ---------------------------------------------------------------- phase 2b: Germany (named perils)
publish(MessageType.MINUTE_CHANGED)   -- clock baseline after the reload above
I.salesClosing = "off"
I.regionSetting = "DE"
I.resolved = nil
check("Germany: crop insurance available", C:isAvailable(), true)
check("Germany: options", table.concat(C:getOfferedPlans(), ","), "PACKAGE,HAIL_STORM,HAIL")
check("Germany: levels 80 / 90 / 100 %", table.concat(C:getCoverageLevels("PACKAGE"), ","), "0.8,0.9,1")
local deTerms = C:getFieldTerms(wheat, "PACKAGE", 0.8, nil)
check("Germany: sum insured = whole field value (10 ha x 9000 l x price)", deTerms.liability, near(10 * 9000 * C:getAveragePrice(101), 0.01))
check("Germany: premium = sum x (6.62 % x 0.7 + 0.03 % tax)", deTerms.yearlyPremium, near(10 * 9000 * C:getAveragePrice(101) * (0.0662 * 0.7 + 0.0003), 0.01))
check("buy package 80 %", I:handleAction(nil, 1, "cropBuy", "PACKAGE 80"), nil)
farm = I:getFarm(1)
realDays(7)
check("package active", farm.crop.status, "ACTIVE")
local claimsBefore = #farm.claims
local function claimOf(cause, share, fieldId)
    I:onDamageLogged({ cause = cause, day = environment.currentMonotonicDay, fieldId = fieldId or 1, farmId = 1,
        crop = fieldId == 2 and "RICE" or "WHEAT", share = share })
    realDays(3) realDays(2)
    return farm.claims[#farm.claims]
end
local claimsBeforeFire = #farm.claims
I:onDamageLogged({ cause = "FIRE", day = environment.currentMonotonicDay, fieldId = 1, farmId = 1, crop = "WHEAT", share = 0.30 })
check("package does not cover field fire: declined at once, no claim", #farm.claims, claimsBeforeFire)
check("letter: not covered", lastMessage(), "tp_msg_ins_claim_not_covered")
check("not covered loss does not count towards the field total", farm.crop.fields[1] == nil or farm.crop.fields[1].lost == 0, true)
local storm = claimOf("TORNADO", 0.30)
local locked = farm.crop.prices.WHEAT
check("tornado (windstorm) covered: 30 % - 20 % deductible paid", storm.payout, near(0.10 * 10 * 9000 * locked, 0.5))
I.valueBasis = "real"
local real = claimOf("HAIL", 0.10)
check("real values: next 10 % paid on 1 500 / ha", real.payout, near(0.10 * 10 * 1500, 0.5))
I.valueBasis = "game"
check("cancel German policy", I:handleAction(nil, 1, "cropCancel", ""), nil)

-- ---------------------------------------------------------------- Australia: switched off until the data is cleared
I.regionSetting = "AU"
I.resolved = nil
check("Australia: switched off", C:isAvailable(), false)
check("Australia: reason given", C:getDisabledReason() ~= nil, true)
check("Australia: buying refused", I:handleAction(nil, 1, "cropBuy", "NAMED 100"), "tp_msg_ins_crop_unavailable")
C:consoleCommand(1, "unlock")
check("t_dev unlock: Australia available for testing", C:isAvailable(), true)
C:consoleCommand(1, "unlock")
check("unlock again: off", C:isAvailable(), false)

-- ---------------------------------------------------------------- South-East Asia: state rice scheme (threshold)
I.regionSetting = "SEA"
I.resolved = nil
check("SEA: state scheme offered", table.concat(C:getOfferedPlans(), ","), "STATE")
local riceTermsSea = C:getFieldTerms(rice, "STATE", 1, nil)
check("SEA rice: local, 100 %", riceTermsSea.isLocal and riceTermsSea.coverage == 1, true)
local wheatTermsSea = C:getFieldTerms(wheat, "STATE", 1, nil)
check("SEA wheat: no state scheme -> unusual (70 %, +25 %)", (not wheatTermsSea.isLocal) and wheatTermsSea.coverage == 0.7, true)
check("buy state scheme", I:handleAction(nil, 1, "cropBuy", "STATE 100"), nil)
realDays(7)
local flood1 = claimOf("FLOOD", 0.50, 2)
check("rice 50 % flooded: below the 75 % threshold", flood1.status, "DENIED")
check("letter: threshold", lastMessage(), "tp_msg_ins_claim_threshold")
local flood2 = claimOf("FLOOD", 0.30, 2)
local ricePrice = farm.crop.prices.RICE
check("80 % lost: whole loss paid", flood2.payout, near(0.80 * 4 * 8000 * ricePrice, 0.5))
check("SEA tornado not covered by the rice scheme", (function()
    local n = #farm.claims
    I:onDamageLogged({ cause = "TORNADO", day = environment.currentMonotonicDay, fieldId = 2, farmId = 1, crop = "RICE", share = 0.9 })
    return #farm.claims == n and lastMessage() == "tp_msg_ins_claim_not_covered" end)(), true)
I.regionSetting = "CA"
I.resolved = nil
TornadoRegion.profiles.CA = { file = "CropInsurance_CA.xml", name = "Canada" }
check("Canada: switched off until SCIC answers", C:isAvailable(), false)
I.regionSetting = "auto"
I.resolved = nil

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
