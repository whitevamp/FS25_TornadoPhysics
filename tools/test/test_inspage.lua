-- Offline smoke test for scripts/gui/pages/TornadoPageInsurance.lua (Insurance tab: Start here + My policies)
-- - Lua 5.1. Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_inspage.lua
-- Real: TornadoMenuPage, the page. Stubs: the insurance modules (quotes), TornadoText, fake GUI elements.
-- Exit code 0 = all checks passed.

TornadoText = { money = function(v) return string.format("$%d", math.floor((v or 0) + 0.5)) end,
    get = function(k) return k end,
    format = function(k, ...) local parts = { k } for _, v in ipairs({ ... }) do table.insert(parts, tostring(v)) end return table.concat(parts, "|") end }
local multiplayer, isServer, isMaster, isManager = false, true, false, false
TornadoSync = { isMultiplayer = function() return multiplayer end, isClient = function() return not isServer end,
    canEditSettings = function() return isServer or isMaster end }
g_currentMission = { getFarmId = function() return 1 end, getIsServer = function() return isServer end, isMasterUser = false, playerUserId = 7 }
g_farmManager = { getFarmById = function() return { isUserFarmManager = function() return isManager end } end }

local requests = {}
TornadoInsurance = { isEnabled = true, adminOnly = false, farms = { [1] = {} },
    getCostScale = function() return 1 end,
    requestAction = function(_, farmId, name, args) table.insert(requests, name .. " " .. args) end }
local salesOpen = true
TornadoInsuranceCrop = { STATUS_ACTIVE = "ACTIVE", PLAN_KEYS = setmetatable({}, { __index = function(_, k) return "plan_" .. k end }),
    isAvailable = function() return true end, getDisabledReason = function() return nil end,
    getOfferedPlans = function() return { "RP", "YP" } end,
    getCoverageLevels = function(_, plan) return plan == "YP" and { 0.5, 0.6, 0.7 } or { 0.5, 0.75, 0.85 } end,
    isSalesOpen = function() return salesOpen end,
    getFarmQuote = function(_, _, plan, coverage) return { fields = 4, liability = 100000, uninsurable = 0,
        monthlyPremium = (plan == "RP" and 100 or 60) * coverage } end,
    getOpenClaimCount = function() return 1 end }
TornadoInsuranceEquipment = { STATUS_ACTIVE = "ACTIVE", DEDUCTIBLES = { 1000, 2500, 5000, 10000 },
    getFarmQuote = function(_, _, deductible) return { vehicles = 8, value = 200000, monthlyPremium = 2000000 / deductible } end,
    getOpenClaimCount = function() return 0 end }
TornadoInsuranceLivestock = { STATUS_ACTIVE = "ACTIVE",
    getFarmQuote = function() return { animals = 25, value = 13730, monthlyPremium = 9 } end,
    hasGovProgram = function() return true end, isHusbandryOn = function() return true end,
    getOpenClaimCount = function() return 0 end }

dofile("scripts/gui/TornadoMenuPage.lua")
dofile("scripts/gui/pages/TornadoPageInsurance.lua")
local P = TornadoPageInsurance

-- fake GUI
local function element(name)
    local e = { name = name, text = "", visible = true, disabled = false, elements = {} }
    function e:setText(t) self.text = t end
    function e:setVisible(v) self.visible = v end
    function e:setDisabled(d) self.disabled = d end
    function e:getIsDisabled() return self.disabled end
    function e:setTexts(t) self.texts = t end
    function e:setState(s) self.state = s end
    function e:getState() return self.state end
    function e:setIsChecked(v) self.checked = v end
    return e
end
local menu = { controls = {}, pages = {}, activePageIndex = 1 }
function menu:registerControl(el, page, def) self.controls[el] = { page = page, def = def } end
function menu:markDirty() self.dirty = true end
function menu:setStatus(t) self.status = t end
function menu:refreshAllPages() P:refresh() end
function menu:confirm(_, callback) self.confirms = (self.confirms or 0) + 1 callback() end
for _, id in ipairs({ "tabInsurance", "pageInsurance", "insNavStart", "insNavPolicies", "insStart", "insPolicies", "insCrop",
    "insCropCoverage", "insEquip", "insLivestock", "insQuote", "insConfirm", "insStartNote", "insQuoteText", "insPolCropText",
    "insPolCropCancel", "insPolEquipText", "insPolEquipCancel", "insPolLivestockText", "insPolLivestockCancel", "insPolClaims" }) do
    menu[id] = element(id)
end
menu.pages = { P }

local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL  %-58s got %s, want %s", label, tostring(got), tostring(want)))
    else
        print(string.format("ok    %-58s %s", label, tostring(got)))
    end
end
local function click(id) local entry = menu.controls[menu[id]] entry.page:onAction(entry.def) end
local function choose(id, value)
    local entry = menu.controls[menu[id]]
    for i, option in ipairs(entry.def.choices) do
        if option.value == value then entry.page:onChoiceChanged(entry.def, menu[id], i) return true end
    end
    return false
