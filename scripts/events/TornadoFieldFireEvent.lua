---@class TornadoFieldFireEvent
---@description server -> clients: a field fire starts (position, size, spread speed) or stops. Clients draw the
--- flames themselves (TornadoFieldFireFX) and grow the ring at the same speed; the crop damage is done on the
--- server and synced by the engine.
---   START : fire id, field id, centre x / z, start radius, max radius, spread speed (m per game second)
---   STOP  : fire id

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoFieldFireEvent = EventIds.getEventClassByName("TornadoFieldFireEvent") or {}
local TornadoFieldFireEvent_mt = Class(TornadoFieldFireEvent, Event)

if EventIds.getEventClassByName("TornadoFieldFireEvent") == nil then
    InitEventClass(TornadoFieldFireEvent, "TornadoFieldFireEvent")
end

TornadoFieldFireEvent.START = 1
TornadoFieldFireEvent.STOP = 2

function TornadoFieldFireEvent.emptyNew()
    return Event.new(TornadoFieldFireEvent_mt)
end

--- fire = { id, fieldId, x, z, radius, maxRadius, speed } (only id is needed for STOP)
function TornadoFieldFireEvent.new(kind, fire)
    local self = TornadoFieldFireEvent.emptyNew()
    self.kind = kind
    self.fire = fire
    return self
end

function TornadoFieldFireEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.kind, 2)
    streamWriteUInt16(streamId, self.fire.id)
    if self.kind == TornadoFieldFireEvent.START then
        streamWriteInt32(streamId, self.fire.fieldId or 0)
        streamWriteFloat32(streamId, self.fire.x)
        streamWriteFloat32(streamId, self.fire.z)
        streamWriteFloat32(streamId, self.fire.radius)
        streamWriteFloat32(streamId, self.fire.maxRadius)
        streamWriteFloat32(streamId, self.fire.speed)
    end
end

function TornadoFieldFireEvent:readStream(streamId, connection)
    self.kind = streamReadUIntN(streamId, 2)
    self.fire = { id = streamReadUInt16(streamId) }
    if self.kind == TornadoFieldFireEvent.START then
        self.fire.fieldId = streamReadInt32(streamId)
        self.fire.x = streamReadFloat32(streamId)
        self.fire.z = streamReadFloat32(streamId)
        self.fire.radius = streamReadFloat32(streamId)
        self.fire.maxRadius = streamReadFloat32(streamId)
        self.fire.speed = streamReadFloat32(streamId)
    end
    self:run(connection)
end

function TornadoFieldFireEvent:run(connection)
    if not connection:getIsServer() or TornadoFieldFireFX == nil then
        return
    end
    if self.kind == TornadoFieldFireEvent.START then
        TornadoFieldFireFX:start(self.fire)
    else
        TornadoFieldFireFX:stop(self.fire.id)
    end
end
