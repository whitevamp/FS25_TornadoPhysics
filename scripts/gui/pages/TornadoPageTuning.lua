---@class TornadoPageTuning
---@description Tuning tab: mirrors t_tune (suction, lift, bale_orbit, bale_suction, purge_time, purge_int,
--- chaos, hover, max_speed, destruct_ratio).

local Page = TornadoMenuPage
local console = TornadoMenuPage.console

local function hasPhysics()
    return TornadoPhysics ~= nil and TornadoPhysics.settings ~= nil
end

local function seconds(ms)
    return string.format("%.1f s", ms / 1000)
end

--- Number row routed through `t_tune <param> <value>`.
local function tuneRow(id, param, key, min, max, step, format)
    return {
        id = id,
        kind = Page.KIND_NUMBER,
        requires = hasPhysics,
        min = min, max = max, step = step, format = format,
        get = function()
            return TornadoPhysics.settings[key]
        end,
        set = function(value)
            return console("cmdTune", param, value)
        end,
    }
end

TornadoPageTuning = TornadoMenuPage.new("Tuning", "Tuning", {
    -- Movement
    tuneRow("tuneSuction", "suction", "suction_speed", 0, 150, 5, "%d"),
    tuneRow("tuneLift", "lift", "lift_speed", 0, 60, 1, "%d"),
    tuneRow("tuneChaos", "chaos", "chaos_factor", 0, 30, 0.5, "%.1f"),
    tuneRow("tuneHover", "hover", "hover_height", 5, 120, 5, "%d m"),
    tuneRow("tuneMaxSpeed", "max_speed", "max_safe_speed", 5, 120, 5, "%d"),
    tuneRow("tuneDestructRatio", "destruct_ratio", "destruction_ratio", 0.05, 1, 0.05, "%.2f"),

    -- Bales
    tuneRow("tuneBaleOrbit", "bale_orbit", "bale_orbit", 0, 80, 1, "%d"),
    tuneRow("tuneBaleSuction", "bale_suction", "bale_suction", 0, 80, 1, "%d"),

    -- Ejection cycle (stored in ms, shown in seconds)
    tuneRow("tunePurgeTime", "purge_time", "purge_duration", 1000, 20000, 500, seconds),
    tuneRow("tunePurgeInterval", "purge_int", "purge_interval", 5000, 180000, 5000, seconds),
})
