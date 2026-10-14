---@class TornadoWeatherEvent
---@description server -> clients: the storm weather the server rolled (supercell type, rain, hail, wind),
--- so every player sees the same storm instead of rolling their own.

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoWeatherEvent = EventIds.getEventClassByName("TornadoWeatherEvent") or {}
local TornadoWeatherEvent_mt = Class(TornadoWeatherEvent, Event)

if EventIds.getEventClassByName("TornadoWeatherEvent") == nil then
    InitEventClass(TornadoWeatherEvent, "TornadoWeatherEvent")
end

function TornadoWeatherEvent.emptyNew()
    return Event.new(TornadoWeatherEvent_mt)
end

--- @param profile table TornadoWeather profile (see TornadoWeather:applyProfile)
function TornadoWeatherEvent.new(profile)
    local self = TornadoWeatherEvent.emptyNew()
    self.profile = profile
    return self
end

function TornadoWeatherEvent:writeStream(streamId, connection)
    local p = self.profile
    streamWriteUIntN(streamId, p.index or 1, 3)
    streamWriteFloat32(streamId, p.rain or 0)
    streamWriteFloat32(streamId, p.hail or 0)
    streamWriteString(streamId, p.region or "")
    streamWriteFloat32(streamId, p.hailCm or -1)
    streamWriteFloat32(streamId, p.gustKmh or -1)
    streamWriteBool(streamId, p.severeWind == true)
    streamWriteFloat32(streamId, p.windMps or -1)
    streamWriteFloat32(streamId, p.headingDeg or -1)
end

function TornadoWeatherEvent:readStream(streamId, connection)
    local p = {}
    p.index = streamReadUIntN(streamId, 3)
    p.rain = streamReadFloat32(streamId)
    p.hail = streamReadFloat32(streamId)
    p.region = streamReadString(streamId)
    p.hailCm = streamReadFloat32(streamId)
    p.gustKmh = streamReadFloat32(streamId)
    p.severeWind = streamReadBool(streamId)
    p.windMps = streamReadFloat32(streamId)
    p.headingDeg = streamReadFloat32(streamId)

    -- -1 / "" mean "not set"
    if p.region == "" then p.region = nil end
    if p.hailCm < 0 then p.hailCm = nil end
    if p.gustKmh < 0 then p.gustKmh = nil end
    if p.windMps < 0 then p.windMps = nil end
    if p.headingDeg < 0 then p.headingDeg = nil end

    self.profile = p
    self:run(connection)
end

function TornadoWeatherEvent:run(connection)
    if connection:getIsServer() and TornadoWeather ~= nil then
        TornadoWeather:applyReceivedProfile(self.profile)
    end
end
