-- Offline test for scripts/insurance/TornadoInsurance.lua + TornadoInsuranceData.lua (phase 0) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_insurance.lua
-- The DB/CropInsurance_*.xml files are read for real (small XML reader below); the savegame XML, money,
-- farms, users, messages and the game clock are stubs. Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- tiny XML reader (DB files only)
local function parseXML(text)
    text = text:gsub("<%?.-%?>", ""):gsub("<!%-%-.-%-%->", "")
    -- ">" is allowed inside attribute values (IT: needs="frequency>=3") - hide it from the tag pattern.
    text = text:gsub('"[^"]*"', function(quoted) return (quoted:gsub(">", "&gt;")) end)
    local root = { name = "#root", attrs = {}, children = {} }
    local stack = { root }
    for slash, name, attrText, selfClose in text:gmatch("<(/?)([%w_:]+)(.-)(/?)>") do
        if slash == "/" then
            table.remove(stack)
        else
            local node = { name = name, attrs = {}, children = {} }
            for key, value in attrText:gmatch('([%w_:]+)%s*=%s*"(.-)"') do
                node.attrs[key] = value
            end
            table.insert(stack[#stack].children, node)
            if selfClose ~= "/" then
                table.insert(stack, node)
            end
        end
    end
    return root
end

-- "a.b(2).c#attr" on a parsed tree
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

-- ---------------------------------------------------------------- stubs
local files = {}                      -- fake savegame files: path -> { key -> value }
local xmlHandles, nextHandle = {}, 1
local dbCache = {}
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
    if path:find("DB/", 1, true) then
        local f = io.open(path, "r")
        if f ~= nil then f:close() return true end
        return false
    end
    return files[path] ~= nil
end
Utils = { getFilename = function(name, dir) return (dir or "") .. name end }

MessageType = { PERIOD_CHANGED = 1, MINUTE_CHANGED = 2 }
local subscriptions = {}
g_messageCenter = {
    subscribe = function(_, kind, fn, target) subscriptions[kind] = { fn = fn, target = target } end,
    unsubscribeAll = function() subscriptions = {} end,
}

local registeredMoneyTypes = {}
MoneyType = { OTHER = { id = 1 }, register = function(statistic, title, env)
    local t = { id = 100 + #registeredMoneyTypes, statistic = statistic, title = title, customEnv = env }
    table.insert(registeredMoneyTypes, t)
    return t
end }
Environment = { PERIODS_IN_YEAR = 12 }
FarmManager = { SPECTATOR_FARM_ID = 0, FARM_ID_SEND_NUM_BITS = 4 }

local balances = { [1] = 0, [2] = 0 }
local moneyLog = {}
local managers = { [1] = { [11] = true }, [2] = { [21] = true } }   -- farm -> userId -> is farm manager
local function makeFarm(id)
    return { farmId = id, isUserFarmManager = function(_, userId) return managers[id] ~= nil and managers[id][userId] == true end }
end
local farmList = { makeFarm(0), makeFarm(1), makeFarm(2) }
g_farmManager = {
    getFarms = function() return farmList end,
    getFarmById = function(_, id) for _, f in ipairs(farmList) do if f.farmId == id and id ~= 0 then return f end end return nil end,
}

local environment = { daysPerPeriod = 1, currentMonotonicDay = 1, dayTime = 0, currentYear = 1, currentPeriod = 1 }
local users = {}
g_currentMission = {
    getIsServer = function() return true end,
    getFarmId = function() return 1 end,
    environment = environment,
    addMoney = function(_, amount, farmId, moneyType) balances[farmId] = balances[farmId] + amount
        table.insert(moneyLog, { amount = amount, farmId = farmId, moneyType = moneyType }) end,
    userManager = { getUserByConnection = function(_, connection) return users[connection] end },
}

local messages = {}
TornadoSync = { MSG_INFO = 3, isMultiplayer = function() return false end,
    sendMessage = function(_, key, params, kind, farmId) table.insert(messages, { key = key, farmId = farmId, params = params }) end }
TornadoText = { PARAM_STRING = 0, PARAM_NUMBER = 1, PARAM_KEY = 2, PARAM_MONEY = 3,
    cash = function(v) return { type = 3, value = v } end,
    formatMessage = function(key) return key end }
TornadoSettings = { getCostScale = function() return 0.7 end }
TornadoDestruction = { _resolveSavegamePath = function() return "savegame1/" end }

-- Region detection stub: base map in the US, climate detection names Kansas.
TornadoRegion = {
    isLoaded = true,
    profiles = {
        US = { file = "CropInsurance_US.xml", name = "United States" },
        DE = { file = "CropInsurance_DE.xml", name = "Germany" },
        CA = { file = "CropInsurance_CA.xml", name = "Canada" },
    },
    detected = { country = "US", source = "baseMap", detail = "MapUS" },
    detect = function(self) return self.detected end,
    getProfileCountry = function(self, country) return self.profiles[country] ~= nil and country or "US" end,
    getCountryName = function(self, country) return self.profiles[country] ~= nil and self.profiles[country].name or country end,
}
TornadoClimate = { regions = {}, detectRegionShared = function() return "US_KS" end }

dofile("scripts/insurance/TornadoInsuranceData.lua")
dofile("scripts/insurance/TornadoInsurance.lua")
dofile("scripts/insurance/TornadoInsuranceCrops.lua")

-- ---------------------------------------------------------------- helpers
local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "function" then ok = want(got) end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-62s got %s", label, tostring(got)))
    else
        print(string.format("ok    %-62s %s", label, tostring(got)))
    end
end
local function near(value, eps) return function(got) return type(got) == "number" and math.abs(got - value) < (eps or 1e-6) end end
local MS_DAY = 24 * 60 * 60 * 1000
--- Moves the game clock by ms and fires one minute message (like a game minute passing).
local function advance(ms)
    local absolute = environment.currentMonotonicDay * MS_DAY + environment.dayTime + ms
    environment.currentMonotonicDay = math.floor(absolute / MS_DAY)
    environment.dayTime = absolute - environment.currentMonotonicDay * MS_DAY
    subscriptions[MessageType.MINUTE_CHANGED].fn(subscriptions[MessageType.MINUTE_CHANGED].target)
end
local function countMessages(key, farmId)
    local n = 0
    for _, m in ipairs(messages) do if m.key == key and (farmId == nil or m.farmId == farmId) then n = n + 1 end end
    return n
end

-- ---------------------------------------------------------------- data: every profile loads
local D = TornadoInsuranceData
for _, country in ipairs({ "US", "CA", "PL", "BR", "DE", "FR", "NL", "ES", "IT", "AU", "AR", "CL", "GB", "SEA" }) do
    local name = "CropInsurance_" .. country .. ".xml"
    local profile = D.load("DB/" .. name, name)
    check("profile " .. country .. " loads with a root region", profile ~= nil and profile.rootId ~= nil, true)
    check("profile " .. country .. " lists crops", profile ~= nil and D.getNumCrops(profile, nil) > 0, true)
end
local us = D.load("DB/CropInsurance_US.xml", "CropInsurance_US.xml")
check("US programme type", us.programType, D.PROGRAM_CURVES)
check("US root region", us.rootId, "US")
check("US_KS parent is US", us.regions.US_KS ~= nil and us.regions.US_KS.parent, "US")
local sea = D.load("DB/CropInsurance_SEA.xml", "x")
check("SEA: container root -> its default child", D.getRegionChain(sea, nil)[1].id, "IDN")
check("DE programme type", D.load("DB/CropInsurance_DE.xml", "x").programType, "namedPeril")
check("SEA programme type (no <program>, no curves)", D.load("DB/CropInsurance_SEA.xml", "x").programType, D.PROGRAM_SCHEMES)
check("missing file -> nil", D.load("DB/CropInsurance_XX.xml", "x"), nil)

local wheatRP = D.getCurve(us, "US_KS", "WHEAT", "RP")
check("Kansas wheat RP curve found (from the US entry)", wheatRP ~= nil and #wheatRP.levels > 3, true)
local l50, l85 = D.getLevel(wheatRP, 0.5), D.getLevel(wheatRP, 0.85)
check("wheat RP 50 % level", l50 ~= nil and l50.premiumRate > 0, true)
check("shaped curve: 85 % costs more than 50 %", l85 ~= nil and l85.premiumRate > l50.premiumRate, true)
check("farmer rate = premium x (1 - subsidy)", l85 ~= nil and math.abs(l85.farmerRate - l85.premiumRate * (1 - l85.subsidyShare)) < 0.002, true)
check("level not offered -> nil", D.getLevel(wheatRP, 0.52), nil)
check("plan the crop lacks -> not offered", D.getCurve(us, "US", "WHEAT", "XX"), nil)
local default = D.getCurve(us, "US", "DEFAULT", "RP")
check("unknown (mod) crop -> DEFAULT curve", D.getCurve(us, "US", "MODCROP", "RP"), default)
check("DEFAULT curve exists", default ~= nil, true)
local spinach, potato = D.getCurve(us, "US", "SPINACH", "APH"), D.getCurve(us, "US", "POTATO", "APH")
local ca = D.load("DB/CropInsurance_CA.xml", "x")
check("Canada offers YP only for wheat", table.concat(D.getPlanIds(ca, "CAN_SK", "WHEAT"), ","), "YP")
check("US wheat plans", table.concat(D.getPlanIds(us, "US_KS", "WHEAT"), ","), "RP,RPHPE,YP")
check("borrowedFrom: spinach uses the potato APH curve", spinach ~= nil and spinach == potato, true)
check("Kansas wheat state factor (DB value)", D.getRateFactor(us, "US_KS", "WHEAT"), near(1.184, 0.001))
check("no state entry -> factor 1.0", D.getRateFactor(us, "US", "WHEAT"), 1.0)
check("region chain US_KS -> US", #D.getRegionChain(us, "US_KS"), 2)
check("unknown region -> root chain", D.getRegionChain(us, "NOPE")[1].id, "US")

-- ---------------------------------------------------------------- module: load, money types, region
local I = TornadoInsurance
I.isEnabled = true
I:loadMap("", "FS25_TornadoPhysics")
check("subscribed to month and minute", subscriptions[MessageType.PERIOD_CHANGED] ~= nil and subscriptions[MessageType.MINUTE_CHANGED] ~= nil, true)
check("two money types registered", #registeredMoneyTypes, 2)
check("premium money type: statistic other + own title", registeredMoneyTypes[1].statistic == "other" and registeredMoneyTypes[1].title == "tp_money_ins_premium"
    and registeredMoneyTypes[1].customEnv == "FS25_TornadoPhysics", true)

local resolved = I:resolveRegion()
check("auto: country from the map", resolved.country, "US")
check("auto: state from the climate detection", resolved.regionId, "US_KS")
check("region name", I:getRegionName(), "United States - Kansas")
I.regionSetting = "DE"
check("setting DE -> Germany, no sub-region", I:resolveRegion().country == "DE" and I:resolveRegion().regionId == nil, true)
I.regionSetting = "US:US_XX"
check("unknown sub-region dropped", I:resolveRegion().regionId, nil)
I.regionSetting = "auto"
TornadoClimate.detectRegionShared = function() return "US" end
check("climate finds only the country -> no sub-region", I:resolveRegion().regionId, nil)
check("no 'United States - United States'", I:getRegionName(), "United States")
TornadoClimate.detectRegionShared = function() return "US_KS" end
I.resolved = nil
check("setRegion by region id", I:setRegion("us_ks") and I.regionSetting, "US:US_KS")
check("setRegion unknown -> false", I:setRegion("Narnia"), false)
check("setRegion auto", I:setRegion("AUTO") and I.regionSetting, "auto")
local options = I:getRegionOptions()
check("region options: countries + states", #options > 50, true)

-- ---------------------------------------------------------------- time model
subscriptions[MessageType.MINUTE_CHANGED].fn(subscriptions[MessageType.MINUTE_CHANGED].target)   -- baseline
check("30 real days = 1 month", I.realDaysToMonths(30), 1)
local d, h = I:getRemainingDaysHours(I.realDaysToMonths(7))
check("7 real days at 1 day/month = ~5.6 h", d == 0 and h == 6, true)
environment.daysPerPeriod = 5
d, h = I:getRemainingDaysHours(I.realDaysToMonths(7))
check("7 real days at 5 days/month = 1 d 4 h", d == 1 and h == 4, true)
environment.daysPerPeriod = 1

local id = I:addTimer(1, I.TIMER_TEST, 30, "x")
advance(MS_DAY / 2)
check("half a month later: half left", I.timers[1].remaining, near(0.5, 1e-6))
check("not fired yet", countMessages("tp_msg_ins_test_timer"), 0)
-- Days per month changes mid-countdown: the rest (half a month) now lasts 1.5 days at 3 days per month.
environment.daysPerPeriod = 3
advance(MS_DAY)
check("after 1 day at 3 days/month: 1/6 left", I.timers[1] ~= nil and I.timers[1].remaining, near(0.5 - 1 / 3, 1e-6))
advance(MS_DAY / 2)
check("fired after 1.5 days", countMessages("tp_msg_ins_test_timer", 1), 1)
check("timer removed", #I.timers, 0)
environment.daysPerPeriod = 1
check("timer id returned", id, 1)

I.isEnabled = false
I:addTimer(2, I.TIMER_TEST, 3, "")
advance(MS_DAY)
check("module OFF: countdown paused", #I.timers, 1)
I.isEnabled = true
advance(MS_DAY)
check("module ON again: runs out", countMessages("tp_msg_ins_test_timer", 2), 1)
check("removeTimer unknown -> false", I:removeTimer(999), false)

-- ---------------------------------------------------------------- billing + money
I.testPremium = 100
subscriptions[MessageType.PERIOD_CHANGED].fn(subscriptions[MessageType.PERIOD_CHANGED].target)
check("farm 1 charged 100 x cost scale 0.7", balances[1], -70)
check("farm 2 charged too", balances[2], -70)
check("spectator farm skipped", #moneyLog, 2)
check("premium money type used", moneyLog[1].moneyType, registeredMoneyTypes[1])
check("premium letter per farm", countMessages("tp_msg_ins_premium_charged", 1), 1)
check("totals", I:getFarm(1).premiumsTotal, 70)
check("history month", I:getFarm(1).history[1].premiums, 70)
I.isEnabled = false
subscriptions[MessageType.PERIOD_CHANGED].fn(subscriptions[MessageType.PERIOD_CHANGED].target)
check("module OFF: no billing", balances[1], -70)
I.isEnabled = true
I.testPremium = 0
subscriptions[MessageType.PERIOD_CHANGED].fn(subscriptions[MessageType.PERIOD_CHANGED].target)
check("no premium -> nothing charged", #moneyLog, 2)

check("payout", I:payOut(1, 500, "tp_msg_ins_payout"), true)
check("payout booked", balances[1], 430)
check("payout money type", moneyLog[3].moneyType, registeredMoneyTypes[2])
check("payout total", I:getFarm(1).payoutsTotal, 500)
check("payout to unknown farm refused", I:payOut(9, 500), false)
check("zero charge refused", I:chargePremium(1, 0), false)
environment.currentPeriod = 2
I:chargePremium(1, 10)
check("new month -> new history entry", #I:getFarm(1).history, 2)

-- ---------------------------------------------------------------- permissions + actions
local admin, manager, worker = {}, {}, {}
users[admin] = { getIsMasterUser = function() return true end, getId = function() return 1 end }
users[manager] = { getIsMasterUser = function() return false end, getId = function() return 11 end }
users[worker] = { getIsMasterUser = function() return false end, getId = function() return 12 end }
check("no connection (host / console) may manage", I:canManage(nil, 1), true)
check("admin may manage", I:canManage(admin, 1), true)
check("farm manager may manage own farm", I:canManage(manager, 1), true)
check("farm manager may not manage another farm", I:canManage(manager, 2), false)
check("worker may not manage", I:canManage(worker, 1), false)
I.adminOnly = true
check("admin only: manager refused", I:canManage(manager, 1), false)
check("admin only: admin allowed", I:canManage(admin, 1), true)

local ran = 0
I:registerAction("testBuy", true, function() ran = ran + 1 return "done" end)
check("manager action refused (admin only)", I:handleAction(manager, 1, "testBuy", ""), "tp_msg_ins_denied_admin")
I.adminOnly = false
check("manager action refused for worker", I:handleAction(worker, 1, "testBuy", ""), "tp_msg_ins_denied")
check("manager action runs for manager", I:handleAction(manager, 1, "testBuy", ""), "done")
I.isEnabled = false
check("manager action refused while OFF", I:handleAction(manager, 1, "testBuy", ""), "tp_msg_ins_off")
I.isEnabled = true
check("action ran once", ran, 1)
check("unknown action ignored", I:handleAction(admin, 1, "nope", ""), nil)
check("read action open to everyone", I:handleAction(worker, 1, "read", ""), nil)
check("inbox read", I:getUnreadCount(1), 0)

-- ---------------------------------------------------------------- inbox limit
for i = 1, I.MAX_INBOX + 5 do I:addInbox(2, "tp_msg_ins_payout", { TornadoText.cash(i) }) end
check("inbox capped", #I:getFarm(2).inbox, I.MAX_INBOX)
check("oldest dropped", I:getFarm(2).inbox[I.MAX_INBOX].params[1].value, I.MAX_INBOX + 5)

-- ---------------------------------------------------------------- save / load
I:addTimer(1, I.TIMER_TEST, 15, "data")
I:save()
local saved = files["savegame1/TornadoInsurance.xml"]
check("save file written", saved ~= nil, true)
local inboxBefore = #I:getFarm(1).inbox
I:deleteMap()
I:loadMap("", "FS25_TornadoPhysics")
check("farm totals restored", I:getFarm(1).premiumsTotal, 80)
check("payouts restored", I:getFarm(1).payoutsTotal, 500)
check("inbox restored", #I:getFarm(1).inbox, inboxBefore)
check("money param restored as number", I:getFarm(1).inbox[2].params[1].value, 70)
check("history restored", #I:getFarm(1).history, 2)
check("timer restored", #I.timers == 1 and I.timers[1].data == "data" and I.timers[1].remaining == 0.5, true)
check("next timer id restored", I.nextTimerId, 4)
check("status text", I:getStatusText():find("Kansas", 1, true) ~= nil, true)

-- ---------------------------------------------------------------- crop cross-reference (map / mod crops)
local C = TornadoInsuranceCrops
local aliases = C.loadAliases("DB/InsuranceCropAliases.xml")
check("aliases loaded", aliases.aliases.SPELT ~= nil and aliases.aliases.SPELT.ratedAs, "WHEAT")
check("prefixes loaded", #aliases.prefixes, 3)
check("categories loaded in order", aliases.categories[1].name, "GRAINHEADER")
local function r(profile, region, name, cats) return C.resolve(aliases, profile, region, name, cats) end
local res = r(us, "US", "WHEAT")
check("WHEAT: own data, local", res.method == "data" and res.ratedAs == "WHEAT" and res.isLocal, true)
res = r(us, "US", "SPELT")
check("SPELT -> WHEAT by alias, local", res.method == "alias" and res.ratedAs == "WHEAT" and res.isLocal, true)
res = r(us, "US", "WINTERWHEAT")
check("WINTERWHEAT -> WHEAT by prefix", res.method == "prefix" and res.ratedAs == "WHEAT", true)
check("WINTERBARLEY -> BARLEY", r(us, "US", "WINTERBARLEY").ratedAs, "BARLEY")
check("WINTEROAT -> OAT", r(us, "US", "WINTEROAT").ratedAs, "OAT")
check("WINTERSPELT -> SPELT -> WHEAT", r(us, "US", "WINTERSPELT").ratedAs, "WHEAT")
check("BEETROOT (game name) -> REDBEET (data name)", r(us, "US", "BEETROOT").ratedAs, "REDBEET")
res = r(us, "US", "GREENRYE")
check("GREENRYE not insurable", res.insurable == false and res.method == "notInsurable", true)
check("OILSEEDRADISH not insurable", r(us, "US", "OILSEEDRADISH").insurable, false)
res = r(us, "US", "HOPS")
check("HOPS -> DEFAULT, unusual", res.method == "default" and res.ratedAs == "DEFAULT" and not res.isLocal, true)
res = r(us, "US", "MODGRAIN", { GRAINHEADER = true })
check("unknown grain-header crop -> WHEAT by category, unusual", res.method == "category" and res.ratedAs == "WHEAT" and not res.isLocal, true)
res = r(us, "US_KS", "RICE")
check("rice in Kansas: in the US data, but unusual for the state", res.method == "data" and not res.isLocal, true)
check("wheat in Kansas: local", r(us, "US_KS", "WHEAT").isLocal, true)
local de = D.load("DB/CropInsurance_DE.xml", "x")
res = r(de, nil, "COTTON", { PLANTER = true })
check("cotton in Germany -> by category (SOYBEAN), unusual", res.method == "category" and res.ratedAs == "SOYBEAN" and not res.isLocal, true)
check("cotton in Germany without category -> DEFAULT", r(de, nil, "COTTON").ratedAs, "DEFAULT")
check("rye in Germany -> WHEAT", r(de, nil, "RYE").ratedAs, "WHEAT")
-- Every crop of the 49-map survey resolves; only the specialty crops fall back to DEFAULT.
local survey = { "ALFALFA", "BEANS", "BLACKBEAN", "BUCKWHEAT", "CHICKPEAS", "CLOVER", "DECOFOLIAGEMIX", "FABABEAN",
    "FIELDGRASS", "FLAX", "FLAXSEED", "FLOWERINGCATCHCROP", "GREENRYE", "HEMP", "HOPS", "HUMUSACTIVE", "LAVENDER",
    "LENTILS", "LINSEED", "MILLET", "MUSTARD", "MUSTARDCOVER", "PEANUT", "PINTOBEAN", "POPPY", "REDONION", "RYE",
    "SILAGEMAIZE", "SPELT", "TOBACCO", "TRITICALE", "VETCHRYE", "WINTERBARLEY", "WINTEROAT", "WINTERWHEAT" }
for _, profile in ipairs({ us, de }) do
    local defaults = {}
    for _, name in ipairs(survey) do
        if r(profile, nil, name).method == "default" then table.insert(defaults, name) end
    end
    check("survey crops on DEFAULT (" .. profile.rootId .. ")", table.concat(defaults, ","), "HOPS,LAVENDER,TOBACCO")
end
-- Alias targets are real crop names (all exist in the US data, which lists every base crop).
check("every alias target is a known crop", (function()
    for name, alias in pairs(aliases.aliases) do
        if r(us, nil, name).method ~= "alias" then
            print("    " .. name .. " -> " .. tostring(alias.ratedAs) .. " is not a crop of the data")
            return false
        end
    end
    return true
end)(), true)
local pl = D.load("DB/CropInsurance_PL.xml", "x")
check("Poland has no grass programme: alfalfa -> DEFAULT, unusual", r(pl, nil, "ALFALFA").method, "default")

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
