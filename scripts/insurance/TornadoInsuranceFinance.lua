---@class TornadoInsuranceFinance
---@version 1.0
---@description Own rows on the game's Finances page for the insurance - "Insurance premiums" and "Insurance
--- payouts" - instead of booking them under "Other", and (when FS25_RedTape by Ozz is installed) premiums as a
--- deductible expense and payouts as taxable income on its tax statement.
---
--- Must run while the mod's scripts load (TornadoMain sources it at the top, like the events): the farms' finance
--- tables are built from FinanceStats.statNames when the savegame loads, before any loadMap. The base-game
--- tables survive savegame reloads, so everything here is added once (guard flags / duplicate checks).
---   * FinanceStats.statNames + statNameToIndex: the two statistics (row order = list order; the finance page,
---     its save file entries and the FinanceStatsEvent network order all follow this list - the same on every
---     machine with the same mods);
---   * I18N.getText: the page asks for "finance_<statistic>" without a mod environment, so these two keys are
---     looked up in this mod's texts (the same way Red Tape does it for its rows);
---   * Red Tape: its RTTaxSystem:categoriseLineItem only knows its own list of statistics (local to the function)
---     and logs "Uncategorised" for others - wrapped once (installRedTape, from TornadoInsurance:loadMap) so our
---     two count. Unofficial: checked against Red Tape 1.0.3.0; nothing happens when it is missing or changed.

TornadoInsuranceFinance = {}

TornadoInsuranceFinance.STAT_PREMIUM = "tornadoInsurancePremium"
TornadoInsuranceFinance.STAT_PAYOUT = "tornadoInsurancePayout"
TornadoInsuranceFinance.REDTAPE_MOD = "FS25_RedTape"

local modName = g_currentModName

local OWN_TEXTS = {
    ["finance_" .. TornadoInsuranceFinance.STAT_PREMIUM] = true,
    ["finance_" .. TornadoInsuranceFinance.STAT_PAYOUT] = true,
}

--- The two statistics on the Finances page (once; the list survives savegame reloads).
function TornadoInsuranceFinance.registerStatistics()
    if FinanceStats == nil or FinanceStats.statNames == nil or FinanceStats.statNameToIndex == nil then
        return false
    end
    for _, name in ipairs({ TornadoInsuranceFinance.STAT_PREMIUM, TornadoInsuranceFinance.STAT_PAYOUT }) do
        if FinanceStats.statNameToIndex[name] == nil then
            table.insert(FinanceStats.statNames, name)
            FinanceStats.statNameToIndex[name] = #FinanceStats.statNames
        end
    end
    return true
end

--- "finance_tornadoInsurance..." asked without a mod environment -> this mod's translations.
function TornadoInsuranceFinance.installTexts()
    if I18N == nil or I18N.getText == nil or I18N.tornadoInsuranceTextsHooked then
        return
    end
    I18N.tornadoInsuranceTextsHooked = true
    I18N.getText = Utils.overwrittenFunction(I18N.getText, function(i18n, superFunc, text, modEnv)
        if modEnv == nil and OWN_TEXTS[text] then
            return superFunc(i18n, text, modName)
        end
        return superFunc(i18n, text, modEnv)
    end)
end

--- Is this one of our two statistics?
function TornadoInsuranceFinance.isOwnStatistic(statistic)
    return statistic == TornadoInsuranceFinance.STAT_PREMIUM or statistic == TornadoInsuranceFinance.STAT_PAYOUT
end

--- Red Tape's tax statement: premiums = expense (deductible), payouts = taxable income (like real crop insurance
--- indemnities). Called from TornadoInsurance:loadMap; returns true when Red Tape is there and wrapped.
function TornadoInsuranceFinance.installRedTape()
    if g_modIsLoaded == nil or not g_modIsLoaded[TornadoInsuranceFinance.REDTAPE_MOD] then
        return false
    end
    local env = _G[TornadoInsuranceFinance.REDTAPE_MOD]
    local taxSystem = type(env) == "table" and env.RTTaxSystem or nil
    if type(taxSystem) ~= "table" or type(taxSystem.categoriseLineItem) ~= "function" then
        print("TORNADO INSURANCE: Red Tape found, but its tax system has changed (no RTTaxSystem.categoriseLineItem) - " ..
            "insurance premiums / payouts are not on its tax statement.")
        return false
    end
    if taxSystem.tornadoInsuranceHooked then
        return true
    end
    taxSystem.tornadoInsuranceHooked = true
    local original = taxSystem.categoriseLineItem
    taxSystem.categoriseLineItem = function(system, lineItem, taxStatement, ...)
        if lineItem ~= nil and taxStatement ~= nil and TornadoInsuranceFinance.isOwnStatistic(lineItem.statistic) then
            local amount = math.abs(tonumber(lineItem.amount) or 0)
            if lineItem.statistic == TornadoInsuranceFinance.STAT_PREMIUM then
                taxStatement.totalExpenses = (taxStatement.totalExpenses or 0) + amount
            else
                taxStatement.totalTaxableIncome = (taxStatement.totalTaxableIncome or 0) + amount
                local taxed = amount
                if system.getTaxedAmount ~= nil then
                    taxed = system:getTaxedAmount(lineItem, taxStatement)
                end
                taxStatement.totalTaxedIncome = (taxStatement.totalTaxedIncome or 0) + taxed
            end
            return
        end
        return original(system, lineItem, taxStatement, ...)
    end
    if TornadoDebug then
        TornadoDebug:info("INSURANCE", "Red Tape found: insurance premiums count as expenses, payouts as taxable income.")
    end
    return true
end

-- While the mod's scripts load: before the savegame builds the farms' finance tables.
TornadoInsuranceFinance.registerStatistics()
TornadoInsuranceFinance.installTexts()