end
local function has(text, part) return string.find(text or "", part, 1, true) ~= nil end

P:bind(menu)
P:onShow()
check("Start here visible, My policies hidden", menu.insStart.visible and not menu.insPolicies.visible, true)
check("crop starts at Not included (no policy)", P.state.crop, "none")
check("hint before a quote", menu.insQuoteText.text, "tp_ins_q_hint")
check("Confirm disabled without a quote", menu.insConfirm.disabled, true)
check("crop options: none + 2 plans", #menu.controls[menu.insCrop].def.choices, 3)

-- Choose crop RP 75 %, equipment 2500, livestock
choose("insCrop", "RP")
choose("insEquip", 2500)
choose("insLivestock", "insured")
click("insQuote")
check("quote has a crop line", has(menu.insQuoteText.text, "tp_ins_q_crop|plan_RP|75|4"), true)
check("quote has an equipment line", has(menu.insQuoteText.text, "tp_ins_q_equip|$2500|8"), true)
check("quote has a livestock line + USDA note", has(menu.insQuoteText.text, "tp_ins_q_livestock|25") and has(menu.insQuoteText.text, "tp_ins_q_livestock_gov"), true)
check("quote total 75 + 800 + 9", has(menu.insQuoteText.text, "tp_ins_q_total|$884"), true)
check("Confirm enabled for the fresh quote", menu.insConfirm.disabled, false)

-- Changing a choice makes the quote stale
choose("insEquip", 5000)
check("changed choice: quote dropped", menu.insQuoteText.text, "tp_ins_q_hint")
check("changed choice: Confirm disabled again", menu.insConfirm.disabled, true)
click("insQuote")
click("insConfirm")
check("confirm asked first", menu.confirms, 1)
check("three requests sent", #requests, 3)
check("crop request", requests[1], "cropBuy RP 0.75")
check("equipment request", requests[2], "equipBuy 5000")
check("livestock request", requests[3], "livestockBuy ")
check("panel never dirty", menu.dirty, nil)

-- The farm now has the policies (server applied them)
TornadoInsurance.farms[1] = { crop = { plan = "RP", coverage = 0.75, status = "PENDING" }, equipment = { deductible = 5000, status = "ACTIVE" },
    livestock = { status = "PENDING" } }
requests = {}
P:onShow()
check("new visit: choices from the policies", P.state.crop == "RP" and P.state.equip == 5000 and P.state.livestock == "insured", true)
click("insQuote")
check("unchanged policies say so", has(menu.insQuoteText.text, "tp_ins_q_unchanged"), true)
check("nothing new: Confirm disabled", menu.insConfirm.disabled, true)

-- Change crop to YP: coverage snaps to a YP level, old -> new price shown
choose("insCrop", "YP")
check("coverage snapped to a YP level (0.7)", P.state.coverage, 0.7)
click("insQuote")
check("change shows old -> new", has(menu.insQuoteText.text, "tp_ins_q_change|$75|$42"), true)
check("a change can be confirmed", menu.insConfirm.disabled, false)

-- Sales closed: the crop change is not sent
salesOpen = false
click("insQuote")
check("sales closed note", has(menu.insQuoteText.text, "tp_ins_q_sales_closed"), true)
check("only a closed crop change: Confirm disabled", menu.insConfirm.disabled, true)
salesOpen = true

-- Not included while a policy exists: kept (cancel is under My policies)
choose("insCrop", "none")
click("insQuote")
check("crop kept line", has(menu.insQuoteText.text, "tp_ins_q_crop_kept"), true)

-- My policies
click("insNavPolicies")
check("My policies visible", menu.insPolicies.visible and not menu.insStart.visible, true)
check("crop policy text", has(menu.insPolCropText.text, "tp_ins_pol_crop|plan_RP|75|tp_ins_status_pending"), true)
check("equipment policy text", has(menu.insPolEquipText.text, "tp_ins_pol_equip|$5000|tp_ins_status_active"), true)
check("open claims counted (server)", menu.insPolClaims.text, "tp_ins_pol_claims|1")
check("cancel enabled for a policy", menu.insPolEquipCancel.disabled, false)
click("insPolEquipCancel")
check("cancel asked first + sent", menu.confirms == 2 and requests[1] == "equipCancel ", true)

-- Multiplayer client who is not a manager: can look, cannot confirm / cancel
multiplayer, isServer = true, false
P:onShow()
click("insNavStart")
choose("insEquip", 1000)
click("insQuote")
check("non-manager: quote still shown", has(menu.insQuoteText.text, "tp_ins_q_equip"), true)
check("non-manager: Confirm disabled", menu.insConfirm.disabled, true)
check("non-manager: note says why", menu.insStartNote.text, "tp_ins_note_manager")
isManager = true
P:refresh()
check("farm manager: Confirm enabled", menu.insConfirm.disabled, false)

-- Insurance off
TornadoInsurance.isEnabled = false
P:refresh()
check("insurance off: note", menu.insStartNote.text, "tp_ins_note_off")
check("insurance off: Confirm disabled", menu.insConfirm.disabled, true)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
