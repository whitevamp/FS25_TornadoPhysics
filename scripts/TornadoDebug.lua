---@class TornadoDebug
---@version 1.4 (POS TRACKER)
---@description Added specific flag for position tracking to reduce console spam.

TornadoDebug = {}
TornadoDebug.verboseMode = false -- The global master switch
TornadoDebug.verboseDestruction = false -- Specifically for save/load/repair
TornadoDebug.verboseIndoorBypass = false
TornadoDebug.verboseRecovery = false --
TornadoDebug.verbosePhysics = false -- Specifically for suction/ejection
TornadoDebug.verboseWeather = false -- Weather system
TornadoDebug.showPosition = false -- Separate flag for coordinate spam

function TornadoDebug:loadMap()
    print("--------------------------------------------------")
    print("TORNADO DEBUG: SYSTEM ONLINE")
end

function TornadoDebug:deleteMap()
end

function TornadoDebug:log(tag, msg)
    -- 1. If the master switch is on, everything prints
    local shouldLog = self.verboseMode 

    -- 2. If the master switch is off, check the specific channels
    if not shouldLog then
        if tag == "DESTRUCTION" and self.verboseDestruction then shouldLog = true end
        if tag == "PHYSICS" and self.verbosePhysics then shouldLog = true end
        if tag == "RECOVERY" and self.verboseRecovery then shouldLog = true end
        if tag == "WEATHER" and self.verboseWeather then shouldLog = true end
    end

    -- 3. Print if a switch was active
    if shouldLog then
        print(string.format("[%s] %s", tag, msg))
    end
end

function TornadoDebug:info(tag, msg)
    print(string.format("[%s] %s", tag, msg))
end

-- Dedicated Position Logger
function TornadoDebug:logPos(msg)
    if self.showPosition then
        print(string.format("[POS] %s", msg))
    end
end

