---@class TornadoActionEvent
---@description client -> server: an admin asks the server to run a tornado action (e.g. t_physics randomize).

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoActionEvent = EventIds.getEventClassByName("TornadoActionEvent") or {}
local TornadoActionEvent_mt = Class(TornadoActionEvent, Event)

if EventIds.getEventClassByName("TornadoActionEvent") == nil then
    InitEventClass(TornadoActionEvent, "TornadoActionEvent")
end

TornadoActionEvent.RANDOMIZE = 1
TornadoActionEvent.NUM_BITS = 3

function TornadoActionEvent.emptyNew()
    return Event.new(TornadoActionEvent_mt)
end

function TornadoActionEvent.new(action)
    local self = TornadoActionEvent.emptyNew()
    self.action = action
    return self
end

function TornadoActionEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.action, TornadoActionEvent.NUM_BITS)
end

function TornadoActionEvent:readStream(streamId, connection)
    self.action = streamReadUIntN(streamId, TornadoActionEvent.NUM_BITS)
    self:run(connection)
end

function TornadoActionEvent:run(connection)
    if connection:getIsServer() or not g_currentMission.userManager:getIsConnectionMasterUser(connection) then
        return
    end

    if self.action == TornadoActionEvent.RANDOMIZE and TornadoPhysics ~= nil then
        -- randomizeTornado() broadcasts the new state to every client itself.
        TornadoPhysics:randomizeTornado()
    end
end
