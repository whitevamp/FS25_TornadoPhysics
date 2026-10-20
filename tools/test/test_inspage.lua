-- Offline smoke test for scripts/gui/pages/TornadoPageInsurance.lua (Insurance tab: Start here, My policies, Claims)
-- - Lua 5.1. Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_inspage.lua
-- Real: TornadoMenuPage, the page. Stubs: the insurance modules (quotes), TornadoText, fake GUI elements.
-- Exit code 0 = all checks passed.

TornadoText = { money = function(v) return string.format("$%d", math.floor((v or 0) + 0.5)) end,
    get = function(k) return k end,
    date = function(day) return "tp_msg_day " .. tostring(day) end,
    month = function(index) return "month " .. tostring(index) end,
    monthShort = function(index) return "m" .. tostring(index) end,
    format = function(k, ...) local parts = { k } for _, v in ipairs({ ... }) do table.insert(parts, tostring(v)) end return table.concat(parts, "|") end }
local multiplayer, isServer, isMaster, isManager = false, true, false, false
TornadoSync = { isMultiplayer = function() return multiplayer end, isClient = function() return not isServer end,
    canEditSettings = function() return isServer or isMaster end }
g_currentMission = { getFarmId = function() return 1 end, getIsServer = function() return isServer end, isMasterUser = false, playerUserId = 7 }
g_farmManager = { getFarmById = function() return { isUserFarmManager = function() return isManager end } end }

local requests = {}
local claimList = {}
renewal = 0
TornadoInsurance = { isEnabled = true, adminOnly = false, removeTotaled = true, farms = { [1] = {} },
    getCostScale = function() return 1 end,
    getClaimList = function() return claimList end,
    getRegionName = function() return "United States - Kansas" end,
    getDaysPerMonth = function() return 1 end,
    realDaysToMonths = function(days) return days / 30 end,
    salvagePenalty = 0.5, rebuiltPenalty = 0.3,
    RATING_MIN = -4, RATING_MAX = 3, RATING_CLAIM_STEPS = 2, CONTINUITY = {}, CONTINUITY_DEFAULT = 0.03,
    getRatingSteps = function() return 3, 5 end,
    getRatingPercent = function(_, level) return level < 0 and level * 3 or level * 5 end,
    getRenewalBonus = function() return renewal end,
    getMonthIndex = function() return 6 end,
    getRemainingDaysHours = function(_, months) local hours = months * 24 * 24 return math.floor(hours / 24), math.floor(hours % 24 + 0.5) end,
    requestAction = function(_, farmId, name, args) table.insert(requests, name .. " " .. args) end }
local salesOpen = true
TornadoInsuranceCrop = { STATUS_ACTIVE = "ACTIVE", SALES_PERIODS = { [12] = true, [1] = true }, WRITE_OFF_SHARE = 0.5, PLAN_KEYS = setmetatable({}, { __index = function(_, k) return "plan_" .. k end }),
    isAvailable = function() return true end, getDisabledReason = function() return nil end,
    getOfferedPlans = function() return { "RP", "YP" } end,
    getCoverageLevels = function(_, plan) return plan == "YP" and { 0.5, 0.6, 0.7 } or { 0.5, 0.75, 0.85 } end,
    isSalesOpen = function() return salesOpen end,
    getFarmQuote = function(_, _, plan, coverage) return { fields = 4, liability = 100000, uninsurable = 0,
        monthlyPremium = (plan == "RP" and 100 or 60) * coverage } end,
    getOpenClaimCount = function() return 1 end }
TornadoInsuranceEquipment = { STATUS_ACTIVE = "ACTIVE", DEDUCTIBLES = { 1000, 2500, 5000, 10000 },
    RATES = { [1000] = 0.015, [2500] = 0.012, [5000] = 0.010, [10000] = 0.008 }, TOTAL_LOSS_SHARE = 0.75,
    WAIT_DAYS = 7, ADJUSTER_DAYS = 3, DECISION_DAYS = 2, PAYOUT_DAYS = 1, CHOICE_DAYS = 7,
    getFarmQuote = function(_, _, deductible) return { vehicles = 8, value = 200000, monthlyPremium = 2000000 / deductible } end,
    getOpenClaimCount = function() return 0 end }
