---@class TornadoDestructionEvent
---@description server -> clients: vehicle parts hidden by TornadoDestruction (or shown again on repair).
--- Nodes are sent as hierarchy paths (TornadoSync.encodeNodePath) because node ids differ per machine.

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoDestructionEvent = EventIds.getEventClassByName("TornadoDestructionEvent") or {}
local TornadoDestructionEvent_mt = Class(TornadoDestructionEvent, Event)

if EventIds.getEventClassByName("TornadoDestructionEvent") == nil then
    InitEventClass(TornadoDestructionEvent, "TornadoDestructionEvent")
end

TornadoDestructionEvent.MAX_NODES = 1023   -- 10 bits
TornadoDestructionEvent.MAX_DEPTH = 63     -- 6 bits

function TornadoDestructionEvent.emptyNew()
    return Event.new(TornadoDestructionEvent_mt)
end

--- @param vehicle table
--- @param nodes table|nil  TornadoDestruction node list ({ id = node, name = ... }); ignored for repairs
--- @param isRepair boolean true = show the vehicle's hidden parts again
function TornadoDestructionEvent.new(vehicle, nodes, isRepair)
    local self = TornadoDestructionEvent.emptyNew()
    self.vehicle = vehicle
    self.isRepair = isRepair == true
    self.paths = {}

    if not self.isRepair and nodes ~= nil then
        for _, nodeInfo in ipairs(nodes) do
            local entry = TornadoSync.encodeNodePath(vehicle, nodeInfo.id)
            if entry ~= nil and #entry.path <= TornadoDestructionEvent.MAX_DEPTH and #self.paths < TornadoDestructionEvent.MAX_NODES then
                self.paths[#self.paths + 1] = entry
            end
        end
    end
    return self
end

function TornadoDestructionEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isRepair)
    if self.isRepair then
        return
    end
    streamWriteUIntN(streamId, #self.paths, 10)
    for _, entry in ipairs(self.paths) do
        streamWriteUInt8(streamId, entry.component)
        streamWriteUIntN(streamId, #entry.path, 6)
        for _, index in ipairs(entry.path) do
            streamWriteUInt16(streamId, index)
        end
    end
end

function TornadoDestructionEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isRepair = streamReadBool(streamId)
    self.paths = {}
    if not self.isRepair then
        local count = streamReadUIntN(streamId, 10)
        for _ = 1, count do
            local entry = { component = streamReadUInt8(streamId), path = {} }
            local depth = streamReadUIntN(streamId, 6)
            for _ = 1, depth do
                entry.path[#entry.path + 1] = streamReadUInt16(streamId)
            end
            self.paths[#self.paths + 1] = entry
        end
    end
    self:run(connection)
end

function TornadoDestructionEvent:run(connection)
    if not connection:getIsServer() or TornadoDestruction == nil then
        return
    end
    if self.isRepair then
        TornadoDestruction:clientRepair(self.vehicle)
    else
        TornadoDestruction:clientDestroy(self.vehicle, self.paths)
    end
end
