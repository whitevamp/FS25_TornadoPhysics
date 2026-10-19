---@class TornadoPageModules
---@description Modules tab: mirrors t_set destruction / recovery / mapui / cargo / husbandry / traffic / wildlife /
--- hazards / insurance.

local Page = TornadoMenuPage
local console = TornadoMenuPage.console
local flipTo = TornadoMenuPage.flipTo

local function hasPhysics()
    return TornadoPhysics ~= nil and TornadoPhysics.settings ~= nil
end

local function hasMapUi()
    return TornadoMapUI ~= nil
end

local function hasCargo()
    return TornadoCargo ~= nil and TornadoCargo.settings ~= nil
end

local function hasHusbandry()
    return TornadoHusbandry ~= nil
end

local function hasTraffic()
    return TornadoTraffic ~= nil
end

local function hasWildlife()
    return TornadoWildlife ~= nil
end

local function hasHazards()
    return TornadoHazards ~= nil
end

local function hasInsurance()
    return TornadoInsurance ~= nil
end

-- Crop policy rows act for the player's own farm (the server checks the permission: farm manager / admin).
local function cropPolicyAvailable()
    return TornadoInsurance ~= nil and TornadoInsuranceCrop ~= nil and TornadoInsurance.isEnabled
        and TornadoInsuranceCrop:isAvailable()
end

local function getPlayerFarmId()
    local farmId = g_currentMission ~= nil and g_currentMission.getFarmId ~= nil and g_currentMission:getFarmId() or 0
    return farmId or 0
end

local function getPlayerPolicy()
    local farm = TornadoInsurance.farms ~= nil and TornadoInsurance.farms[getPlayerFarmId()] or nil
    return farm ~= nil and farm.crop or nil, farm
end

-- Equipment policy rows: also for the player's own farm.
local function equipPolicyAvailable()
    return TornadoInsurance ~= nil and TornadoInsuranceEquipment ~= nil and TornadoInsurance.isEnabled
end

local function getPlayerEquipPolicy()
    local farm = TornadoInsurance.farms ~= nil and TornadoInsurance.farms[getPlayerFarmId()] or nil
    return farm ~= nil and farm.equipment or nil, farm
end

-- Total loss picked in the panel (claim id, this machine only).
local equipChoice = { claimId = nil }

local function getPendingTotals()
    local _, farm = getPlayerEquipPolicy()
    return TornadoInsuranceEquipment:getPendingTotals(farm)
end

local function getChosenTotal()
    local totals = getPendingTotals()
    for _, claim in ipairs(totals) do
        if claim.id == equipChoice.claimId then
            return claim
        end
    end
    return totals[1]
end

local function showInfo(text)
    -- The panel's status line only fits a short sentence: longer texts go to the game's info dialog.
    if InfoDialog ~= nil and InfoDialog.show ~= nil then
        InfoDialog.show(text)
        return nil
    end
    return text
end

