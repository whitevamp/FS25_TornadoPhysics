-- Offline test for scripts/insurance/TornadoInsuranceLivestock.lua (livestock insurance) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_livestock.lua
-- Real: TornadoInsurance, TornadoInsuranceLivestock, TornadoHusbandry:executeKill (the kill hook), TornadoText
--       with the English texts. Stubs: placeables + animal groups, animal system, clock, money, savegame XML.
-- Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- stubs: XML, files
local files, xmlHandles, nextHandle = {}, {}, 1
function createXMLFile(_, path) local h = nextHandle nextHandle = nextHandle + 1 xmlHandles[h] = { path = path, data = {} } return h end
function loadXMLFile(_, path)
    if files[path] == nil then return 0 end
    local h = nextHandle nextHandle = nextHandle + 1
    xmlHandles[h] = { path = path, data = files[path] }
    return h
end
local function setter(h, key, value) xmlHandles[h].data[key] = value end
setXMLFloat, setXMLInt, setXMLBool, setXMLString = setter, setter, setter, setter
local function getter(h, key) return xmlHandles[h].data[key] end
getXMLFloat, getXMLInt, getXMLBool, getXMLString = getter, getter, getter, getter
function saveXMLFile(h) files[xmlHandles[h].path] = xmlHandles[h].data end
function delete(h) xmlHandles[h] = nil end
function fileExists(path) return files[path] ~= nil end
Utils = { getFilename = function(name, dir) return (dir or "") .. name end }

local texts = {}
do
    local f = assert(io.open("translations/translation_en.xml", "r"))
    for name, text in f:read("*a"):gmatch('<text name="([^"]+)" text="([^"]*)"') do
        texts[name] = text:gsub("&quot;", '"'):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
    end
    f:close()
end
g_i18n = { hasText = function(_, key) return texts[key] ~= nil end, getText = function(_, key) return texts[key] end,
    formatMoney = function(_, amount) return string.format("$%d", math.floor(amount + 0.5)) end }
dofile("scripts/TornadoText.lua")

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
local balance = 0
local farmList = { { farmId = 0 }, { farmId = 1 } }
g_farmManager = { getFarms = function() return farmList end, getFarmById = function(_, id) return id == 1 and farmList[2] or nil end }
local environment = { daysPerPeriod = 1, currentMonotonicDay = 10, dayTime = 0, currentYear = 1, currentPeriod = 5 }

-- Animals: COW sells 2000 each, SHEEP 200 each
local animalTypes = { [1] = { name = "COW" }, [2] = { name = "SHEEP" } }
local subTypes = { [11] = { typeIndex = 1 }, [21] = { typeIndex = 2 } }
local function cluster(subType, count, price)
    local c = { subTypeIndex = subType, numAnimals = count, price = price }
    function c:getSubTypeIndex() return self.subTypeIndex end
    function c:getNumAnimals() return self.numAnimals end
    function c:getSellPrice() return self.price end
    function c:changeNumAnimals(delta) self.numAnimals = self.numAnimals + delta end
    return c
end
local cows = cluster(11, 10, 2000)
local sheep = cluster(21, 20, 200)
local pasture = { name = "Cow Pasture", farm = 1, clusters = { cows, sheep }, spec_husbandry = {}, spec_husbandryFence = { hasFence = true } }
function pasture:getName() return self.name end
function pasture:getOwnerFarmId() return self.farm end
function pasture:getClusters() return self.clusters end
function pasture:getClusterSystem() return { updateNow = function() end } end
local neighbour = { name = "Other farm", farm = 2, clusters = { cluster(11, 50, 2000) }, spec_husbandry = {} }
function neighbour:getName() return self.name end
function neighbour:getOwnerFarmId() return self.farm end
function neighbour:getClusters() return self.clusters end

g_currentMission = {
    getIsServer = function() return true end, getFarmId = function() return 1 end, environment = environment,
    addMoney = function(_, amount, farmId) if farmId == 1 then balance = balance + amount end end,
    animalSystem = { getSubTypeByIndex = function(_, i) return subTypes[i] end, getTypeByIndex = function(_, i) return animalTypes[i] end },
    placeableSystem = { placeables = { pasture, neighbour } },
}

local inbox = {}
TornadoSync = { isMultiplayer = function() return false end, MSG_BLINKING = 2,
    sendMessage = function(_, key, params) table.insert(inbox, { key = key, text = TornadoText.formatMessage(key, params) }) end }
