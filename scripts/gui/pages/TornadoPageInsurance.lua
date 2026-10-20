---@class TornadoPageInsurance
---@version 1.1 (step 2: Claims)
---@description Insurance tab (full width, decided 2026-10-19): side buttons on the left choose a section.
---   Start here  - choose crop (plan + coverage), equipment (deductible) and livestock cover -> Get quote shows each
---                 line (what is insured, its value, the monthly price, old -> new for a change) and the total ->
---                 Confirm & start sends every chosen policy / change at once. Confirm only works for a fresh quote
---                 of exactly what is chosen.
---   My policies - each policy (status, terms, monthly price, open claims) with Cancel (asks first).
---   Claims      - every claim of the farm (TornadoInsurance:getClaimList) as a table with a type / open filter;
---                 the selected claim in full on the right (amounts, what happens next and when). A total loss
---                 waiting for the farm's choice gets Accept / Buy back here (asks first).
--- Buying, cancelling and choosing are checked on the server (farm manager / admin, TornadoInsurance:canManage);
--- here the buttons are greyed out for players who may not, and everybody may look. Payments / Coverage info
--- follow in a later step. Nothing here is a setting, so the panel is never marked dirty.

local Page = TornadoMenuPage

local CLAIM_ROWS = 10
local SUBJECT_CHARS = 28
local OPEN_STATUS = { RECEIVED = true, INSPECTED = true, APPROVED = true, TOTAL = true }
local CLAIM_FILTERS = { "ALL", "OPEN", "CROP", "EQUIP", "LIVESTOCK" }
local CLAIM_FILTER_KEYS = { ALL = "tp_ins_cl_f_all", OPEN = "tp_ins_cl_f_open", CROP = "tp_ins_cl_type_crop",
    EQUIP = "tp_ins_cl_type_equip", LIVESTOCK = "tp_ins_cl_type_livestock" }

local state = {
    section = "start",       -- "start" | "policies" | "claims"
    claimFilter = "ALL",     -- one of CLAIM_FILTERS
    crop = nil,              -- chosen crop plan id or "none" (nil = take the current policy on the first draw)
    coverage = nil,          -- chosen crop coverage (0.5 - 0.85)
    equip = nil,             -- chosen deductible or 0
    livestock = nil,         -- "insured" | "none"
    quoted = nil,            -- signature of the choices the shown quote is for
    quoteText = nil,
}

local claimTable = TornadoTable.new(CLAIM_ROWS, function(claim) return claim.kind .. "#" .. tostring(claim.id) end)

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

local function policyTexts()
    local farmId = getFarmId()
    local farm = getFarm()
    local texts = {}
    local crop = farm ~= nil and farm.crop or nil
    if crop ~= nil and TornadoInsuranceCrop ~= nil then
        local quote = TornadoInsuranceCrop:getFarmQuote(farmId, crop.plan, crop.coverage, crop)
        texts.crop = TornadoText.format("tp_ins_pol_crop", TornadoText.get(TornadoInsuranceCrop.PLAN_KEYS[crop.plan] or crop.plan),
            percent(crop.coverage), statusText(crop, TornadoInsuranceCrop.STATUS_ACTIVE), quote.fields, TornadoText.money(quote.liability),
            TornadoText.money(quote.monthlyPremium))
    else
        texts.crop = TornadoText.get("tp_ins_pol_crop_none")
    end
    local equip = farm ~= nil and farm.equipment or nil
    if equip ~= nil and TornadoInsuranceEquipment ~= nil then
        local quote = TornadoInsuranceEquipment:getFarmQuote(farmId, equip.deductible)
        texts.equip = TornadoText.format("tp_ins_pol_equip", TornadoText.money(equip.deductible * (TornadoInsurance:getCostScale() or 1)),
            statusText(equip, TornadoInsuranceEquipment.STATUS_ACTIVE), quote.vehicles, TornadoText.money(quote.value),
            TornadoText.money(quote.monthlyPremium))
    else
        texts.equip = TornadoText.get("tp_ins_pol_equip_none")
    end
    local livestock = farm ~= nil and farm.livestock or nil
    if livestock ~= nil and TornadoInsuranceLivestock ~= nil then
        local quote = TornadoInsuranceLivestock:getFarmQuote(farmId)
        texts.livestock = TornadoText.format("tp_ins_pol_livestock", statusText(livestock, TornadoInsuranceLivestock.STATUS_ACTIVE),
            quote.animals, TornadoText.money(quote.value), TornadoText.money(quote.monthlyPremium))
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
        if claimValue(claim, 2) > 0 then
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
    elseif status == "PAID" or status == "SETTLED" or status == "BOUGHT_BACK" then
        table.insert(lines, TornadoText.get("tp_ins_cl_done"))
    end
    return table.concat(lines, "\n")
