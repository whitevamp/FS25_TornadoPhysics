---@class TornadoPageDeveloper
---@description Developer tab: mirrors t_dev (hud, pos, verbose channels, status, hotspotdump, kill_test)
--- plus t_set mapui dump. None of these are stored in the XML, so they never trigger auto-save.

local Page = TornadoMenuPage
local console = TornadoMenuPage.console
local flipTo = TornadoMenuPage.flipTo

local function hasDebug()
    return TornadoDebug ~= nil
end

--- On/Off row for a TornadoDebug flag, routed through the matching t_dev toggle.
local function debugRow(id, key, ...)
    local args = { ... }
    return {
        id = id,
        kind = Page.KIND_BOOL,
        requires = hasDebug,
        keepClean = true,
        localOnly = true,
        get = function()
            return TornadoDebug[key]
        end,
        set = function(value)
            return flipTo(value, TornadoDebug[key], "cmdDev", (table.unpack or unpack)(args))
        end,
    }
end

local function actionRow(id, requires, fn, confirm, serverOnly)
    return {
        id = id,
        kind = Page.KIND_ACTION,
        requires = requires,
        keepClean = true,
        localOnly = true,
        serverOnly = serverOnly,
        confirm = confirm,
        run = fn,
    }
end

TornadoPageDeveloper = TornadoMenuPage.new("Developer", "Developer", {
    -- Overlays
    {
        id = "devHud",
        kind = Page.KIND_BOOL,
        localOnly = true,
        serverOnly = true,   -- the telemetry labels are drawn by the server's physics loop
        requires = function()
            return TornadoPhysics ~= nil
        end,
        keepClean = true,
        get = function()
            return TornadoPhysics.debugMode
        end,
        set = function(value)
            return flipTo(value, TornadoPhysics.debugMode, "cmdDev", "hud")
        end,
    },
    debugRow("devPos", "showPosition", "pos"),

    -- Verbose logging ("all" also switches the destruction + physics channels)
    debugRow("devVerboseAll", "verboseMode", "verbose", "all"),
    debugRow("devVerbosePhysics", "verbosePhysics", "verbose", "physics"),
    debugRow("devVerboseDestruction", "verboseDestruction", "verbose", "destruction"),
    debugRow("devVerboseIndoor", "verboseIndoorBypass", "verbose", "destruction_indoor_bypass"),

    -- Diagnostics
    actionRow("devStatus", function()
        return TornadoPhysics ~= nil and TornadoPhysics.activeNodes ~= nil
    end, function()
        return console("cmdDev", "status")
    end),
    actionRow("devHotspotDump", function()
        return TornadoHotspot ~= nil or TornadoMapUI ~= nil
    end, function()
        return console("cmdDev", "hotspotdump")
    end),
    actionRow("devMapUiDump", function()
        return TornadoMapUI ~= nil
    end, function()
        return console("cmdSet", "mapui", "dump")
    end),
    actionRow("devKillTest", function()
        return TornadoHusbandry ~= nil
    end, function()
        return console("cmdDev", "kill_test")
    end, "tp_confirm_kill_test", true),
})
