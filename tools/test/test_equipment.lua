-- Offline test for scripts/insurance/TornadoInsuranceEquipment.lua (insurance phase 3: equipment) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_equipment.lua
-- Real: TornadoInsurance, TornadoInsuranceEquipment, TornadoRecovery (estimate), TornadoText with the English texts,
--       TornadoInsuranceStateEvent (stream round trip).
-- Stubs: vehicles, vehicle system, clock, money, savegame XML, network stream.
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
function entityExists(node) return node ~= nil end
function setVisibility() end
Utils = { getFilename = function(name, dir) return (dir or "") .. name end }

-- ---------------------------------------------------------------- English texts (real TornadoText)
local texts = {}
do
    local f = assert(io.open("translations/translation_en.xml", "r"))
    for name, text in f:read("*a"):gmatch('<text name="([^"]+)" text="([^"]*)"') do
        texts[name] = text:gsub("&quot;", '"'):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
    end
    f:close()
end
g_i18n = {
    hasText = function(_, key) return texts[key] ~= nil end,
    getText = function(_, key) return texts[key] end,
    formatMoney = function(_, amount) return string.format("$%d", math.floor(amount + 0.5)) end,
}
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
VehiclePropertyState = { NONE = 1, OWNED = 2, LEASED = 3, MISSION = 4, SHOP_CONFIG = 5 }

local balance = 0
local farmList = { { farmId = 0 }, { farmId = 1 }, { farmId = 2 } }
g_farmManager = {
    getFarms = function() return farmList end,
    getFarmById = function(_, id) return (id == 1 or id == 2) and farmList[id + 1] or nil end,
}
local environment = { daysPerPeriod = 1, currentMonotonicDay = 10, dayTime = 0, currentYear = 1, currentPeriod = 5 }

-- Vehicles
local vehicles, byUniqueId, nextNode = {}, {}, 100
local function addVehicle(def)
    nextNode = nextNode + 1
    local v = { rootNode = nextNode, uniqueId = def.id, propertyState = def.state or VehiclePropertyState.OWNED,
        farmId = def.farm or 1, price = def.price or 100000, sell = def.sell or 50000, damage = def.damage or 0,
        typeName = def.typeName or "tractor", name = def.name or def.id, controlled = false }
    v.getUniqueId = function(self) return self.uniqueId end
    v.getOwnerFarmId = function(self) return self.farmId end
    v.getPrice = function(self) return self.price end
    -- Like the game: damage lowers the sell price (repair price is subtracted).
    v.getSellPrice = function(self) return self.sell * (1 - self.damage * 0.5) end
    v.getDamageAmount = function(self) return self.damage end
    v.setDamageAmount = function(self, d) self.damage = d end
    v.getFullName = function(self) return self.name end
    v.getIsControlled = function(self) return self.controlled end
    v.delete = function(self)
        self.isDeleted = true
        byUniqueId[self.uniqueId] = nil
        for i = #vehicles, 1, -1 do if vehicles[i] == self then table.remove(vehicles, i) end end
    end
    if def.ads ~= nil then
        v.spec_AdvancedDamageSystem = {}
        v.adsPrice = def.ads
        v.getServicePrice = function(self) return self.adsPrice end
    end
    table.insert(vehicles, v)
    byUniqueId[v.uniqueId] = v
    return v
end

g_currentMission = {
    getIsServer = function() return true end,
    getFarmId = function() return 1 end,
    environment = environment,
    addMoney = function(_, amount, farmId) if farmId == 1 then balance = balance + amount end end,
    vehicleSystem = { vehicles = vehicles, getVehicleByUniqueId = function(_, id) return byUniqueId[id] end },
}

local inbox = {}
TornadoSync = { isMultiplayer = function() return false end, MSG_CRITICAL = 1, sendDestruction = function() end,
    sendMessage = function(_, key, params) table.insert(inbox, { key = key, params = params, text = TornadoText.formatMessage(key, params) }) end }