TornadoInsuranceLivestock = { STATUS_ACTIVE = "ACTIVE", RATE = 0.008, EXCESS_SHARE = 0.05, GOV_SHARE = 0.75,
    getFarmQuote = function() return { animals = 25, value = 13730, monthlyPremium = 9 } end,
    hasGovProgram = function() return true end, isHusbandryOn = function() return true end,
    getOpenClaimCount = function() return 0 end }

TornadoInsuranceDamage = { CAUSE_KEYS = { TORNADO = "tp_cause_tornado" } }
dofile("scripts/gui/TornadoMenuPage.lua")
dofile("scripts/gui/TornadoTable.lua")
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
    function e:getDescendantByName(n) return self.cells ~= nil and self.cells[n] or nil end
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
    "insPolCropCancel", "insPolEquipText", "insPolEquipCancel", "insPolLivestockText", "insPolLivestockCancel", "insPolClaims",
    "insNavClaims", "insClaims", "insClaimFilter", "insClaimTable", "insClaimScrollUp", "insClaimScrollDown", "insClaimInfo",
    "insClaimDetailHead", "insClaimDetailStatus", "insClaimDetailText", "insClaimAccept", "insClaimBuyBack", "insClaimNote",
    "insNavPayments", "insNavInfo", "insPayments", "insInfo", "insPayTable", "insPayScrollUp", "insPayScrollDown", "insPayInfo",
    "insPayTotals", "insPayMonthHead", "insPayMonthText", "insInfoText" }) do
    menu[id] = element(id)
end
for slot = 1, 10 do
    local row = element("insClaimRow" .. slot)
    row.cells = {}
    for _, name in ipairs({ "day", "type", "subject", "status", "amount" }) do
        row.cells[name] = element(name)
        table.insert(row.elements, row.cells[name])
    end
    menu["insClaimRow" .. slot] = row
    local payRow = element("insPayRow" .. slot)
    payRow.cells = {}
    for _, name in ipairs({ "month", "premiums", "payouts", "net" }) do
        payRow.cells[name] = element(name)
        table.insert(payRow.elements, payRow.cells[name])
    end
    menu["insPayRow" .. slot] = payRow
end
for slot = 1, 12 do
    for _, prefix in ipairs({ "insChartP", "insChartO" }) do
        local bar = element(prefix .. slot)
        bar.size = { 0.01, 0.2 }
        function bar:setSize(x, y) self.size = { x or self.size[1], y or self.size[2] } end
        menu[prefix .. slot] = bar
    end
    menu["insChartL" .. slot] = element("insChartL" .. slot)
end
menu.insChartEmpty, menu.insChartMax = element("insChartEmpty"), element("insChartMax")
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

