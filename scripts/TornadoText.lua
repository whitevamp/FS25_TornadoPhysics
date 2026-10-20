---@class TornadoText
---@description Player-visible texts in the player's language (translations/translation_xx.xml, built from
--- tools/translations_source.py). Console and log output stay English on purpose.
--- Messages the server sends to clients travel as a text key plus parameters, so every player reads them
--- in their own language (see TornadoMessageEvent).

TornadoText = {}

-- The mod's own g_i18n (it holds the texts of translations/; falls back to the game's texts). Taken while
-- this file loads in the mod environment, so calls from anywhere use the mod's texts.
local modI18n = g_i18n

-- Parameter types of a networked message (TornadoMessageEvent).
TornadoText.PARAM_STRING = 0 -- shown as is (names, region names)
TornadoText.PARAM_NUMBER = 1 -- for %d / %.1f
TornadoText.PARAM_KEY = 2    -- a text key, translated on the receiving machine
TornadoText.PARAM_MONEY = 3  -- an amount, formatted in the receiver's currency

--- The text of a key, or the key itself when it is unknown (never nil).
function TornadoText.get(key)
    if key == nil then
        return ""
    end
    if modI18n ~= nil and modI18n:hasText(key) then
        return modI18n:getText(key)
    end
    return key
end

--- string.format on a translated text.
function TornadoText.format(key, ...)
    return string.format(TornadoText.get(key), ...)
end

--- Money in the player's currency.
function TornadoText.money(amount)
    if modI18n ~= nil and modI18n.formatMoney ~= nil then
        return modI18n:formatMoney(amount or 0, 0, true, true)
    end
    return string.format("$%d", math.floor((amount or 0) + 0.5))
end

--- A day of the save (environment.currentMonotonicDay counting) as the game's calendar shows it: "Aug" at one
--- day per month, else "Aug 3"; withYear adds ", year 2". Without an environment (offline tests): "Day 12".
function TornadoText.date(day, withYear)
    local mission = g_currentMission
    local environment = mission ~= nil and mission.environment or nil
    if environment == nil or environment.getPeriodFromDay == nil or modI18n == nil or modI18n.formatPeriod == nil
        or environment.currentDay == nil or environment.currentMonotonicDay == nil then
        return string.format("%s %d", TornadoText.get("tp_msg_day"), day or 0)
    end
    day = day or environment.currentMonotonicDay
    local period = environment:getPeriodFromDay(day)
    local text = modI18n:formatPeriod(period, true) or "?"
    local daysPerPeriod = math.max(1, environment.daysPerPeriod or 1)
    if daysPerPeriod > 1 then
        text = string.format("%s %d", text, environment:getDayInPeriodFromDay(day))
    end
    if withYear then
        local seasonalDay = environment.currentDay + (day - environment.currentMonotonicDay)
        local year = math.floor((seasonalDay - 1) / (daysPerPeriod * 12)) + 1
        text = text .. ", " .. TornadoText.format("tp_date_year", math.max(1, year))
    end
    return text
end

--- Compass code from TornadoClimate.directionToLabel ("N", "NE", ...) in the player's language.
function TornadoText.direction(code)
    if code == nil then
        return nil
    end
    return TornadoText.get("tp_dir_" .. code)
end

-- Builders for message parameters: TornadoText.str("x"), TornadoText.num(3), ...
function TornadoText.str(value) return { type = TornadoText.PARAM_STRING, value = tostring(value or "") } end
function TornadoText.num(value) return { type = TornadoText.PARAM_NUMBER, value = tonumber(value) or 0 } end
function TornadoText.key(value) return { type = TornadoText.PARAM_KEY, value = tostring(value or "") } end
function TornadoText.cash(value) return { type = TornadoText.PARAM_MONEY, value = tonumber(value) or 0 } end

--- Builds the final text of a message on this machine.
function TornadoText.formatMessage(key, params)
    local args = {}
    for i, param in ipairs(params or {}) do
        if param.type == TornadoText.PARAM_NUMBER then
            args[i] = param.value
        elseif param.type == TornadoText.PARAM_KEY then
            args[i] = TornadoText.get(param.value)
        elseif param.type == TornadoText.PARAM_MONEY then
            args[i] = TornadoText.money(param.value)
        else
            args[i] = tostring(param.value)
        end
    end
    return string.format(TornadoText.get(key), unpack(args))
end
