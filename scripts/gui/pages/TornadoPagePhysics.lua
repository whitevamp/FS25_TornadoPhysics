---@class TornadoPagePhysics
---@description Physics tab: mirrors t_physics (radius, power, heavy, fence, dmg_in, dmg_out, toggles, randomize)
--- plus t_set climate (real-life tornado climate mode and region).

local Page = TornadoMenuPage
local console = TornadoMenuPage.console
local flipTo = TornadoMenuPage.flipTo

local function hasPhysics()
    return TornadoPhysics ~= nil and TornadoPhysics.settings ~= nil
end

local function setting(key)
    return function()
        return TornadoPhysics.settings[key]
    end
end

--- Number row routed through `t_physics <sub> <value>`.
local function numberRow(id, sub, key, min, max, step, format)
    return {
        id = id,
        kind = Page.KIND_NUMBER,
        requires = hasPhysics,
        min = min, max = max, step = step, format = format,
        get = setting(key),
        set = function(value)
            return console("cmdPhysics", sub, value)
        end,
    }
end

--- On/Off row routed through the matching `t_physics <sub>` toggle.
local function toggleRow(id, sub, key)
    return {
        id = id,
        kind = Page.KIND_BOOL,
        requires = hasPhysics,
        get = setting(key),
        set = function(value)
            return flipTo(value, TornadoPhysics.settings[key], "cmdPhysics", sub)
        end,
    }
end

local function hasClimate()
    return TornadoClimate ~= nil and TornadoClimate:hasData()
end

--- Sub-features only do something in real-life mode, so they are greyed out while it is off.
local function climateOn()
    return hasClimate() and TornadoClimate.isEnabled
end

local function climateToggle(id, sub, field)
    return {
        id = id,
        kind = Page.KIND_BOOL,
        requires = climateOn,
        get = function()
            return TornadoClimate[field]
        end,
        set = function(value)
            return console("cmdSet", "climate", sub, value and "on" or "off")
        end,
    }
end

TornadoPagePhysics = TornadoMenuPage.new("Physics", "Physics", {
    -- Real-life climate
    {
        id = "physClimate",
        kind = Page.KIND_BOOL,
        requires = hasClimate,
        get = function()
            return TornadoClimate.isEnabled
        end,
        set = function(value)
            return console("cmdSet", "climate", value and "on" or "off")
        end,
    },
    {
        id = "physClimateRegion",
        kind = Page.KIND_CHOICE,
        requires = hasClimate,
        options = function()
            local options = { { value = "AUTO", text = TornadoClimate:getRegionLabel("AUTO") } }
            for _, id in ipairs(TornadoClimate.regionOrder) do
                options[#options + 1] = { value = id, text = TornadoClimate.regions[id].name }
            end
            return options
        end,
        get = function()
            return TornadoClimate.regionSetting
        end,
        set = function(value)
            return console("cmdSet", "climate", "region", value)
        end,
    },
    climateToggle("physClimateSeasons", "seasons", "useSeasonality"),
    climateToggle("physClimateDirection", "direction", "useDirection"),
    climateToggle("physClimateOutbreaks", "outbreaks", "useOutbreaks"),
    {
        id = "physClimateFrequency",
        kind = Page.KIND_NUMBER,
        requires = climateOn,
        min = 0.25, max = 4, step = 0.25, format = "x%.2f",
        get = function()
            return TornadoClimate.frequency
        end,
        set = function(value)
            return console("cmdSet", "climate", "frequency", value)
        end,
    },
    {
        id = "physClimateOutbreakMax",
        kind = Page.KIND_NUMBER,
        requires = climateOn,
        min = 2, max = 10, step = 1, format = "%d",
        get = function()
            return TornadoClimate.outbreakMax
        end,
        set = function(value)
            return console("cmdSet", "climate", "outbreakmax", value)
        end,
    },

    -- Storm
    numberRow("physRadius", "radius", "base_radius", 10, 150, 5, "%d m"),
    numberRow("physPower", "power", "ejection_power", 5, 100, 1, "%d"),
    numberRow("physHeavy", "heavy", "heavy_threshold", 0.5, 20, 0.5, "%.1f t"),
    {
        id = "physRandomize",
        kind = Page.KIND_ACTION,
        requires = hasPhysics,
        keepClean = true,
        run = function()
            return console("cmdPhysics", "randomize")
        end,
    },

    -- Damage
    numberRow("physDmgIn", "dmg_in", "damage_center", 0, 1, 0.01, "%.2f / s"),
    numberRow("physDmgOut", "dmg_out", "damage_outer", 0, 1, 0.01, "%.2f / s"),
    toggleRow("physOutdoorDamage", "outdoor_damage", "outdoor_damage"),
    toggleRow("physIndoorDamage", "indoor_damage", "indoor_damage"),

    -- Objects
    toggleRow("physLiftBales", "lift_bales", "lift_bales"),
    toggleRow("physLiftLogs", "lift_logs", "lift_logs"),

    -- Map border
    toggleRow("physBorder", "border", "border_safety"),
    numberRow("physFence", "fence", "geo_fence", 0, 200, 5, "%d m"),
})

--- Note under the climate rows: what the next tornado will use, and the last real-life roll.
function TornadoPagePhysics:onRefresh()
    local note = self.menu ~= nil and self.menu.physClimateNote or nil
    if note == nil then
        return
    end

    if TornadoClimate == nil or not TornadoClimate:hasData() then
        note:setText(TornadoText.get("tp_note_climate_missing"))
        return
    end
    if not TornadoClimate.isEnabled then
        note:setText(TornadoText.get("tp_note_classic"))
        return
    end

    local region = TornadoClimate:getActiveRegion()
    if region == nil then
        note:setText(TornadoText.get("tp_note_no_region"))
        return
    end

    local text = TornadoText.format("tp_note_next_region", region.name)
    local last = TornadoClimate.lastRoll
    if last ~= nil then
        -- The last roll keeps the region it was rolled with, even after the region setting changes.
        text = text .. " " .. TornadoText.format("tp_note_last_roll", last.regionName, last.ef)
        if last.width ~= nil then
            text = text .. " " .. TornadoText.format("tp_note_real_width", last.width)
        end
        text = text .. "."
    end
    local storm = TornadoWeather ~= nil and TornadoWeather.lastProfile or nil
    if storm ~= nil and storm.region ~= nil then
        text = text .. " " .. TornadoText.format("tp_note_storm",
            storm.hailCm ~= nil and string.format("%.1f cm", storm.hailCm) or TornadoText.get("tp_none"), storm.gustKmh)
    end
    note:setText(text)
end