TornadoSettings = { getCostScale = function() return 1 end }
TornadoDestruction = { _resolveSavegamePath = function() return "savegame1/" end }
local stormActive = true
TornadoInsuranceCrop = { install = function() end, uninstall = function() end, isStormActive = function() return stormActive end,
    getOpenClaimCount = function() return 0 end }

dofile("scripts/TornadoHusbandry.lua")
dofile("scripts/insurance/TornadoInsuranceLivestock.lua")
dofile("scripts/insurance/TornadoInsurance.lua")
local LV = TornadoInsuranceLivestock
local I = TornadoInsurance

-- Region / data stubs (the profile loader is tested elsewhere)
local country, animalData, program = "DE", {}, nil
I.resolveRegion = function() return { country = country } end
I.getProfile = function() return { program = program }, nil end
TornadoInsuranceData = { getAnimal = function(_, _, animalType) return animalData[animalType] end }

-- ---------------------------------------------------------------- helpers
local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok = got == want
    if type(want) == "number" and type(got) == "number" then ok = math.abs(got - want) < 0.01 end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-62s got %s, want %s", label, tostring(got), tostring(want)))
    else
        print(string.format("ok    %-62s %s", label, tostring(got)))
    end
end
local function lastKey() return inbox[#inbox] ~= nil and inbox[#inbox].key or "" end
local function hasKey(key) for _, m in ipairs(inbox) do if m.key == key then return true end end return false end
local MS_PER_DAY = 24 * 3600 * 1000
local function realDays(days)
    for _ = 1, math.ceil(days * 48) do
        environment.dayTime = environment.dayTime + 60000
        if environment.dayTime >= MS_PER_DAY then environment.dayTime = environment.dayTime - MS_PER_DAY environment.currentMonotonicDay = environment.currentMonotonicDay + 1 end
        publish(MessageType.MINUTE_CHANGED)
    end
end
local function lastClaim() local list = I.farms[1].livestockClaims or {} return list[#list] end

-- ---------------------------------------------------------------- setup
I.isEnabled = true
I:loadMap("", "FS25_TornadoPhysics")
publish(MessageType.MINUTE_CHANGED)
TornadoHusbandry.isActive = true

-- 1. Quote: own animals only
local quote = LV:getFarmQuote(1)
check("quote: 30 animals of farm 1", quote.animals, 30)
check("quote: value 10 x 2000 + 20 x 200", quote.value, 24000)
check("premium 0.8 % a year / 12", quote.monthlyPremium, 24000 * 0.008 / 12)

-- 2. Buy
stormActive = true
check("no buying during a storm", LV:buy(1), "tp_msg_ins_crop_storm")
stormActive = false
I:requestAction(1, "livestockBuy", "")
check("pending", I.farms[1].livestock.status, LV.STATUS_PENDING)
check("bought letter", lastKey(), "tp_msg_ins_lv_bought")
check("buying twice refused", LV:buy(1), "tp_msg_ins_lv_already")
realDays(7)
check("active after 7 days", I.farms[1].livestock.status, LV.STATUS_ACTIVE)
local before = balance
publish(MessageType.PERIOD_CHANGED)
check("monthly premium charged", before - balance, 16)

-- 3. Tornado kills 3 cows through the real husbandry code: valued BEFORE removal
stormActive = true
TornadoHusbandry.LOSS_MIN, TornadoHusbandry.LOSS_MAX = 3, 3
local killed = TornadoHusbandry:executeKill(pasture)
check("husbandry killed 3", killed, 3)
check("cows left", cows.numAnimals, 7)
check("kill recorded with its value", LV.kills[1] ~= nil and LV.kills[1].value, 6000)
check("kill recorded as COW", LV.kills[1].animalType, "COW")
realDays(0.1)
check("tornado still on the map: no claim yet", lastClaim(), nil)
stormActive = false
LV:onStormEnded()
local claim = lastClaim()
check("claim opened at the storm end", claim ~= nil and claim.count, 3)
check("received letter", lastKey(), "tp_msg_ins_lv_claim_received")
realDays(3)
check("inspected", claim.status, "INSPECTED")
realDays(2)
check("approved", claim.status, "APPROVED")
check("no state programme in DE", claim.govPayout, 0)
check("payout = value - 5 % excess", claim.payout, 5700)
before = balance
realDays(1)
check("paid", claim.status, "PAID")
check("money in", balance - before, 5700)

-- 4. United States: the state pays 75 %, the policy the rest (minus the excess)
country = "US"
LV:onAnimalsKilled(pasture, cows, 2)          -- 4000
LV:onStormEnded()
claim = lastClaim()
realDays(5)
check("US: state 75 % of 4000", claim.govPayout, 3000)
check("US: policy pays 95 % - state = 800", claim.payout, 800)
check("US: state letter", hasKey("tp_msg_ins_lv_gov_approved"), true)
before = balance
realDays(1)
check("US: both paid, never above the value", balance - before, 3800)

-- 5. US without a policy: state only
I:requestAction(1, "livestockCancel", "")
check("cancelled", I.farms[1].livestock, nil)
LV:onAnimalsKilled(pasture, sheep, 5)         -- 1000
LV:onStormEnded()
claim = lastClaim()
check("US, no policy: claim for the state programme", claim ~= nil and claim.insured, 0)
realDays(6)
check("US, no policy: state 750, policy 0", claim.govPayout == 750 and claim.payout == 0, true)

-- 6. No policy, no programme: nothing
country = "DE"
local claims = #I.farms[1].livestockClaims
LV:onAnimalsKilled(pasture, sheep, 1)
LV:onStormEnded()
check("DE, no policy: no claim", #I.farms[1].livestockClaims, claims)

-- 7. Poland: subsidised rate and cap per head; replacement value
country = "PL"
animalData = { COW = { type = "COW", rate = 0.004, maxSumPerHead = 1000 } }
program = { subsidyShare = 0.65, rateCaps = { animal = 0.005 } }
check("PL: farmer rate 0.4 % - 65 % subsidy = 0.14 %", LV:getRate("COW"), 0.0014)
check("PL: sheep (no data) default rate", LV:getRate("SHEEP"), 0.008)
check("PL: cows capped at 1000 a head", LV:getInsuredValue("COW", 3, 6000), 3000)
I.replacementValue = true
check("replacement value +15 % (under the cap)", LV:getInsuredValue("SHEEP", 2, 400), 460)
I.replacementValue = false

-- 8. Kill test with no tornado on the map: closed at the next minute
I:requestAction(1, "livestockBuy", "")
realDays(7)
stormActive = false
claims = #I.farms[1].livestockClaims
LV:onAnimalsKilled(pasture, sheep, 2)
realDays(0.05)
check("no tornado: kills closed by the minute check", #I.farms[1].livestockClaims, claims + 1)

-- 9. Save / load mid-storm
stormActive = true
LV:onAnimalsKilled(pasture, cows, 1)
I:save()
I:deleteMap()
I:loadMap("", "FS25_TornadoPhysics")
check("policy restored", I.farms[1].livestock ~= nil and I.farms[1].livestock.status, LV.STATUS_ACTIVE)
check("claims restored", #I.farms[1].livestockClaims, claims + 1)
check("kill of the running storm restored", #LV.kills, 1)
check("restored kill keeps its value", LV.kills[1].value, 2000)

-- 10. A slow tornado: many hits on the same pasture = ONE claim for all of them; a second pasture with the
--     same name stays its own claim
stormActive = true
LV.kills = {}
local twin = { name = "Cow Pasture", farm = 1, clusters = { cluster(11, 40, 2000) }, spec_husbandry = {}, uniqueId = "twin" }
function twin:getName() return self.name end
function twin:getOwnerFarmId() return self.farm end
function twin:getUniqueId() return self.uniqueId end
pasture.uniqueId = "main"
function pasture:getUniqueId() return self.uniqueId end
local bigHerd = cluster(11, 545, 2000)
for _ = 1, 109 do LV:onAnimalsKilled(pasture, bigHerd, 5) end
LV:onAnimalsKilled(twin, twin.clusters[1], 3)
claims = #I.farms[1].livestockClaims
stormActive = false
LV:onStormEnded()
check("109 hits on one pasture + 1 on its namesake = 2 claims", #I.farms[1].livestockClaims, claims + 2)
check("the big claim holds all 545 cows", I.farms[1].livestockClaims[claims + 1].count, 545)
check("... at their total value", I.farms[1].livestockClaims[claims + 1].value, 545 * 2000)
check("namesake pasture: its own claim of 3", I.farms[1].livestockClaims[claims + 2].count, 3)

-- 11. Every letter formats
local bad = 0
for _, m in ipairs(inbox) do if string.find(m.text, "tp_msg", 1, true) then bad = bad + 1 print("  unformatted: " .. m.text) end end
check("all letters formatted", bad, 0)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
