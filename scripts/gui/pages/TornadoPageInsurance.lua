---@class TornadoPageInsurance
---@version 1.3 (phase 4a: chart, no-claims / renewal, crop write-off)
---@description Insurance tab (full width, decided 2026-10-19): side buttons on the left choose a section.
---   Start here  - choose crop (plan + coverage), equipment (deductible) and livestock cover -> Get quote shows each
---                 line (what is insured, its value, the monthly price, old -> new for a change) and the total ->
---                 Confirm & start sends every chosen policy / change at once. Confirm only works for a fresh quote
---                 of exactly what is chosen.
---   My policies - each policy (status, terms, monthly price, open claims) with Cancel (asks first).
---   Claims      - every claim of the farm (TornadoInsurance:getClaimList) as a table with a type / open filter;
---                 the selected claim in full on the right (amounts, what happens next and when). A total loss
---                 waiting for the farm's choice gets Accept / Buy back here (asks first).
---   Payments    - the farm's monthly history (premiums, payouts, net; 24 months) as a table, totals and the next
---                 bill on the right, the selected month split by policy type.
---   Coverage info - how the insurance works here: region, what each policy covers and costs, timing, rules.
--- Buying, cancelling and choosing are checked on the server (farm manager / admin, TornadoInsurance:canManage);
--- here the buttons are greyed out for players who may not, and everybody may look. Nothing here is a setting,
--- so the panel is never marked dirty.

local Page = TornadoMenuPage

local CLAIM_ROWS = 10
local SUBJECT_CHARS = 28
local OPEN_STATUS = { RECEIVED = true, INSPECTED = true, APPROVED = true, TOTAL = true, WRITEOFF = true }
local CHART_MONTHS = 12
local CLAIM_FILTERS = { "ALL", "OPEN", "CROP", "EQUIP", "LIVESTOCK" }
local CLAIM_FILTER_KEYS = { ALL = "tp_ins_cl_f_all", OPEN = "tp_ins_cl_f_open", CROP = "tp_ins_cl_type_crop",
    EQUIP = "tp_ins_cl_type_equip", LIVESTOCK = "tp_ins_cl_type_livestock" }

local PAY_ROWS = 10
local PART_KEYS = { crop = "tp_ins_cl_type_crop", equipment = "tp_ins_cl_type_equip", livestock = "tp_ins_cl_type_livestock",
    state = "tp_ins_pay_state" }
local PART_ORDER = { "crop", "equipment", "livestock", "state" }

local state = {
    section = "start",       -- "start" | "policies" | "claims" | "payments" | "info"
    claimFilter = "ALL",     -- one of CLAIM_FILTERS
    crop = nil,              -- chosen crop plan id or "none" (nil = take the current policy on the first draw)
    coverage = nil,          -- chosen crop coverage (0.5 - 0.85)
    equip = nil,             -- chosen deductible or 0
    livestock = nil,         -- "insured" | "none"
    quoted = nil,            -- signature of the choices the shown quote is for
    quoteText = nil,
}

local claimTable = TornadoTable.new(CLAIM_ROWS, function(claim) return claim.kind .. "#" .. tostring(claim.id) end)
local payTable = TornadoTable.new(PAY_ROWS, function(month) return month.month end)

local function hasInsurance()
    return TornadoInsurance ~= nil and TornadoInsurance.farms ~= nil
end

local function isOn()
    return hasInsurance() and TornadoInsurance.isEnabled
end

local function getFarmId()
    local farmId = g_currentMission ~= nil and g_currentMission.getFarmId ~= nil and g_currentMission:getFarmId() or 0
    return farmId or 0
end

local function getFarm()
    return hasInsurance() and TornadoInsurance.farms[getFarmId()] or nil
end

local function cropAvailable()
    return TornadoInsuranceCrop ~= nil and TornadoInsuranceCrop:isAvailable()
end

--- May this player buy / change / cancel the farm's policies? (server checks again)
local function canManage()
    if g_currentMission == nil or TornadoInsurance == nil then
        return false
    end
    if TornadoSync == nil or not TornadoSync:isMultiplayer() or g_currentMission:getIsServer() then
        return true
    end
    if g_currentMission.isMasterUser == true then
        return true
    end
    if TornadoInsurance.adminOnly then
        return false
    end
    local farm = g_farmManager ~= nil and g_farmManager:getFarmById(getFarmId()) or nil
    local userId = g_currentMission.playerUserId
    return farm ~= nil and userId ~= nil and farm.isUserFarmManager ~= nil and farm:isUserFarmManager(userId)
end

local function percent(value)
    return math.floor((value or 0) * 100 + 0.5)
end