local costScale = 1
TornadoSettings = { getCostScale = function() return costScale end }
TornadoDestruction = { _destroyedObjects = {}, _resolveSavegamePath = function() return "savegame1/" end,
    KIND_TRASH = "trash", KIND_STRUCT = "struct", KIND_WHEEL = "wheel", KIND_TRACK = "track", TRASH_KEYWORDS = {} }
TornadoEffects = { activeEffects = {}, fireFate = {}, willBurn = function(self, node) return self.fireFate[node] == true end }
local stormActive = false
TornadoInsuranceCrop = { install = function() end, uninstall = function() end, isStormActive = function() return stormActive end,
    getOpenClaimCount = function() return 0 end }

dofile("scripts/TornadoRecovery.lua")
dofile("scripts/insurance/TornadoInsuranceEquipment.lua")
dofile("scripts/insurance/TornadoInsurance.lua")
local E = TornadoInsuranceEquipment
local I = TornadoInsurance

-- ---------------------------------------------------------------- helpers
local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    local ok
    if type(want) == "number" and type(got) == "number" then
        ok = math.abs(got - want) < 0.01
    else
        ok = got == want
    end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL  %-62s got %s, want %s", label, tostring(got), tostring(want)))
    else
        print(string.format("ok    %-62s %s", label, tostring(got)))
    end
