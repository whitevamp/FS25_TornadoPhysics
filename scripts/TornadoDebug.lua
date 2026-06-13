---@class TornadoDebug
---@version 1.4 (POS TRACKER)
---@description Added specific flag for position tracking to reduce console spam.

TornadoDebug = {}
--TornadoDebug.verboseMode = false
TornadoDebug.verboseMode = false -- The global master switch
TornadoDebug.verboseDestruction = false -- Specifically for save/load/repair
TornadoDebug.verbosePhysics = false -- Specifically for suction/ejection
TornadoDebug.showPosition = false -- Separate flag for coordinate spam

function TornadoDebug:loadMap()
    print("--------------------------------------------------")
    print("TORNADO DEBUG: SYSTEM ONLINE")
end

function TornadoDebug:deleteMap()
end

function TornadoDebug:log(tag, msg)
    if self.verboseMode then
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