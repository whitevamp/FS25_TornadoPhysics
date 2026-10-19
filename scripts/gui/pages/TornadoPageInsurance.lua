---@class TornadoPageInsurance
---@version 1.0 (step 1: Start here + My policies)
---@description Insurance tab (full width, decided 2026-10-19): side buttons on the left choose a section.
---   Start here  - choose crop (plan + coverage), equipment (deductible) and livestock cover -> Get quote shows each
---                 line (what is insured, its value, the monthly price, old -> new for a change) and the total ->
---                 Confirm & start sends every chosen policy / change at once. Confirm only works for a fresh quote
---                 of exactly what is chosen.
---   My policies - each policy (status, terms, monthly price, open claims) with Cancel (asks first).
--- Buying and cancelling are checked on the server (farm manager / admin, TornadoInsurance:canManage); here the
--- buttons are greyed out for players who may not, and everybody may look at quotes. Claims / Payments / Coverage
--- info follow in later steps. Nothing here is a setting, so the panel is never marked dirty.

local Page = TornadoMenuPage

local state = {
    section = "start",       -- "start" | "policies"
    crop = nil,              -- chosen crop plan id or "none" (nil = take the current policy on the first draw)
    coverage = nil,          -- chosen crop coverage (0.5 - 0.85)
    equip = nil,             -- chosen deductible or 0
    livestock = nil,         -- "insured" | "none"
    quoted = nil,            -- signature of the choices the shown quote is for
    quoteText = nil,
}

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
}

TornadoPageInsurance = TornadoMenuPage.new("Insurance", "Insurance", defs)
TornadoPageInsurance.noLayout = true
TornadoPageInsurance.state = state
TornadoPageInsurance.buildQuote = buildQuote       -- offline tests
TornadoPageInsurance.policyTexts = policyTexts
TornadoPageInsurance.canManage = canManage

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
    local onStart = state.section == "start"
    if menu.insStart ~= nil then menu.insStart:setVisible(onStart) end
    if menu.insPolicies ~= nil then menu.insPolicies:setVisible(not onStart) end
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
end

--- Every visit: choices start again from the farm's current policies, old quotes are dropped.
function TornadoPageInsurance:onShow()
    state.crop, state.coverage, state.equip, state.livestock = nil, nil, nil, nil
    invalidateQuote()
    self:refresh()
end

function TornadoPageInsurance:getFirstFocusElement()
    local menu = self.menu
    if menu == nil then return nil end
    return state.section == "start" and menu.insNavStart or menu.insNavPolicies
end
