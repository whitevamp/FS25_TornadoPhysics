-- Offline test for scripts/insurance/TornadoInsuranceFinance.lua (Finances-page rows + Red Tape tax) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_finance.lua
-- Stubs FinanceStats, I18N, Utils.overwrittenFunction and Red Tape's RTTaxSystem (1.0.3.0 behaviour).
-- Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- stubs
Utils = { overwrittenFunction = function(old, new)
    return function(self, ...) return new(self, old, ...) end
end }
FinanceStats = { statNames = { "newVehiclesCost", "other" }, statNameToIndex = { newVehiclesCost = 1, other = 2 } }
local lookups = {}
I18N = { getText = function(_, text, modEnv) table.insert(lookups, { text = text, env = modEnv }) return text .. "@" .. tostring(modEnv) end }
g_currentModName = "FS25_TornadoPhysics"

-- Red Tape stand-in: categoriseLineItem only knows its own lists (here: newVehiclesCost as an expense).
local uncategorised = {}
local RTTaxSystem = {}
function RTTaxSystem:getTaxedAmount(lineItem, taxStatement) return lineItem.amount * 0.5 end
function RTTaxSystem:categoriseLineItem(lineItem, taxStatement)
    if lineItem.statistic == "newVehiclesCost" then
        taxStatement.totalExpenses = taxStatement.totalExpenses + math.abs(lineItem.amount)
    else
        table.insert(uncategorised, lineItem.statistic)
    end
end
g_modIsLoaded = { FS25_RedTape = true }
FS25_RedTape = { RTTaxSystem = RTTaxSystem }

dofile("scripts/insurance/TornadoInsuranceFinance.lua")
local F = TornadoInsuranceFinance

-- ---------------------------------------------------------------- helpers
local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL  %-62s got %s", label, tostring(got)))
    else
        print(string.format("ok    %-62s %s", label, tostring(got)))
    end
end

-- ---------------------------------------------------------------- Finances-page rows
check("premium row added after the base rows", FinanceStats.statNames[3], F.STAT_PREMIUM)
check("payout row added", FinanceStats.statNames[4], F.STAT_PAYOUT)
check("index table updated", FinanceStats.statNameToIndex[F.STAT_PAYOUT], 4)
dofile("scripts/insurance/TornadoInsuranceFinance.lua")   -- next savegame in the same game session
check("loaded again: no duplicate rows", #FinanceStats.statNames, 4)

-- ---------------------------------------------------------------- texts
check("row title from this mod's texts", I18N.getText({}, "finance_" .. F.STAT_PREMIUM, nil), "finance_tornadoInsurancePremium@FS25_TornadoPhysics")
check("other texts untouched", I18N.getText({}, "finance_other", nil), "finance_other@nil")
check("explicit mod environment kept", I18N.getText({}, "finance_" .. F.STAT_PAYOUT, "X"), "finance_tornadoInsurancePayout@X")
check("text hook installed once", I18N.tornadoInsuranceTextsHooked, true)

-- ---------------------------------------------------------------- Red Tape
check("Red Tape found and wrapped", F.installRedTape(), true)
local wrapped = RTTaxSystem.categoriseLineItem
check("installed again: wrapped only once", F.installRedTape() and RTTaxSystem.categoriseLineItem == wrapped, true)
local statement = { totalExpenses = 0, totalTaxableIncome = 0, totalTaxedIncome = 0 }
RTTaxSystem:categoriseLineItem({ statistic = F.STAT_PREMIUM, amount = -400 }, statement)
check("premium = deductible expense", statement.totalExpenses, 400)
RTTaxSystem:categoriseLineItem({ statistic = F.STAT_PAYOUT, amount = 1000 }, statement)
check("payout = taxable income", statement.totalTaxableIncome, 1000)
check("payout taxed with Red Tape's own rate rules", statement.totalTaxedIncome, 500)
RTTaxSystem:categoriseLineItem({ statistic = "newVehiclesCost", amount = -50 }, statement)
check("Red Tape's own statistics still work", statement.totalExpenses, 450)
check("nothing of ours 'uncategorised'", #uncategorised, 0)

g_modIsLoaded = {}
check("Red Tape not installed: nothing done", F.installRedTape(), false)
g_modIsLoaded = { FS25_RedTape = true }
FS25_RedTape = { RTTaxSystem = {} }
check("Red Tape changed (no categoriseLineItem): skipped", F.installRedTape(), false)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