local function penaltyRow(id, field, sub)
    return {
        id = id,
        kind = Page.KIND_CHOICE,
        requires = hasInsurance,
        options = function()
            local options = {}
            for percent = 0, 90, 10 do
                options[#options + 1] = { value = percent, text = TornadoText.format("tp_insurance_title_penalty_option", percent) }
            end
            return options
        end,
        get = function()
            return math.floor((TornadoInsurance[field] or 0) * 10 + 0.5) * 10
        end,
        set = function(value)
            return console("cmdSet", "insurance", sub, value)
        end,
    }
end

-- Choice kept on this machine until the player buys (plan / coverage of a policy not bought yet).
local cropChoice = { plan = nil, coverage = 0.75 }

local function getChosenPlan()
    local policy = getPlayerPolicy()
    if policy ~= nil then
        return policy.plan
    end
    if cropChoice.plan == nil then
        local plans = TornadoInsuranceCrop:getOfferedPlans()
        cropChoice.plan = plans[1]
    end
    return cropChoice.plan
end

local function getChosenCoverage()
    local policy = getPlayerPolicy()
    return policy ~= nil and policy.coverage or cropChoice.coverage
end

--- Percent row (25 - 300 %) routed through `t_set hazards <sub> <percent>`.
local function hazardsPercentRow(id, key)
    return {
        id = id,
        kind = Page.KIND_NUMBER,
        requires = hasHazards,
        min = 25, max = 300, step = 25, format = "%d %%",
        get = function()
            return (TornadoHazards[key] or 1.0) * 100
        end,
        set = function(value)
            return console("cmdSet", "hazards", key, value)
        end,
    }
end

--- Number row routed through `t_set cargo <sub> <value>`.
local function cargoRow(id, sub, key, min, max, step, format)
    return {
        id = id,
        kind = Page.KIND_NUMBER,
        requires = hasCargo,
        min = min, max = max, step = step, format = format,
        get = function()
            return TornadoCargo.settings[key]
        end,
        set = function(value)
            return console("cmdSet", "cargo", sub, value)
        end,
    }
end

TornadoPageModules = TornadoMenuPage.new("Modules", "Modules", {
    -- Gameplay
    {
        id = "modDestruction",
        kind = Page.KIND_BOOL,
        requires = hasPhysics,
        get = function()
            return TornadoPhysics.settings.destructionEnabled
        end,
        set = function(value)
            return console("cmdSet", "destruction", value and "on" or "off")
        end,
    },
    {
        id = "modRecovery",
        kind = Page.KIND_BOOL,
        requires = function()
            return TornadoSettings ~= nil
        end,
        keepClean = true, -- the console handler saves the XML itself
        get = function()
            return TornadoSettings.recoveryEnabled
        end,
        set = function(value)
            return flipTo(value, TornadoSettings.recoveryEnabled, "cmdSet", "recovery")
        end,
    },
    {
        id = "modMoneyScale",
        kind = Page.KIND_NUMBER,
        requires = function()
            return TornadoSettings ~= nil
        end,
        min = 25, max = 200, step = 5, format = "%d %%",
        get = function()
            return (TornadoSettings.moneyScale or 1.0) * 100
        end,
        set = function(value)
            return console("cmdSet", "money", value)
        end,
    },

    -- Map overlay
    {
        id = "modMapUi",
        kind = Page.KIND_BOOL,
        localOnly = true,
        requires = hasMapUi,
        get = function()
            return TornadoMapUI.enabled
        end,
        set = function(value)
            return console("cmdSet", "mapui", value and "on" or "off")
        end,
    },
    {
        id = "modMapUiSelected",
        kind = Page.KIND_BOOL,
        localOnly = true,
        requires = hasMapUi,
        get = function()
            return TornadoMapUI.onlyWhenSelected
        end,
        set = function(value)
            return flipTo(value, TornadoMapUI.onlyWhenSelected, "cmdSet", "mapui", "sel")
        end,
    },

    -- Cargo spilling
    {
        id = "modCargo",
        kind = Page.KIND_BOOL,
        requires = hasCargo,
        get = function()
            return TornadoCargo.isEnabled
        end,
        set = function(value)
            return flipTo(value, TornadoCargo.isEnabled, "cmdSet", "cargo", "toggle")
        end,
    },
    cargoRow("modCargoSpillHeight", "spill_height", "spillHeight", 0, 10, 0.25, "%.2f m"),
    cargoRow("modCargoSpillAngle", "spill_angle", "spillAngle", 0, 1, 0.05, "%.2f"),
    cargoRow("modCargoDrainRate", "drain_rate", "drainRate", 0.01, 1, 0.01, "%.2f"),
    cargoRow("modCargoSpread", "spread", "spreadRadius", 0.5, 20, 0.5, "%.1f m"),
    cargoRow("modCargoLeakChance", "leak_chance", "coverLeakChance", 0, 1, 0.05, function(value)
        return string.format("%d %%", math.floor(value * 100 + 0.5))
    end),
    {
        id = "modCargoVerbose",
        kind = Page.KIND_BOOL,
        localOnly = true,
        requires = hasCargo,
        keepClean = true, -- not part of the XML
        get = function()
            return TornadoCargo.isVerbose
        end,
        set = function(value)
            return flipTo(value, TornadoCargo.isVerbose, "cmdSet", "cargo", "verbose")
        end,
    },

    -- Livestock
    {
        id = "modHusbandry",
        kind = Page.KIND_BOOL,
        requires = hasHusbandry,
        get = function()
            return TornadoHusbandry.isActive
        end,
        set = function(value)
            return flipTo(value, TornadoHusbandry.isActive, "cmdSet", "husbandry", "toggle")
        end,
    },
    {
        id = "modHusbandryImmunity",
        kind = Page.KIND_NUMBER,
        requires = hasHusbandry,
        min = 0, max = 600, step = 15,
        format = function(value)
            return string.format("%d:%02d min", math.floor(value / 60), math.floor(value % 60))
        end,
        get = function()
            return (TornadoHusbandry.IMMUNITY_DURATION or 0) / 1000
        end,
        set = function(value)
            return console("cmdSet", "husbandry", "immunity", value)
        end,
    },

    -- Road traffic
    {
        id = "modTraffic",
        kind = Page.KIND_BOOL,
        requires = hasTraffic,
        get = function()
            return TornadoTraffic.isEnabled
        end,
        set = function(value)
            return console("cmdSet", "traffic", value and "on" or "off")
        end,
    },
    {
        id = "modTrafficBuffer",
        kind = Page.KIND_NUMBER,
        requires = hasTraffic,
        min = 0, max = 200, step = 10, format = "%d m",
        get = function()
            return TornadoTraffic.bufferDistance
        end,
        set = function(value)
            return console("cmdSet", "traffic", "buffer", value)
        end,
    },

    -- Wildlife
    {
        id = "modWildlife",
        kind = Page.KIND_BOOL,
        requires = hasWildlife,
        get = function()
            return TornadoWildlife.isEnabled
        end,
        set = function(value)
            return console("cmdSet", "wildlife", value and "on" or "off")
        end,
    },
    {
        id = "modWildlifeDistance",
        kind = Page.KIND_NUMBER,
        requires = hasWildlife,
        min = 0, max = 500, step = 25, format = "%d m",
        get = function()
            return TornadoWildlife.fleeDistance
        end,
        set = function(value)
            return console("cmdSet", "wildlife", "distance", value)
        end,
    },

    -- Natural hazards
    {
        id = "modHazards",
        kind = Page.KIND_BOOL,
        requires = hasHazards,
        get = function()
            return TornadoHazards.isEnabled
        end,
        set = function(value)
            return console("cmdSet", "hazards", value and "on" or "off")
        end,
    },
    {
        id = "modHazardsDrought",
        kind = Page.KIND_BOOL,
        requires = hasHazards,
        get = function()
            return TornadoHazards.droughtEnabled
        end,
        set = function(value)
            return console("cmdSet", "hazards", "drought", value and "on" or "off")
        end,
    },
    {
        id = "modHazardsFlood",
        kind = Page.KIND_BOOL,
        requires = hasHazards,
        get = function()
            return TornadoHazards.floodEnabled
        end,
        set = function(value)
            return console("cmdSet", "hazards", "flood", value and "on" or "off")
        end,
    },
    {
        id = "modHazardsFire",
        kind = Page.KIND_BOOL,
        requires = hasHazards,
        get = function()
            return TornadoHazards.fireEnabled
        end,
        set = function(value)
            return console("cmdSet", "hazards", "fire", value and "on" or "off")
        end,
    },
    {
        id = "modHazardsOwned",
        kind = Page.KIND_BOOL,
        requires = hasHazards,
        get = function()
            return TornadoHazards.ownedOnly
        end,
        set = function(value)
            return console("cmdSet", "hazards", "owned", value and "on" or "off")
        end,
    },
    hazardsPercentRow("modHazardsIntensity", "intensity"),
    hazardsPercentRow("modHazardsFrequency", "frequency"),

    -- Insurance
    {
        id = "modInsurance",
        kind = Page.KIND_BOOL,
        requires = hasInsurance,
        get = function()
            return TornadoInsurance.isEnabled
        end,
        set = function(value)
            return console("cmdSet", "insurance", value and "on" or "off")
        end,
    },
    {
        id = "modInsuranceAdminOnly",
        kind = Page.KIND_BOOL,
        requires = hasInsurance,
        get = function()
            return TornadoInsurance.adminOnly
        end,
        set = function(value)
            return console("cmdSet", "insurance", "managers", value and "admin" or "farm")
        end,
    },
    {
        id = "modInsuranceSales",
        kind = Page.KIND_CHOICE,
        requires = hasInsurance,
        options = function()
            return {
                { value = "auto", text = TornadoText.get("tp_insurance_sales_auto") },
                { value = "on", text = TornadoText.get("tp_insurance_sales_on") },
                { value = "off", text = TornadoText.get("tp_insurance_sales_off") },
            }
        end,
        get = function()
            return TornadoInsurance.salesClosing or "auto"
        end,
        set = function(value)
            return console("cmdSet", "insurance", "sales", value)
        end,
    },
    {
        id = "modInsuranceValue",
        kind = Page.KIND_CHOICE,
        requires = hasInsurance,
        options = function()
            return {
                { value = "game", text = TornadoText.get("tp_insurance_value_game") },
                { value = "real", text = TornadoText.get("tp_insurance_value_real") },
            }
        end,
        get = function()
            return TornadoInsurance.valueBasis or "game"
        end,
        set = function(value)
            return console("cmdSet", "insurance", "value", value)
        end,
    },
    {
        id = "modInsuranceReplacement",
        kind = Page.KIND_BOOL,
        requires = hasInsurance,
        get = function()
            return TornadoInsurance.replacementValue == true
        end,
        set = function(value)
            return console("cmdSet", "insurance", "replacement", value and "on" or "off")
        end,
    },
    {
        id = "modInsuranceRemoveTotaled",
        kind = Page.KIND_BOOL,
        requires = hasInsurance,
        get = function()
            return TornadoInsurance.removeTotaled ~= false
        end,
        set = function(value)
            return console("cmdSet", "insurance", "totaled", value and "remove" or "keep")
        end,
    },
    penaltyRow("modInsuranceSalvage", "salvagePenalty", "salvage"),
    penaltyRow("modInsuranceRebuilt", "rebuiltPenalty", "rebuilt"),
    {
        id = "modInsuranceCropPlan",
        kind = Page.KIND_CHOICE,
        requires = cropPolicyAvailable,
        localOnly = true,
        keepClean = true,
        options = function()
            local options = { { value = "none", text = TornadoText.get("tp_plan_none") } }
            for _, planId in ipairs(TornadoInsuranceCrop:getOfferedPlans()) do
                options[#options + 1] = { value = planId, text = TornadoText.get(TornadoInsuranceCrop.PLAN_KEYS[planId] or planId) }
            end
            return options
        end,
        get = function()
            local policy = getPlayerPolicy()
            return policy ~= nil and policy.plan or "none"
        end,
        set = function(value)
            local farmId = getPlayerFarmId()
            if value == "none" then
                if getPlayerPolicy() ~= nil then
                    TornadoInsurance:requestAction(farmId, "cropCancel", "")
                end
                return nil
            end
            cropChoice.plan = value
            TornadoInsurance:requestAction(farmId, "cropBuy", string.format("%s %.2f", value, getChosenCoverage()))
            return nil
        end,
    },
    {
        id = "modInsuranceCropCoverage",
        kind = Page.KIND_CHOICE,
        requires = cropPolicyAvailable,
        localOnly = true,
        keepClean = true,
        options = function()
            local planId = getChosenPlan()
            local policy = getPlayerPolicy()
            local options = {}
            for _, coverage in ipairs(planId ~= nil and TornadoInsuranceCrop:getCoverageLevels(planId) or {}) do
                local quote = TornadoInsuranceCrop:getFarmQuote(getPlayerFarmId(), planId, coverage, policy)
                options[#options + 1] = { value = coverage, text = TornadoText.format("tp_insurance_coverage_option",
                    math.floor(coverage * 100 + 0.5), TornadoText.money(quote.monthlyPremium)) }
            end
            return options
        end,
        get = function()
            return getChosenCoverage()
        end,
        set = function(value)
            cropChoice.coverage = value
            local policy = getPlayerPolicy()
            if policy ~= nil then
                TornadoInsurance:requestAction(getPlayerFarmId(), "cropBuy", string.format("%s %.2f", policy.plan, value))
            end
            return nil
        end,
    },
    {
        id = "modInsuranceCropStatus",
        kind = Page.KIND_ACTION,
        requires = cropPolicyAvailable,
        localOnly = true,
        keepClean = true,
        run = function()
            local policy, farm = getPlayerPolicy()
            local text
            if policy == nil then
                text = TornadoText.get("tp_msg_ins_crop_none_status")
            else
                local quote = TornadoInsuranceCrop:getFarmQuote(getPlayerFarmId(), policy.plan, policy.coverage, policy)
                text = TornadoText.format("tp_msg_ins_crop_status",
                TornadoText.get(TornadoInsuranceCrop.PLAN_KEYS[policy.plan] or policy.plan),
                math.floor((policy.coverage or 0) * 100 + 0.5),
                TornadoText.get(policy.status == TornadoInsuranceCrop.STATUS_ACTIVE and "tp_ins_status_active" or "tp_ins_status_pending"),
                    quote.fields, TornadoText.money(quote.liability), TornadoText.money(quote.monthlyPremium),
                    farm ~= nil and (farm.openClaims or TornadoInsuranceCrop:getOpenClaimCount(farm)) or 0)
            end
            -- The panel's status line only fits a short sentence: show the summary in the game's info dialog.
            if InfoDialog ~= nil and InfoDialog.show ~= nil then
                InfoDialog.show(text)
                return nil
            end
            return text
        end,
    },
    -- Equipment policy (player's farm)
    {
        id = "modInsuranceEquipDeductible",
        kind = Page.KIND_CHOICE,
        requires = equipPolicyAvailable,
        localOnly = true,
        keepClean = true,
        options = function()
            local options = { { value = 0, text = TornadoText.get("tp_insurance_equip_none") } }
            local scale = TornadoInsurance:getCostScale() or 1
            for _, deductible in ipairs(TornadoInsuranceEquipment.DEDUCTIBLES) do
                local quote = TornadoInsuranceEquipment:getFarmQuote(getPlayerFarmId(), deductible)
                options[#options + 1] = { value = deductible, text = TornadoText.format("tp_insurance_equip_option",
                    TornadoText.money(deductible * scale), TornadoText.money(quote.monthlyPremium)) }
            end
            return options
        end,
        get = function()
            local policy = getPlayerEquipPolicy()
            return policy ~= nil and policy.deductible or 0
        end,
        set = function(value)
            local farmId = getPlayerFarmId()
            if value == 0 then
                if getPlayerEquipPolicy() ~= nil then
                    TornadoInsurance:requestAction(farmId, "equipCancel", "")
                end
                return nil
            end
            TornadoInsurance:requestAction(farmId, "equipBuy", tostring(value))
            return nil
        end,
    },
    {
        id = "modInsuranceEquipStatus",
        kind = Page.KIND_ACTION,
        requires = equipPolicyAvailable,
        localOnly = true,
        keepClean = true,
        run = function()
            local policy, farm = getPlayerEquipPolicy()
            if policy == nil then
                return showInfo(TornadoText.get("tp_msg_ins_eq_none_status"))
            end
            local quote = TornadoInsuranceEquipment:getFarmQuote(getPlayerFarmId(), policy.deductible)
            local scale = TornadoInsurance:getCostScale() or 1
            return showInfo(TornadoText.format("tp_msg_ins_eq_status", TornadoText.money(policy.deductible * scale),
                TornadoText.get(policy.status == TornadoInsuranceEquipment.STATUS_ACTIVE and "tp_ins_status_active" or "tp_ins_status_pending"),
                quote.vehicles, TornadoText.money(quote.value), TornadoText.money(quote.monthlyPremium),
                #TornadoInsuranceEquipment:getPendingTotals(farm)))
        end,
    },
    {
        id = "modInsuranceEquipTotal",
        kind = Page.KIND_CHOICE,
        requires = equipPolicyAvailable,
        localOnly = true,
        keepClean = true,
        options = function()
            local options = {}
            for _, claim in ipairs(getPendingTotals()) do
                options[#options + 1] = { value = claim.id, text = TornadoText.format("tp_insurance_equip_total_option",
                    claim.name or "?", TornadoText.money(claim.lossPayout or 0), TornadoText.money(claim.buyBackPayout or 0)) }
            end
            if #options == 0 then
                options[1] = { value = 0, text = TornadoText.get("tp_insurance_equip_total_none") }
            end
            return options
        end,
        get = function()
            local claim = getChosenTotal()
            return claim ~= nil and claim.id or 0
        end,
        set = function(value)
            equipChoice.claimId = value
            return nil
        end,
    },
    {
        id = "modInsuranceEquipAccept",
        kind = Page.KIND_ACTION,
        requires = equipPolicyAvailable,
        localOnly = true,
        keepClean = true,
        confirm = "tp_confirm_equip_accept",
        run = function()
            local claim = getChosenTotal()
            if claim == nil then
                return TornadoText.get("tp_insurance_equip_total_none")
            end
            TornadoInsurance:requestAction(getPlayerFarmId(), "equipAccept", tostring(claim.id))
            equipChoice.claimId = nil
            return nil
        end,
    },
    {
        id = "modInsuranceEquipBuyBack",
        kind = Page.KIND_ACTION,
        requires = equipPolicyAvailable,
        localOnly = true,
        keepClean = true,
        confirm = "tp_confirm_equip_buyback",
        run = function()
            local claim = getChosenTotal()
            if claim == nil then
                return TornadoText.get("tp_insurance_equip_total_none")
            end
            TornadoInsurance:requestAction(getPlayerFarmId(), "equipBuyBack", tostring(claim.id))
            equipChoice.claimId = nil
            return nil
        end,
    },
    -- Livestock policy (player's farm)
    {
        id = "modInsuranceLivestock",
        kind = Page.KIND_CHOICE,
        requires = function()
            return TornadoInsurance ~= nil and TornadoInsuranceLivestock ~= nil and TornadoInsurance.isEnabled
        end,
        localOnly = true,
        keepClean = true,
        options = function()
            -- What is priced: animals, their value, the monthly premium (no animals: say so instead of "$0").
            local quote = TornadoInsuranceLivestock:getFarmQuote(getPlayerFarmId())
            local insuredText = quote.animals > 0 and TornadoText.format("tp_insurance_livestock_option", quote.animals,
                TornadoText.money(quote.value), TornadoText.money(quote.monthlyPremium)) or TornadoText.get("tp_insurance_livestock_empty")
            return {
                { value = "none", text = TornadoText.get("tp_insurance_livestock_none") },
                { value = "insured", text = insuredText },
            }
        end,
        get = function()
            local farm = TornadoInsurance.farms ~= nil and TornadoInsurance.farms[getPlayerFarmId()] or nil
            return farm ~= nil and farm.livestock ~= nil and "insured" or "none"
        end,
        set = function(value)
            local farm = TornadoInsurance.farms ~= nil and TornadoInsurance.farms[getPlayerFarmId()] or nil
            local has = farm ~= nil and farm.livestock ~= nil
            if value == "insured" and not has then
                TornadoInsurance:requestAction(getPlayerFarmId(), "livestockBuy", "")
            elseif value == "none" and has then
                TornadoInsurance:requestAction(getPlayerFarmId(), "livestockCancel", "")
            end
            return nil
        end,
    },
    {
        id = "modInsuranceLivestockStatus",
        kind = Page.KIND_ACTION,
        requires = function()
            return TornadoInsurance ~= nil and TornadoInsuranceLivestock ~= nil and TornadoInsurance.isEnabled
        end,
        localOnly = true,
        keepClean = true,
        run = function()
            local farm = TornadoInsurance.farms ~= nil and TornadoInsurance.farms[getPlayerFarmId()] or nil
            local policy = farm ~= nil and farm.livestock or nil
            local quote = TornadoInsuranceLivestock:getFarmQuote(getPlayerFarmId())
            local statusKey = "tp_ins_status_none"
            if policy ~= nil then
                statusKey = policy.status == TornadoInsuranceLivestock.STATUS_ACTIVE and "tp_ins_status_active" or "tp_ins_status_pending"
            end
            local text = TornadoText.format("tp_msg_ins_lv_status", TornadoText.get(statusKey), quote.animals,
                TornadoText.money(quote.value), TornadoText.money(quote.monthlyPremium),
                TornadoText.get(TornadoInsuranceLivestock:hasGovProgram() and "tp_ins_lv_gov_us" or "tp_ins_lv_gov_none"))
            if not TornadoInsuranceLivestock.isHusbandryOn() then
                text = text .. "\n\n" .. TornadoText.get("tp_ins_lv_husbandry_off")
            end
            return showInfo(text)
        end,
    },
    {
        id = "modInsuranceRegion",
        kind = Page.KIND_CHOICE,
        requires = hasInsurance,
        options = function()
            -- "Auto (United States - Kansas)": shows what the detection found.
            local autoName = TornadoInsurance.regionSetting == TornadoInsurance.REGION_AUTO and TornadoInsurance:getRegionName()
                or nil
            local options = { { value = TornadoInsurance.REGION_AUTO, text = autoName ~= nil
                and TornadoText.format("tp_insurance_region_auto_found", autoName) or TornadoText.get("tp_insurance_region_auto") } }
            for _, option in ipairs(TornadoInsurance:getRegionOptions()) do
                options[#options + 1] = { value = option.value, text = option.name }
            end
            return options
        end,
        get = function()
            return TornadoInsurance.regionSetting
        end,
        set = function(value)
            return console("cmdSet", "insurance", "region", value)
        end,
    },
})
