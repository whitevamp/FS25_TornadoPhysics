---@class TornadoFxEvent
---@description server -> clients: smoke / fire on a tornado-damaged vehicle.
---   FX_CONTACT : the vehicle is being hit (smoke, restarts its smoke timer) - sent at most every 2 s per vehicle
---   FX_BURN    : the server decided this vehicle catches fire (the 50/50 roll is only made on the server)

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoFxEvent = EventIds.getEventClassByName("TornadoFxEvent") or {}
local TornadoFxEvent_mt = Class(TornadoFxEvent, Event)

if EventIds.getEventClassByName("TornadoFxEvent") == nil then
    InitEventClass(TornadoFxEvent, "TornadoFxEvent")
end

function TornadoFxEvent.emptyNew()
    return Event.new(TornadoFxEvent_mt)
end

function TornadoFxEvent.new(vehicle, kind)
    local self = TornadoFxEvent.emptyNew()
    self.vehicle = vehicle
    self.kind = kind
    return self
end

function TornadoFxEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.kind, 2)
end

function TornadoFxEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.kind = streamReadUIntN(streamId, 2)
    self:run(connection)
end

function TornadoFxEvent:run(connection)
    if not connection:getIsServer() or TornadoEffects == nil then
        return
    end
    local vehicle = self.vehicle
    if vehicle == nil or vehicle.rootNode == nil or not entityExists(vehicle.rootNode) then
        return
    end

    if self.kind == TornadoSync.FX_BURN then
        TornadoEffects:markBurning(vehicle.rootNode)
    else
        TornadoEffects:playDamageEffect(vehicle.rootNode)
    end
end