end
local function lastMessage() return inbox[#inbox] or { key = "", text = "" } end
local function hasMessage(key)
    for _, m in ipairs(inbox) do if m.key == key then return true end end
    return false
end
local MS_PER_DAY = 24 * 3600 * 1000
-- daysPerPeriod = 1: one month (30 real days) = one in-game day -> 1 real day = 48 in-game minutes.
local function realDays(days)
    local steps = math.ceil(days * 48)
    for _ = 1, steps do
        environment.dayTime = environment.dayTime + 60000
        if environment.dayTime >= MS_PER_DAY then
            environment.dayTime = environment.dayTime - MS_PER_DAY
            environment.currentMonotonicDay = environment.currentMonotonicDay + 1
        end
        publish(MessageType.MINUTE_CHANGED)
    end
end
local function destroy(v, struct, wheels)
    local nodes = {}
    for i = 1, struct or 0 do table.insert(nodes, { id = 1000 + i, name = "part" .. i, kind = "struct" }) end
    for i = 1, wheels or 0 do table.insert(nodes, { id = 2000 + i, name = "wheel#" .. i, kind = "wheel" }) end
    TornadoDestruction._destroyedObjects[v.rootNode] = { obj = v, nodes = nodes }
end
local function claimOf(uniqueId)
    for _, claim in ipairs(I.farms[1].equipClaims or {}) do if claim.uniqueId == uniqueId then return claim end end
    return nil
end

-- ---------------------------------------------------------------- setup
I.isEnabled = true
I:loadMap("", "FS25_TornadoPhysics")
publish(MessageType.MINUTE_CHANGED)   -- timer baseline

local tractor = addVehicle({ id = "tractor", price = 200000, sell = 100000 })
local trailer = addVehicle({ id = "trailer", price = 40000, sell = 20000, damage = 0.2, typeName = "trailer" })
addVehicle({ id = "leased", state = VehiclePropertyState.LEASED, sell = 90000 })
addVehicle({ id = "pallet", typeName = "pallet", sell = 500 })
addVehicle({ id = "neighbour", farm = 2, sell = 70000 })

-- 1. Quote: owned vehicles of the farm only.
local quote = E:getFarmQuote(1, 2500)
check("quote: 2 insurable vehicles (no leased / pallet / other farm)", quote.vehicles, 2)
check("quote: value = sell prices", quote.value, 100000 + 20000 * 0.9)
check("quote: premium 1.2 % a year / 12", quote.monthlyPremium, 118000 * 0.012 / 12)
check("higher deductible = lower premium", E:getFarmQuote(1, 10000).monthlyPremium < E:getFarmQuote(1, 1000).monthlyPremium, true)

-- 2. Buy: pending, no contact recorded before the cover starts.
stormActive = true
check("no buying during a storm", E:buy(1, "2500"), "tp_msg_ins_crop_storm")
stormActive = false
check("unknown deductible refused", E:buy(1, "3000"), "tp_msg_ins_eq_unknown_deductible")
I:requestAction(1, "equipBuy", "2500")
check("policy pending", I.farms[1].equipment.status, E.STATUS_PENDING)
check("bought letter", lastMessage().key, "tp_msg_ins_eq_bought")
E:onVehicleContact(tractor)
check("pending policy: no value snapshot", E.contacts.tractor, nil)
check("no premium while pending", E:getMonthlyPremium(1), 0)
realDays(7)
check("active after 7 real days", I.farms[1].equipment.status, E.STATUS_ACTIVE)
check("active letter", lastMessage().key, "tp_msg_ins_eq_active")

-- 3. Billing
local before = balance
publish(MessageType.PERIOD_CHANGED)
check("monthly premium charged", before - balance, math.floor(118000 * 0.012 / 12 + 0.5))

-- 4. Storm: value recorded at first contact, before the damage.
E:onVehicleContact(tractor)
E:onVehicleContact(trailer)
E:onVehicleContact(byUniqueId.leased)
check("snapshot: tractor value before damage", E.contacts.tractor.value, 100000)
check("leased vehicle not recorded", E.contacts.leased, nil)
tractor.damage = 0.5
destroy(tractor, 4, 2)
E:onVehicleContact(tractor)
check("second contact keeps the first value", E.contacts.tractor.value, 100000)
-- Recovery estimate: tow 500 + 0.5 % of 200000 = 1500, 4 parts x 30, 2 wheels x 1200, engine 8 % x 0.5 = 8000
local estimate = TornadoRecovery:estimateRepairCost(tractor)
check("tow bill estimate total", estimate.total, 1500 + 120 + 2400 + 8000)
E:onStormEnded()
local claim = claimOf("tractor")
check("claim opened for the tractor", claim ~= nil, true)
check("claim estimate = tow bill (no damage before)", claim.estimate, 12020)
check("trailer: old damage only - no claim", claimOf("trailer"), nil)
check("contacts cleared after the storm", next(E.contacts), nil)
check("received letter", lastMessage().key, "tp_msg_ins_eq_claim_received")
realDays(3)
check("inspected after 3 days", claim.status, "INSPECTED")
realDays(2)
check("approved after 2 more days", claim.status, "APPROVED")
check("approved letter", lastMessage().key, "tp_msg_ins_eq_claim_approved")
before = balance
realDays(1)
check("paid", claim.status, "PAID")
check("payout = estimate - deductible", balance - before, 12020 - 2500)
TornadoDestruction._destroyedObjects[tractor.rootNode] = nil
tractor.damage = 0

-- 5. Damage the storm added, not what was there before (engine) + ADS breakdowns it added.
local loader = addVehicle({ id = "loader", price = 100000, sell = 60000, damage = 0.4, ads = 1000 })
E:onVehicleContact(loader)
loader.damage = 0.6
loader.adsPrice = 6000
local result = E:assess(E.contacts.loader)
check("engine: only the added 20 % (100000 x 8 % x 0.2)", result.engine, 1600)
check("ADS: only the added repair price", result.ads, 5000)
check("estimate = engine + ADS (no parts lost)", result.estimate, 6600)
E.contacts = {}
loader.damage, loader.adsPrice = 0, 0

-- 6. Below the deductible: closed.
E:onVehicleContact(trailer)
destroy(trailer, 2, 0)
E:onStormEnded()
local small = claimOf("trailer")
check("small claim opened", small ~= nil, true)
realDays(5)
check("estimate below deductible: denied", small.status, "DENIED")
check("deductible letter", lastMessage().key, "tp_msg_ins_eq_claim_deductible")
TornadoDestruction._destroyedObjects[trailer.rootNode] = nil

-- 7. Reset before the storm ended: the tow bill's estimate is kept.
TornadoSettings.recoveryEnabled = true
E:onVehicleContact(tractor)
tractor.damage = 0.25
destroy(tractor, 0, 1)
before = balance
TornadoRecovery:processRecovery(tractor)
check("tow bill charged on reset", before - balance, 1500 + 1200 + 4000)
check("vehicle repaired by the reset", tractor.damage, 0)
E:onStormEnded()
local reset = nil
for _, c in ipairs(I.farms[1].equipClaims) do if c.uniqueId == "tractor" and c.status == "RECEIVED" then reset = c end end
check("claim after the reset uses the tow bill", reset ~= nil and reset.estimate or nil, 6700)
realDays(6)
check("reset claim paid", reset.status, "PAID")

-- 8. Burned vehicle = total loss; buy back -> Salvage title -> Rebuilt.
local combine = addVehicle({ id = "combine", price = 300000, sell = 50000 })
E:onVehicleContact(combine)
combine.damage = 1.0
combine.tornadoIsOnFire = true      -- ignite threshold reached ...
TornadoEffects.fireFate[combine.rootNode] = true   -- ... and the fire roll came up
destroy(combine, 3, 0)
E:onStormEnded()
local burned = claimOf("combine")
check("burned claim flagged", burned.burned, true)
realDays(5)
check("burned vehicle: total loss", burned.status, "TOTAL")
check("total loss letter (burned)", lastMessage().key, "tp_msg_ins_eq_total_burned")
check("accept pays value - deductible", burned.lossPayout, 47500)
check("buy back also keeps the salvage value back", burned.buyBackPayout, 47500 - 7500)
check("pending total listed", #E:getPendingTotals(I.farms[1]), 1)
before = balance
I:requestAction(1, "equipBuyBack", tostring(burned.id))
check("bought back", burned.status, "BOUGHT_BACK")
check("buy-back payout", balance - before, 40000)
check("choice timers removed", burned.choiceTimer == nil and burned.reminderTimer == nil, true)
check("vehicle kept", combine.isDeleted, nil)
check("Salvage title", I.farms[1].titles.combine, E.TITLE_SALVAGE)
E.wrapSellPrice(combine)
check("Salvage: sell price -50 %", combine:getSellPrice(), 50000 * 0.5 * 0.5)
check("second choice refused", E:choose(1, burned.id, true), "tp_msg_ins_eq_no_total")
-- Repaired (reset): Rebuilt
TornadoRecovery:processRecovery(combine)
check("reset clears the fire roll", TornadoEffects.fireFate[combine.rootNode], nil)
check("Rebuilt after the repair", I.farms[1].titles.combine, E.TITLE_REBUILT)
check("Rebuilt: sell price -30 %", combine:getSellPrice(), 50000 * 0.7)
I.rebuiltPenalty = 0.4
check("penalty setting applies at once", combine:getSellPrice(), 50000 * 0.6)
I.rebuiltPenalty = 0.3
I.isEnabled = false
check("insurance off: no title penalty", combine:getSellPrice(), 50000)
I.isEnabled = true
check("wrapped only once", (function() local f = combine.getSellPrice E.wrapSellPrice(combine) return combine.getSellPrice == f end)(), true)

-- 8b. Past the ignite threshold but the fire roll said no: NOT a total loss.
local truck = addVehicle({ id = "truck", price = 150000, sell = 90000 })
E:onVehicleContact(truck)
truck.damage = 1.0
truck.tornadoIsOnFire = true
TornadoEffects.fireFate[truck.rootNode] = false
destroy(truck, 3, 1)
E:onStormEnded()
local smoked = claimOf("truck")
check("threshold only: not flagged burned", smoked.burned, false)
realDays(5)
check("threshold only: repair claim, no total loss", smoked.status, "APPROVED")
realDays(1)
TornadoDestruction._destroyedObjects[truck.rootNode] = nil

-- 9. Total loss by estimate (old cheap tool), no choice -> reminder, accepted, wreck removed.
local mower = addVehicle({ id = "mower", price = 100000, sell = 3000, typeName = "mower" })
E:onVehicleContact(mower)
destroy(mower, 10, 2)    -- tow 1000 + 10 x 30 + 2 x 600 = 2500 >= 75 % of 3000
E:onStormEnded()
local old = claimOf("mower")
check("old tool estimate", old.estimate, 2500)
realDays(5)
check("estimate >= 75 % of value: total loss", old.status, "TOTAL")
mower.controlled = true
realDays(3.5)
check("reminder halfway", hasMessage("tp_msg_ins_eq_total_reminder"), true)
before = balance
realDays(3.6)
check("no choice in time: accepted", old.status, "SETTLED")
check("auto-settled letter", lastMessage().key, "tp_msg_ins_eq_settled_auto")
check("payout value - deductible", balance - before, 500)
check("someone sits in it: removal waits", mower.isDeleted, nil)
mower.controlled = false
realDays(0.2)
check("wreck removed by the next scan", mower.isDeleted, true)
check("no removal pending any more", old.removePending, nil)

-- 10. Replacement value + keep totalled vehicles.
I.replacementValue = true
local decision = E:decide({ value = 40000, estimate = 31000, deductible = 2500 })
check("replacement value: 40000 + 15 % -> 31000 is no total loss", decision.status, "APPROVED")
check("replacement value total loss payout", E:decide({ value = 40000, estimate = 40000, deductible = 2500 }).lossPayout, 46000 - 2500)
I.replacementValue = false
check("sell value: 31000 >= 75 % of 40000 = total loss", E:decide({ value = 40000, estimate = 31000, deductible = 2500 }).status, "TOTAL")
I.removeTotaled = false
local baler = addVehicle({ id = "baler", price = 100000, sell = 3000, typeName = "baler" })
E:onVehicleContact(baler)
destroy(baler, 10, 2)
E:onStormEnded()
realDays(5)
local kept = claimOf("baler")
before = balance
I:requestAction(1, "equipAccept", tostring(kept.id))
check("keep totalled: accept keeps the vehicle", baler.isDeleted, nil)
check("keep totalled: buy-back amount", balance - before, 50)
check("keep totalled: Salvage title", I.farms[1].titles.baler, E.TITLE_SALVAGE)
check("keep totalled letter", lastMessage().key, "tp_msg_ins_eq_kept")
I.removeTotaled = true

-- 11. Sold before the decision: the claim still pays.
local seeder = addVehicle({ id = "seeder", price = 80000, sell = 40000, typeName = "sowingMachine" })
E:onVehicleContact(seeder)
seeder.damage = 0.5
destroy(seeder, 5, 2)
E:onStormEnded()
local sold = claimOf("seeder")
seeder:delete()
before = balance
realDays(6)
check("sold vehicle: claim still paid", sold.status, "PAID")
check("sold vehicle: payout", balance - before, sold.estimate - 2500)

-- 12. Cost scale: the deductible follows it.
costScale = 2
E:onVehicleContact(tractor)
destroy(tractor, 0, 2)
E:onStormEnded()
local scaled = nil
for _, c in ipairs(I.farms[1].equipClaims) do if c.uniqueId == "tractor" and c.status == "RECEIVED" then scaled = c end end
check("deductible x cost scale", scaled.deductible, 5000)
TornadoDestruction._destroyedObjects[tractor.rootNode] = nil
costScale = 1

-- 13. Every letter formats with its parameters (English texts).
local bad = 0
for _, m in ipairs(inbox) do
    if string.find(m.text, "tp_msg", 1, true) then bad = bad + 1 print("  unformatted: " .. m.text) end
end
check("all letters formatted", bad, 0)
print("  e.g. " .. (function() for _, m in ipairs(inbox) do if m.key == "tp_msg_ins_eq_total_burned" then return m.text end end end)())

-- 14. State event round trip (what clients get).
EventIds = { getEventClassByName = function() return nil end }
function Class(_, base) return { __index = setmetatable({}, { __index = base }) } end
function InitEventClass() end
Event = { new = function(mt) return setmetatable({}, mt) end }
dofile("scripts/events/TornadoInsuranceStateEvent.lua")
setmetatable(TornadoInsuranceStateEvent, nil)
local stream = {}
local function push(v) table.insert(stream, v) end
local function pop() return table.remove(stream, 1) end
streamWriteUIntN, streamWriteFloat32, streamWriteString, streamWriteInt32, streamWriteBool =
    function(_, v) push(v) end, function(_, v) push(v) end, function(_, v) push(v) end, function(_, v) push(v) end, function(_, v) push(v) end
streamReadUIntN, streamReadFloat32, streamReadString, streamReadInt32, streamReadBool = pop, pop, pop, pop, pop
-- one pending total for the round trip
local press = addVehicle({ id = "press", price = 100000, sell = 3000, typeName = "baler" })
E:onVehicleContact(press)
destroy(press, 10, 2)
E:onStormEnded()
realDays(5)
local event = TornadoInsuranceStateEvent.new(1, I.farms[1])
event.writeStream = TornadoInsuranceStateEvent.writeStream
TornadoInsuranceStateEvent.writeStream(event, 0, nil)
local received = { run = function() end }
TornadoInsuranceStateEvent.readStream(received, 0, nil)
check("state: deductible", received.state.equipDeductible, 2500)
check("state: status", received.state.equipStatus, E.STATUS_ACTIVE)
check("state: titles", received.state.titles.combine, E.TITLE_REBUILT)
check("state: total loss to choose", #received.state.equipTotals, 1)
check("state: buy-back amount", received.state.equipTotals[1].buyBackPayout, 50)
-- Claims section list (TornadoInsurance:getClaimList -> state event)
local list = I:getClaimList(1)
check("claim list: every equipment claim", #list, #I.farms[1].equipClaims)
local pressSummary = nil
for _, c in ipairs(received.state.claimList) do if c.subject == "press" or c.status == "TOTAL" then pressSummary = c end end
check("claim list sent: the total loss", pressSummary ~= nil and pressSummary.kind, "EQUIP")
check("claim list sent: buy-back amount", pressSummary.values[6], 50)
check("claim list sent: auto-accept countdown running", pressSummary.remaining > 0, true)
check("claim list sent: as many as the server has", #received.state.claimList, math.min(#list, 50))
local newestFirst = true
for i = 2, #list do if list[i].day > list[i - 1].day then newestFirst = false end end
check("claim list newest first", newestFirst, true)
check("stream fully read", #stream, 0)

-- 15. Save / load (also a storm still running: its recorded values survive the reload)
E:onVehicleContact(tractor)
tractor.damage = 0.3
destroy(tractor, 2, 1)
I:save()
local saved = I.farms[1]
local savedClaims = #saved.equipClaims
I:deleteMap()
I:loadMap("", "FS25_TornadoPhysics")
local farm = I.farms[1]
check("policy restored", farm.equipment ~= nil and farm.equipment.deductible, 2500)
check("policy status restored", farm.equipment.status, E.STATUS_ACTIVE)
check("claims restored", #farm.equipClaims, savedClaims)
check("titles restored", farm.titles.combine, E.TITLE_REBUILT)
local restored = nil
for _, c in ipairs(farm.equipClaims) do if c.uniqueId == "press" then restored = c end end
check("pending total restored with its choice timer", restored.status == "TOTAL" and restored.choiceTimer ~= nil, true)
before = balance
I:requestAction(1, "equipAccept", tostring(restored.id))
check("accept after reload", restored.status, "SETTLED")
check("press removed", press.isDeleted, true)
check("running storm's recorded value restored", E.contacts.tractor ~= nil and E.contacts.tractor.value, 100000)
E:onStormEnded()
local resumed = nil
for _, c in ipairs(I.farms[1].equipClaims) do if c.uniqueId == "tractor" and c.status == "RECEIVED" then resumed = c end end
check("storm ended after the reload: claim opened", resumed ~= nil, true)
TornadoDestruction._destroyedObjects[tractor.rootNode] = nil
tractor.damage = 0

-- 16. Insurance OFF: the scan leaves vehicle prices alone.
local spare = addVehicle({ id = "spare", sell = 10000 })
I.isEnabled = false
E:scan()
check("insurance off: no sell price wrapper", spare.tornadoTitleWrapped, nil)
I.isEnabled = true
E:scan()
check("insurance on: wrapped by the scan", spare.tornadoTitleWrapped, true)

-- 17. Cancel
I:requestAction(1, "equipCancel", "")
check("cancelled", I.farms[1].equipment, nil)
check("no premium after cancel", E:getMonthlyPremium(1), 0)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