-- Claims section
multiplayer, isServer, isManager = false, true, false
TornadoInsurance.isEnabled = true
click("insNavClaims")
check("Claims visible, others hidden", menu.insClaims.visible and not menu.insStart.visible and not menu.insPolicies.visible, true)
check("no claims: info says so", menu.insClaimInfo.text, "tp_ins_cl_none")
check("no claims: row 1 hidden", menu.insClaimRow1.visible, false)
check("no claims: no total-loss buttons", menu.insClaimAccept.visible, false)
claimList = {
    { kind = "EQUIP", id = 3, day = 12, status = "TOTAL", subject = "Fendt 942", values = { 230000, 200000, 2500, 0, 227500, 112500 },
        flag = true, remaining = 0.25 },
    { kind = "CROP", id = 7, day = 11, status = "APPROVED", subject = "14", info = "WHEAT", cause = "TORNADO", values = { 0.42, 8100 },
        remaining = 1 / 24 },
    { kind = "LIVESTOCK", id = 1, day = 10, status = "PAID", subject = "Cow barn", values = { 6, 9000, 10350, 6750, 3082 }, flag = true,
        remaining = -1 },
    { kind = "CROP", id = 2, day = 4, status = "DENIED", subject = "3", info = "BARLEY", cause = "TORNADO", values = { 0.05, 0 },
        remaining = -1 },
}
P:refresh()
check("4 claims: info", menu.insClaimInfo.text, "tp_msg_showing|1|4|4")
check("row 1 day", menu.insClaimRow1.cells.day.text, "tp_msg_day 12")
check("row 1 type", menu.insClaimRow1.cells.type.text, "tp_ins_cl_type_equip")
check("row 1 status", menu.insClaimRow1.cells.status.text, "tp_ins_cs_total")
check("row 1 amount = accept payout", menu.insClaimRow1.cells.amount.text, "$227500")
check("row 2 subject = field", menu.insClaimRow2.cells.subject.text, "tp_ins_cl_field|14")
check("row 3 livestock amount = state + policy", menu.insClaimRow3.cells.amount.text, "$9832")
check("row 4 declined: no amount", menu.insClaimRow4.cells.amount.text, "-")
check("row 5 hidden", menu.insClaimRow5.visible, false)
check("first claim selected", P.claimTable:getSelected().id, 3)
check("detail: burned + choice", has(menu.insClaimDetailText.text, "tp_ins_cl_equip_burned") and
    has(menu.insClaimDetailText.text, "tp_ins_cl_total_choice|$227500|$112500"), true)
check("detail: choose within (0.25 month x 24 days = 6 days)", has(menu.insClaimDetailText.text, "tp_ins_cl_next_total|6|0"), true)
check("total loss: both buttons shown + enabled", menu.insClaimAccept.visible and menu.insClaimBuyBack.visible
    and not menu.insClaimAccept.disabled and not menu.insClaimBuyBack.disabled, true)
requests = {}
local confirmsBefore = menu.confirms
click("insClaimBuyBack")
check("buy back asks first + sends claim id", menu.confirms == confirmsBefore + 1 and requests[1] == "equipBuyBack 3", true)
click("insClaimAccept")
check("accept sends claim id", requests[2], "equipAccept 3")
-- Select the crop claim
click("insClaimRow2")
check("row 2 selected", P.claimTable:getSelected().id, 7)
check("crop detail", has(menu.insClaimDetailText.text, "tp_ins_cl_crop_body|14|WHEAT|tp_cause_tornado|42"), true)
check("crop detail: payout + payment in 1 day", has(menu.insClaimDetailText.text, "tp_ins_cl_payout|$8100")
    and has(menu.insClaimDetailText.text, "tp_ins_cl_next_approved|1|0"), true)
check("not a total loss: buttons hidden", menu.insClaimAccept.visible or menu.insClaimBuyBack.visible, false)
click("insClaimRow3")
check("livestock detail", has(menu.insClaimDetailText.text, "tp_ins_cl_lv_body|6|Cow barn|$9000")
    and has(menu.insClaimDetailText.text, "tp_ins_cl_lv_gov|$6750") and has(menu.insClaimDetailText.text, "tp_ins_cl_lv_policy|$10350|$3082")
    and has(menu.insClaimDetailText.text, "tp_ins_cl_done"), true)
