---@class TornadoPageModules
---@description Modules tab: mirrors t_set destruction / recovery / mapui / cargo / husbandry / traffic / wildlife /
--- hazards.

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
})
