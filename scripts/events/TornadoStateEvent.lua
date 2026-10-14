---@class TornadoStateEvent
---@description server -> clients: the tornado's rolled stats, so clients show the same EF rating, funnel size,
--- map overlay, hotspot, compass marker, siren and touchdown warning as the host.
--- Sent on touchdown / re-roll (isNewTouchdown = true), on despawn (isActive = false) and to joining players.

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoStateEvent = EventIds.getEventClassByName("TornadoStateEvent") or {}
local TornadoStateEvent_mt = Class(TornadoStateEvent, Event)

if EventIds.getEventClassByName("TornadoStateEvent") == nil then
    InitEventClass(TornadoStateEvent, "TornadoStateEvent")
end

function TornadoStateEvent.emptyNew()
    return Event.new(TornadoStateEvent_mt)
end

--- Captures the server's current tornado stats.
function TornadoStateEvent.new(isActive, isNewTouchdown)
    local self = TornadoStateEvent.emptyNew()
    self.isActive = isActive == true
    self.isNewTouchdown = isNewTouchdown == true

    if self.isActive and TornadoPhysics ~= nil then
        self.efNum = TornadoPhysics.currentEfNum or 0
        self.windMin = TornadoPhysics.currentWindMin or 0
        self.windMax = TornadoPhysics.currentWindMax or 0
        self.radiusM = TornadoPhysics.currentRadiusM or 0
        self.outerRadius = TornadoPhysics:getOuterRadius() or 0
        self.sizeMultiplier = TornadoPhysics.sizeMultiplier or 1
        self.scale = TornadoPhysics.currentScale or 1

        local roll = TornadoClimate ~= nil and TornadoClimate.lastRoll or nil
        self.hasClimateRoll = roll ~= nil
        if roll ~= nil then
            self.rollRegion = roll.region or ""
            self.rollRegionName = roll.regionName or ""
            self.rollEf = roll.ef or 0
            self.rollWidth = roll.width or -1
        end
    end
    return self
end

function TornadoStateEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.isActive)
    if not self.isActive then
        return
    end
    streamWriteBool(streamId, self.isNewTouchdown)
    streamWriteUIntN(streamId, math.max(0, math.min(7, self.efNum)), 3)
    streamWriteUInt16(streamId, math.max(0, math.min(65535, math.floor(self.windMin))))
    streamWriteUInt16(streamId, math.max(0, math.min(65535, math.floor(self.windMax))))
    streamWriteUInt16(streamId, math.max(0, math.min(65535, math.floor(self.radiusM))))
    streamWriteFloat32(streamId, self.outerRadius)
    streamWriteFloat32(streamId, self.sizeMultiplier)
    streamWriteFloat32(streamId, self.scale)

    streamWriteBool(streamId, self.hasClimateRoll)
    if self.hasClimateRoll then
        streamWriteString(streamId, self.rollRegion)
        streamWriteString(streamId, self.rollRegionName)
        streamWriteUIntN(streamId, math.max(0, math.min(7, self.rollEf)), 3)
        streamWriteFloat32(streamId, self.rollWidth)
    end
end

function TornadoStateEvent:readStream(streamId, connection)
    self.isActive = streamReadBool(streamId)
    if self.isActive then
        self.isNewTouchdown = streamReadBool(streamId)
        self.efNum = streamReadUIntN(streamId, 3)
        self.windMin = streamReadUInt16(streamId)
        self.windMax = streamReadUInt16(streamId)
        self.radiusM = streamReadUInt16(streamId)
        self.outerRadius = streamReadFloat32(streamId)
        self.sizeMultiplier = streamReadFloat32(streamId)
        self.scale = streamReadFloat32(streamId)

        self.hasClimateRoll = streamReadBool(streamId)
        if self.hasClimateRoll then
            self.rollRegion = streamReadString(streamId)
            self.rollRegionName = streamReadString(streamId)
            self.rollEf = streamReadUIntN(streamId, 3)
            self.rollWidth = streamReadFloat32(streamId)
        end
    end
    self:run(connection)
end

function TornadoStateEvent:run(connection)
    if connection:getIsServer() and TornadoPhysics ~= nil then
        TornadoPhysics:applyClientState(self)
    end
end