click("insClaimRow4")
check("declined detail", has(menu.insClaimDetailText.text, "tp_ins_cl_denied"), true)
-- Filters
choose("insClaimFilter", "OPEN")
check("open filter: 2 claims, 2 hidden", menu.insClaimInfo.text, "tp_msg_showing|1|2|2 tp_msg_hidden_short|2")
choose("insClaimFilter", "LIVESTOCK")
check("livestock filter: 1 claim", P.claimTable:getSelected().kind, "LIVESTOCK")
P:onShow()
check("new visit: filter back to All", P.state.claimFilter == "ALL" and #P.claimTable.entries == 4, true)
-- Totalled vehicles kept on this server: one choice only
TornadoInsurance.removeTotaled = false
click("insClaimRow1")
check("kept setting: keep text", has(menu.insClaimDetailText.text, "tp_ins_cl_total_keep|$112500"), true)
check("kept setting: buy back hidden", menu.insClaimAccept.visible and not menu.insClaimBuyBack.visible, true)
TornadoInsurance.removeTotaled = true
-- Non-manager in multiplayer: may look, not choose
multiplayer, isServer = true, false
P:refresh()
check("non-manager: accept disabled + note", menu.insClaimAccept.disabled and menu.insClaimNote.text == "tp_ins_note_manager", true)
multiplayer, isServer = false, true

-- Payments section
click("insNavPayments")
check("Payments visible, Claims hidden", menu.insPayments.visible and not menu.insClaims.visible, true)
check("no history: info", menu.insPayInfo.text, "tp_ins_pay_none")
TornadoInsurance.farms[1].premiumsTotal, TornadoInsurance.farms[1].payoutsTotal = 370, 8100
TornadoInsurance.farms[1].crop.status = "ACTIVE"
TornadoInsurance.farms[1].history = {
    { month = 5, premiums = 185, payouts = 0, premiumBy = { crop = 125, equipment = 59, livestock = 1 }, payoutBy = {} },
    { month = 6, premiums = 185, payouts = 8100, premiumBy = { crop = 125, equipment = 59, livestock = 1 }, payoutBy = { crop = 8100 } },
}
P:refresh()
check("2 months, newest first", menu.insPayRow1.cells.month.text, "month 6")
check("row 1 net = payouts - premiums", menu.insPayRow1.cells.net.text, "+$7915")
check("row 2 net negative", menu.insPayRow2.cells.net.text, "-$185")
check("row 3 hidden", menu.insPayRow3.visible, false)
check("totals: balance plus", has(menu.insPayTotals.text, "tp_ins_pay_balance_plus|$7730"), true)
check("next bill: active policies only (crop 75 + equipment 400)", has(menu.insPayTotals.text, "tp_ins_pay_next|$475|"), true)
check("next bill split by type", has(menu.insPayTotals.text, "tp_ins_cl_type_crop $75, tp_ins_cl_type_equip $400"), true)
check("pending policy noted", has(menu.insPayTotals.text, "tp_ins_pay_pending"), true)
check("selected month split", has(menu.insPayMonthText.text, "tp_ins_cl_type_crop $8100"), true)
click("insPayRow2")
check("row 2 selected: premiums split", has(menu.insPayMonthText.text, "tp_ins_cl_type_crop $125, tp_ins_cl_type_equip $59, tp_ins_cl_type_livestock $1"), true)
check("month head", menu.insPayMonthHead.text, "month 5")
-- Coverage info
click("insNavInfo")
check("Coverage info visible", menu.insInfo.visible and not menu.insPayments.visible, true)
local info = menu.insInfoText.text
check("info: region", has(info, "tp_ins_info_region|United States - Kansas"), true)
check("info: crop plans + levels 50 - 85", has(info, "tp_ins_info_crop|plan_RP, plan_YP|50|85|tp_ins_info_sales_open"), true)
check("info: equipment rates", has(info, "tp_ins_info_rate|$1000|1.5") and has(info, "tp_ins_info_rate|$10000|0.8"), true)
check("info: total loss 75", has(info, "|75"), true)
check("info: salvage / rebuilt", has(info, "tp_ins_info_total|50|30"), true)
check("info: livestock rate from the herd (9 x 12 / 13730)", has(info, "tp_ins_info_livestock|0.8|5"), true)
check("info: USDA", has(info, "tp_ins_info_livestock_gov|75"), true)
check("info: timing (stub: 24 days per month, 7 real days = 5 d 14 h)", has(info, "tp_ins_info_timing|1|tp_ins_info_duration|5|14"), true)
salesOpen = false
P:refresh()
check("info: sales closed", has(menu.insInfoText.text, "tp_ins_info_sales_closed"), true)
salesOpen = true

-- Phase 4a: chart (Payments: months 5 + 6 of the history above, current month 6)
click("insNavPayments")
check("chart: newest month on the right (payout = biggest = full)", menu.insChartO12.visible and math.abs(menu.insChartO12.size[2] - 0.2) < 1e-9, true)
check("chart: premium bar scaled 185 / 8100", math.abs(menu.insChartP12.size[2] - 0.2 * math.max(0.02, 185 / 8100)) < 1e-9, true)
check("chart: month 5 premium shown, no payout bar", menu.insChartP11.visible and not menu.insChartO11.visible, true)
check("chart: months without data hidden", menu.insChartP1.visible or menu.insChartO1.visible, false)
check("chart: labels", menu.insChartL12.text == "m6" and menu.insChartL7.text == "m1" and menu.insChartL6.text == "", true)
check("chart: scale label", menu.insChartMax.text, "$8100")
-- My policies: price factor
TornadoInsurance.farms[1].rating = { equipment = -2, crop = 1 }
renewal = 0.03
click("insNavPolicies")
check("equipment: no-claims discount line", has(menu.insPolEquipText.text, "tp_ins_pol_price_factor|tp_ins_rating_line_discount|6"), true)
check("crop: surcharge + renewal", has(menu.insPolCropText.text, "tp_ins_rating_line_surcharge|5, tp_ins_rating_line_renewal|3"), true)
check("livestock: nothing applies, no line", has(menu.insPolLivestockText.text, "tp_ins_pol_price_factor"), false)
-- Coverage info: write-off + no-claims rule
click("insNavInfo")
check("info: write-off rule", has(menu.insInfoText.text, "tp_ins_info_writeoff|50"), true)
check("info: no-claims rule (3 / 12 / 10 / 15 / 3)", has(menu.insInfoText.text, "tp_ins_info_noclaims|3|12|10|15|3"), true)
-- Claims: crop write-off offer
table.insert(claimList, 1, { kind = "CROP", id = 9, day = 13, status = "WRITEOFF", subject = "5", info = "WHEAT", cause = "TORNADO",
    values = { 0.55, 9450, 23625 }, remaining = 0.2 })
click("insNavClaims")
P.claimTable:reset(claimList)
P:refresh()
check("write-off row amount = write-off payout", menu.insClaimRow1.cells.amount.text, "$23625")
check("write-off status text", menu.insClaimRow1.cells.status.text, "tp_ins_cs_writeoff")
check("write-off detail", has(menu.insClaimDetailText.text, "tp_ins_cl_writeoff_choice|$23625|5|$9450")
    and has(menu.insClaimDetailText.text, "tp_ins_cl_next_writeoff"), true)
check("buttons: write off / keep", menu.insClaimAccept.text == "tp_btn_ins_write_off" and menu.insClaimBuyBack.text == "tp_btn_ins_keep_crop"
    and menu.insClaimAccept.visible and menu.insClaimBuyBack.visible, true)
requests = {}
click("insClaimAccept")
click("insClaimBuyBack")
check("write-off requests", requests[1] == "cropWriteOff 9" and requests[2] == "cropKeep 9", true)
check("write-off confirm text", menu.controls[menu.insClaimAccept].def.confirm, "tp_confirm_crop_writeoff")
click("insClaimRow2")
check("equipment total loss: buttons back to accept / buy back", menu.insClaimAccept.text == "tp_btn_ins_accept_total"
    and menu.controls[menu.insClaimAccept].def.confirm == "tp_confirm_equip_accept", true)

-- Insurance off
TornadoInsurance.isEnabled = false
P:refresh()
check("insurance off: note", menu.insStartNote.text, "tp_ins_note_off")
check("insurance off: Confirm disabled", menu.insConfirm.disabled, true)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