-- =========================================================================
-- CHOICES (start from the farm's current policies)
-- =========================================================================

local function initChoices()
    local farm = getFarm()
    if state.crop == nil then
        state.crop = farm ~= nil and farm.crop ~= nil and farm.crop.plan or "none"
        state.coverage = farm ~= nil and farm.crop ~= nil and farm.crop.coverage or 0.75
    end
    if state.equip == nil then
        state.equip = farm ~= nil and farm.equipment ~= nil and farm.equipment.deductible or 0
    end
    if state.livestock == nil then
        state.livestock = farm ~= nil and farm.livestock ~= nil and "insured" or "none"
    end
end

local function signature()
    return string.format("%s|%.2f|%s|%s", tostring(state.crop), state.coverage or 0, tostring(state.equip), tostring(state.livestock))
end

local function invalidateQuote()
    state.quoted = nil
    state.quoteText = nil
end

-- =========================================================================
-- QUOTE
-- =========================================================================

--- One quote line per chosen type + the total. Returns text, anything to confirm?
local function buildQuote()
    initChoices()
    local farmId = getFarmId()
    local farm = getFarm()
    local lines, total, changes = {}, 0, 0
    local function money(v) return TornadoText.money(v or 0) end

    -- Crop
    if state.crop ~= nil and state.crop ~= "none" and cropAvailable() then
        local current = farm ~= nil and farm.crop or nil
        local quote = TornadoInsuranceCrop:getFarmQuote(farmId, state.crop, state.coverage, current)
        local planText = TornadoText.get(TornadoInsuranceCrop.PLAN_KEYS[state.crop] or state.crop)
        local line = TornadoText.format("tp_ins_q_crop", planText, percent(state.coverage), quote.fields, money(quote.liability),
            money(quote.monthlyPremium))
        if current ~= nil and current.plan == state.crop and math.abs((current.coverage or 0) - state.coverage) < 0.001 then
            line = line .. " " .. TornadoText.get("tp_ins_q_unchanged")
        else
            if current ~= nil then
                local old = TornadoInsuranceCrop:getFarmQuote(farmId, current.plan, current.coverage, current)
                line = line .. " " .. TornadoText.format("tp_ins_q_change", money(old.monthlyPremium), money(quote.monthlyPremium))
            end
            if not TornadoInsuranceCrop:isSalesOpen() then
                line = line .. " " .. TornadoText.get("tp_ins_q_sales_closed")
            else
                changes = changes + 1
            end
        end
        if quote.uninsurable > 0 then
            line = line .. " " .. TornadoText.format("tp_ins_q_uninsurable", quote.uninsurable)
        end
        total = total + quote.monthlyPremium
        table.insert(lines, line)
    elseif farm ~= nil and farm.crop ~= nil then
        table.insert(lines, TornadoText.get("tp_ins_q_crop_kept"))
    end

    -- Equipment
    if TornadoInsuranceEquipment ~= nil and (state.equip or 0) > 0 then
        local current = farm ~= nil and farm.equipment or nil
        local quote = TornadoInsuranceEquipment:getFarmQuote(farmId, state.equip)
        local scale = TornadoInsurance:getCostScale() or 1
        local line = TornadoText.format("tp_ins_q_equip", money(state.equip * scale), quote.vehicles, money(quote.value),
            money(quote.monthlyPremium))
        if current ~= nil and current.deductible == state.equip then
            line = line .. " " .. TornadoText.get("tp_ins_q_unchanged")
        else
            if current ~= nil then
                local old = TornadoInsuranceEquipment:getFarmQuote(farmId, current.deductible)
                line = line .. " " .. TornadoText.format("tp_ins_q_change", money(old.monthlyPremium), money(quote.monthlyPremium))
            end
            changes = changes + 1
        end
        total = total + quote.monthlyPremium
        table.insert(lines, line)
    elseif farm ~= nil and farm.equipment ~= nil then
        table.insert(lines, TornadoText.get("tp_ins_q_equip_kept"))
    end

    -- Livestock
    if TornadoInsuranceLivestock ~= nil and state.livestock == "insured" then
        local quote = TornadoInsuranceLivestock:getFarmQuote(farmId)
        local line = TornadoText.format("tp_ins_q_livestock", quote.animals, money(quote.value), money(quote.monthlyPremium))
        if farm ~= nil and farm.livestock ~= nil then
            line = line .. " " .. TornadoText.get("tp_ins_q_unchanged")
        else
            changes = changes + 1
        end
        if TornadoInsuranceLivestock:hasGovProgram() then
            line = line .. " " .. TornadoText.get("tp_ins_q_livestock_gov")
        end
        if not TornadoInsuranceLivestock.isHusbandryOn() then
            line = line .. " " .. TornadoText.get("tp_ins_lv_husbandry_off")
        end
        total = total + quote.monthlyPremium
        table.insert(lines, line)
    elseif farm ~= nil and farm.livestock ~= nil then
        table.insert(lines, TornadoText.get("tp_ins_q_livestock_kept"))
    end

    if #lines == 0 then
        return TornadoText.get("tp_ins_q_nothing"), false
    end
    table.insert(lines, "")
    table.insert(lines, TornadoText.format("tp_ins_q_total", money(total)))
    if changes > 0 then
        table.insert(lines, TornadoText.get("tp_ins_q_wait"))
    end
    table.insert(lines, TornadoText.get("tp_ins_grows"))
    return table.concat(lines, "\n"), changes > 0
end

--- Sends every chosen new policy / change (the server checks the permission and the rules again).
local function confirm()
    local farmId = getFarmId()
    local farm = getFarm()
    local sent = 0
    if state.crop ~= nil and state.crop ~= "none" and cropAvailable() then
        local current = farm ~= nil and farm.crop or nil
        if current == nil or current.plan ~= state.crop or math.abs((current.coverage or 0) - state.coverage) >= 0.001 then
            TornadoInsurance:requestAction(farmId, "cropBuy", string.format("%s %.2f", state.crop, state.coverage))
            sent = sent + 1
        end
    end
    if TornadoInsuranceEquipment ~= nil and (state.equip or 0) > 0 then
        if farm == nil or farm.equipment == nil or farm.equipment.deductible ~= state.equip then
            TornadoInsurance:requestAction(farmId, "equipBuy", tostring(state.equip))
            sent = sent + 1
        end
    end
    if TornadoInsuranceLivestock ~= nil and state.livestock == "insured" and (farm == nil or farm.livestock == nil) then
        TornadoInsurance:requestAction(farmId, "livestockBuy", "")
        sent = sent + 1
    end
    invalidateQuote()
    return sent > 0 and TornadoText.format("tp_ins_confirm_sent", sent) or TornadoText.get("tp_ins_q_nothing_new")
end

-- =========================================================================
-- MY POLICIES
-- =========================================================================

local function statusText(policy, activeStatus)
    return TornadoText.get(policy.status == activeStatus and "tp_ins_status_active" or "tp_ins_status_pending")
end

--- "No-claims discount -6 percent, renewal bonus -3 percent" for one policy type ("" when nothing applies).
local function ratingText(kind)
    if TornadoInsurance.getRatingPercent == nil then
        return ""
    end
    local farm = getFarm()
    local level = farm ~= nil and farm.rating ~= nil and farm.rating[kind] or 0
    local items = {}
    local change = TornadoInsurance:getRatingPercent(level)
    if change < 0 then
        table.insert(items, TornadoText.format("tp_ins_rating_line_discount", -change))
    elseif change > 0 then
        table.insert(items, TornadoText.format("tp_ins_rating_line_surcharge", change))
    end
    local renewal = kind == "crop" and TornadoInsurance:getRenewalBonus(getFarmId()) or 0
    if renewal > 0 then
        table.insert(items, TornadoText.format("tp_ins_rating_line_renewal", math.floor(renewal * 100 + 0.5)))
    end
    if #items == 0 then
        return ""
    end
    return "\n" .. TornadoText.format("tp_ins_pol_price_factor", table.concat(items, ", "))
end

local function policyTexts()
    local farmId = getFarmId()
    local farm = getFarm()
    local texts = {}
    local crop = farm ~= nil and farm.crop or nil
    if crop ~= nil and TornadoInsuranceCrop ~= nil then
        local quote = TornadoInsuranceCrop:getFarmQuote(farmId, crop.plan, crop.coverage, crop)
        texts.crop = TornadoText.format("tp_ins_pol_crop", TornadoText.get(TornadoInsuranceCrop.PLAN_KEYS[crop.plan] or crop.plan),
            percent(crop.coverage), statusText(crop, TornadoInsuranceCrop.STATUS_ACTIVE), quote.fields, TornadoText.money(quote.liability),
            TornadoText.money(quote.monthlyPremium)) .. ratingText("crop")
    else
        texts.crop = TornadoText.get("tp_ins_pol_crop_none")
    end
    local equip = farm ~= nil and farm.equipment or nil
    if equip ~= nil and TornadoInsuranceEquipment ~= nil then
        local quote = TornadoInsuranceEquipment:getFarmQuote(farmId, equip.deductible)
        texts.equip = TornadoText.format("tp_ins_pol_equip", TornadoText.money(equip.deductible * (TornadoInsurance:getCostScale() or 1)),
            statusText(equip, TornadoInsuranceEquipment.STATUS_ACTIVE), quote.vehicles, TornadoText.money(quote.value),
            TornadoText.money(quote.monthlyPremium)) .. ratingText("equipment")
    else
        texts.equip = TornadoText.get("tp_ins_pol_equip_none")
    end
    local livestock = farm ~= nil and farm.livestock or nil
    if livestock ~= nil and TornadoInsuranceLivestock ~= nil then
        local quote = TornadoInsuranceLivestock:getFarmQuote(farmId)
        texts.livestock = TornadoText.format("tp_ins_pol_livestock", statusText(livestock, TornadoInsuranceLivestock.STATUS_ACTIVE),
            quote.animals, TornadoText.money(quote.value), TornadoText.money(quote.monthlyPremium)) .. ratingText("livestock")
    else
        texts.livestock = TornadoText.get("tp_ins_pol_livestock_none")
    end
    texts.claims = TornadoText.format("tp_ins_pol_claims", farm ~= nil and (farm.openClaims or 0) or 0)
    if farm ~= nil and g_currentMission ~= nil and g_currentMission:getIsServer() then
        local open = 0
        for _, module in ipairs({ TornadoInsuranceCrop, TornadoInsuranceEquipment, TornadoInsuranceLivestock }) do
            if module ~= nil and module.getOpenClaimCount ~= nil then
                open = open + module:getOpenClaimCount(farm)
            end
        end
        texts.claims = TornadoText.format("tp_ins_pol_claims", open)
    end
    return texts
end

-- =========================================================================
-- CLAIMS
-- =========================================================================

local function getClaims()
    local claims = {}
    local all = hasInsurance() and TornadoInsurance.getClaimList ~= nil and TornadoInsurance:getClaimList(getFarmId()) or {}
    for _, claim in ipairs(all) do
        local filter = state.claimFilter
        if filter == "ALL" or (filter == "OPEN" and OPEN_STATUS[claim.status]) or filter == claim.kind then
            table.insert(claims, claim)
        end
    end
    return claims, #all
end

local function claimValue(claim, index)
    return claim.values ~= nil and claim.values[index] or 0
end

local function claimTypeText(claim)
    return TornadoText.get(CLAIM_FILTER_KEYS[claim.kind] or "tp_ins_cl_type_crop")
end

local function claimSubject(claim)
    if claim.kind == "CROP" then
        return TornadoText.format("tp_ins_cl_field", claim.subject or "?")
    end
    return claim.subject or "?"
end

local function claimStatusText(claim)
    return TornadoText.get("tp_ins_cs_" .. string.lower(claim.status or ""))
end

--- What the claim paid / pays (nil = not known yet).
local function claimAmount(claim)
    if claim.kind == "CROP" then
        if claim.status == "WRITEOFF" then
            return claimValue(claim, 3)
        end
        return claimValue(claim, 2) > 0 and claimValue(claim, 2) or nil
    elseif claim.kind == "EQUIP" then
        if claim.status == "TOTAL" then
            return claimValue(claim, 5)
        end
        return claimValue(claim, 4) > 0 and claimValue(claim, 4) or nil
    end
    local total = claimValue(claim, 4) + claimValue(claim, 5)
    return total > 0 and total or nil
end

local function dayText(day, withYear)
    return TornadoText.date(day, withYear)
end

local function shorten(text, length)
    text = text or ""
    if string.len(text) <= length then
        return text
    end
    return string.sub(text, 1, length - 3) .. "..."
end

local function cropTitle(name)
    local fillType = g_fillTypeManager ~= nil and g_fillTypeManager.getFillTypeByName ~= nil and g_fillTypeManager:getFillTypeByName(name) or nil
    return fillType ~= nil and fillType.title or (name or "?")
end

--- The selected claim in full: amounts, then what happens next and when.
local function claimDetail(claim)
    local money = TornadoText.money
    local lines = {}
    if claim.kind == "CROP" then
        local causeKey = TornadoInsuranceDamage ~= nil and TornadoInsuranceDamage.CAUSE_KEYS ~= nil and TornadoInsuranceDamage.CAUSE_KEYS[claim.cause]
            or claim.cause
        table.insert(lines, TornadoText.format("tp_ins_cl_crop_body", claim.subject or "?", cropTitle(claim.info),
            TornadoText.get(causeKey or ""), math.max(1, percent(claimValue(claim, 1)))))
        if claim.status == "WRITEOFF" then
            table.insert(lines, TornadoText.format("tp_ins_cl_writeoff_choice", money(claimValue(claim, 3)), claim.subject or "?",
                money(claimValue(claim, 2))))
        elseif claimValue(claim, 2) > 0 then
            table.insert(lines, TornadoText.format("tp_ins_cl_payout", money(claimValue(claim, 2))))
        end
    elseif claim.kind == "EQUIP" then
        table.insert(lines, TornadoText.format("tp_ins_cl_equip_body", money(claimValue(claim, 1)), money(claimValue(claim, 2)),
            money(claimValue(claim, 3))))
        if claim.flag then
            table.insert(lines, TornadoText.get("tp_ins_cl_equip_burned"))
        end
        if claim.status == "TOTAL" then
            if TornadoInsurance.removeTotaled == false then
                table.insert(lines, TornadoText.format("tp_ins_cl_total_keep", money(claimValue(claim, 6))))
            else
                table.insert(lines, TornadoText.format("tp_ins_cl_total_choice", money(claimValue(claim, 5)), money(claimValue(claim, 6))))
            end
        elseif claimValue(claim, 4) > 0 then
            table.insert(lines, TornadoText.format("tp_ins_cl_payout", money(claimValue(claim, 4))))
        end
    else
        table.insert(lines, TornadoText.format("tp_ins_cl_lv_body", math.floor(claimValue(claim, 1) + 0.5), claim.subject or "?",
            money(claimValue(claim, 2))))
        if claim.flag then
            table.insert(lines, TornadoText.format("tp_ins_cl_lv_gov", money(claimValue(claim, 4))))
        end
        if claimValue(claim, 3) > 0 then
            table.insert(lines, TornadoText.format("tp_ins_cl_lv_policy", money(claimValue(claim, 3)), money(claimValue(claim, 5))))
        end
    end
    table.insert(lines, "")
    local status = claim.status or ""
    if OPEN_STATUS[status] and (claim.remaining or -1) >= 0 then
        local days, hours = TornadoInsurance:getRemainingDaysHours(claim.remaining)
        table.insert(lines, TornadoText.format("tp_ins_cl_next_" .. string.lower(status), days, hours))
    elseif status == "DENIED" then
        table.insert(lines, TornadoText.get("tp_ins_cl_denied"))
    elseif status == "PAID" or status == "SETTLED" or status == "BOUGHT_BACK" or status == "WRITTEN_OFF" then
        table.insert(lines, TornadoText.get("tp_ins_cl_done"))
    end
    return table.concat(lines, "\n")
end

-- =========================================================================
-- PAYMENTS
-- =========================================================================

--- The farm's months, newest first.
local function getMonths()
    local farm = getFarm()
    local months = {}
    for _, month in ipairs(farm ~= nil and farm.history or {}) do
        table.insert(months, month)
    end
    table.sort(months, function(a, b) return (a.month or 0) > (b.month or 0) end)
    return months
end

--- "crop $125, equipment $59" (policy types in a fixed order, others last).
local function partsText(parts)
    local items, seen = {}, {}
    for _, name in ipairs(PART_ORDER) do
        if (parts ~= nil and parts[name] or 0) > 0 then
            table.insert(items, string.format("%s %s", TornadoText.get(PART_KEYS[name]), TornadoText.money(parts[name])))
            seen[name] = true
        end
    end
    local other = 0
    for name, amount in pairs(parts or {}) do
        if not seen[name] then
            other = other + (amount or 0)
        end
    end
    if other > 0 then
        table.insert(items, string.format("%s %s", TornadoText.get("tp_ins_pay_other"), TornadoText.money(other)))
    end
    return table.concat(items, ", ")
end

--- What the next month change bills: active policies only (pending ones start later). Returns total, parts.
local function nextBill()
    local farmId = getFarmId()
    local farm = getFarm()
    local parts, total = {}, 0
    if farm == nil then
        return 0, parts
    end
    local crop = farm.crop
    if crop ~= nil and TornadoInsuranceCrop ~= nil and crop.status == TornadoInsuranceCrop.STATUS_ACTIVE then
        parts.crop = TornadoInsuranceCrop:getFarmQuote(farmId, crop.plan, crop.coverage, crop).monthlyPremium
    end
    local equip = farm.equipment
    if equip ~= nil and TornadoInsuranceEquipment ~= nil and equip.status == TornadoInsuranceEquipment.STATUS_ACTIVE then
        parts.equipment = TornadoInsuranceEquipment:getFarmQuote(farmId, equip.deductible).monthlyPremium
    end
    local livestock = farm.livestock
    if livestock ~= nil and TornadoInsuranceLivestock ~= nil and livestock.status == TornadoInsuranceLivestock.STATUS_ACTIVE then
        parts.livestock = TornadoInsuranceLivestock:getFarmQuote(farmId).monthlyPremium
    end
    for _, amount in pairs(parts) do
        total = total + amount
    end
    return total, parts
end

local function totalsText()
    local farm = getFarm()
    local premiums = farm ~= nil and farm.premiumsTotal or 0
    local payouts = farm ~= nil and farm.payoutsTotal or 0
    local lines = {
        TornadoText.format("tp_ins_pay_premiums_total", TornadoText.money(premiums)),
        TornadoText.format("tp_ins_pay_payouts_total", TornadoText.money(payouts)),
        TornadoText.format(payouts >= premiums and "tp_ins_pay_balance_plus" or "tp_ins_pay_balance_minus",
            TornadoText.money(math.abs(payouts - premiums))),
        "",
    }
    local total, parts = nextBill()
    if total > 0 then
        table.insert(lines, TornadoText.format("tp_ins_pay_next", TornadoText.money(total), partsText(parts)))
    else
        table.insert(lines, TornadoText.get("tp_ins_pay_next_none"))
    end
    local pending = farm ~= nil and ((farm.crop ~= nil and farm.crop.status ~= "ACTIVE") or (farm.equipment ~= nil and farm.equipment.status ~= "ACTIVE")
        or (farm.livestock ~= nil and farm.livestock.status ~= "ACTIVE"))
    if pending then
        table.insert(lines, TornadoText.get("tp_ins_pay_pending"))
    end
    return table.concat(lines, "\n")
end

local function monthText(month)
    local lines = {}
    table.insert(lines, TornadoText.format("tp_ins_pay_month_premiums", TornadoText.money(month.premiums or 0)))
    local premiumParts = partsText(month.premiumBy)
    if premiumParts ~= "" then
        table.insert(lines, "   " .. premiumParts)
    end
    table.insert(lines, TornadoText.format("tp_ins_pay_month_payouts", TornadoText.money(month.payouts or 0)))
    local payoutParts = partsText(month.payoutBy)
    if payoutParts ~= "" then
        table.insert(lines, "   " .. payoutParts)
    end
    return table.concat(lines, "\n")
end

local function signedMoney(amount)
    if amount > 0 then
        return "+" .. TornadoText.money(amount)
    elseif amount < 0 then
        return "-" .. TornadoText.money(-amount)
    end
    return TornadoText.money(0)
end

-- =========================================================================
-- COVERAGE INFO
-- =========================================================================

local function duration(realDays)
    local days, hours = TornadoInsurance:getRemainingDaysHours(TornadoInsurance.realDaysToMonths(realDays))
    return TornadoText.format("tp_ins_info_duration", days, hours)
end

local function oneDecimal(value)
    return string.format("%.1f", value)
end

--- How the insurance works on this map, from the region data and the rules the modules use.
local function coverageText()
    local lines = {}
    if not TornadoInsurance.isEnabled then
        table.insert(lines, TornadoText.get("tp_ins_note_off"))
        table.insert(lines, "")
    end
    local regionName = TornadoInsurance.getRegionName ~= nil and TornadoInsurance:getRegionName() or nil
    table.insert(lines, TornadoText.format("tp_ins_info_region", regionName or "?"))
    table.insert(lines, "")

    -- Crop
    if cropAvailable() then
        local plans, low, high = {}, nil, nil
        for _, planId in ipairs(TornadoInsuranceCrop:getOfferedPlans()) do
            table.insert(plans, TornadoText.get(TornadoInsuranceCrop.PLAN_KEYS[planId] or planId))
            for _, level in ipairs(TornadoInsuranceCrop:getCoverageLevels(planId)) do
                low = (low == nil or level < low) and level or low
                high = (high == nil or level > high) and level or high
            end
        end
        local sales
        if TornadoInsuranceCrop:isSalesOpen() then
            sales = TornadoText.get("tp_ins_info_sales_open")
        else
            local names = {}
            local formatPeriod = g_i18n ~= nil and g_i18n.formatPeriod ~= nil
            for _, period in ipairs({ 12, 1 }) do
                if TornadoInsuranceCrop.SALES_PERIODS[period] then
                    table.insert(names, formatPeriod and g_i18n:formatPeriod(period, false) or tostring(period))
                end
            end
            sales = TornadoText.format("tp_ins_info_sales_closed", table.concat(names, " / "))
        end
        table.insert(lines, TornadoText.format("tp_ins_info_crop", table.concat(plans, ", "), percent(low or 0), percent(high or 0), sales))
    elseif TornadoInsuranceCrop ~= nil then
        local reason = TornadoInsuranceCrop:getDisabledReason()
        table.insert(lines, TornadoText.get(reason ~= nil and "tp_ins_note_crop_off" or "tp_ins_note_crop_none"))
    end

    -- Equipment
    if TornadoInsuranceEquipment ~= nil then
        local rates = {}
        local scale = TornadoInsurance:getCostScale() or 1
        for _, deductible in ipairs(TornadoInsuranceEquipment.DEDUCTIBLES or {}) do
            local rate = TornadoInsuranceEquipment.RATES ~= nil and TornadoInsuranceEquipment.RATES[deductible] or 0
            table.insert(rates, TornadoText.format("tp_ins_info_rate", TornadoText.money(deductible * scale), oneDecimal(rate * 100)))
        end
        local valueText = TornadoText.get(TornadoInsurance.replacementValue and "tp_ins_info_value_replacement" or "tp_ins_info_value_sell")
        table.insert(lines, TornadoText.format("tp_ins_info_equip", valueText, table.concat(rates, ", "),
            percent(TornadoInsuranceEquipment.TOTAL_LOSS_SHARE)))
        if TornadoInsurance.removeTotaled == false then
            table.insert(lines, TornadoText.format("tp_ins_info_total_keep", percent(TornadoInsurance.salvagePenalty),
                percent(TornadoInsurance.rebuiltPenalty)))
        else
            table.insert(lines, TornadoText.format("tp_ins_info_total", percent(TornadoInsurance.salvagePenalty),
                percent(TornadoInsurance.rebuiltPenalty)))
        end
    end

    -- Livestock
    if TornadoInsuranceLivestock ~= nil then
        local quote = TornadoInsuranceLivestock:getFarmQuote(getFarmId())
        local scale = TornadoInsurance:getCostScale() or 1
        local rate = TornadoInsuranceLivestock.RATE
        if quote.value > 0 and scale > 0 then
            rate = quote.monthlyPremium * 12 / (quote.value * scale)
        end
        table.insert(lines, TornadoText.format("tp_ins_info_livestock", oneDecimal(rate * 100), percent(TornadoInsuranceLivestock.EXCESS_SHARE)))
        if TornadoInsuranceLivestock:hasGovProgram() then
            table.insert(lines, TornadoText.format("tp_ins_info_livestock_gov", percent(TornadoInsuranceLivestock.GOV_SHARE)))
        end
    end
    if cropAvailable() and TornadoInsuranceCrop.WRITE_OFF_SHARE ~= nil then
        table.insert(lines, TornadoText.format("tp_ins_info_writeoff", percent(TornadoInsuranceCrop.WRITE_OFF_SHARE)))
    end
    if TornadoInsurance.getRatingSteps ~= nil then
        local discount, surcharge = TornadoInsurance:getRatingSteps()
        if discount > 0 or surcharge > 0 then
            table.insert(lines, TornadoText.format("tp_ins_info_noclaims", discount, -TornadoInsurance:getRatingPercent(TornadoInsurance.RATING_MIN),
                surcharge * TornadoInsurance.RATING_CLAIM_STEPS, TornadoInsurance:getRatingPercent(TornadoInsurance.RATING_MAX),
                math.floor(((TornadoInsurance.CONTINUITY ~= nil and TornadoInsurance.resolveRegion ~= nil
                    and TornadoInsurance.CONTINUITY[TornadoInsurance:resolveRegion().country or ""]) or TornadoInsurance.CONTINUITY_DEFAULT or 0) * 100 + 0.5)))
        else
            table.insert(lines, TornadoText.get("tp_ins_info_noclaims_off"))
        end
    end
    table.insert(lines, "")

    -- Timing (the same durations for every policy type)
    local E = TornadoInsuranceEquipment or {}
    table.insert(lines, TornadoText.format("tp_ins_info_timing", TornadoInsurance:getDaysPerMonth(), duration(E.WAIT_DAYS or 7),
        duration(E.ADJUSTER_DAYS or 3), duration(E.DECISION_DAYS or 2), duration(E.PAYOUT_DAYS or 1), duration(E.CHOICE_DAYS or 7)))
    table.insert(lines, TornadoText.get("tp_ins_info_billing"))
    table.insert(lines, TornadoText.get("tp_ins_grows"))
    table.insert(lines, TornadoText.get(TornadoInsurance.adminOnly and "tp_ins_note_admin" or "tp_ins_info_manage"))
    return table.concat(lines, "\n")
end

--- The selected claim when it waits for the farm's choice: an equipment total loss or a crop write-off offer.
local function getSelectedChoice()
    local claim = claimTable:getSelected()
    if claim ~= nil and ((claim.kind == "EQUIP" and claim.status == "TOTAL") or (claim.kind == "CROP" and claim.status == "WRITEOFF")) then
        return claim
    end
    return nil
end

-- =========================================================================
-- CONTROL DEFINITIONS
-- =========================================================================

local function action(id, run, extra)
    local def = { id = id, kind = Page.KIND_ACTION, requires = hasInsurance, localOnly = true, keepClean = true, run = run }
    for k, v in pairs(extra or {}) do def[k] = v end
    return def
end

local function choice(id, options, get, set, requires)
    return { id = id, kind = Page.KIND_CHOICE, requires = requires or isOn, localOnly = true, keepClean = true,
        options = options, get = get, set = function(value) set(value) invalidateQuote() return nil end }
end

local defs = {
    action("insNavStart", function() state.section = "start" return nil end),
    action("insNavPolicies", function() state.section = "policies" return nil end),
    action("insNavClaims", function() state.section = "claims" return nil end),
    action("insNavPayments", function() state.section = "payments" return nil end),
    action("insNavInfo", function() state.section = "info" return nil end),

    choice("insCrop", function()
        local options = { { value = "none", text = TornadoText.get("tp_ins_not_included") } }
        if cropAvailable() then
            for _, planId in ipairs(TornadoInsuranceCrop:getOfferedPlans()) do
                options[#options + 1] = { value = planId, text = TornadoText.get(TornadoInsuranceCrop.PLAN_KEYS[planId] or planId) }
            end
        end
        return options
    end, function() initChoices() return state.crop end, function(value)
        state.crop = value
        -- Keep a coverage level the new plan offers (the closest one).
        local levels = value ~= "none" and cropAvailable() and TornadoInsuranceCrop:getCoverageLevels(value) or {}
        local best = nil
        for _, level in ipairs(levels) do
            if best == nil or math.abs(level - (state.coverage or 0.75)) < math.abs(best - (state.coverage or 0.75)) then
                best = level
            end
        end
        state.coverage = best or state.coverage
    end),
    choice("insCropCoverage", function()
        local options = {}
        local planId = state.crop ~= nil and state.crop ~= "none" and state.crop or nil
        for _, coverage in ipairs(planId ~= nil and cropAvailable() and TornadoInsuranceCrop:getCoverageLevels(planId) or {}) do
            options[#options + 1] = { value = coverage, text = string.format("%d %%", percent(coverage)) }
        end
        if #options == 0 then
            options[1] = { value = state.coverage or 0.75, text = "-" }
        end
        return options
    end, function() initChoices() return state.coverage end, function(value) state.coverage = value end),
    choice("insEquip", function()
        local options = { { value = 0, text = TornadoText.get("tp_ins_not_included") } }
        local scale = TornadoInsurance:getCostScale() or 1
        for _, deductible in ipairs(TornadoInsuranceEquipment ~= nil and TornadoInsuranceEquipment.DEDUCTIBLES or {}) do
            options[#options + 1] = { value = deductible, text = TornadoText.format("tp_ins_deductible_option", TornadoText.money(deductible * scale)) }
        end
        return options
    end, function() initChoices() return state.equip end, function(value) state.equip = value end),
    choice("insLivestock", function()
        return { { value = "none", text = TornadoText.get("tp_ins_not_included") },
            { value = "insured", text = TornadoText.get("tp_ins_livestock_all") } }
    end, function() initChoices() return state.livestock end, function(value) state.livestock = value end),

    action("insQuote", function()
        local text = buildQuote()
        state.quoteText = text
        state.quoted = signature()
        return nil
    end, { requires = isOn }),
    action("insConfirm", function() return confirm() end, { requires = isOn, confirm = "tp_confirm_ins_start" }),

    action("insPolCropCancel", function()
        TornadoInsurance:requestAction(getFarmId(), "cropCancel", "")
        invalidateQuote()
        return TornadoText.get("tp_ins_cancel_sent")
    end, { requires = isOn, confirm = "tp_confirm_ins_cancel_crop" }),
    action("insPolEquipCancel", function()
        TornadoInsurance:requestAction(getFarmId(), "equipCancel", "")
        invalidateQuote()
        return TornadoText.get("tp_ins_cancel_sent")
    end, { requires = isOn, confirm = "tp_confirm_ins_cancel_equip" }),
    action("insPolLivestockCancel", function()
        TornadoInsurance:requestAction(getFarmId(), "livestockCancel", "")
        invalidateQuote()
        return TornadoText.get("tp_ins_cancel_sent")
    end, { requires = isOn, confirm = "tp_confirm_ins_cancel_livestock" }),

    choice("insClaimFilter", function()
        local options = {}
        for _, filter in ipairs(CLAIM_FILTERS) do
            options[#options + 1] = { value = filter, text = TornadoText.get(CLAIM_FILTER_KEYS[filter]) }
        end
        return options
    end, function() return state.claimFilter end, function(value)
        state.claimFilter = value
        claimTable:reset(getClaims())
    end, hasInsurance),
    action("insClaimScrollUp", function() claimTable:scroll(-CLAIM_ROWS) return nil end),
    action("insClaimScrollDown", function() claimTable:scroll(CLAIM_ROWS) return nil end),
    -- First / second choice of the selected claim: total loss accept / buy back, write-off / keep the crop.
    action("insClaimAccept", function()
        local claim = getSelectedChoice()
        if claim == nil then
            return TornadoText.get("tp_insurance_equip_total_none")
        end
        TornadoInsurance:requestAction(getFarmId(), claim.kind == "CROP" and "cropWriteOff" or "equipAccept", tostring(claim.id))
        return TornadoText.get("tp_ins_choice_sent")
    end, { requires = isOn, confirm = "tp_confirm_equip_accept" }),
    action("insClaimBuyBack", function()
        local claim = getSelectedChoice()
        if claim == nil then
            return TornadoText.get("tp_insurance_equip_total_none")
        end
        TornadoInsurance:requestAction(getFarmId(), claim.kind == "CROP" and "cropKeep" or "equipBuyBack", tostring(claim.id))
        return TornadoText.get("tp_ins_choice_sent")
    end, { requires = isOn, confirm = "tp_confirm_equip_buyback" }),
}
for slot = 1, CLAIM_ROWS do
    defs[#defs + 1] = action("insClaimRow" .. slot, function()
        claimTable:selectSlot(slot)
        return nil
    end, { slot = slot, table = "claims" })
end
for slot = 1, PAY_ROWS do
    defs[#defs + 1] = action("insPayRow" .. slot, function()
        payTable:selectSlot(slot)
        return nil
    end, { slot = slot, table = "payments" })
end
defs[#defs + 1] = action("insPayScrollUp", function() payTable:scroll(-PAY_ROWS) return nil end)
defs[#defs + 1] = action("insPayScrollDown", function() payTable:scroll(PAY_ROWS) return nil end)

TornadoPageInsurance = TornadoMenuPage.new("Insurance", "Insurance", defs)

local function findDef(id)
    for _, def in ipairs(defs) do
        if def.id == id then
            return def
        end
    end
    return nil
end
TornadoPageInsurance.noLayout = true
TornadoPageInsurance.state = state
TornadoPageInsurance.buildQuote = buildQuote       -- offline tests
TornadoPageInsurance.policyTexts = policyTexts
TornadoPageInsurance.canManage = canManage
TornadoPageInsurance.claimTable = claimTable
TornadoPageInsurance.claimDetail = claimDetail
TornadoPageInsurance.payTable = payTable
TornadoPageInsurance.coverageText = coverageText
TornadoPageInsurance.nextBill = nextBill

local function setText(element, text)
    if element ~= nil then element:setText(text or "") end
end

local function setDisabled(element, disabled)
    if element ~= nil then element:setDisabled(disabled) end
end

--- Draws the active section after the base refresh (which filled the choices).
function TornadoPageInsurance:onRefresh()
    local menu = self.menu
    if menu == nil or not hasInsurance() then
        return
    end
    initChoices()
    if menu.insStart ~= nil then menu.insStart:setVisible(state.section == "start") end
    if menu.insPolicies ~= nil then menu.insPolicies:setVisible(state.section == "policies") end
    if menu.insClaims ~= nil then menu.insClaims:setVisible(state.section == "claims") end
    if menu.insPayments ~= nil then menu.insPayments:setVisible(state.section == "payments") end
    if menu.insInfo ~= nil then menu.insInfo:setVisible(state.section == "info") end
    local manage = canManage()

    -- Start here
    local note
    if not TornadoInsurance.isEnabled then
        note = TornadoText.get("tp_ins_note_off")
    elseif not manage then
        note = TornadoText.get(TornadoInsurance.adminOnly and "tp_ins_note_admin" or "tp_ins_note_manager")
    elseif not cropAvailable() and TornadoInsuranceCrop ~= nil then
        local reason = TornadoInsuranceCrop:getDisabledReason()
        note = reason ~= nil and TornadoText.get("tp_ins_note_crop_off") or TornadoText.get("tp_ins_note_crop_none")
    end
    setText(menu.insStartNote, note)
    setDisabled(menu.insCrop, not (isOn() and cropAvailable()))
    setDisabled(menu.insCropCoverage, not (isOn() and cropAvailable() and state.crop ~= "none"))
    local fresh = state.quoted ~= nil and state.quoted == signature()
    setText(menu.insQuoteText, fresh and state.quoteText or TornadoText.get("tp_ins_q_hint"))
    local anything = false
    if fresh then
        anything = select(2, buildQuote())
    end
    setDisabled(menu.insConfirm, not (isOn() and manage and fresh and anything))

    -- My policies
    local texts = policyTexts()
    setText(menu.insPolCropText, texts.crop)
    setText(menu.insPolEquipText, texts.equip)
    setText(menu.insPolLivestockText, texts.livestock)
    setText(menu.insPolClaims, texts.claims)
    local farm = getFarm()
    setDisabled(menu.insPolCropCancel, not (isOn() and manage and farm ~= nil and farm.crop ~= nil))
    setDisabled(menu.insPolEquipCancel, not (isOn() and manage and farm ~= nil and farm.equipment ~= nil))
    setDisabled(menu.insPolLivestockCancel, not (isOn() and manage and farm ~= nil and farm.livestock ~= nil))

    self:drawClaims(manage)
    self:drawPayments()
    if state.section == "info" then
        setText(menu.insInfoText, coverageText())
    end
end

local function getChild(row, name)
    return row ~= nil and row.getDescendantByName ~= nil and row:getDescendantByName(name) or nil
end

--- Claims section: rows, scroll info, the selected claim and the total-loss buttons.
function TornadoPageInsurance:drawClaims(manage)
    local menu = self.menu
    local claims, numAll = getClaims()
    claimTable:setEntries(claims)
    for slot = 1, CLAIM_ROWS do
        local row = menu["insClaimRow" .. slot]
        local claim = claimTable:getVisible(slot)
        if row ~= nil then
            row:setVisible(claim ~= nil)
            row:setDisabled(claim == nil)
            if claim ~= nil then
                local amount = claimAmount(claim)
                setText(getChild(row, "day"), dayText(claim.day))
                setText(getChild(row, "type"), claimTypeText(claim))
                setText(getChild(row, "subject"), shorten(claimSubject(claim), SUBJECT_CHARS))
                setText(getChild(row, "status"), claimStatusText(claim))
                setText(getChild(row, "amount"), amount ~= nil and TornadoText.money(amount) or "-")
            end
        end
    end
    setDisabled(menu.insClaimScrollUp, not claimTable:canScrollUp())
    setDisabled(menu.insClaimScrollDown, not claimTable:canScrollDown())
    local first, last, total = claimTable:getRange()
    local hidden = numAll - total
    local info
    if total > 0 then
        info = TornadoText.format("tp_msg_showing", first, last, total)
        if hidden > 0 then
            info = info .. " " .. TornadoText.format("tp_msg_hidden_short", hidden)
        end
    elseif hidden > 0 then
        info = TornadoText.format("tp_ins_cl_hidden", hidden)
    else
        info = TornadoText.get("tp_ins_cl_none")
    end
    setText(menu.insClaimInfo, info)

    local claim = claimTable:getSelected()
    setText(menu.insClaimDetailHead, claim ~= nil and string.format("%s #%d - %s", claimTypeText(claim), claim.id or 0, dayText(claim.day, true)) or "")
    setText(menu.insClaimDetailStatus, claim ~= nil and string.format("%s - %s", claimSubject(claim), claimStatusText(claim)) or "")
    setText(menu.insClaimDetailText, claim ~= nil and claimDetail(claim) or info)
    local choiceClaim = getSelectedChoice()
    local isCrop = choiceClaim ~= nil and choiceClaim.kind == "CROP"
    local acceptDef, secondDef = findDef("insClaimAccept"), findDef("insClaimBuyBack")
    if acceptDef ~= nil then acceptDef.confirm = isCrop and "tp_confirm_crop_writeoff" or "tp_confirm_equip_accept" end
    if secondDef ~= nil then secondDef.confirm = isCrop and "tp_confirm_crop_keep" or "tp_confirm_equip_buyback" end
    setText(menu.insClaimAccept, TornadoText.get(isCrop and "tp_btn_ins_write_off" or "tp_btn_ins_accept_total"))
    setText(menu.insClaimBuyBack, TornadoText.get(isCrop and "tp_btn_ins_keep_crop" or "tp_btn_ins_buy_back"))
    if menu.insClaimAccept ~= nil then menu.insClaimAccept:setVisible(choiceClaim ~= nil) end
    if menu.insClaimBuyBack ~= nil then
        menu.insClaimBuyBack:setVisible(choiceClaim ~= nil and (isCrop or TornadoInsurance.removeTotaled ~= false))
    end
    setDisabled(menu.insClaimAccept, not (isOn() and manage and choiceClaim ~= nil))
    setDisabled(menu.insClaimBuyBack, not (isOn() and manage and choiceClaim ~= nil))
    local note = nil
    if choiceClaim ~= nil and not manage then
        note = TornadoText.get(TornadoInsurance.adminOnly and "tp_ins_note_admin" or "tp_ins_note_manager")
    end
    setText(menu.insClaimNote, note)
end

--- Payments section: months, scroll info, totals + next bill, the selected month by policy type.
function TornadoPageInsurance:drawPayments()
    local menu = self.menu
    payTable:setEntries(getMonths())
    for slot = 1, PAY_ROWS do
        local row = menu["insPayRow" .. slot]
        local month = payTable:getVisible(slot)
        if row ~= nil then
            row:setVisible(month ~= nil)
            row:setDisabled(month == nil)
            if month ~= nil then
                setText(getChild(row, "month"), TornadoText.month(month.month))
                setText(getChild(row, "premiums"), TornadoText.money(month.premiums or 0))
                setText(getChild(row, "payouts"), TornadoText.money(month.payouts or 0))
                setText(getChild(row, "net"), signedMoney((month.payouts or 0) - (month.premiums or 0)))
            end
        end
    end
    setDisabled(menu.insPayScrollUp, not payTable:canScrollUp())
    setDisabled(menu.insPayScrollDown, not payTable:canScrollDown())
    local first, last, total = payTable:getRange()
    setText(menu.insPayInfo, total > 0 and TornadoText.format("tp_msg_showing", first, last, total) or TornadoText.get("tp_ins_pay_none"))
    setText(menu.insPayTotals, totalsText())
    self:drawChart()
    local month = payTable:getSelected()
    setText(menu.insPayMonthHead, month ~= nil and TornadoText.month(month.month) or "")
    setText(menu.insPayMonthText, month ~= nil and monthText(month) or "")
end

--- Premiums vs. payouts of the last CHART_MONTHS months (oldest left), bars scaled to the biggest amount.
function TornadoPageInsurance:drawChart()
    local menu = self.menu
    local farm = getFarm()
    local byMonth = {}
    for _, month in ipairs(farm ~= nil and farm.history or {}) do
        byMonth[month.month] = month
    end
    local current = TornadoInsurance.getMonthIndex ~= nil and TornadoInsurance:getMonthIndex() or 0
    local biggest = 0
    for i = 0, CHART_MONTHS - 1 do
        local month = byMonth[current - i]
        if month ~= nil then
            biggest = math.max(biggest, month.premiums or 0, month.payouts or 0)
        end
    end
    local function setBar(bar, value)
        if bar == nil then
            return
        end
        local full = bar.tornadoFullHeight
        if biggest <= 0 or (value or 0) <= 0 or full == nil then
            bar:setVisible(false)
            return
        end
        bar:setVisible(true)
        bar:setSize(nil, math.max(full * 0.02, full * value / biggest))
    end
    for slot = 1, CHART_MONTHS do
        local index = current - (CHART_MONTHS - slot)
        local month = byMonth[index]
        setBar(menu["insChartP" .. slot], month ~= nil and month.premiums or 0)
        setBar(menu["insChartO" .. slot], month ~= nil and month.payouts or 0)
        setText(menu["insChartL" .. slot], index >= 1 and TornadoText.monthShort(index) or "")
    end
    setText(menu.insChartEmpty, biggest > 0 and "" or TornadoText.get("tp_ins_pay_chart_empty"))
    setText(menu.insChartMax, biggest > 0 and TornadoText.money(biggest) or "")
end

local TABLES = { claims = claimTable, payments = payTable }
local ROW_PREFIX = { claims = "insClaimRow", payments = "insPayRow" }
local NUM_ROWS = { claims = CLAIM_ROWS, payments = PAY_ROWS }

--- Row selection look: the row and its cells ask getIsSelected() (same trick as the Messages table).
local baseBind = TornadoMenuPage.bind
function TornadoPageInsurance:bind(menu)
    baseBind(self, menu)
    self.tableElements = { claims = menu.insClaimTable, payments = menu.insPayTable }
    -- Chart bars: their XML height is the full height; drawChart scales them.
    for slot = 1, CHART_MONTHS do
        for _, prefix in ipairs({ "insChartP", "insChartO" }) do
            local bar = menu[prefix .. slot]
            if bar ~= nil and bar.size ~= nil then
                bar.tornadoFullHeight = bar.size[2]
            end
        end
    end
    for name, tbl in pairs(TABLES) do
        for slot = 1, NUM_ROWS[name] do
            local row = menu[ROW_PREFIX[name] .. slot]
            if row ~= nil then
                local isSelected = function()
                    return tbl:getSelectedSlot() == slot
                end
                row.getIsSelected = isSelected
                for _, child in ipairs(row.elements or {}) do
                    child.getIsSelected = isSelected
                end
            end
        end
    end
end

--- Row focus (controller / keyboard) selects that row of its table.
function TornadoPageInsurance:onRowFocus(def)
    local tbl = def ~= nil and TABLES[def.table or ""] or nil
    if tbl ~= nil and def.slot ~= nil and tbl:selectSlot(def.slot) then
        self:refresh()
    end
end

--- Mouse wheel over the visible section's table: one row per notch.
function TornadoPageInsurance:onMouseWheel(posX, posY, direction)
    local tbl = TABLES[state.section]
    local area = self.tableElements ~= nil and self.tableElements[state.section] or nil
    if tbl == nil or area == nil or area.absPosition == nil or area.absSize == nil or GuiUtils == nil then
        return false
    end
    if not GuiUtils.checkOverlayOverlap(posX, posY, area.absPosition[1], area.absPosition[2], area.absSize[1], area.absSize[2]) then
        return false
    end
    if tbl:scroll(direction) then
        self:refresh()
    end
    return true
end

--- Every visit: choices start again from the farm's current policies, old quotes are dropped.
function TornadoPageInsurance:onShow()
    state.crop, state.coverage, state.equip, state.livestock = nil, nil, nil, nil
    invalidateQuote()
    if state.claimFilter ~= "ALL" then
        state.claimFilter = "ALL"
        claimTable:reset(getClaims())
    end
    self:refresh()
end

function TornadoPageInsurance:getFirstFocusElement()
    local menu = self.menu
    if menu == nil then return nil end
    if state.section == "claims" then
        local slot = claimTable:getSelectedSlot()
        return slot ~= nil and menu["insClaimRow" .. slot] or menu.insNavClaims
    elseif state.section == "payments" then
        local slot = payTable:getSelectedSlot()
        return slot ~= nil and menu["insPayRow" .. slot] or menu.insNavPayments
    elseif state.section == "info" then
        return menu.insNavInfo
    end
    return state.section == "start" and menu.insNavStart or menu.insNavPolicies
end
