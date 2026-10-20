-- Offline test for TornadoText.date (a save day shown as the game's calendar month / day / year).
-- Lua 5.1. Run from the mod root:  lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_date.lua
-- Real: TornadoText, the game's Environment:getPeriodFromDay / getDayInPeriodFromDay and I18N:formatPeriod
-- (copied from dataS/scripts_decoded). Exit code 0 = all checks passed.

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local environment = { daysPerPeriod = 1, currentDay = 6, currentMonotonicDay = 6, daylight = { latitude = 40 } }
g_currentMission = { environment = environment }
g_i18n = {
    hasText = function(_, key) return key == "tp_date_year" or key == "tp_msg_day" end,
    getText = function(_, key)
        if key == "tp_date_year" then return "year %d" end
        if key == "tp_msg_day" then return "Day" end
        local month = tonumber(string.match(key, "^ui_month(%d+)"))
        return month ~= nil and MONTHS[month] or key
    end,
}
-- I18N:formatPeriod (game code): period 1 = March in the north, September in the south.
function g_i18n:formatPeriod(period, useShort)
    local month = period + 2
    if g_currentMission.environment.daylight.latitude < 0 then month = month + 6 end
    return self:getText("ui_month" .. (month - 1) % 12 + 1 .. (useShort and "_short" or ""))
end
-- Environment (game code)
function environment:getPeriodFromDay(day)
    local diff = day - self.currentMonotonicDay
    return math.ceil(((self.currentDay + diff - 1) % (self.daysPerPeriod * 12) + 1) / self.daysPerPeriod)
end
function environment:getDayInPeriodFromDay(day)
    return (self.currentDay + day - self.currentMonotonicDay - 1) % self.daysPerPeriod + 1
end

dofile("scripts/TornadoText.lua")

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

-- The user's save: 1 day per month, day 6 of the save = the 6th month from March = August.
check("1 day/month: day 6 = Aug", TornadoText.date(6), "Aug")
check("1 day/month: with year", TornadoText.date(6, true), "Aug, year 1")
check("1 day/month: day 11 = Jan of year 1", TornadoText.date(11, true), "Jan, year 1")
check("1 day/month: day 13 = Mar of year 2", TornadoText.date(13, true), "Mar, year 2")
check("1 day/month: day 4 (earlier) = Jun", TornadoText.date(4), "Jun")
-- 3 days per month, today = save day 20 = seasonal day 20 (Sep 2)
environment.daysPerPeriod, environment.currentDay, environment.currentMonotonicDay = 3, 20, 20
check("3 days/month: today", TornadoText.date(20), "Sep 2")
check("3 days/month: 2 days ago", TornadoText.date(18), "Aug 3")
check("3 days/month: next year", TornadoText.date(37, true), "Mar 1, year 2")
-- Southern map: months shifted by 6
environment.daylight.latitude = -30
check("southern map", TornadoText.date(20), "Mar 2")
-- No environment: the old "Day N"
g_currentMission = nil
check("no environment: Day N", TornadoText.date(12), "Day 12")

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
