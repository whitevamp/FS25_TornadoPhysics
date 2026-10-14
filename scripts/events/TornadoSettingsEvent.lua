---@class TornadoSettingsEvent
---@description Full snapshot of the shared gameplay settings (TornadoSync.SETTINGS).
---   server -> client : on join and after every change; the client just applies it.
---   client -> server : an admin changed something; the server checks the sender is an admin,
---                      applies, saves its config and re-broadcasts to everyone else.

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoSettingsEvent = EventIds.getEventClassByName("TornadoSettingsEvent") or {}
local TornadoSettingsEvent_mt = Class(TornadoSettingsEvent, Event)

if EventIds.getEventClassByName("TornadoSettingsEvent") == nil then
    InitEventClass(TornadoSettingsEvent, "TornadoSettingsEvent")
end

function TornadoSettingsEvent.emptyNew()
    return Event.new(TornadoSettingsEvent_mt)
end

--- Captures the current settings when written.
function TornadoSettingsEvent.new()
    return TornadoSettingsEvent.emptyNew()
end

function TornadoSettingsEvent:writeStream(streamId, connection)
    TornadoSync.writeSettings(streamId)
end

function TornadoSettingsEvent:readStream(streamId, connection)
    self.values = TornadoSync.readSettings(streamId)
    self:run(connection)
end

function TornadoSettingsEvent:run(connection)
    if connection:getIsServer() then
        -- Received from the server: this is the game's real configuration.
        TornadoSync.applySettings(self.values)
        return
    end

    -- Received from a client: only admins may change shared gameplay settings.
    if not g_currentMission.userManager:getIsConnectionMasterUser(connection) then
        -- Put the sender back on the server's values.
        connection:sendEvent(TornadoSettingsEvent.new())
        return
    end

    TornadoSync.applySettings(self.values)
    if TornadoSettings ~= nil then
        TornadoSettings:saveToXML()
    end
    g_server:broadcastEvent(TornadoSettingsEvent.new(), false, connection)
end