end

local function getSelectedTotal()
    local claim = claimTable:getSelected()
    if claim ~= nil and claim.kind == "EQUIP" and claim.status == "TOTAL" then
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
    action("insClaimAccept", function()
        local claim = getSelectedTotal()
        if claim == nil then
            return TornadoText.get("tp_insurance_equip_total_none")
        end
        TornadoInsurance:requestAction(getFarmId(), "equipAccept", tostring(claim.id))
        return TornadoText.get("tp_ins_choice_sent")
    end, { requires = isOn, confirm = "tp_confirm_equip_accept" }),
    action("insClaimBuyBack", function()
        local claim = getSelectedTotal()
        if claim == nil then
            return TornadoText.get("tp_insurance_equip_total_none")
        end
        TornadoInsurance:requestAction(getFarmId(), "equipBuyBack", tostring(claim.id))
        return TornadoText.get("tp_ins_choice_sent")
    end, { requires = isOn, confirm = "tp_confirm_equip_buyback" }),
}
for slot = 1, CLAIM_ROWS do
    defs[#defs + 1] = action("insClaimRow" .. slot, function()
        claimTable:selectSlot(slot)
        return nil
    end, { slot = slot })
end

TornadoPageInsurance = TornadoMenuPage.new("Insurance", "Insurance", defs)
TornadoPageInsurance.noLayout = true
TornadoPageInsurance.state = state
TornadoPageInsurance.buildQuote = buildQuote       -- offline tests
TornadoPageInsurance.policyTexts = policyTexts
TornadoPageInsurance.canManage = canManage
TornadoPageInsurance.claimTable = claimTable
TornadoPageInsurance.claimDetail = claimDetail

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
    local totalLoss = getSelectedTotal()
    if menu.insClaimAccept ~= nil then menu.insClaimAccept:setVisible(totalLoss ~= nil) end
    if menu.insClaimBuyBack ~= nil then menu.insClaimBuyBack:setVisible(totalLoss ~= nil and TornadoInsurance.removeTotaled ~= false) end
    setDisabled(menu.insClaimAccept, not (isOn() and manage and totalLoss ~= nil))
    setDisabled(menu.insClaimBuyBack, not (isOn() and manage and totalLoss ~= nil))
    local note = nil
    if totalLoss ~= nil and not manage then
        note = TornadoText.get(TornadoInsurance.adminOnly and "tp_ins_note_admin" or "tp_ins_note_manager")
    end
    setText(menu.insClaimNote, note)
end

--- Row selection look: the row and its cells ask getIsSelected() (same trick as the Messages table).
local baseBind = TornadoMenuPage.bind
function TornadoPageInsurance:bind(menu)
    baseBind(self, menu)
    self.claimTableElement = menu.insClaimTable
    for slot = 1, CLAIM_ROWS do
        local row = menu["insClaimRow" .. slot]
        if row ~= nil then
            local isSelected = function()
                return claimTable:getSelectedSlot() == slot
            end
            row.getIsSelected = isSelected
            for _, child in ipairs(row.elements or {}) do
                child.getIsSelected = isSelected
            end
        end
    end
end

--- Row focus (controller / keyboard) selects that claim.
function TornadoPageInsurance:onRowFocus(def)
    if def ~= nil and def.slot ~= nil and claimTable:selectSlot(def.slot) then
        self:refresh()
    end
end

--- Mouse wheel over the claims table: one row per notch.
function TornadoPageInsurance:onMouseWheel(posX, posY, direction)
    local area = self.claimTableElement
    if state.section ~= "claims" or area == nil or area.absPosition == nil or area.absSize == nil or GuiUtils == nil then
        return false
    end
    if not GuiUtils.checkOverlayOverlap(posX, posY, area.absPosition[1], area.absPosition[2], area.absSize[1], area.absSize[2]) then
        return false
    end
    if claimTable:scroll(direction) then
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
    end
    return state.section == "start" and menu.insNavStart or menu.insNavPolicies
end
